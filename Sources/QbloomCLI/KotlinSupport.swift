import ArgumentParser
import Foundation

func kotlinChecks(in root: URL) -> [Check] {
  var checks = javaChecks(in: root)
  checks.append(
    Check(
      name: "Kotlin Gradle plugin", status: "resolved-at-build", version: "2.4.10",
      severity: "info",
      remediation:
        "The first explicit build resolves the pinned Kotlin plugin from Maven Central; later builds can use Gradle's cache"
    ))
  return checks
}

func buildKotlin(
  _ root: URL, manifest: Manifest, release: Bool, verbose: Bool = false,
  progress: BuildProgressDisplay? = nil
) throws {
  let failures = kotlinChecks(in: root).filter { $0.severity == "error" }
  guard failures.isEmpty else {
    throw QbloomError.message(failures.compactMap(\.remediation).joined(separator: "; "))
  }
  try buildProject(
    root, release: release, verbose: verbose,
    environment: javaEnvironment(), progress: progress)
}

func kotlinLibrary(_ root: URL, release: Bool) -> URL {
  #if os(macOS)
    let extensionName = "dylib"
  #elseif os(Windows)
    let extensionName = "dll"
  #else
    let extensionName = "so"
  #endif
  #if os(Windows)
    let filename = "qbloom_kotlin_qt.\(extensionName)"
  #else
    let filename = "libqbloom_kotlin_qt.\(extensionName)"
  #endif
  return cmakeArtifact(in: root, filename: filename, release: release)
}

func kotlinInvocation(
  _ root: URL, manifest: Manifest, release: Bool, arguments: [String],
  environment: [String: String] = [:]
) throws {
  let library = kotlinLibrary(root, release: release)
  guard FileManager.default.fileExists(atPath: library.path) else {
    throw QbloomError.message("JNI library is missing: \(library.path); run qbloom build")
  }
  let args = [
    "--offline", "--no-daemon", "qtRun", "-PqbloomNativeLibrary=\(library.path)",
    "-PqbloomAppArgs=\(arguments.joined(separator: "\u{1f}"))",
  ]
  try runGradle(args, in: codeRoot(root, manifest), environment: environment)
}

func runKotlin(_ root: URL, manifest: Manifest, release: Bool, arguments: [String]) throws {
  try buildKotlin(root, manifest: manifest, release: release)
  try kotlinInvocation(root, manifest: manifest, release: release, arguments: arguments)
}

func testKotlin(_ root: URL, manifest: Manifest, release: Bool, headless: Bool) throws {
  try buildKotlin(root, manifest: manifest, release: release)
  try runGradle(["--offline", "--no-daemon", "logicTest"], in: codeRoot(root, manifest))
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
  try kotlinInvocation(
    root, manifest: manifest, release: release, arguments: ["--smoke-test"], environment: env)
}
