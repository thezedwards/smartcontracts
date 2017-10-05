package global.papyrus;

import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.smartcontracts.SecurityDepositRegistry;
import global.papyrus.utils.PapyrusMember;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.generated.Uint16;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.crypto.CipherException;

import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.concurrent.ExecutionException;

import static global.papyrus.utils.PapyrusUtils.*;
import static global.papyrus.utils.Web3jUtils.asCf;
import static java.util.Arrays.asList;

/**
 * Created by andreyvlasenko on 03/10/17.
 */
public class SSPTest extends DepositTest{
    private PapyrusMember ssp;
    private PapyrusDAO dao;
    private PapyrusPrototypeToken token;

    @BeforeClass
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException, ExecutionException, InterruptedException {
        ssp = createNewMember(1, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dao = loadDaoContract(ssp.transactionManager);
        token = asCf(dao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), ssp.transactionManager)).join();
        initDepositContract();
    }

    @Test
    public void testRegister() throws ExecutionException, InterruptedException {
        asCf(dao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(dao.registerSsp(ssp.getAddress(), new Uint16(3))).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(token.approve(daoAddress(), new Uint256(BigInteger.TEN))).join();
        asCf(dao.registerSsp(ssp.getAddress(), new Uint16(3))).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        testDepositsTaken();
//        asCf(dao.findSsp(ssp.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), ssp.address)).join();
    }

    @Test
    public void testUnregister() throws ExecutionException, InterruptedException {
        asCf(dao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(dao.unregisterSsp(ssp.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        testDepositsReturned();
    }

    @Override
    protected PapyrusMember member() {
        return ssp;
    }

    @Override
    protected PapyrusDAO dao() {
        return dao;
    }

    @Override
    protected PapyrusPrototypeToken token() {
        return token;
    }
}
