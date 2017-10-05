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
public class PublisherTest extends DepositTest{
    private PapyrusMember publisher;
    private PapyrusDAO dao;
    private PapyrusPrototypeToken token;

    @BeforeClass
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        publisher = createNewMember(1, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dao = loadDaoContract(publisher.transactionManager);
        token = asCf(dao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), publisher.transactionManager)).join();
        initDepositContract();
    }

    @Test
    public void testRegister() throws ExecutionException, InterruptedException {
        asCf(dao.isPublisherRegistered(publisher.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(dao.registerPublisher(publisher.getAddress(), generateUrl(3))).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isPublisherRegistered(publisher.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(token.approve(daoAddress(), new Uint256(BigInteger.TEN))).join();
        asCf(dao.registerPublisher(publisher.getAddress(), generateUrl(3))).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isPublisherRegistered(publisher.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        testDepositsTaken();
//        asCf(dao.findAuditor(publisher.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), publisher.address)).join();
    }

    @Test
    public void testUnregister() throws ExecutionException, InterruptedException {
        asCf(dao.isPublisherRegistered(publisher.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(dao.unregisterPublisher(publisher.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isPublisherRegistered(publisher.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        testDepositsReturned();
    }

    @Override
    protected PapyrusMember member() {
        return publisher;
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
