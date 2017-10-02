package global.papyrus;

import org.web3j.abi.datatypes.Address;
import org.web3j.crypto.Credentials;
import org.web3j.crypto.WalletFile;

/**
 * Created by andreyvlasenko on 23/09/17.
 */
public class PapyrusMember {
    public final WalletFile walletFile;
    public final Credentials credentials;
    public String refillTransaction;
    public String mintTransaction;

    public PapyrusMember(WalletFile walletFile, Credentials credentials) {
        this.walletFile = walletFile;
        this.credentials = credentials;
    }

    public PapyrusMember withRefillTransaction(String refillTransaction) {
        this.refillTransaction = refillTransaction;
        return this;
    }

    public PapyrusMember withMintTransaction(String mintTransaction) {
        this.mintTransaction = mintTransaction;
        return this;
    }

    public String getAddressHex() {
        return "0x" + walletFile.getAddress();
    }

    public Address getAddress() {
        return new Address("0x" + walletFile.getAddress());
    }
}
