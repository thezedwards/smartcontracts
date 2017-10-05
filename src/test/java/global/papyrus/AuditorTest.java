package global.papyrus;

import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.utils.PapyrusMember;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.crypto.CipherException;

import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.concurrent.ExecutionException;

import static global.papyrus.utils.PapyrusUtils.*;
import static global.papyrus.utils.PapyrusUtils.daoAddress;
import static global.papyrus.utils.Web3jUtils.asCf;
import static java.util.Arrays.asList;

/**
 * Created by andreyvlasenko on 04/10/17.
 */
public class AuditorTest extends DepositTest{
    private PapyrusMember auditor;
    private PapyrusDAO dao;
    private PapyrusPrototypeToken token;

    @BeforeClass
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        auditor = createNewMember(1, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dao = loadDaoContract(auditor.transactionManager);
        token = asCf(dao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), auditor.transactionManager)).join();
        initDepositContract();
    }

    @Test
    public void testRegister() throws ExecutionException, InterruptedException {
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(dao.registerAuditor(auditor.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(token.approve(daoAddress(), new Uint256(BigInteger.TEN))).join();
        asCf(dao.registerAuditor(auditor.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        testDepositsTaken();
//        asCf(dao.findAuditor(auditor.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), auditor.address)).join();
    }

    @Test
    public void testUnregister() throws ExecutionException, InterruptedException {
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(dao.unregisterAuditor(auditor.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        testDepositsReturned();
    }

    @Override
    protected PapyrusMember member() {
        return auditor;
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
