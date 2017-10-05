package global.papyrus;

import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.smartcontracts.SecurityDepositRegistry;
import global.papyrus.utils.PapyrusMember;
import org.testng.Assert;
import org.testng.annotations.BeforeMethod;
import org.web3j.abi.datatypes.Address;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

import static global.papyrus.utils.PapyrusUtils.depositAmount;
import static global.papyrus.utils.PapyrusUtils.loadSecurityDepositRegistry;
import static global.papyrus.utils.Web3jUtils.asCf;

public abstract class DepositTest {

    private int memberBalanceBeforeTest;
    private int daoBalanceBeforeTest;
    private SecurityDepositRegistry depositRegistry;

    protected void initDepositContract() {
        depositRegistry = asCf(dao().securityDepositRegistry()).thenApply(registryAddress ->
                loadSecurityDepositRegistry(registryAddress.toString(), member().transactionManager)
        ).join();
    }

    @BeforeMethod
    public void rememberBalances() throws ExecutionException, InterruptedException {
        daoBalanceBeforeTest = balanceOf(new Address(dao().getContractAddress())).get();
        memberBalanceBeforeTest = balanceOf(member().getAddress()).get();
    }

    protected void testDepositsTaken() {
        CompletableFuture.allOf(
            balanceOf(member().getAddress()).thenAccept(
                    balance -> Assert.assertEquals(balance.intValue(), memberBalanceBeforeTest - depositAmount)
            ),
            balanceOf(new Address(dao().getContractAddress())).thenAccept(
                    balance -> Assert.assertEquals(balance.intValue(), daoBalanceBeforeTest + depositAmount)
            ),
            asCf(depositRegistry.getDeposit(member().getAddress())).thenAccept(deposit ->
                    Assert.assertEquals(deposit.getValue().intValue(), depositAmount)
            )
        ).join();
    }

    protected void testDepositsReturned() {
        CompletableFuture.allOf(
                balanceOf(member().getAddress()).thenAccept(
                        balance -> Assert.assertEquals(balance.intValue(), memberBalanceBeforeTest + depositAmount)
                ),
                balanceOf(new Address(dao().getContractAddress())).thenAccept(
                        balance -> Assert.assertEquals(balance.intValue(), daoBalanceBeforeTest - depositAmount)
                ),
                asCf(depositRegistry.getDeposit(member().getAddress())).thenAccept(deposit ->
                        Assert.assertEquals(deposit.getValue().intValue(), 0)
                )
        ).join();
    }

    protected CompletableFuture<Integer> balanceOf(Address address) {
        return asCf(token().balanceOf(address)).thenApply(uint -> uint.getValue().intValue());
    }

    protected abstract PapyrusMember member();

    protected abstract PapyrusDAO dao();

    protected abstract PapyrusPrototypeToken token();
}
