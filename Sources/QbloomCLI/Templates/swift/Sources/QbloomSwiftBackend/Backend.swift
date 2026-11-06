// Experimental C ABI adapter. @_cdecl is underscored Swift API; keep it isolated here.
public final class CounterState {
  public private(set) var count: Int32 = 0

  public init() {}

  public var greeting: String { "Hello, world!" }

  @discardableResult
  public func increment() -> Int32 {
    if count < Int32.max { count += 1 }
    return count
  }

  @discardableResult
  public func reset() -> Int32 {
    count = 0
    return count
  }
}

@_cdecl("qbloom_swift_new")
public func qbloomSwiftNew() -> UnsafeMutableRawPointer {
  Unmanaged.passRetained(CounterState()).toOpaque()
}

@_cdecl("qbloom_swift_destroy")
public func qbloomSwiftDestroy(_ handle: UnsafeMutableRawPointer?) {
  guard let handle else { return }
  Unmanaged<CounterState>.fromOpaque(handle).release()
}

@_cdecl("qbloom_swift_greeting")
public func qbloomSwiftGreeting(
  _ handle: UnsafeMutableRawPointer?, _ buffer: UnsafeMutablePointer<CChar>?, _ capacity: Int32
) -> Int32 {
  guard let handle, let buffer, capacity > 0 else { return -1 }
  let state = Unmanaged<CounterState>.fromOpaque(handle).takeUnretainedValue()
  let bytes = Array(state.greeting.utf8CString)
  guard bytes.count <= Int(capacity) else { return -2 }
  for (index, byte) in bytes.enumerated() { buffer[index] = byte }
  return 0
}

@_cdecl("qbloom_swift_count")
public func qbloomSwiftCount(_ handle: UnsafeMutableRawPointer?) -> Int32 {
  guard let handle else { return -1 }
  return Unmanaged<CounterState>.fromOpaque(handle).takeUnretainedValue().count
}

@_cdecl("qbloom_swift_increment")
public func qbloomSwiftIncrement(_ handle: UnsafeMutableRawPointer?) -> Int32 {
  guard let handle else { return -1 }
  return Unmanaged<CounterState>.fromOpaque(handle).takeUnretainedValue().increment()
}

@_cdecl("qbloom_swift_reset")
public func qbloomSwiftReset(_ handle: UnsafeMutableRawPointer?) -> Int32 {
  guard let handle else { return -1 }
  return Unmanaged<CounterState>.fromOpaque(handle).takeUnretainedValue().reset()
}
