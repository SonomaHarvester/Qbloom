import ArgumentParser
import Foundation

func javaHome() -> String? {
  if let home = ProcessInfo.processInfo.environment["JAVA_HOME"] { return home }
  if let java = executable("java"),
    let settings = outputOf(
      java, ["-XshowSettings:properties", "-version"], includeStandardError: true),
    let line = settings.split(whereSeparator: \.isNewline).first(where: {
      $0.trimmingCharacters(in: .whitespaces).hasPrefix("java.home =")
    })
  {
    return String(line.split(separator: "=", maxSplits: 1)[1]).trimmingCharacters(in: .whitespaces)
  }
  #if os(macOS)
    if let brew = executable("brew"), let prefix = outputOf(brew, ["--prefix", "openjdk"]) {
      let home = prefix + "/libexec/openjdk.jdk/Contents/Home"
      if FileManager.default.isExecutableFile(atPath: home + "/bin/javac") { return home }
    }
  #endif
  return nil
}

func javaEnvironment(_ home: String? = javaHome()) -> [String: String] {
  home.map { ["JAVA_HOME": $0] } ?? [:]
}

private func jdkTool(_ name: String, home: String?) -> String? {
  guard let home else { return executable(name) }
  #if os(Windows)
    return home + "/bin/" + name + ".exe"
  #else
    return home + "/bin/" + name
  #endif
}

private func gradleCommand(home: String?) -> (tool: String, prefix: [String])? {
  #if os(Windows)
    // Use Gradle's launcher JAR so project arguments go directly to Java.
    guard let batch = executable("gradle.bat"), let java = jdkTool("java", home: home) else {
      return nil
    }
    let lib = URL(fileURLWithPath: batch).deletingLastPathComponent().deletingLastPathComponent()
      .appendingPathComponent("lib")
    let launchers = (try? FileManager.default.contentsOfDirectory(atPath: lib.path))?.filter {
      $0.hasPrefix("gradle-gradle-cli-main-") && $0.hasSuffix(".jar")
    }
    guard let launchers, launchers.count == 1 else { return nil }
    return (
      java, ["-Dorg.gradle.appname=gradle", "-jar", lib.appendingPathComponent(launchers[0]).path]
    )
  #else
    return executable("gradle").map { ($0, []) }
  #endif
}

func runGradle(
  _ arguments: [String], in directory: URL, environment: [String: String] = [:]
) throws {
  let home = javaHome()
  guard let gradle = gradleCommand(home: home) else {
    throw QbloomError.message(Toolchain.missingToolAdvice("gradle"))
  }
  let status = try Runner.run(
    gradle.tool, gradle.prefix + arguments, in: directory,
    environment: javaEnvironment(home).merging(environment) { _, new in new })
  if status != 0 { throw ExitCode(status) }
}

func javaChecks(in root: URL) -> [Check] {
  var checks: [Check] = []
  let home = javaHome()
  var versions: [String: String] = [:]
  for (name, args) in [
    ("java", ["-version"]), ("javac", ["-version"]),
    ("gradle", ["--version"]), ("cmake", ["--version"]), cppCompilerProbe,
  ] {
    let gradle = name == "gradle" ? gradleCommand(home: home) : nil
    let path: String?
    switch name {
    case "gradle": path = gradle?.tool
    case "java", "javac": path = jdkTool(name, home: home)
    default: path = executable(name)
    }
    guard let path, FileManager.default.isExecutableFile(atPath: path) else {
      checks.append(
        Check(
          name: name, status: "missing", version: nil, severity: "error",
          remediation: Toolchain.missingToolAdvice(name)))
      continue
    }
    let version = outputOf(
      path, (gradle?.prefix ?? []) + args, includeStandardError: name == "java" || name == "cl",
      environment: name == "gradle" ? javaEnvironment(home) : [:])
    versions[name] = version
    let firstVersionLine = version?.split(whereSeparator: \.isNewline).first {
      name != "gradle" || $0.hasPrefix("Gradle ")
    }
    checks.append(
      Check(
        name: name, status: version == nil ? "broken" : "found",
        version: firstVersionLine.map(String.init),
        severity: version == nil ? "error" : "info",
        remediation: version == nil ? "Repair \(name); it cannot run" : nil))
  }
  let javacVersion = versions["javac"] ?? ""
  let javacMajor =
    Int(javacVersion.split(separator: " ").last?.split(separator: ".").first ?? "") ?? 0
  if javacMajor < 21 {
    checks.append(
      Check(
        name: "JDK version", status: "unsupported", version: javacVersion,
        severity: "error", remediation: Toolchain.jdk.installationAdvice("Install JDK 21 or newer"))
    )
  }
  let gradleVersion =
    versions["gradle"]?
    .split(whereSeparator: \.isNewline).first { $0.hasPrefix("Gradle ") }?
    .split(separator: " ").last.map(String.init) ?? ""
  let components = gradleVersion.split(separator: ".").compactMap { Int($0) }
  let gradleGood =
    components.count >= 2
    && (components[0] > 8
      || (components[0] == 8
        && (components[1] > 14
          || (components[1] == 14 && (components.count < 3 || components[2] >= 2)))))
  if !gradleGood {
    checks.append(
      Check(
        name: "Gradle version", status: "unsupported", version: gradleVersion,
        severity: "error",
        remediation: Toolchain.gradle.installationAdvice("Install Gradle 8.14.2 or newer")))
  }
  checks.append(qtModuleCheck("Qt6Quick"))
  checks.append(qtModuleCheck("Qt6QuickControls2"))
  if let qmake = qtQmake() {
    let qtVersion = outputOf(qmake, ["-query", "QT_VERSION"])
    let parts = qtVersion?.split(separator: ".").compactMap { Int($0) } ?? []
    let good = parts.count >= 2 && parts[0] == 6 && parts[1] >= 8
    checks.append(
      Check(
        name: "Qt version", status: good ? "found" : "unsupported", version: qtVersion,
        severity: good ? "info" : "error",
        remediation: good
          ? nil : Toolchain.qt.installationAdvice("Install Qt 6.8 or newer development tools")))
  } else {
    checks.append(
      Check(
        name: "Qt version", status: "unknown", version: nil,
        severity: "warning",
        remediation: "qmake6 is unavailable; CMake will verify the Qt version during build"))
  }
  let headers = home.map { FileManager.default.fileExists(atPath: $0 + "/include/jni.h") } ?? false
  checks.append(
    Check(
      name: "JNI headers", status: headers ? "found" : "missing", version: home,
      severity: headers ? "info" : "error",
      remediation: headers
        ? nil : "Set JAVA_HOME to a JDK 21+ installation containing include/jni.h"))
  return checks
}

func buildJava(
  _ root: URL, manifest: Manifest, release: Bool, verbose: Bool = false,
  progress: BuildProgressDisplay? = nil
) throws {
  let failures = javaChecks(in: root).filter { $0.severity == "error" }
  guard failures.isEmpty else {
    throw QbloomError.message(failures.compactMap(\.remediation).joined(separator: "; "))
  }
  try buildProject(
    root, release: release, verbose: verbose,
    environment: javaEnvironment(), progress: progress)
}

func javaLibrary(_ root: URL, release: Bool) -> URL {
  #if os(macOS)
    let extensionName = "dylib"
  #elseif os(Windows)
    let extensionName = "dll"
  #else
    let extensionName = "so"
  #endif
  #if os(Windows)
    let filename = "qbloom_java_qt.\(extensionName)"
  #else
    let filename = "libqbloom_java_qt.\(extensionName)"
  #endif
  return cmakeArtifact(in: root, filename: filename, release: release)
}

func javaInvocation(
  _ root: URL, manifest: Manifest, release: Bool, arguments: [String],
  environment: [String: String] = [:]
) throws {
  let library = javaLibrary(root, release: release)
  guard FileManager.default.fileExists(atPath: library.path) else {
    throw QbloomError.message("JNI library is missing: \(library.path); run qbloom build")
  }
  let args = [
    "--offline", "--no-daemon", "qtRun", "-PqbloomNativeLibrary=\(library.path)",
    "-PqbloomAppArgs=\(arguments.joined(separator: "\u{1f}"))",
  ]
  try runGradle(args, in: codeRoot(root, manifest), environment: environment)
}

func runJava(_ root: URL, manifest: Manifest, release: Bool, arguments: [String]) throws {
  try buildJava(root, manifest: manifest, release: release)
  try javaInvocation(root, manifest: manifest, release: release, arguments: arguments)
}

func testJava(_ root: URL, manifest: Manifest, release: Bool, headless: Bool) throws {
  try buildJava(root, manifest: manifest, release: release)
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
  try javaInvocation(
    root, manifest: manifest, release: release, arguments: ["--smoke-test"], environment: env)
}
