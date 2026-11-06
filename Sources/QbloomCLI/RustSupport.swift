import ArgumentParser
import Foundation

private func rustEnvironment(_ root: URL) -> [String: String] {
  var values = ["CARGO_TARGET_DIR": root.appendingPathComponent(".qbloom/build").path]
  if let qmake = qtQmake() { values["QMAKE"] = qmake }
  return values
}

func rustChecks(in root: URL) -> [Check] {
  var checks: [Check] = []
  for (name, arguments) in [
    ("cargo", ["--version"]), ("rustc", ["--version"]),
    cppCompilerProbe, ("cmake", ["--version"]),
    ("qmake6", ["-query", "QT_VERSION"]),
  ] {
    guard let path = name == "qmake6" ? qtQmake() : executable(name) else {
      checks.append(
        Check(
          name: name, status: "missing", version: nil, severity: "error",
          remediation: name == "cargo" || name == "rustc"
            ? Toolchain.rust.installationAdvice("Install Rust 1.85 or newer for CXX-Qt 0.10.0")
            : Toolchain.missingToolAdvice(name)))
      continue
    }
    let version = outputOf(path, arguments, includeStandardError: name == "cl")?
      .split(whereSeparator: \.isNewline).first.map(String.init)
    if name == "rustc", let version {
      let number = version.split(separator: " ").dropFirst().first?.split(separator: ".") ?? []
      let major = number.first.flatMap { Int($0) } ?? 0
      let minor = number.dropFirst().first.flatMap { Int($0) } ?? 0
      if major < 1 || (major == 1 && minor < 85) {
        checks.append(
          Check(
            name: name, status: "unsupported", version: version,
            severity: "error",
            remediation: Toolchain.rust.installationAdvice(
              "Install Rust 1.85 or newer for CXX-Qt 0.10.0")))
        continue
      }
    }
    if name == "qmake6", let version {
      let number = version.split(separator: ".")
      let major = number.first.flatMap { Int($0) } ?? 0
      let minor = number.dropFirst().first.flatMap { Int($0) } ?? 0
      if major != 6 || minor < 8 {
        checks.append(
          Check(
            name: name, status: "unsupported", version: version,
            severity: "error",
            remediation: Toolchain.qt.installationAdvice(
              "Install Qt 6.8 or newer development tools")))
        continue
      }
    }
    checks.append(
      Check(
        name: name, status: version == nil ? "broken" : "found",
        version: version, severity: version == nil ? "error" : "info",
        remediation: version == nil ? "Repair \(name); it is on PATH but cannot run" : nil))
  }
  checks.append(qtModuleCheck("Qt6Quick"))
  checks.append(qtModuleCheck("Qt6QuickControls2"))
  return checks
}

func buildRust(
  _ root: URL, manifest: Manifest, release: Bool, progress: BuildProgressDisplay? = nil
) throws {
  guard let cargo = executable("cargo") else {
    throw QbloomError.message("Cargo is missing; run qbloom doctor")
  }
  guard qtQmake() != nil else {
    throw QbloomError.message("Qt 6 qmake6 is missing; run qbloom doctor")
  }
  let args = ["build", "--locked"] + (release ? ["--release"] : [])
  progress?.start("Cargo build")
  let result = try Runner.run(
    cargo, args, in: codeRoot(root, manifest), environment: rustEnvironment(root))
  if result != 0 { throw ExitCode(result) }
  progress?.finish("Cargo build")
}

private func rustApplication(in root: URL, name: String, release: Bool) -> URL {
  let mode = release ? "release" : "debug"
  #if os(Windows)
    let filename = identifier(name) + ".exe"
  #else
    let filename = identifier(name)
  #endif
  return root.appendingPathComponent(".qbloom/build/\(mode)/\(filename)")
}

func runRust(_ root: URL, manifest: Manifest, release: Bool, arguments: [String]) throws {
  try buildRust(root, manifest: manifest, release: release)
  let app = rustApplication(in: root, name: manifest.name, release: release)
  let result = try Runner.run(app.path, arguments, in: root)
  if result != 0 { throw ExitCode(result) }
}

func testRust(_ root: URL, manifest: Manifest, release: Bool, headless: Bool) throws {
  try buildRust(root, manifest: manifest, release: release)
  guard let cargo = executable("cargo") else {
    throw QbloomError.message("Cargo is missing; run qbloom doctor")
  }
  let arguments = ["test", "--locked"] + (release ? ["--release"] : [])
  let unitStatus = try Runner.run(
    cargo, arguments, in: codeRoot(root, manifest), environment: rustEnvironment(root))
  if unitStatus != 0 { throw ExitCode(unitStatus) }
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
  let app = rustApplication(in: root, name: manifest.name, release: release)
  var environment: [String: String] = [:]
  if headless {
    environment["QT_QPA_PLATFORM"] = "offscreen"
    environment["QT_QUICK_BACKEND"] = "software"
  }
  let smokeStatus = try Runner.run(
    app.path, ["--smoke-test"], in: root,
    environment: environment)
  if smokeStatus != 0 { throw ExitCode(smokeStatus) }
}
