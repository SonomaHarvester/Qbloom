import ArgumentParser
import Foundation

func goChecks() -> [Check] {
  guard let go = executable("go") else {
    return [
      Check(
        name: "go", status: "missing", version: nil, severity: "error",
        remediation: Toolchain.go.installationAdvice("Install Go 1.23 or newer and add go to PATH"))
    ]
  }
  let version = outputOf(go, ["version"])
  let versionWord = version?.split(separator: " ").first(where: { $0.hasPrefix("go1.") })
  let components = versionWord?.dropFirst(2).split(separator: ".") ?? []
  let goodVersion =
    components.count >= 2 && (Int(components[0]) ?? 0) >= 1
    && (Int(components[1]) ?? 0) >= 23
  let goCheck = Check(
    name: "go", status: goodVersion ? "found" : "unsupported", version: version,
    severity: goodVersion ? "info" : "error",
    remediation: goodVersion
      ? nil
      : Toolchain.go.installationAdvice(
        "Install Go 1.23 or newer (set GOTOOLCHAIN=local for offline builds)"))
  let cc = outputOf(go, ["env", "CC"])
  let ccFound = cc.flatMap { executable($0) } != nil
  let ccCheck = Check(
    name: "cgo C compiler", status: ccFound ? "found" : "missing", version: cc,
    severity: ccFound ? "info" : "error",
    remediation: ccFound ? nil : "Install the C compiler selected by `go env CC` for cgo")
  #if os(FreeBSD)
    let hostOS = "freebsd"
  #elseif os(Linux)
    let hostOS = "linux"
  #elseif os(macOS)
    let hostOS = "darwin"
  #elseif os(Windows)
    let hostOS = "windows"
  #else
    let hostOS = "unknown"
  #endif
  let hostArch = architecture() == "x86_64" ? "amd64" : architecture()
  let goOS = outputOf(go, ["env", "GOOS"])
  let goArch = outputOf(go, ["env", "GOARCH"])
  let matchingTarget = goOS == hostOS && goArch == hostArch
  let targetCheck = Check(
    name: "Go target", status: matchingTarget ? "found" : "unsupported",
    version: [goOS ?? "?", goArch ?? "?"].joined(separator: "/"),
    severity: matchingTarget ? "info" : "error",
    remediation: matchingTarget
      ? nil : "Set GOOS/GOARCH for the native Qt host target \(hostOS)/\(hostArch)")
  return [goCheck, ccCheck, targetCheck]
}

func buildGo(
  _ root: URL, manifest: Manifest, release: Bool, verbose: Bool = false,
  progress: BuildProgressDisplay? = nil
) throws {
  let failures = goChecks().filter { $0.severity == "error" }
  guard failures.isEmpty else {
    throw QbloomError.message(failures.compactMap(\.remediation).joined(separator: "; "))
  }
  #if os(Windows)
    // cgo uses MinGW while the Qt facade uses the MSVC kit.
    let host = ProcessInfo.processInfo.environment
    let hasCompiler = host.keys.contains { $0.caseInsensitiveCompare("CXX") == .orderedSame }
    let environment = hasCompiler ? [:] : ["CXX": "cl.exe"]
  #else
    let environment: [String: String] = [:]
  #endif
  try buildProject(
    root, release: release, verbose: verbose, environment: environment, progress: progress)
}

func runGo(_ root: URL, manifest: Manifest, release: Bool, arguments: [String]) throws {
  try buildGo(root, manifest: manifest, release: release)
  let app = cmakeApplication(in: root, layout: manifest.layout, release: release)
  let status = try Runner.run(app.path, arguments, in: root)
  if status != 0 { throw ExitCode(status) }
}

func testGo(_ root: URL, manifest: Manifest, release: Bool, headless: Bool) throws {
  try buildGo(root, manifest: manifest, release: release)
  guard let go = executable("go") else {
    throw QbloomError.message("Go is missing; run qbloom doctor")
  }
  let unit = try Runner.run(
    go, ["test", "./..."], in: codeRoot(root, manifest),
    environment: ["CGO_ENABLED": "1", "GOTOOLCHAIN": "local", "GOPROXY": "off"])
  if unit != 0 { throw ExitCode(unit) }
  #if os(Linux) || os(FreeBSD)
    let host = ProcessInfo.processInfo.environment
    if !headless && host["DISPLAY"] == nil && host["WAYLAND_DISPLAY"] == nil
      && host["QT_QPA_PLATFORM"] == nil
    {
      print(
        L10n.noDisplay
      )
      return
    }
  #endif
  let app = cmakeApplication(in: root, layout: manifest.layout, release: release)
  let environment =
    headless ? ["QT_QPA_PLATFORM": "offscreen", "QT_QUICK_BACKEND": "software"] : [:]
  let smoke = try Runner.run(app.path, ["--smoke-test"], in: root, environment: environment)
  if smoke != 0 { throw ExitCode(smoke) }
}
