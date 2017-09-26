package global.papyrus;

import org.web3j.crypto.Credentials;
import org.web3j.crypto.WalletFile;

/**
 * Created by andreyvlasenko on 23/09/17.
 */
public class PapyrusMember {
    public final WalletFile walletFile;
    public final Credentials credentials;
    public final String refillTransaction;

    public PapyrusMember(WalletFile walletFile, Credentials credentials, String refillTransaction) {
        this.walletFile = walletFile;
        this.credentials = credentials;
        this.refillTransaction = refillTransaction;
    }

    public String getAddress() {
        return "0x" + walletFile.getAddress();
    }
}
