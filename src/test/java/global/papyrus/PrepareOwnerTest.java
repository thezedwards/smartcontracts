package global.papyrus;

import org.testng.annotations.Test;
import org.web3j.crypto.CipherException;
import org.web3j.protocol.core.DefaultBlockParameterName;

import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;

import static global.papyrus.utils.PapyrusUtils.*;

public class PrepareOwnerTest {
    //Year must be enough for testing purposes
    public static final BigInteger UNLOCK_PERIOD = BigInteger.valueOf(60 * 60 * 24 * 365);


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
                ).thenCompose(ownerAccountId -> parity.personalUnlockAccount(ownerAccountId, randomCitizenPassword, UNLOCK_PERIOD).sendAsync())
                .join();
    }

    @Test(enabled = true)
    public void checkEtherBalance() {
        web3j.ethGetBalance(ownerAddr, DefaultBlockParameterName.LATEST).sendAsync()
                .thenAccept(balanceResponse -> System.out.println(balanceResponse.getBalance().toString())).join();
    }
}
