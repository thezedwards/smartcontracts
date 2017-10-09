package global.papyrus;

import org.testng.annotations.Test;
import org.web3j.crypto.CipherException;
import org.web3j.protocol.core.DefaultBlockParameterName;

import java.io.IOException;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;

import static global.papyrus.utils.PapyrusUtils.*;

public class PrepareOwnerTest {
    @Test(enabled = false)
    public void registerOwner() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        parity.ethCoinbase().sendAsync()
                //New account with some Ether
                .thenCombine(parity.personalNewAccount(randomCitizenPassword).sendAsync(),
                        (coinbase, newAccount) -> {
                            transferEther(coinbase.getAddress(), newAccount.getAccountId(), 100000);
                            System.out.println("New owner:" + newAccount.getAccountId());
                            return newAccount.getAccountId();
                        }
                ).thenCompose(ownerAccountId -> parity.personalUnlockAccount(ownerAccountId, randomCitizenPassword, unlockPeriod).sendAsync())
                .join();
    }

    @Test(enabled = false)
    public void checkEtherBalance() {
        web3j.ethGetBalance(ownerAddr, DefaultBlockParameterName.LATEST).sendAsync()
                .thenAccept(balanceResponse -> System.out.println(balanceResponse.getBalance().toString())).join();
    }

    @Test(enabled = false)
    public void unlockOwner() {
        parity.personalUnlockAccount(ownerAddr, randomCitizenPassword, unlockPeriod).sendAsync().join();
    }
}
