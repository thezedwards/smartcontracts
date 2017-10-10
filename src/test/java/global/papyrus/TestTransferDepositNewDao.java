package global.papyrus;

import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.utils.PapyrusMember;
import org.testng.Assert;
import org.testng.annotations.AfterClass;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.crypto.CipherException;
import org.web3j.tx.ClientTransactionManager;

import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;

import static global.papyrus.utils.PapyrusUtils.*;
import static global.papyrus.utils.Web3jUtils.asCf;
import static java.util.Arrays.asList;

@Test(enabled = false)
public class TestTransferDepositNewDao {
    private PapyrusMember auditor;
    private PapyrusDAO dao;
    private PapyrusDAO ownerDao;
    private PapyrusPrototypeToken token;
    private PapyrusPrototypeToken ownerToken;
    private int daoBalance;

    @BeforeClass(enabled = false)
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        auditor = createNewMember(2, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dao = loadDaoContract(auditor.transactionManager);
        ownerDao = loadDaoContract(new ClientTransactionManager(web3j, ownerAddr));
        token = asCf(dao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), auditor.transactionManager)).join();
        ownerToken = asCf(dao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), new ClientTransactionManager(web3j, ownerAddr))).join();
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(token.approve(daoAddress(), new Uint256(BigInteger.TEN))).join();
        asCf(dao.registerAuditor(auditor.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
    }

    @Test(enabled = false)
    public void transferDepositsToAnotherAddress() {
        daoBalance = asCf(balanceOf(token, daoAddress())).join();
        int ownerBalance = asCf(balanceOf(token, ownerAddress())).join();
        //Let owner be the new Dao (destination on money transfer not so important)
        asCf(dao.transferDepositsToNewDao(ownerAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        //Nothing changed
        balanceOf(token, daoAddress()).thenAccept(
                realBalance -> Assert.assertEquals(realBalance.intValue(), daoBalance)
        ).join();
        balanceOf(token, ownerAddress()).thenAccept(
                realBalance -> Assert.assertEquals(realBalance.intValue(), ownerBalance)
        ).join();
        //Now should work
        asCf(ownerDao.transferDepositsToNewDao(ownerAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        balanceOf(token, daoAddress()).thenAccept(
                realBalance -> Assert.assertEquals(realBalance.intValue(), 0)
        ).join();
        balanceOf(token, ownerAddress()).thenAccept(
                realBalance -> Assert.assertEquals(realBalance.intValue(), ownerBalance + daoBalance)
        ).join();
    }

    @AfterClass(enabled = false)
    public void unregisterUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        asCf(ownerToken.transfer(daoAddress(), new Uint256(daoBalance))).join();
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(dao.unregisterAuditor(auditor.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
    }
}
