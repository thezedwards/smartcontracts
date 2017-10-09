package global.papyrus;

import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.smartcontracts.SSPRegistry;
import global.papyrus.utils.PapyrusMember;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import org.web3j.abi.datatypes.generated.Uint16;
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
 * Created by andreyvlasenko on 03/10/17.
 */
public class SSPTest extends DepositTest {
    private PapyrusMember ssp;
    private PapyrusMember sspRegistrar;
    private PapyrusDAO dao;
    private PapyrusDAO daoRegistrar;
    private PapyrusPrototypeToken token;
    private PapyrusPrototypeToken tokenRegistrar;
    private SSPRegistry sspRegistry;

    enum SSPType {
        Gate(0), Direct(1);

        public final Uint8 code;

        SSPType(int code) {
            this.code = new Uint8(code);
        }
    }

    @BeforeClass
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        ssp = createNewMember(2, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        sspRegistrar = createNewMember(2, 100)
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
        dao = loadDaoContract(ssp.transactionManager);
        daoRegistrar = loadDaoContract(sspRegistrar.transactionManager);
        token = asCf(dao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), ssp.transactionManager)).join();
        tokenRegistrar = asCf(daoRegistrar.token())
                .thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), sspRegistrar.transactionManager)
                ).join();
        sspRegistry = asCf(daoRegistrar.sspRegistry())
                .thenApply(sspRegistryAddress -> loadSspRegistry(sspRegistryAddress.toString(), ssp.transactionManager))
                .join();
        initDepositContract();
    }

    @Test
    public void testRegister() throws ExecutionException, InterruptedException {
        testSspRegistration(dao, token);
        assertDepositsTaken();
    }

    @Test(dependsOnMethods = {"testRegister"})
    public void testUnregister() throws ExecutionException, InterruptedException {
        testSspUnregistration(dao, daoRegistrar);
        assertDepositsReturned();
    }

    @Test(dependsOnMethods = {"testUnregister"})
    public void testRegisterWithRegistrar() {
        testSspRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
    }

    @Test(dependsOnMethods = {"testRegisterWithRegistrar"})
    public void testUnregisterWithRegistrar() {
        testSspUnregistration(daoRegistrar, dao);
        assertRegistrarDepositsReturned();
    }

    @Test(dependsOnMethods = {"testUnregisterWithRegistrar"})
    public void testTransferOwnership() {
        testSspRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
        rememberBalances();
        assertRecordOwner(ssp, sspRegistrar);
        //Only owner is permitted to transfer ownership
        asCf(dao.transferSSPRecord(ssp.getAddress(), ssp.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(ssp, sspRegistrar);
        //Now should work
        asCf(daoRegistrar.transferSSPRecord(ssp.getAddress(), ssp.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(ssp, ssp);
        //Ok, now lets unregister it and check deposit returned to new owner
        testSspUnregistration(dao, daoRegistrar);
        assertRegistrarDepositsReturned();
    }

    @Test(dependsOnMethods = {"testTransferOwnership"})
    public void testTransferOwnershipAndDeposit() {
        testSspRegistration(daoRegistrar, tokenRegistrar);
        assertRegistrarDepositsTaken();
        rememberBalances();
        assertRecordOwner(ssp, sspRegistrar);
        //Only owner is permitted to transfer ownership
        asCf(dao.transferSSPRecord(ssp.getAddress(), ssp.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(ssp, sspRegistrar);
        //Now should work
        asCf(daoRegistrar.transferSSPRecord(ssp.getAddress(), ssp.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(daoRegistrar.transferSecurityDeposit(ssp.getAddress(), ssp.getAddress()))
                .thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        assertRecordOwner(ssp, ssp);
        //Ok, now lets unregister it and check deposit returned to new owner
        testSspUnregistration(dao, daoRegistrar);
        assertDepositsReturned();
    }

    protected void testSspRegistration(PapyrusDAO dao, PapyrusPrototypeToken token) {
        asCf(dao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(dao.registerSsp(ssp.getAddress(), SSPType.Direct.code, new Uint16(3))).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
        asCf(token.approve(daoAddress(), new Uint256(BigInteger.TEN))).join();
        asCf(dao.registerSsp(ssp.getAddress(), SSPType.Direct.code, new Uint16(3))).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
//        asCf(dao.findSsp(ssp.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), ssp.address)).join();
    }

    protected void testSspUnregistration(PapyrusDAO permittedDao, PapyrusDAO nonpermittedDao) {
        asCf(permittedDao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(nonpermittedDao.unregisterSsp(ssp.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertTrue(types.getValue())).join();
        asCf(permittedDao.unregisterSsp(ssp.getAddress())).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(permittedDao.isSspRegistered(ssp.getAddress())).thenAccept(types -> Assert.assertFalse(types.getValue())).join();
    }

    protected void assertRecordOwner(PapyrusMember record, PapyrusMember recordOwner) {
        asCf(sspRegistry.getOwner(record.getAddress())).thenAccept(owner -> Assert.assertEquals(owner.toString(), recordOwner.address)).join();
    }

    @Override
    protected PapyrusMember member() {
        return ssp;
    }

    @Override
    protected PapyrusMember registrar() {
        return sspRegistrar;
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
