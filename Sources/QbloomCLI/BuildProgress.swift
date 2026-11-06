import Foundation

/// Progress is local to the current native build step. Unknown totals stay unknown.
enum BuildProgress {
  static func useNerdFont(
    environment: [String: String] = ProcessInfo.processInfo.environment,
    isTerminal: Bool
  ) -> Bool {
    if let setting = environment["UNICODE_PROGRESS_BAR"]?.lowercased() {
      if ["true", "1", "yes"].contains(setting) { return true }
      if ["false", "0", "no"].contains(setting) { return false }
    }
    guard isTerminal, !["dumb", "unknown"].contains(environment["TERM"]?.lowercased() ?? "")
    else { return false }

    // LC_CTYPE controls output encoding. A terminal can use UTF-8 while the
    // message locale is different, so LC_MESSAGES is deliberately ignored.
    let locale =
      ["LC_ALL", "LC_CTYPE", "LANG"]
      .compactMap { environment[$0] }
      .first { !$0.isEmpty }?.lowercased() ?? ""
    if locale == "c" || locale == "posix" { return false }
    if let encoding = locale.split(separator: ".", maxSplits: 1).dropFirst().first {
      let name = encoding.split(separator: "@", maxSplits: 1).first ?? ""
      return name == "utf-8" || name == "utf8"
    }
    // Modern interactive terminals normally use UTF-8. Font coverage still
    // cannot be queried through a portable terminal API.
    return true
  }

  static func fraction(in line: String) -> Int? {
    let trimmed = line.trimmingCharacters(in: .whitespaces)
    if trimmed.hasPrefix("["), let close = trimmed.firstIndex(of: "]") {
      let inner = trimmed[trimmed.index(after: trimmed.startIndex)..<close]
      let parts = inner.split(separator: "/")
      if parts.count == 2, let done = Int(parts[0]), let total = Int(parts[1]), total > 0,
        done >= 0, done <= total
      {
        return done * 100 / total
      }
    }
    // CMake's Makefile generator prints lines such as "[ 42%] Building CXX object".
    if trimmed.hasPrefix("["), let close = trimmed.firstIndex(of: "]") {
      let inner = trimmed[trimmed.index(after: trimmed.startIndex)..<close]
        .trimmingCharacters(in: .whitespaces)
      if inner.hasSuffix("%"), let value = Int(inner.dropLast()), (0...100).contains(value) {
        return value
      }
    }
    return nil
  }

  static func bar(_ percent: Int, nerdFont: Bool) -> String {
    let filled = max(0, min(10, percent / 10))
    if nerdFont {
      // Fira Code / Nerd Fonts progress glyphs U+EE00...U+EE05.
      let left = filled > 0 ? "\u{EE03}" : "\u{EE00}"
      let middle =
        String(repeating: "\u{EE04}", count: max(0, filled - 1))
        + String(repeating: "\u{EE01}", count: 10 - filled)
      let right = filled == 10 ? "\u{EE05}" : "\u{EE02}"
      return left + middle + right
    }
    return "[" + String(repeating: "#", count: filled)
      + String(repeating: "-", count: 10 - filled) + "]"
  }
}

final class BuildProgressDisplay {
  private let interactive: Bool = {
    #if os(Windows)
      return false
    #else
      return isatty(STDOUT_FILENO) == 1
    #endif
  }()
  private let nerdFont: Bool = {
    #if os(Windows)
      let isTerminal = false
    #else
      let isTerminal = isatty(STDOUT_FILENO) == 1
    #endif
    return BuildProgress.useNerdFont(isTerminal: isTerminal)
  }()
  private var percent = 0
  private var step = ""
  private var visible = false

  func start(_ step: String) {
    self.step = step
    percent = 0
    visible = false
  }

  func show() {
    guard interactive else { return }
    if visible { print("\r\u{001B}[2K", terminator: "") }
    print(
      label + ": " + BuildProgress.bar(percent, nerdFont: nerdFont) + " \(percent)%",
      terminator: "")
    visible = true
    // Flush buffered output without accessing libc's mutable stdout global.
    fflush(nil)
  }

  func output(_ line: String, verbose: Bool = false) {
    let value = BuildProgress.fraction(in: line)
    if let value { percent = value }
    if interactive && value != nil && !verbose {
      show()
      return
    }
    if visible { print("\r\u{001B}[2K", terminator: "") }
    print(line)
    visible = false
    show()
    fflush(nil)
  }

  func finish(_ step: String) {
    if visible { print("\r\u{001B}[2K", terminator: "") }
    print("\(L10n.message(step)): \(BuildProgress.bar(100, nerdFont: nerdFont)) 100%")
    visible = false
    fflush(nil)
  }

  func fail() {
    if visible { print("\r\u{001B}[2K", terminator: "") }
    visible = false
    fflush(nil)
  }

  private var label: String { L10n.message(step) }
}
