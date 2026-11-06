import XCTest

@testable import QbloomSwiftBackend

final class BackendTests: XCTestCase {
  func testGreetingAndCounter() {
    let state = CounterState()
    XCTAssertEqual(state.greeting, "Hello, world!")
    XCTAssertEqual(state.count, 0)
    XCTAssertEqual(state.increment(), 1)
    XCTAssertEqual(state.increment(), 2)
    XCTAssertEqual(state.reset(), 0)
  }

  func testCAbiBufferAndHandle() {
    let handle = qbloomSwiftNew()
    defer { qbloomSwiftDestroy(handle) }
    var buffer = [CChar](repeating: 0, count: 64)
    XCTAssertEqual(qbloomSwiftGreeting(handle, &buffer, Int32(buffer.count)), 0)
    XCTAssertEqual(
      String(
        decoding: buffer.prefix(while: { $0 != 0 }).map { UInt8(bitPattern: $0) }, as: UTF8.self),
      "Hello, world!")
    XCTAssertEqual(qbloomSwiftCount(handle), 0)
    XCTAssertEqual(qbloomSwiftIncrement(handle), 1)
    XCTAssertEqual(qbloomSwiftIncrement(handle), 2)
    XCTAssertEqual(qbloomSwiftReset(handle), 0)
    XCTAssertEqual(qbloomSwiftGreeting(handle, &buffer, 1), -2)
  }
}
