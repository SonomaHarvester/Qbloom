package qbloom.app;

public final class Main {
    private static native int launch(Backend backend, String[] args);

    public static void main(String[] args) {
        String library = System.getenv("QBLOOM_NATIVE_LIBRARY");
        if (library == null || library.isBlank()) {
            throw new IllegalStateException("QBLOOM_NATIVE_LIBRARY must point to the built Qt JNI library; use qbloom run");
        }
        System.load(library);
        int status = launch(new Backend(), args);
        if (status != 0) System.exit(status);
    }
}
