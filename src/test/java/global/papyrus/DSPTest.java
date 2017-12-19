package global.papyrus;

import global.papyrus.smartcontracts.*;
import global.papyrus.utils.PapyrusMember;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.abi.datatypes.generated.Uint8;
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
@Test(enabled = false)
public class DSPTest extends DepositTest{
    private PapyrusMember dsp;
    private PapyrusMember dspRegistrar;
    private PapyrusDAO dao;
    private PapyrusDAO daoRegistrar;
    private PapyrusPrototypeToken token;
    private PapyrusPrototypeToken tokenRegistrar;
    private DSPRegistry dspRegistry;

    enum DSPType {
        Gate(0), Direct(1);

        public final BigInteger code;

        DSPType(int code) {
            this.code = BigInteger.valueOf(code);
        }
    }

    @BeforeClass(enabled = false)
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        dsp = createNewMember(2, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dspRegistrar = createNewMember(2, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dao = loadDaoContract(dsp.transactionManager);
        daoRegistrar = loadDaoContract(dspRegistrar.transactionManager);
        token = asCf(dao.token().sendAsync()).thenApply(tokenAddress -> loadTokenContract(tokenAddress, dsp.transactionManager)).join();
        tokenRegistrar = asCf(daoRegistrar.token().sendAsync())
                .thenApply(tokenAddress -> loadTokenContract(tokenAddress, dspRegistrar.transactionManager)
                ).join();
        dspRegistry = asCf(daoRegistrar.dspRegistry().sendAsync())
                .thenApply(dspRegistryAddress -> loadDspRegistry(dspRegistryAddress, dsp.transactionManager))
                .join();
        initDepositContract();
    }

    @Test(enabled = false)
    public void testRegister() throws ExecutionException, InterruptedException {
        testDspRegistration(dao, token);
        assertDepositsTaken();
    }

    @Test(dependsOnMethods = {"testRegister"}, enabled = false)
    public void testUnregister() throws ExecutionException, InterruptedException {
        testDspUnregistration(dao, daoRegistrar);
        assertDepositsReturned();
    }

    @Test(dependsOnMethods = {"testUnregister"}, enabled = false)
    public void testRegisterWithRegistrar() {
        testDspRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
    }

    @Test(dependsOnMethods = {"testRegisterWithRegistrar"}, enabled = false)
    public void testUnregisterWithRegistrar() {
        testDspUnregistration(daoRegistrar, dao);
        assertRegistrarDepositsReturned();
    }

    @Test(dependsOnMethods = {"testUnregisterWithRegistrar"}, enabled = false)
    public void testTransferOwnership() {
        testDspRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
        rememberBalances();
        assertRecordOwner(dsp, dspRegistrar);
        //Only owner is permitted to transfer ownership
        asCf(dao.transferDSPRecord(dsp.getAddress().getValue(), dsp.getAddress().getValue()).sendAsync())
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(dsp, dspRegistrar);
        //Now should work
        asCf(daoRegistrar.transferDSPRecord(dsp.getAddress().getValue(), dsp.getAddress().getValue()).sendAsync())
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(dsp, dsp);
        //Ok, now lets unregister it and check deposit returned to new owner
        testDspUnregistration(dao, daoRegistrar);
        assertRegistrarDepositsReturned();
    }

    @Test(dependsOnMethods = {"testTransferOwnership"}, enabled = false)
    public void testTransferOwnershipAndDeposit() {
        testDspRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
        rememberBalances();
        assertRecordOwner(dsp, dspRegistrar);
        //Only owner is permitted to transfer ownership
        asCf(dao.transferDSPRecord(dsp.getAddress().getValue(), dsp.getAddress().getValue()).sendAsync())
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(dsp, dspRegistrar);
        //Now should work
        asCf(daoRegistrar.transferDSPRecord(dsp.getAddress().getValue(), dsp.getAddress().getValue()).sendAsync())
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(dsp, dsp);
        //Ok, now lets unregister it and check deposit returned to new owner
        testDspUnregistration(dao, daoRegistrar);
        assertDepositsReturned();
    }

    protected void testDspRegistration(PapyrusDAO dao, PapyrusPrototypeToken token) {
        asCf(dao.isDspRegistered(dsp.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertFalse).join();
        asCf(dao.registerDsp(dsp.getAddress().getValue(), DSPType.Direct.code, generateUrl(5)).sendAsync()).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isDspRegistered(dsp.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertFalse).join();
        asCf(token.approve(daoAddress().getValue(), BigInteger.TEN).sendAsync()).join();
        asCf(dao.registerDsp(dsp.getAddress().getValue(), DSPType.Direct.code, generateUrl(5)).sendAsync()).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isDspRegistered(dsp.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertTrue).join();
//        asCf(dao.findDsp(dsp.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), dsp.address)).join();
    }

    protected void testDspUnregistration(PapyrusDAO permittedDao, PapyrusDAO nonpermittedDao) {
        asCf(permittedDao.isDspRegistered(dsp.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertTrue).join();
        asCf(nonpermittedDao.unregisterDsp(dsp.getAddress().getValue()).sendAsync()).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isDspRegistered(dsp.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertTrue).join();
        asCf(permittedDao.unregisterDsp(dsp.getAddress().getValue()).sendAsync()).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isDspRegistered(dsp.getAddress().getValue()).sendAsync()).thenAccept(Assert::assertFalse).join();
    }

    protected void assertRecordOwner(PapyrusMember record, PapyrusMember recordOwner) {
        asCf(dspRegistry.getOwner(record.getAddress().getValue()).sendAsync()).thenAccept(owner -> Assert.assertEquals(owner, recordOwner.address)).join();
    }

    @Override
    protected PapyrusMember member() {
        return dsp;
    }

    @Override
    protected PapyrusMember registrar() {
        return dspRegistrar;
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
