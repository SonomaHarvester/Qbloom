package qbloom.app;

public final class Backend {
    private int count;

    public String greeting() { return "Hello, world!"; }
    public int count() { return count; }
    public void increment() { count++; }
    public void reset() { count = 0; }
}
