package global.papyrus.utils;

import global.papyrus.smartcontracts.*;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.StaticArray;
import org.web3j.abi.datatypes.generated.Bytes32;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.crypto.CipherException;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.request.Transaction;
import org.web3j.protocol.core.methods.response.EthSendTransaction;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.protocol.http.HttpService;
import org.web3j.protocol.parity.Parity;
import org.web3j.tx.ClientTransactionManager;
import org.web3j.tx.ManagedTransaction;
import org.web3j.tx.TransactionManager;

import java.io.FileReader;
import java.io.IOException;
import java.math.BigDecimal;
import java.math.BigInteger;
import java.math.MathContext;
import java.math.RoundingMode;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.Collection;
import java.util.Optional;
import java.util.Properties;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Stream;

import static global.papyrus.utils.Web3jUtils.asCf;
import static org.web3j.tx.ManagedTransaction.GAS_PRICE;
import static org.web3j.tx.Transfer.GAS_LIMIT;

/**
 * Created by andreyvlasenko on 23/09/17.
 */
public class PapyrusUtils {
    public static final int depositAmount = 10;
    public static final BigInteger ethPrice = BigInteger.valueOf(1_000_000_000_000_000_000L);
    public static final BigInteger gasPrice = ManagedTransaction.GAS_PRICE;
    public static final BigInteger gasLimit = BigInteger.valueOf(10_000_000);
    //Year must be enough for testing purposes
    public static final BigInteger unlockPeriod = BigInteger.valueOf(60 * 60 * 24 * 365);
    public static final String randomCitizenPassword = "mypasswd";
    public static final Parity parity = Parity.build(new HttpService("http://dev.papyrus.global:80/"));
    public static final Web3j web3j = Web3j.build(new HttpService("http://dev.papyrus.global:80/"));
    public static final String ownerAddr = System.getProperty("owner.addr");
    public static final Properties addresses = loadAddresses();

    private PapyrusUtils() {/**/}

    public static final long AWAIT_BLOCK_DELAY = 5 * 1000;

    public static CompletableFuture<PapyrusMember> createNewMember(double initialBalance, long initialPrpBalance) throws NoSuchAlgorithmException, NoSuchProviderException, InvalidAlgorithmParameterException, CipherException, IOException {
        return parity.ethCoinbase().sendAsync()
                //New account with some Ether
                .thenCombine(parity.personalNewAccount(randomCitizenPassword).sendAsync(),
                    (coinbase, newAccount) -> {
                        if (initialBalance > 0) {
                            return transferEther(coinbase.getAddress(), newAccount.getAccountId(), initialBalance)
                                    .thenApply(transaction -> new PapyrusMember(newAccount.getAccountId(), web3j)
                                            .withRefillTransaction(transaction.getTransactionHash())
                                    );
                        } else {
                            return CompletableFuture.completedFuture(new PapyrusMember(newAccount.getAccountId(), web3j));
                        }
                    }
                )
                //Flat map
                .thenCompose(papyrusMember -> papyrusMember)
                //Mint some tokens for new member
                .thenCompose(papyrusMember -> mintPrp(papyrusMember.address, initialPrpBalance)
                        .thenApply(transaction -> papyrusMember.withMintTransaction(transaction.getTransactionHash()))
                )
                //And unlock it
                .thenCompose(member -> parity.personalUnlockAccount(member.address, randomCitizenPassword).sendAsync()
                        .thenApply(unlocked -> member)
                );
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

    public static CompletableFuture<EthSendTransaction> transferEther(String from, String to, double ethAmount) {
        return web3j.ethGetTransactionCount(from, DefaultBlockParameterName.LATEST).sendAsync()
                .thenCompose(transactionCount -> parity.ethSendTransaction(
                                Transaction.createEtherTransaction(from, transactionCount.getTransactionCount(),
                                        GAS_PRICE, GAS_LIMIT, to, toWei(ethAmount))).sendAsync()
                );
    }

    public static CompletableFuture<TransactionReceipt> mintPrp(String to, long prpAmount) {
        return Web3jUtils.asCf(loadDaoContract(new ClientTransactionManager(web3j, ownerAddr)).token()).thenCompose(tokenAddr ->
            Web3jUtils.asCf(loadTokenContract(tokenAddr.toString(), new ClientTransactionManager(web3j, ownerAddr)).mint(new Address(to), new Uint256(prpAmount), new Uint256(0)))
        );
    }

    public static CompletableFuture<?> allTransactionsMinedAsync(Collection<String> txHashes) {
        return CompletableFuture.allOf(txHashes.stream().map(PapyrusUtils::transactionMinedAsync).toArray(CompletableFuture[]::new));
    }

    public static PapyrusPrototypeToken loadTokenContract(String contractAddress, TransactionManager tm) {
        return PapyrusPrototypeToken.load(contractAddress, web3j, tm, gasPrice, gasLimit);
    }

    public static PapyrusDAO loadDaoContract(TransactionManager tm) {
        return PapyrusDAO.load(addresses.getProperty("dao"), web3j, tm, gasPrice, gasLimit);
    }

    public static SSPRegistry loadSspRegistry(String contractAddress, TransactionManager tm) {
        return SSPRegistry.load(contractAddress, web3j, tm, gasPrice, gasLimit);
    }

    public static DSPRegistry loadDspRegistry(String contractAddress, TransactionManager tm) {
        return DSPRegistry.load(contractAddress, web3j, tm, gasPrice, gasLimit);
    }

    public static AuditorRegistry loadAuditorRegistry(String contractAddress, TransactionManager tm) {
        return AuditorRegistry.load(contractAddress, web3j, tm, gasPrice, gasLimit);
    }

    public static PublisherRegistry loadPublisherRegistry(String contractAddress, TransactionManager tm) {
        return PublisherRegistry.load(contractAddress, web3j, tm, gasPrice, gasLimit);
    }

    public static DSPRegistrar loadDspRegistrar(TransactionManager tm) {
        return DSPRegistrar.load(addresses.getProperty("dao"), web3j, tm, gasPrice, gasLimit);
    }

    public static SecurityDepositRegistry loadSecurityDepositRegistry(String contractAddress, TransactionManager tm) {
        return SecurityDepositRegistry.load(contractAddress, web3j, tm, gasPrice, gasLimit);
    }

    public static Address daoAddress() {
        return new Address(addresses.getProperty("dao"));
    }

    public static Address ownerAddress() {
        return new Address(ownerAddr);
    }

    public static BigInteger toWei(double amount) {
        return BigDecimal.valueOf(amount).multiply(new BigDecimal(ethPrice)).toBigIntegerExact();
    }

    public static double fromWei(BigInteger weiAmount) {
        return new BigDecimal(weiAmount).divide(new BigDecimal(ethPrice), new MathContext(18, RoundingMode.HALF_UP)).doubleValue();
    }

    public static StaticArray<Bytes32> generateUrl(int length) {
        return new StaticArray<>(Stream.generate(() -> UUID.randomUUID().toString().replaceAll("-", "")).limit(length)
                .map(str -> new Bytes32(str.getBytes()))
                .toArray(Bytes32[]::new));
    }

    public static CompletableFuture<Integer> balanceOf(PapyrusPrototypeToken token, Address address) {
        return asCf(token.balanceOf(address)).thenApply(uint -> uint.getValue().intValue());
    }

    public static Properties loadAddresses() {
        try {
            Properties addresses = new Properties();
            addresses.load(new FileReader("contracts.properties"));
            return addresses;
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }
}
