package global.papyrus.utils;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Future;

import org.web3j.protocol.core.RemoteCall;


public class Web3jUtils {
    private Web3jUtils() {/**/}

    public static <T> CompletableFuture<T> asCf(RemoteCall<T> call) {
        return call.sendAsync();
    }

    public static <T> CompletableFuture<T> asCf(Future<T> future) {
        return (CompletableFuture<T>)future;
    }
}
