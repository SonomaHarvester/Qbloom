package qbloom.app;

public final class BackendTest {
    public static void main(String[] args) {
        Backend backend = new Backend();
        check("Hello, world!".equals(backend.greeting()));
        check(backend.count() == 0);
        backend.increment();
        check(backend.count() == 1);
        backend.increment();
        check(backend.count() == 2);
        backend.reset();
        check(backend.count() == 0);
        System.out.println("PASS: Java backend 0 -> 1 -> 2 -> 0");
    }

    private static void check(boolean valid) {
        if (!valid) throw new AssertionError("Java backend contract failed");
    }
}
