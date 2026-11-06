package qbloom.app

object BackendTest {
    @JvmStatic
    fun main(args: Array<String>) {
        val backend = Backend()
        check(backend.greeting() == "Hello, world!")
        check(backend.count() == 0)
        backend.increment()
        check(backend.count() == 1)
        backend.increment()
        check(backend.count() == 2)
        backend.reset()
        check(backend.count() == 0)
        println("PASS: Kotlin backend 0 -> 1 -> 2 -> 0")
    }
}
