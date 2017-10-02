package global.papyrus;

import com.fasterxml.jackson.databind.ObjectMapper;
import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import global.papyrus.smartcontracts.PapyrusToken;
import org.testng.Assert;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.crypto.CipherException;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.WalletFile;
import org.web3j.crypto.WalletUtils;
import org.web3j.protocol.ObjectMapperFactory;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.request.Transaction;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.protocol.http.HttpService;
import org.web3j.protocol.parity.Parity;
import org.web3j.protocol.parity.methods.response.PersonalUnlockAccount;

import java.io.File;
import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.Collection;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Future;

import static java.util.stream.Collectors.toList;
import static org.web3j.tx.ManagedTransaction.GAS_PRICE;
import static org.web3j.tx.Transfer.GAS_LIMIT;

/**
 * Created by andreyvlasenko on 23/09/17.
 */
public class PapyrusUtils {
    public static final String ownerPassword = "mypasswd";
    public static final String randomCitizenPassword = "mypasswd";
    public static final String coinbasePassword = "Test#Passwd";
    public static final String ethHome = System.getProperty("user.home") + File.separator + ".ppr";
    public static final ObjectMapper objectMapper = ObjectMapperFactory.getObjectMapper();
    public static final Parity parity = Parity.build(new HttpService("http://dev.papyrus.global:80/"));
    public static final Web3j web3j = Web3j.build(new HttpService("http://dev.papyrus.global:80/"));
    public static Credentials ownerCredentials = null;
    static {
        try {
            String ownerAddr = System.getProperty("owner.addr");
            //noinspection ConstantConditions
            ownerCredentials = WalletUtils.loadCredentials(ownerPassword, new File(ethHome).listFiles((dir, name) -> name.contains(ownerAddr))[0]);
        } catch (Exception e) {
            Assert.fail("Cannot load owner's credentials", e);
        }
    }

    private PapyrusUtils() {/**/}

    public static final long AWAIT_BLOCK_DELAY = 5 * 1000;

    public static CompletableFuture<PapyrusMember> createNewMember(BigInteger initialBalance, BigInteger initialPrpBalance) throws NoSuchAlgorithmException, NoSuchProviderException, InvalidAlgorithmParameterException, CipherException, IOException {
        String walletFileName = WalletUtils.generateNewWalletFile(randomCitizenPassword, new File(ethHome), false);
        File file = new File(ethHome + File.separator + walletFileName);
        WalletFile walletFile = objectMapper.readValue(new File(ethHome + File.separator + walletFileName), WalletFile.class);
        String walletAddress = "0x" + walletFile.getAddress();
        Credentials credentials = WalletUtils.loadCredentials(randomCitizenPassword, file);
        CompletableFuture<PersonalUnlockAccount> zeroAcc = web3j.ethAccounts().sendAsync()
                .thenApply(accounts -> accounts.getAccounts().get(0))
                .thenApply(address -> parity.personalUnlockAccount(address, coinbasePassword).sendAsync())
                .thenCompose(unlockedAccount -> unlockedAccount);
        return parity.ethCoinbase().sendAsync()
            .thenCompose(coinbase -> parity.personalUnlockAccount(coinbase.getAddress(), coinbasePassword).sendAsync()
                    .thenCompose(unlock -> web3j.ethGetTransactionCount(coinbase.getAddress(), DefaultBlockParameterName.LATEST).sendAsync())
                    .thenCombine(parity.personalNewAccountFromWallet(walletFile, randomCitizenPassword).sendAsync(),
                            (transactionCount, newAccount) -> parity.ethSendTransaction(Transaction.createEtherTransaction(coinbase.getAddress(), transactionCount.getTransactionCount(),
                                    GAS_PRICE, GAS_LIMIT, walletAddress, initialBalance)).sendAsync()
                    )
            )
            .thenCompose(transactionFuture -> transactionFuture.thenApply(transaction -> new PapyrusMember(walletFile, credentials).withRefillTransaction(transaction.getTransactionHash())))
            .thenCombine((CompletableFuture<TransactionReceipt>)loadTokenContract(ownerCredentials).mint(new Address(walletAddress), new Uint256(initialPrpBalance)),
                ((papyrusMember, mintTransaction) -> papyrusMember.withMintTransaction(mintTransaction.getTransactionHash())));
    }

    public static CompletableFuture<?> transactionMinedAsync(String txHash) {
        return web3j.ethGetTransactionReceipt(txHash).sendAsync().thenApply(receiptResponse -> {
            Optional<TransactionReceipt> receipt = receiptResponse.getTransactionReceipt();
            if (receipt.isPresent() && receipt.get().getBlockHash() != null) {
                return CompletableFuture.completedFuture(Void.TYPE);
            } else {
                return CompletableFuture.supplyAsync(() -> {
                    try {Thread.sleep(AWAIT_BLOCK_DELAY);} catch (InterruptedException e) {/**/}
                    return transactionMinedAsync(txHash);
                });
            }
        });
    }

    public static CompletableFuture<?> allTransactionsMinedAsync(Collection<String> txHashes) {
        return CompletableFuture.allOf(txHashes.stream().map(PapyrusUtils::transactionMinedAsync).toArray(CompletableFuture[]::new));
    }

    public static PapyrusPrototypeToken loadTokenContract(Credentials credentials) {
        return PapyrusPrototypeToken.load(System.getProperty("token.addr"), web3j, credentials, GAS_PRICE, GAS_LIMIT);
    }

    public static PapyrusDAO loadDaoContract(Credentials credentials) {
        return PapyrusDAO.load(System.getProperty("dao.addr"), web3j, credentials, GAS_PRICE, GAS_LIMIT);
    }

    public static Address daoAddress() {
        return new Address(System.getProperty("dao.addr"));
    }
}
