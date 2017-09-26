package global.papyrus;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.web3j.crypto.CipherException;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.WalletFile;
import org.web3j.crypto.WalletUtils;
import org.web3j.protocol.ObjectMapperFactory;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.request.Transaction;
import org.web3j.protocol.http.HttpService;
import org.web3j.protocol.parity.Parity;
import org.web3j.protocol.parity.methods.response.NewAccountIdentifier;

import java.io.File;
import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.concurrent.CompletableFuture;

import static org.web3j.tx.ManagedTransaction.GAS_PRICE;
import static org.web3j.tx.Transfer.GAS_LIMIT;

/**
 * Created by andreyvlasenko on 23/09/17.
 */
public class PapyrusUtils {
    public static final String password = "mypasswd";
    public static final String ethHome = "/Users/andreyvlasenko/.ppr";
    public static final ObjectMapper objectMapper = ObjectMapperFactory.getObjectMapper();
    public static final Parity parity = Parity.build(new HttpService("http://dev.papyrus.global:80/"));
    public static final Web3j web3j = Web3j.build(new HttpService("http://dev.papyrus.global:80/"));

    public static CompletableFuture<PapyrusMember> createNewMember(BigInteger initialBalance) throws NoSuchAlgorithmException, NoSuchProviderException, InvalidAlgorithmParameterException, CipherException, IOException {
        String walletFileName = WalletUtils.generateNewWalletFile(password, new File(ethHome), false);
        File file = new File(ethHome + File.separator + walletFileName);
        WalletFile walletFile = objectMapper.readValue(new File(ethHome + File.separator + walletFileName), WalletFile.class);
        String walletAddress = "0x" + walletFile.getAddress();
        Credentials credentials = WalletUtils.loadCredentials(password, file);
        return parity.ethCoinbase().sendAsync()
                .thenCompose(coinbase -> parity.personalUnlockAccount(coinbase.getAddress(), "Test#Passwd").sendAsync()
                        .thenCompose(unlock -> web3j.ethGetTransactionCount(coinbase.getAddress(), DefaultBlockParameterName.LATEST).sendAsync())
                        .thenCombine(parity.personalNewAccountFromWallet(walletFile, password).sendAsync(),
                                (transactionCount, newAccount) -> parity.ethSendTransaction(Transaction.createEtherTransaction(coinbase.getAddress(), transactionCount.getTransactionCount(),
                                        GAS_PRICE, GAS_LIMIT, walletAddress, BigInteger.valueOf(10000))).sendAsync()
                        )
                ).thenCompose(transactionFuture -> transactionFuture.thenApply(transaction -> new PapyrusMember(walletFile, credentials, transaction.getTransactionHash())));
    }

    public static void awaitTransactionMined() {

    }
}
