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
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.abi.datatypes.generated.Uint8;
import org.web3j.crypto.CipherException;

import global.papyrus.smartcontracts.DSPRegistry;
import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.utils.PapyrusMember;

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

        public final Uint8 code;

        DSPType(int code) {
            this.code = new Uint8(code);
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
        token = asCf(dao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), dsp.transactionManager)).join();
        tokenRegistrar = asCf(daoRegistrar.token())
                .thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), dspRegistrar.transactionManager)
                ).join();
        dspRegistry = asCf(daoRegistrar.dspRegistry())
                .thenApply(dspRegistryAddress -> loadDspRegistry(dspRegistryAddress.toString(), dsp.transactionManager))
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
        asCf(dao.transferDSPRecord(dsp.getAddress(), dsp.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(dsp, dspRegistrar);
        //Now should work
        asCf(daoRegistrar.transferDSPRecord(dsp.getAddress(), dsp.getAddress()))
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
        asCf(dao.transferDSPRecord(dsp.getAddress(), dsp.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(dsp, dspRegistrar);
        //Now should work
        asCf(daoRegistrar.transferDSPRecord(dsp.getAddress(), dsp.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(dsp, dsp);
        //Ok, now lets unregister it and check deposit returned to new owner
        testDspUnregistration(dao, daoRegistrar);
        assertDepositsReturned();
    }

    protected void testDspRegistration(PapyrusDAO dao, PapyrusPrototypeToken token) {
        asCf(dao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(dao.registerDsp(dsp.getAddress(), DSPType.Direct.code, generateUrl5())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(token.approve(daoAddress(), new Uint256(BigInteger.TEN))).join();
        asCf(dao.registerDsp(dsp.getAddress(), DSPType.Direct.code, generateUrl5())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
//        asCf(dao.findDsp(dsp.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), dsp.address)).join();
    }

    protected void testDspUnregistration(PapyrusDAO permittedDao, PapyrusDAO nonpermittedDao) {
        asCf(permittedDao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(nonpermittedDao.unregisterDsp(dsp.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(permittedDao.unregisterDsp(dsp.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isDspRegistered(dsp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
    }

    protected void assertRecordOwner(PapyrusMember record, PapyrusMember recordOwner) {
        asCf(dspRegistry.getOwner(record.getAddress())).thenAccept(owner -> Assert.assertEquals(owner.toString(), recordOwner.address)).join();
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
