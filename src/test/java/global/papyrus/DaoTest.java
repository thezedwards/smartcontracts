package global.papyrus;

import com.fasterxml.jackson.databind.ObjectMapper;
import global.papyrus.smartcontracts.PapyrusDAO;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.Type;
import org.web3j.crypto.CipherException;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.WalletFile;
import org.web3j.crypto.WalletUtils;
import org.web3j.protocol.ObjectMapperFactory;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.DefaultBlockParameterName;
import org.web3j.protocol.core.methods.request.Transaction;
import org.web3j.protocol.core.methods.response.*;
import org.web3j.protocol.http.HttpService;
import org.web3j.protocol.parity.Parity;
import org.web3j.protocol.parity.methods.response.NewAccountIdentifier;
import org.web3j.protocol.parity.methods.response.PersonalUnlockAccount;
import org.web3j.tx.RawTransactionManager;
import org.web3j.tx.Transfer;

import java.io.File;
import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.List;
import java.util.concurrent.ExecutionException;

import static org.web3j.tx.ManagedTransaction.GAS_PRICE;
import static org.web3j.tx.Transfer.GAS_LIMIT;

/**
 * Created by andreyvlasenko on 20/09/17.
 */
public class DaoTest {

    public static final String password = "mypasswd";
    public static final String ethHome = "/Users/andrew/.ppr";
    public static final ObjectMapper objectMapper = ObjectMapperFactory.getObjectMapper();

    public static void main(String[] args) throws ExecutionException, InterruptedException, IOException, CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException {
        Web3j web3j = Web3j.build(new HttpService("http://dev.papyrus.global:80/"));  // defaults to http://localhost:8545/
        Parity parity = Parity.build(new HttpService("http://dev.papyrus.global:80/"));
//        NewAccountIdentifier accountIdentifier = parity.personalNewAccount("mypasswd").send();
//        EthCoinbase coinbase = parity.ethCoinbase().send();
//        System.out.println(accountIdentifier.getAccountId());
//
//        parity.personalUnlockAccount(coinbase.getAddressHex(), "Test#Passwd").send();
//        EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
//                coinbase.getAddressHex(), DefaultBlockParameterName.LATEST).sendAsync().get();
//        EthSendTransaction transaction = parity.ethSendTransaction(Transaction.createEtherTransaction(coinbase.getAddressHex(), ethGetTransactionCount.getTransactionCount(),
//                GAS_PRICE, GAS_LIMIT, accountIdentifier.getAccountId(), BigInteger.valueOf(10000))).send();
//        BigInteger balance = parity.ethGetBalance(accountIdentifier.getAccountId(), DefaultBlockParameterName.LATEST).send().getBalance();
//        System.out.println(balance.longValue());

        //Creating new wallet
//        String walletFileName = WalletUtils.generateNewWalletFile(password, new File(ethHome), false);
//        File file = new File(ethHome + File.separator + walletFileName);
//        WalletFile walletFile = objectMapper.readValue(new File(ethHome + File.separator + walletFileName), WalletFile.class);
//        String walletAddress = "0x" + walletFile.getAddress();
//        NewAccountIdentifier myAccount = parity.personalNewAccountFromWallet(walletFile, password).send();
//        Credentials myWalletCredentials = WalletUtils.loadCredentials(password, file);
//
//        //Refilling balance
//        EthCoinbase coinbase = parity.ethCoinbase().send();
//        parity.personalUnlockAccount(coinbase.getAddress(), "Test#Passwd").send();
//        EthGetTransactionCount ethGetTransactionCount = web3j.ethGetTransactionCount(
//                coinbase.getAddress(), DefaultBlockParameterName.LATEST).sendAsync().get();
//        EthSendTransaction transaction = parity.ethSendTransaction(Transaction.createEtherTransaction(coinbase.getAddress(), ethGetTransactionCount.getTransactionCount(),
//                GAS_PRICE, GAS_LIMIT, walletAddress, BigInteger.valueOf(100000))).send();
//        System.out.println("Money sent");
//        Thread.sleep(120 * 1000);
        PersonalUnlockAccount personalUnlockAccount = parity.personalUnlockAccount("0xbcb960702272e89b76cfed5395404f345a4a0fdc", "mypasswd").send();
        EthGetBalance ethGetBalance = parity.ethGetBalance("0xbcb960702272e89b76cfed5395404f345a4a0fdc", DefaultBlockParameterName.LATEST).send();
        System.out.println("0xbcb960702272e89b76cfed5395404f345a4a0fdc" + ": " + ethGetBalance.getBalance());

//        //Testing contract
//        PapyrusDAO daoContract = PapyrusDAO.load(args[0], web3j, myWalletCredentials, GAS_PRICE, GAS_LIMIT);
//        Address sspRegistryAddress = daoContract.getSSPRegistry().get();
//        System.out.println(sspRegistryAddress);

//        Address auditor  = new Address("0x2242936ea02b5c029172faaee8d6066755a32394");
//        TransactionReceipt r = daoContract.registerAuditor(auditor).get();
//        List<Type> res = daoContract.findAuditor(auditor).get();
//        System.out.println(daoContract);
    }


}
