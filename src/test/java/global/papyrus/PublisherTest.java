package global.papyrus;

import global.papyrus.smartcontracts.PublisherRegistry;
import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
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
import static global.papyrus.utils.PapyrusUtils.daoAddress;
import static global.papyrus.utils.Web3jUtils.asCf;
import static java.util.Arrays.asList;

/**
 * Created by andreyvlasenko on 04/10/17.
 */
@Test(enabled = false)
public class PublisherTest extends DepositTest{
    private PapyrusMember publisher;
    private PapyrusMember publisherRegistrar;
    private PapyrusDAO dao;
    private PapyrusDAO daoRegistrar;
    private PapyrusPrototypeToken token;
    private PapyrusPrototypeToken tokenRegistrar;
    private PublisherRegistry publisherRegistry;

    @BeforeClass(enabled = false)
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        publisher = createNewMember(2, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        publisherRegistrar = createNewMember(2, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dao = loadDaoContract(publisher.transactionManager);
        daoRegistrar = loadDaoContract(publisherRegistrar.transactionManager);
        token = asCf(dao.token().sendAsync()).thenApply(tokenAddress -> loadTokenContract(tokenAddress, publisher.transactionManager)).join();
        tokenRegistrar = asCf(daoRegistrar.token().sendAsync())
                .thenApply(tokenAddress -> loadTokenContract(tokenAddress, publisherRegistrar.transactionManager)
                ).join();
        publisherRegistry = asCf(daoRegistrar.publisherRegistry().sendAsync())
                .thenApply(publisherRegistryAddress -> loadPublisherRegistry(publisherRegistryAddress, publisher.transactionManager))
                .join();
        initDepositContract();
    }

    @Test(enabled = false)
    public void testRegister() throws ExecutionException, InterruptedException {
        testPublisherRegistration(dao, token);
        assertDepositsTaken();
    }

    @Test(dependsOnMethods = {"testRegister"}, enabled = false)
    public void testUnregister() throws ExecutionException, InterruptedException {
        testPublisherUnregistration(dao, daoRegistrar);
        assertDepositsReturned();
    }

    @Test(dependsOnMethods = {"testUnregister"}, enabled = false)
    public void testRegisterWithRegistrar() {
        testPublisherRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
    }

    @Test(dependsOnMethods = {"testRegisterWithRegistrar"}, enabled = false)
    public void testUnregisterWithRegistrar() {
        testPublisherUnregistration(daoRegistrar, dao);
        assertRegistrarDepositsReturned();
    }

    @Test(dependsOnMethods = {"testUnregisterWithRegistrar"}, enabled = false)
    public void testTransferOwnership() {
        testPublisherRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
        rememberBalances();
        assertRecordOwner(publisher, publisherRegistrar);
        //Only owner is permitted to transfer ownership
        asCf(dao.transferPublisherRecord(publisher.getAddress().getValue(), publisher.getAddress().getValue()).sendAsync())
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(publisher, publisherRegistrar);
        //Now should work
        asCf(daoRegistrar.transferPublisherRecord(publisher.getAddress().getValue(), publisher.getAddress().getValue()).sendAsync())
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(publisher, publisher);
        //Ok, now lets unregister it and check deposit returned to new owner
        testPublisherUnregistration(dao, daoRegistrar);
        assertRegistrarDepositsReturned();
    }

    @Test(dependsOnMethods = {"testTransferOwnership"}, enabled = false)
    public void testTransferOwnershipAndDeposit() {
        testPublisherRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
        rememberBalances();
        assertRecordOwner(publisher, publisherRegistrar);
        //Only owner is permitted to transfer ownership
        asCf(dao.transferPublisherRecord(publisher.getAddress().getValue(), publisher.getAddress().getValue()).sendAsync())
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(publisher, publisherRegistrar);
        //Now should work
        asCf(daoRegistrar.transferPublisherRecord(publisher.getAddress().getValue(), publisher.getAddress().getValue()).sendAsync())
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(publisher, publisher);
        //Ok, now lets unregister it and check deposit returned to new owner
        testPublisherUnregistration(dao, daoRegistrar);
        assertDepositsReturned();
    }

    protected void testPublisherRegistration(PapyrusDAO dao, PapyrusPrototypeToken token) {
        asCf(dao.isPublisherRegistered(publisher.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertFalse).join();
        asCf(dao.registerPublisher(publisher.getAddress().getValue(), generateUrl(5)).sendAsync()).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isPublisherRegistered(publisher.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertFalse).join();
        asCf(token.approve(daoAddress().getValue(), BigInteger.TEN).sendAsync()).join();
        asCf(dao.registerPublisher(publisher.getAddress().getValue(), generateUrl(5)).sendAsync()).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isPublisherRegistered(publisher.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertTrue).join();
//        asCf(dao.findPublisher(publisher.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), publisher.address)).join();
    }

    protected void testPublisherUnregistration(PapyrusDAO permittedDao, PapyrusDAO nonpermittedDao) {
        asCf(permittedDao.isPublisherRegistered(publisher.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertTrue).join();
        asCf(nonpermittedDao.unregisterPublisher(publisher.getAddress().getValue()).sendAsync()).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isPublisherRegistered(publisher.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertTrue).join();
        asCf(permittedDao.unregisterPublisher(publisher.getAddress().getValue()).sendAsync()).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isPublisherRegistered(publisher.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertFalse).join();
    }

    protected void assertRecordOwner(PapyrusMember record, PapyrusMember recordOwner) {
        asCf(publisherRegistry.getOwner(record.getAddress().getValue()).sendAsync()).thenAccept(owner -> Assert.assertEquals(owner, recordOwner.address)).join();
    }

    @Override
    protected PapyrusMember member() {
        return publisher;
    }

    @Override
    protected PapyrusMember registrar() {
        return publisherRegistrar;
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
