package qbloom.app

class Backend {
    private var value = 0

    fun greeting(): String = "Hello, world!"
    fun count(): Int = value
    fun increment() { value += 1 }
    fun reset() { value = 0 }
}
