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

public class ActivityTrack {
    @Test
    public void createTrack() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException, ExecutionException, InterruptedException {
        try {
            PapyrusMember dsp = createNewMember(0.3d, 10).join();
            PapyrusMember ssp = createNewMember(0.3d, 10).join();
            PapyrusMember auditor = createNewMember(0.3d, 10).join();

            System.out.println("DSP - " + dsp.address + ", mintTx - " + dsp.mintTransaction);
            System.out.println("SSP - " + ssp.address + ", mintTx - " + ssp.mintTransaction);
            System.out.println("Auditor - " + auditor.address + ", mintTx - " + auditor.mintTransaction);

            PapyrusDAO dspDao = loadDaoContract(dsp.transactionManager);
            PapyrusDAO sspDao = loadDaoContract(ssp.transactionManager);
            PapyrusDAO auditorDao = loadDaoContract(auditor.transactionManager);

            PapyrusPrototypeToken dspToken = asCf(dspDao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), dsp.transactionManager)).join();
            PapyrusPrototypeToken sspToken = asCf(sspDao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), ssp.transactionManager)).join();
            PapyrusPrototypeToken auditorToken = asCf(auditorDao.token()).thenApply(tokenAddress -> loadTokenContract(tokenAddress.toString(), auditor.transactionManager)).join();

            CompletableFuture.allOf(
                    asCf(dspToken.approve(daoAddress(), new Uint256(10))).thenCompose(wtw ->
                            asCf(dspDao.registerDsp(dsp.getAddress(), DSPTest.DSPType.Direct.code, generateUrl(5))).thenAccept(
                                    transactionReceipt -> {
                                        asCf(dspDao.isDspRegistered(dsp.getAddress())).thenAccept(res -> {
                                            Assert.assertTrue(res.getValue());
                                            System.out.println("DSP Registered in system, tx - " + transactionReceipt.getTransactionHash());
                                        });
                                    })),
                    asCf(sspToken.approve(daoAddress(), new Uint256(10))).thenCompose(wtw ->
                            asCf(sspDao.registerSsp(ssp.getAddress(), SSPTest.SSPType.Direct.code, new Uint16(5))).thenAccept(
                                    transactionReceipt -> {
                                        asCf(sspDao.isSspRegistered(ssp.getAddress())).thenAccept(res -> {
                                            Assert.assertTrue(res.getValue());
                                            System.out.println("SSP Registered in system, tx - " + transactionReceipt.getTransactionHash());
                                        });
                                    })),
                    asCf(auditorToken.approve(daoAddress(), new Uint256(10))).thenCompose(wtw ->
                            asCf(auditorDao.registerAuditor(auditor.getAddress())).thenAccept(
                                    transactionReceipt -> {
                                        asCf(auditorDao.isAuditorRegistered(auditor.getAddress())).thenAccept(res -> {
                                            Assert.assertTrue(res.getValue());
                                            System.out.println("Auditor Registered in system, tx - " + transactionReceipt.getTransactionHash());
                                        });
                                    }))
            ).join();

            mintPrp(dsp.address, ethPrice.longValue()).thenAccept(transactionReceipt -> System.out.println("Tokens for DSP minted, tx - " + transactionReceipt.getTransactionHash())).join();
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
