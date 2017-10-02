package global.papyrus;

import global.papyrus.smartcontracts.PapyrusDAO;
import global.papyrus.smartcontracts.PapyrusPrototypeToken;
import org.testng.Assert;
import org.testng.annotations.BeforeClass;
import org.testng.annotations.Test;
import org.web3j.abi.datatypes.StaticArray;
import org.web3j.abi.datatypes.Type;
import org.web3j.abi.datatypes.generated.Bytes32;
import org.web3j.abi.datatypes.generated.Uint256;
import org.web3j.crypto.CipherException;
import org.web3j.protocol.core.methods.request.EthFilter;

import java.io.IOException;
import java.math.BigInteger;
import java.security.InvalidAlgorithmParameterException;
import java.security.NoSuchAlgorithmException;
import java.security.NoSuchProviderException;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Stream;

import static java.util.Arrays.asList;
import static global.papyrus.PapyrusUtils.*;
import static global.papyrus.Web3jUtils.*;

/**
 * Created by andreyvlasenko on 27/09/17.
 */
public class DSPTest {

    private PapyrusMember dsp;

    @BeforeClass
    public void registerUser() throws CipherException, InvalidAlgorithmParameterException, NoSuchAlgorithmException, NoSuchProviderException, IOException {
        dsp = createNewMember(BigInteger.valueOf(100), BigInteger.valueOf(100))
                .thenApply(papyrusMember -> {
                    allTransactionsMinedAsync(asList(papyrusMember.refillTransaction, papyrusMember.mintTransaction));
                    return papyrusMember;
                }).join();
    }

    @Test
    public void testRegister() {
        PapyrusDAO dao = loadDaoContract(dsp.credentials);
        PapyrusPrototypeToken token = loadTokenContract(dsp.credentials);
        asCf(dao.findDsp(dsp.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), "0x0")).join();
        asCf(dao.registerDsp(dsp.getAddress(), generateUrl(3))).thenAccept(receipt -> Assert.assertNull(receipt.getTransactionHash())).join();
        asCf(token.approve(daoAddress(), new Uint256(BigInteger.TEN))).join();
        asCf(dao.registerDsp(dsp.getAddress(), generateUrl(3))).thenAccept(receipt -> Assert.assertNotNull(receipt.getTransactionHash())).join();
        asCf(dao.findDsp(dsp.getAddress())).thenAccept(types -> Assert.assertEquals(types.get(0).getTypeAsString(), dsp.getAddressHex())).join();
    }

    public static StaticArray<Bytes32> generateUrl(int length) {
        return new StaticArray<>(Stream.generate(() -> UUID.randomUUID().toString().replaceAll("-", "")).limit(length).toArray(Bytes32[]::new));
    }
}
