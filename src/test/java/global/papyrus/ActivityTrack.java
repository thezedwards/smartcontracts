package global.papyrus;

import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.utils.PapyrusMember;
import org.testng.Assert;
import org.testng.annotations.Test;
import org.web3j.abi.datatypes.generated.Uint16;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.crypto.CipherException;
import org.web3j.protocol.core.methods.response.TransactionReceipt;

import java.io.IOException;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ExecutionException;

import static global.papyrus.utils.PapyrusUtils.*;
import static global.papyrus.utils.Web3jUtils.asCf;

public class ActivityTrack extends Object {
    @Test
    public void createTrack() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException, ExecutionException, InterruptedException {
        PapyrusMember dsp = createNewMember(0.3d, 10).join();
        PapyrusMember ssp = createNewMember(0.3d, 10).join();
        PapyrusMember publisher = createNewMember(0.3d, 10).join();

        System.out.println("DSP - " + dsp.address + ", mintTx - " + dsp.mintTransaction);
        System.out.println("SSP - " + ssp.address + ", mintTx - " + ssp.mintTransaction);
        System.out.println("Publisher - " + publisher.address + ", mintTx - " + publisher.mintTransaction);

        PapyrusDAO dspDao = loadDaoContract(dsp.transactionManager);
        PapyrusDAO sspDao = loadDaoContract(ssp.transactionManager);
        PapyrusDAO publisherDao = loadDaoContract(publisher.transactionManager);

        PapyrusPrototypeToken dspToken = asCf(dspDao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), dsp.transactionManager)).join();
        PapyrusPrototypeToken sspToken = asCf(sspDao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), ssp.transactionManager)).join();
        PapyrusPrototypeToken publisherToken = asCf(publisherDao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), publisher.transactionManager)).join();

        CompletableFuture.allOf(
                asCf(dspToken.approve(daoAddress(), new Uint256(10))).thenCompose(wtw ->
                    asCf(dspDao.registerDsp(dsp.getAddress(), DSPTest.DSPType.Direct.code, generateUrl(5))).thenAccept(
                        transactionReceipt -> {
                            asCf(dspDao.isDspRegistered(dsp.getAddress())).thenAccept(res ->  {
                                Assert.assertTrue(res.getValue());
                                System.out.println("DSP Registered in system, tx - " + transactionReceipt.getTransactionHash());
                            });
                        })),
                asCf(sspToken.approve(daoAddress(), new Uint256(10))).thenCompose(wtw ->
                    asCf(sspDao.registerSsp(ssp.getAddress(), SSPTest.SSPType.Direct.code, new Uint16(5))).thenAccept(
                        transactionReceipt -> {
                            asCf(sspDao.isSspRegistered(ssp.getAddress())).thenAccept(res ->  {
                                Assert.assertTrue(res.getValue());
                                System.out.println("SSP Registered in system, tx - " + transactionReceipt.getTransactionHash());
                            });
                        })),
                asCf(publisherToken.approve(daoAddress(), new Uint256(10))).thenCompose(wtw ->
                    asCf(publisherDao.registerPublisher(publisher.getAddress(), generateUrl(5))).thenAccept(
                        transactionReceipt -> {
                            asCf(publisherDao.isPublisherRegistered(publisher.getAddress())).thenAccept(res ->  {
                                Assert.assertTrue(res.getValue());
                                System.out.println("Publisher Registered in system, tx - " + transactionReceipt.getTransactionHash());
                            });
                        }))
        ).join();

        mintPrp(dsp.address, 10).thenAccept(transactionReceipt -> System.out.println("Tokens for DSP minted, tx - " + transactionReceipt.getTransactionHash())).join();
    }
}
