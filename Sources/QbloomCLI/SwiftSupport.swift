import ArgumentParser
import Foundation

func swiftChecks(in root: URL) -> [Check] {
  var checks: [Check] = []
  guard let swift = executable("swift") else {
    return [
      Check(
        name: "swift", status: "missing", version: nil, severity: "error",
        remediation: Toolchain.swift.installationAdvice(
          "Install Swift 6.4 or newer and add swift to PATH"))
    ]
  }
  let version = outputOf(swift, ["--version"])
  let versionWord = version?.split(separator: " ").first(where: { $0.first?.isNumber == true })
  let numbers = versionWord?.split(separator: ".") ?? []
  let major = numbers.first.flatMap { Int($0) } ?? 0
  let minor = numbers.dropFirst().first.flatMap { Int($0) } ?? 0
  let good = major > 6 || (major == 6 && minor >= 4)
  checks.append(
    Check(
      name: "swift", status: good ? "found" : "unsupported",
      version: version?.split(separator: "\n").first.map(String.init),
      severity: good ? "info" : "error",
      remediation: good
        ? nil
        : version == nil
          ? Toolchain.swift.installationAdvice("Install Swift 6.4 or newer and add swift to PATH")
          : "Install Swift 6.4 or newer for the experimental C ABI adapter"))
  for (name, args) in [
    ("cmake", ["--version"]), cppCompilerProbe,
    ("qmake6", ["-query", "QT_VERSION"]),
  ] {
    guard let path = name == "qmake6" ? qtQmake() : executable(name) else {
      checks.append(
        Check(
          name: name, status: "missing", version: nil,
          severity: "error", remediation: Toolchain.missingToolAdvice(name)))
      continue
    }
    let value = outputOf(path, args, includeStandardError: name == "cl")?
      .split(whereSeparator: \.isNewline).first.map(String.init)
    if name == "qmake6", let value {
      let parts = value.split(separator: ".").compactMap { Int($0) }
      if parts.count < 2 || parts[0] != 6 || parts[1] < 8 {
        checks.append(
          Check(
            name: name, status: "unsupported", version: value,
            severity: "error",
            remediation: Toolchain.qt.installationAdvice(
              "Install Qt 6.8 or newer development tools")))
        continue
      }
    }
    checks.append(
      Check(
        name: name, status: value == nil ? "broken" : "found",
        version: value, severity: value == nil ? "error" : "info",
        remediation: value == nil ? "Repair \(name); it cannot run" : nil))
  }
  checks.append(qtModuleCheck("Qt6Quick"))
  checks.append(qtModuleCheck("Qt6QuickControls2"))
  return checks
}

func buildSwift(
  _ root: URL, release: Bool, verbose: Bool = false, progress: BuildProgressDisplay? = nil
) throws {
  let failures = swiftChecks(in: root).filter { $0.severity == "error" }
  guard failures.isEmpty else {
    throw QbloomError.message(failures.compactMap(\.remediation).joined(separator: "; "))
  }
  try buildProject(root, release: release, verbose: verbose, progress: progress)
}

func runSwift(_ root: URL, manifest: Manifest, release: Bool, arguments: [String]) throws {
  try buildSwift(root, release: release)
  let app = cmakeApplication(in: root, layout: manifest.layout, release: release)
  let status = try Runner.run(app.path, arguments, in: root)
  if status != 0 { throw ExitCode(status) }
}

func testSwift(_ root: URL, manifest: Manifest, release: Bool, headless: Bool) throws {
  try buildSwift(root, release: release)
  guard let swift = executable("swift") else { throw QbloomError.message("Swift is missing") }
  let arguments = [
    "test", "--package-path", codeRoot(root, manifest).path,
    "--scratch-path", root.appendingPathComponent(".qbloom/build/swift").path,
    "--configuration", release ? "release" : "debug",
  ]
  let unit = try Runner.run(swift, arguments, in: codeRoot(root, manifest))
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
  let env = headless ? ["QT_QPA_PLATFORM": "offscreen", "QT_QUICK_BACKEND": "software"] : [:]
  let app = cmakeApplication(in: root, layout: manifest.layout, release: release)
  let smoke = try Runner.run(app.path, ["--smoke-test"], in: root, environment: env)
  if smoke != 0 { throw ExitCode(smoke) }
}
