package global.papyrus;

import global.papyrus.smartcontracts.*;
import global.papyrus.utils.PapyrusMember;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
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
 * Created by andreyvlasenko on 27/09/17.
 */
public class DSPTest extends DepositTest{
    private PapyrusMember dsp;
    private PapyrusDAO dao;
    private PapyrusPrototypeToken token;

    @BeforeClass
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        dsp = createNewMember(1, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dao = loadDaoContract(dsp.transactionManager);
        token = asCf(dao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), dsp.transactionManager)).join();
        initDepositContract();
    }

    @Test
    public void testRegister() throws ExecutionException, InterruptedException {
        asCf(dao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(dao.registerDsp(dsp.getAddress(), generateUrl(3))).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(token.approve(daoAddress(), new Uint256(BigInteger.TEN))).join();
        asCf(dao.registerDsp(dsp.getAddress(), generateUrl(3))).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        testDepositsTaken();
//        asCf(dao.findDsp(dsp.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), dsp.address)).join();
    }

    @Test
    public void testUnregister() throws ExecutionException, InterruptedException {
        asCf(dao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(dao.unregisterDsp(dsp.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        testDepositsReturned();
    }

    @Override
    protected PapyrusMember member() {
        return dsp;
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
