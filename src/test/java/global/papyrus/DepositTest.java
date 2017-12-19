package global.papyrus;

import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.smartcontracts.SecurityDepositRegistry;
import global.papyrus.utils.PapyrusMember;
import org.testng.Assert;
import org.testng.annotations.BeforeMethod;
import org.web3j.abi.datatypes.Address;

import java.util.concurrent.CompletableFuture;

import static global.papyrus.utils.PapyrusUtils.*;
import static global.papyrus.utils.Web3jUtils.asCf;

public abstract class DepositTest {

    private int memberBalanceBeforeTest;
    private int daoBalanceBeforeTest;
    private int registrarBalanceBeforeTest;
    private SecurityDepositRegistry depositRegistry;

    protected void initDepositContract() {
        depositRegistry = asCf(dao().securityDepositRegistry().sendAsync()).thenApply(registryAddress ->
                loadSecurityDepositRegistry(registryAddress, member().transactionManager)
        ).join();
    }

    @BeforeMethod(enabled = false)
    public void rememberBalances() {
        daoBalanceBeforeTest = asCf(balanceOf(token(), new Address(dao().getContractAddress()))).join();
        memberBalanceBeforeTest = asCf(balanceOf(token(), member().getAddress())).join();
        registrarBalanceBeforeTest = asCf(balanceOf(token(), registrar().getAddress())).join();
    }

    protected void assertDepositsTaken() {
        CompletableFuture.allOf(
                assertMemberBalance(member(), memberBalanceBeforeTest - depositAmount),
                assertMemberBalance(registrar(), registrarBalanceBeforeTest),
                assertDaoBalance(daoBalanceBeforeTest + depositAmount),
                assertRegistryRecord(member(), depositAmount),
                assertRegistryRecord(registrar(), 0)
        ).join();
    }

    protected void assertDepositsReturned() {
        CompletableFuture.allOf(
                assertMemberBalance(member(), memberBalanceBeforeTest + depositAmount),
                assertMemberBalance(registrar(), registrarBalanceBeforeTest),
                assertDaoBalance(daoBalanceBeforeTest - depositAmount),
                assertRegistryRecord(member(), 0),
                assertRegistryRecord(registrar(), 0)
        ).join();
    }

    protected void assertRegistrarDepositsTaken() {
        CompletableFuture.allOf(
                assertMemberBalance(member(), memberBalanceBeforeTest),
                assertMemberBalance(registrar(), registrarBalanceBeforeTest - depositAmount),
                assertDaoBalance(daoBalanceBeforeTest + depositAmount),
                assertRegistryRecord(member(), depositAmount),
                assertRegistryRecord(registrar(), 0)
        ).join();
    }

    protected void assertRegistrarDepositsReturned() {
        CompletableFuture.allOf(
                assertMemberBalance(member(), memberBalanceBeforeTest),
                assertMemberBalance(registrar(), registrarBalanceBeforeTest + depositAmount),
                assertDaoBalance(daoBalanceBeforeTest - depositAmount),
                assertRegistryRecord(member(), 0),
                assertRegistryRecord(registrar(), 0)
        ).join();
    }

    protected CompletableFuture<Void> assertMemberBalance(PapyrusMember member, int balance) {
        return balanceOf(token(), member.getAddress()).thenAccept(
                realBalance -> Assert.assertEquals(realBalance.intValue(), balance)
        );
    }

    protected CompletableFuture<Void> assertDaoBalance(int daoBalance) {
        return balanceOf(token(), new Address(dao().getContractAddress())).thenAccept(
                balance -> Assert.assertEquals(balance.intValue(), daoBalance)
        );
    }

    protected CompletableFuture<Void> assertRegistryRecord(PapyrusMember member, int amount) {
        return asCf(depositRegistry.getDeposit(member.getAddress().getValue()).sendAsync()).thenAccept(deposit ->
                Assert.assertEquals(deposit.intValue(), amount)
        );
    }

    protected abstract PapyrusMember member();

    protected abstract PapyrusMember registrar();

    protected abstract PapyrusDAO dao();

    protected abstract PapyrusPrototypeToken token();
}
