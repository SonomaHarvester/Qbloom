import Foundation

#if canImport(Darwin)
  import Darwin
#elseif canImport(Glibc)
  import Glibc
#endif

enum CLIStyle {
  private static let commandPattern =
    #"\bqbloom (?:init|in|add|override|ovr|doctor|build|run|test|clean)\b"#
  private static let optionPattern = #"(?<![A-Za-z0-9])--[a-z][a-z0-9-]*\b"#
  private static let cyan = "\u{001B}[1;36m"
  private static let reset = "\u{001B}[0m"

  static func decorateError(_ value: String, enabled: Bool = colorEnabled()) -> String {
    guard enabled else { return value }
    return highlight(optionPattern, in: highlight(commandPattern, in: value))
  }

  private static func highlight(_ pattern: String, in value: String) -> String {
    guard let expression = try? NSRegularExpression(pattern: pattern) else { return value }
    var result = value
    let matches = expression.matches(
      in: value, range: NSRange(value.startIndex..<value.endIndex, in: value))
    for match in matches.reversed() {
      guard let range = Range(match.range, in: result) else { continue }
      result.replaceSubrange(range, with: cyan + result[range] + reset)
    }
    return result
  }

  private static func colorEnabled() -> Bool {
    let environment = ProcessInfo.processInfo.environment
    if environment["NO_COLOR"] != nil || environment["TERM"] == "dumb" { return false }
    #if canImport(Darwin) || canImport(Glibc)
      return isatty(STDERR_FILENO) == 1
    #else
      return false
    #endif
  }
}
