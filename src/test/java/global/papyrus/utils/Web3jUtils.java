package global.papyrus.utils;

import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Future;


public class Web3jUtils {
    private Web3jUtils() {/**/}

    public static <T> CompletableFuture<T> asCf(Future<T> future) {
        return (CompletableFuture<T>)future;
    }
}
