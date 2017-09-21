package global.papyrus;

import global.papyrus.smartcontracts.PapyrusDAO;
import org.web3j.abi.datatypes.Address;
import org.web3j.abi.datatypes.Type;
import org.web3j.crypto.CipherException;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.WalletUtils;
import org.web3j.protocol.Web3j;
import org.web3j.protocol.core.methods.response.TransactionReceipt;
import org.web3j.protocol.core.methods.response.Web3ClientVersion;
import org.web3j.protocol.http.HttpService;

import java.io.File;
import java.io.IOException;
import java.math.BigInteger;
import java.util.List;
import java.util.concurrent.ExecutionException;

/**
 * Created by andreyvlasenko on 20/09/17.
 */
public class DaoTest {
    public static final BigInteger GAS_PRICE = BigInteger.valueOf(1);
    public static final BigInteger GAS_LIMIT = BigInteger.valueOf(1000000);

    public static void main(String[] args) throws ExecutionException, InterruptedException, IOException, CipherException {
        Web3j web3j = Web3j.build(new HttpService());  // defaults to http://localhost:8545/
        Web3ClientVersion web3ClientVersion = web3j.web3ClientVersion().sendAsync().get();
        System.out.println(web3ClientVersion.getWeb3ClientVersion());
        Credentials credentials = WalletUtils.loadCredentials("1234567890", new File("/Users/andreyvlasenko/papyrus/geth/keystore/UTC--2017-07-07T12-02-40.770316400Z--f61e02f629e3ca8af430f8db8d1ab22c7093303b"));
        PapyrusDAO daoContract = PapyrusDAO.load(args[0], web3j, credentials, GAS_PRICE, GAS_LIMIT);
        Address auditor  = new Address("0x2242936ea02b5c029172faaee8d6066755a32394");
        TransactionReceipt r = daoContract.registerAuditor(auditor).get();
        List<Type> res = daoContract.findAuditor(auditor).get();
        System.out.println(daoContract);
    }
}
