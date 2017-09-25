package global.papyrus;

import org.web3j.crypto.Credentials;
import org.web3j.crypto.WalletFile;

/**
 * Created by andreyvlasenko on 23/09/17.
 */
public class PapyrusMember {
    public final WalletFile walletFile;
    public final Credentials credentials;

    public PapyrusMember(WalletFile walletFile, Credentials credentials) {
        this.walletFile = walletFile;
        this.credentials = credentials;
    }

    public String getAddress() {
        return "0x" + walletFile.getAddress();
    }
}
