package global.papyrus.utils;

import org.web3j.abi.datatypes.Address;
import org.web3j.protocol.Web3j;
import org.web3j.tx.ClientTransactionManager;
import org.web3j.tx.TransactionManager;

/**
 * Created by andreyvlasenko on 23/09/17.
 */
public class PapyrusMember {
    public String address;
    public TransactionManager transactionManager;
    public String refillTransaction;
    public String mintTransaction;

    public PapyrusMember(String address, Web3j web3j) {
        this.address = address;
        this.transactionManager = new ClientTransactionManager(web3j, address);
    }

    public PapyrusMember withRefillTransaction(String refillTransaction) {
        this.refillTransaction = refillTransaction;
        return this;
    }

    public PapyrusMember withMintTransaction(String mintTransaction) {
        this.mintTransaction = mintTransaction;
        return this;
    }

    public Address getAddress() {
        return new Address(address);
    }
}
