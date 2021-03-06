package global.papyrus;

import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.concurrent.ExecutionException;

import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import org.web3j.abi.datatypes.DynamicBytes;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.crypto.CipherException;

import global.papyrus.smartcontracts.AuditorRegistry;
import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.utils.PapyrusMember;

import static global.papyrus.utils.PapyrusUtils.*;
import static global.papyrus.utils.Web3jUtils.asCf;
import static java.util.Arrays.asList;

/**
 * Created by andreyvlasenko on 04/10/17.
 */
public class AuditorTest extends DepositTest{
    private PapyrusMember auditor;
    private PapyrusMember auditorRegistrar;
    private PapyrusDAO dao;
    private PapyrusDAO daoRegistrar;
    private PapyrusPrototypeToken token;
    private PapyrusPrototypeToken tokenRegistrar;
    private AuditorRegistry auditorRegistry;

    @BeforeClass(enabled = false)
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        auditor = createNewMember(2, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        auditorRegistrar = createNewMember(2, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dao = loadDaoContract(auditor.transactionManager);
        daoRegistrar = loadDaoContract(auditorRegistrar.transactionManager);
        token = asCf(dao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), auditor.transactionManager)).join();
        tokenRegistrar = asCf(daoRegistrar.token())
                .thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), auditorRegistrar.transactionManager)
                ).join();
        auditorRegistry = asCf(daoRegistrar.auditorRegistry())
                .thenApply(auditorRegistryAddress -> loadAuditorRegistry(auditorRegistryAddress.toString(), auditor.transactionManager))
                .join();
        initDepositContract();
    }

    @Test(enabled = false)
    public void testRegister() throws ExecutionException, InterruptedException {
        testAuditorRegistration(dao, token);
        assertDepositsTaken();
    }

    @Test(dependsOnMethods = {"testRegister"}, enabled = false)
    public void testUnregister() throws ExecutionException, InterruptedException {
        testAuditorUnregistration(dao, daoRegistrar);
        assertDepositsReturned();
    }

    @Test(dependsOnMethods = {"testUnregister"}, enabled = false)
    public void testRegisterWithRegistrar() {
        testAuditorRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
    }

    @Test(dependsOnMethods = {"testRegisterWithRegistrar"}, enabled = false)
    public void testUnregisterWithRegistrar() {
        testAuditorUnregistration(daoRegistrar, dao);
        assertRegistrarDepositsReturned();
    }

    @Test(dependsOnMethods = {"testUnregisterWithRegistrar"}, enabled = false)
    public void testTransferOwnership() {
        testAuditorRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
        rememberBalances();
        assertRecordOwner(auditor, auditorRegistrar);
        //Only owner is permitted to transfer ownership
        asCf(dao.transferAuditorRecord(auditor.getAddress(), auditor.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(auditor, auditorRegistrar);
        //Now should work
        asCf(daoRegistrar.transferAuditorRecord(auditor.getAddress(), auditor.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(auditor, auditor);
        //Ok, now lets unregister it and check deposit returned to new owner
        testAuditorUnregistration(dao, daoRegistrar);
        assertRegistrarDepositsReturned();
    }

    @Test(dependsOnMethods = {"testTransferOwnership"}, enabled = false)
    public void testTransferOwnershipAndDeposit() {
        testAuditorRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
        rememberBalances();
        assertRecordOwner(auditor, auditorRegistrar);
        //Only owner is permitted to transfer ownership
        asCf(dao.transferAuditorRecord(auditor.getAddress(), auditor.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(auditor, auditorRegistrar);
        //Now should work
        asCf(daoRegistrar.transferAuditorRecord(auditor.getAddress(), auditor.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(auditor, auditor);
        //Ok, now lets unregister it and check deposit returned to new owner
        testAuditorUnregistration(dao, daoRegistrar);
        assertDepositsReturned();
    }

    protected void testAuditorRegistration(PapyrusDAO dao, PapyrusPrototypeToken token) {
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(dao.registerAuditor(auditor.getAddress(), DynamicBytes.DEFAULT)).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(token.approve(daoAddress(), new Uint256(BigInteger.TEN))).join();
        asCf(dao.registerAuditor(auditor.getAddress(), DynamicBytes.DEFAULT)).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
//        asCf(dao.findAuditor(auditor.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), auditor.address)).join();
    }

    protected void testAuditorUnregistration(PapyrusDAO permittedDao, PapyrusDAO nonpermittedDao) {
        asCf(permittedDao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(nonpermittedDao.unregisterAuditor(auditor.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(permittedDao.unregisterAuditor(auditor.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isAuditorRegistered(auditor.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
    }

    protected void assertRecordOwner(PapyrusMember record, PapyrusMember recordOwner) {
        asCf(auditorRegistry.getOwner(record.getAddress())).thenAccept(owner -> Assert.assertEquals(owner.toString(), recordOwner.address)).join();
    }

    @Override
    protected PapyrusMember member() {
        return auditor;
    }

    @Override
    protected PapyrusMember registrar() {
        return auditorRegistrar;
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
