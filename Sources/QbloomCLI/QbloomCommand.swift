import ArgumentParser
import Foundation

enum QbloomError: Error, LocalizedError {
  case message(String)
  var errorDescription: String? {
    if case .message(let value) = self { return CLIStyle.decorateError(L10n.message(value)) }
    return nil
  }
}

enum Backend: String, CaseIterable {
  case cpp, rust, go, swift, python, java, kotlin
}

struct Manifest {
  let name: String
  let backend: Backend
  let bridge: String
  let buildDir: String
  let layout: String

  var contents: String {
    """
    schema_version = 1
    name = \(tomlQuote(name))
    backend = \(tomlQuote(backend.rawValue))
    bridge = \(tomlQuote(bridge))
    qt_major = 6
    build_dir = \(tomlQuote(buildDir))
    layout = \(tomlQuote(layout))

    """
  }

  static func read(at directory: URL) throws -> Manifest {
    let url = directory.appendingPathComponent("qbloom.toml")
    let input = try String(contentsOf: url, encoding: .utf8)
    var fields: [String: String] = [:]
    let allowed: Set<String> = [
      "schema_version", "name", "backend", "bridge", "qt_major", "build_dir", "layout",
    ]
    for rawLine in input.split(separator: "\n", omittingEmptySubsequences: false) {
      let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
      if line.isEmpty || line.hasPrefix("#") { continue }
      let parts = line.split(separator: "=", maxSplits: 1)
      guard parts.count == 2 else {
        throw QbloomError.message("Unsupported qbloom.toml syntax: \(line)")
      }
      let key = parts[0].trimmingCharacters(in: .whitespaces)
      let value = parts[1].trimmingCharacters(in: .whitespaces)
      guard allowed.contains(key), fields[key] == nil else {
        throw QbloomError.message("Unknown or duplicate qbloom.toml key: \(key)")
      }
      if value.hasPrefix("\"") {
        guard
          let decoded = try? JSONSerialization.jsonObject(with: Data("[\(value)]".utf8))
            as? [String],
          decoded.count == 1
        else {
          throw QbloomError.message("Invalid string in qbloom.toml: \(key)")
        }
        fields[key] = decoded[0]
      } else if (key == "schema_version" && value == "1") || (key == "qt_major" && value == "6") {
        fields[key] = value
      } else {
        throw QbloomError.message("Unsupported qbloom.toml value for \(key)")
      }
    }
    guard fields.count >= allowed.count - 1, fields["schema_version"] == "1",
      fields["qt_major"] == "6",
      let name = fields["name"], let backendName = fields["backend"],
      let backend = Backend(rawValue: backendName),
      let bridge = fields["bridge"], let buildDir = fields["build_dir"],
      buildDir == ".qbloom/build",
      ["init", "added"].contains(fields["layout"] ?? "init")
    else {
      throw QbloomError.message(
        "Invalid or unsupported qbloom.toml schema; this qbloom supports schema_version = 1")
    }
    return Manifest(
      name: name, backend: backend, bridge: bridge, buildDir: buildDir,
      layout: fields["layout"] ?? "init")
  }
}

func tomlQuote(_ value: String) -> String {
  let data = try! JSONSerialization.data(withJSONObject: [value], options: [.fragmentsAllowed])
  let text = String(decoding: data, as: UTF8.self)
  return String(text.dropFirst().dropLast()).replacingOccurrences(of: "\\/", with: "/")
}

struct Runner {
  @discardableResult
  static func run(
    _ executable: String, _ arguments: [String], in directory: URL,
    environment: [String: String]? = nil, onStart: (() -> Void)? = nil,
    onOutput: ((String) -> Void)? = nil
  ) throws -> Int32 {
    let task = Process()
    task.executableURL = URL(fileURLWithPath: executable)
    task.arguments = arguments
    task.currentDirectoryURL = directory
    if let environment {
      task.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
    }
    print("$ \(([executable] + arguments).map(shellQuote).joined(separator: " "))")
    fflush(nil)
    onStart?()
    let pipe: Pipe? = onOutput == nil ? nil : Pipe()
    if let pipe {
      task.standardOutput = pipe
      task.standardError = pipe
    }
    try task.run()
    if let pipe {
      var pending = Data()
      while true {
        let chunk = pipe.fileHandleForReading.readData(ofLength: 4096)
        if chunk.isEmpty { break }
        pending.append(chunk)
        while let end = pending.firstIndex(of: 10) {
          let line = String(decoding: pending[..<end], as: UTF8.self)
          if let onOutput { onOutput(line) } else { print(line) }
          fflush(nil)
          pending.removeSubrange(...end)
        }
      }
      if !pending.isEmpty {
        let line = String(decoding: pending, as: UTF8.self)
        if let onOutput { onOutput(line) } else { print(line) }
        fflush(nil)
      }
    }
    task.waitUntilExit()
    return task.terminationStatus
  }
}

func shellQuote(_ value: String) -> String {
  if value.allSatisfy({ $0.isASCII && ($0.isLetter || $0.isNumber || "_./-".contains($0)) }) {
    return value
  }
  return "'" + value.replacingOccurrences(of: "'", with: "'\\''") + "'"
}

private let searchPathSeparator: Character = {
  #if os(Windows)
    return ";"
  #else
    return ":"
  #endif
}()

func executable(
  _ name: String, environment: [String: String] = ProcessInfo.processInfo.environment
) -> String? {
  #if os(Windows)
    let path = environment.first { $0.key.caseInsensitiveCompare("PATH") == .orderedSame }?.value
    let lower = name.lowercased()
    let filename = lower.hasSuffix(".exe") || lower.hasSuffix(".bat") ? name : name + ".exe"
  #else
    let path = environment["PATH"]
    let filename = name
  #endif
  for component in (path ?? "").split(separator: searchPathSeparator) {
    let file = URL(fileURLWithPath: String(component)).appendingPathComponent(filename).path
    #if os(Windows)
      if lower.hasSuffix(".bat") {
        var directory: ObjCBool = false
        if FileManager.default.fileExists(atPath: file, isDirectory: &directory),
          !directory.boolValue
        {
          return file
        }
        continue
      }
    #endif
    if FileManager.default.isExecutableFile(atPath: file) { return file }
  }
  return nil
}

func qtQmake() -> String? {
  #if os(Windows)
    return executable("qmake6") ?? executable("qmake")
  #else
    return executable("qmake6")
  #endif
}

let cppCompilerProbe: (String, [String]) = {
  #if os(Windows)
    return ("cl", ["/?"])
  #else
    return ("c++", ["--version"])
  #endif
}()

func outputOf(
  _ path: String, _ arguments: [String], includeStandardError: Bool = false,
  environment: [String: String] = [:]
) -> String? {
  let task = Process()
  let pipe = Pipe()
  task.executableURL = URL(fileURLWithPath: path)
  task.arguments = arguments
  if !environment.isEmpty {
    task.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
  }
  task.standardOutput = pipe
  task.standardError = includeStandardError ? pipe : Pipe()
  do {
    try task.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    task.waitUntilExit()
    guard task.terminationStatus == 0 else { return nil }
    return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
  } catch { return nil }
}

func architecture() -> String {
  #if arch(x86_64)
    return "x86_64"
  #elseif arch(arm64)
    return "arm64"
  #else
    return "unknown"
  #endif
}

func qtModuleCheck(_ module: String) -> Check {
  var roots: [String] = []
  if let qmake = qtQmake(),
    let libraries = outputOf(qmake, ["-query", "QT_INSTALL_LIBS"])
  {
    roots.append(libraries + "/cmake")
  }
  if let qmake = qtQmake(),
    let prefix = outputOf(qmake, ["-query", "QT_INSTALL_PREFIX"])
  {
    roots.append(prefix + "/lib/cmake")
    roots.append(prefix + "/lib64/cmake")
  }
  if let prefixes = ProcessInfo.processInfo.environment["CMAKE_PREFIX_PATH"] {
    roots += prefixes.split(separator: searchPathSeparator).map { String($0) + "/lib/cmake" }
  }
  if let qtDir = ProcessInfo.processInfo.environment["Qt6_DIR"] {
    roots.append(URL(fileURLWithPath: qtDir).deletingLastPathComponent().path)
  }
  let found = roots.contains { root in
    FileManager.default.fileExists(atPath: root + "/\(module)/\(module)Config.cmake")
  }
  return Check(
    name: module, status: found ? "found" : "missing", version: nil,
    severity: found ? "info" : "error",
    remediation: found
      ? nil
      : Toolchain.qtQuick.installationAdvice(
        "Install Qt 6 \(module) development files or set CMAKE_PREFIX_PATH"))
}

struct Scaffolder {
  static func create(name: String, backend: Backend, bridge: String, parent: URL, reset: Bool)
    throws -> URL
  {
    guard !name.isEmpty, name != ".", name != "..", !name.contains("/"), !name.contains("\\"),
      !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
    else {
      throw QbloomError.message("Project name must be one safe directory name")
    }
    guard
      backend == .cpp || backend == .python || backend == .go || backend == .rust
        || backend == .java || backend == .swift || backend == .kotlin
    else {
      throw QbloomError.message(
        "\(backend.rawValue) backend is unverified and has no generated template yet")
    }
    let allowedBridges =
      backend == .go || backend == .java || backend == .swift || backend == .kotlin
      ? ["auto", "ffi"] : ["auto", "native"]
    guard allowedBridges.contains(bridge) else {
      throw QbloomError.message(
        "\(backend.rawValue) supports --bridge \(allowedBridges.joined(separator: " or "))")
    }
    let fm = FileManager.default
    let base = parent.standardizedFileURL
    var isDirectory: ObjCBool = false
    guard fm.fileExists(atPath: base.path, isDirectory: &isDirectory), isDirectory.boolValue else {
      throw QbloomError.message("Parent directory does not exist: \(base.path)")
    }
    let destination = base.appendingPathComponent(name)
    if fm.fileExists(atPath: destination.path) {
      if !reset {
        throw QbloomError.message(
          "Destination exists: \(destination.path). Use qbloom override to reset a generated project."
        )
      }
      guard !isSymlink(destination), isDirectoryAt(destination) else {
        throw QbloomError.message("Override requires a real project directory, not a symlink")
      }
      let marker = destination.appendingPathComponent("qbloom.toml")
      guard !isSymlink(marker), fm.fileExists(atPath: marker.path) else {
        throw QbloomError.message("Override requires a qbloom init project")
      }
      let manifest = try Manifest.read(at: destination)
      guard manifest.layout == "init" else {
        throw QbloomError.message("Override cannot replace a project created with qbloom add")
      }
    } else if reset {
      throw QbloomError.message("No generated project exists at \(destination.path)")
    }
    let stage = base.appendingPathComponent(".qbloom-stage-\(UUID().uuidString)")
    try fm.createDirectory(at: stage, withIntermediateDirectories: false)
    defer { try? fm.removeItem(at: stage) }
    let templates = Bundle.module.url(forResource: "Templates", withExtension: nil)!
    let source = templates.appendingPathComponent(backend.rawValue)
    let targetName = identifier(name)
    let variables = [
      "{{NAME}}": name, "{{TARGET}}": targetName,
      "{{QML_NAME}}": qmlString(name), "{{EXECUTABLE}}": "qbloom_app",
      "{{MODULE_URI}}": "Qbloom.App",
    ]
    try copyTemplates(
      from: templates.appendingPathComponent("common"), to: stage, variables: variables)
    try copyTemplates(from: source, to: stage, variables: variables)
    try Manifest(
      name: name, backend: backend, bridge: bridge, buildDir: ".qbloom/build", layout: "init"
    )
    .contents.write(
      to: stage.appendingPathComponent("qbloom.toml"), atomically: true, encoding: .utf8)
    if reset {
      let backup = base.appendingPathComponent(".qbloom-override-backup-\(UUID().uuidString)")
      try fm.moveItem(at: destination, to: backup)
      do {
        try fm.moveItem(at: stage, to: destination)
      } catch {
        do { try fm.moveItem(at: backup, to: destination) } catch {
          throw QbloomError.message("Override failed; original project is at \(backup.path)")
        }
        throw error
      }
      print("\(L10n.text("Backup saved at", "백업 저장 위치")): \(backup.path)")
    } else {
      try fm.moveItem(at: stage, to: destination)
    }
    return destination
  }

  static func copyTemplates(from source: URL, to destination: URL, variables: [String: String])
    throws
  {
    let fm = FileManager.default
    let root = source.resolvingSymlinksInPath()
    let prefix = root.path + "/"
    guard
      let files = fm.enumerator(
        at: root, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey])
    else {
      throw QbloomError.message("Bundled templates are missing")
    }
    for case let url as URL in files {
      if isSymlink(url) { throw QbloomError.message("Template symlink rejected: \(url.path)") }
      let path = url.resolvingSymlinksInPath().path
      guard path.hasPrefix(prefix) else {
        throw QbloomError.message("Template is outside its resource directory: \(path)")
      }
      let relative = String(path.dropFirst(prefix.count))
      let target = destination.appendingPathComponent(relative)
      if (try url.resourceValues(forKeys: [.isDirectoryKey])).isDirectory == true {
        try fm.createDirectory(at: target, withIntermediateDirectories: true)
      } else {
        var content = try String(contentsOf: url, encoding: .utf8)
        for (key, value) in variables {
          content = content.replacingOccurrences(of: key, with: value)
        }
        if content.contains("{{") {
          throw QbloomError.message("Unresolved template variable in \(relative)")
        }
        try fm.createDirectory(
          at: target.deletingLastPathComponent(), withIntermediateDirectories: true)
        try content.write(to: target, atomically: true, encoding: .utf8)
      }
    }
  }
}

func isSymlink(_ url: URL) -> Bool {
  (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true
}

func isDirectoryAt(_ url: URL) -> Bool {
  (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
}

func identifier(_ value: String) -> String {
  let mapped = value.unicodeScalars.map { scalar -> Character in
    if scalar.isASCII && (CharacterSet.alphanumerics.contains(scalar) || scalar == "_") {
      return Character(scalar)
    }
    return "_"
  }
  var result = String(mapped)
  if result.isEmpty || result.first!.isNumber { result = "app_" + result }
  return result
}

func qmlString(_ value: String) -> String {
  let encoded = tomlQuote(value)
  return encoded
}

@main
struct Qbloom: ParsableCommand {
  private static let version: String = {
    let platform: String
    #if os(macOS)
      platform = "apple-macos"
    #elseif os(FreeBSD)
      platform = "unknown-freebsd"
    #elseif os(Linux)
      platform = "unknown-linux"
    #elseif os(Windows)
      platform = "unknown-windows-msvc"
    #else
      platform = "unknown-unknown"
    #endif
    let osVersion = ProcessInfo.processInfo.operatingSystemVersionString
    return "0.2.1 (\(architecture())-\(platform), \(osVersion))"
  }()

  static let configuration = CommandConfiguration(
    commandName: "qbloom",
    abstract: L10n.text("Create and run Qt Quick projects", "Qt Quick 프로젝트 생성 및 실행"),
    version: version,
    subcommands: [
      Init.self, Add.self, Override.self, Doctor.self, Build.self, Run.self, Test.self, Clean.self,
    ]
  )
}

struct CreateOptions: ParsableArguments {
  @Argument(help: ArgumentHelp(L10n.text("Project directory name", "프로젝트 디렉터리 이름")))
  var name: String
  @Flag var cpp = false
  @Flag var rust = false
  @Flag var go = false
  @Flag var swift = false
  @Flag var python = false
  @Flag var java = false
  @Flag var kotlin = false
  @Option(name: .long, help: ArgumentHelp(L10n.text("Parent directory", "상위 디렉터리")))
  var dir: String = "."
  @Option(
    name: .long,
    help: ArgumentHelp(
      L10n.text(
        "auto, native, or ffi (availability depends on backend)",
        "auto, native 또는 ffi (백엔드별 지원 범위가 다름)")))
  var bridge: String = "auto"
  @Option(name: .long) var qtDir: String?
  @Flag(name: .long) var noGit = false
  @Flag var force = false

  func selectedBackend() throws -> Backend {
    let selected: [Backend] = [
      cpp ? .cpp : nil, rust ? .rust : nil, go ? .go : nil,
      swift ? .swift : nil, python ? .python : nil, java ? .java : nil,
      kotlin ? .kotlin : nil,
    ].compactMap { $0 }
    guard selected.count < 2 else {
      throw QbloomError.message("Backend flags are mutually exclusive")
    }
    return selected.first ?? .cpp
  }

  func execute(reset: Bool) throws {
    let backend = try selectedBackend()
    guard qtDir == nil else {
      throw QbloomError.message(
        "--qt-dir is not implemented yet; set CMAKE_PREFIX_PATH when building")
    }
    guard !force else {
      throw QbloomError.message("--force is unavailable; use qbloom override for a confirmed reset")
    }
    let parent = URL(fileURLWithPath: dir, isDirectory: true)
    let destination = parent.appendingPathComponent(name)
    if reset {
      guard isDirectoryAt(destination), !isSymlink(destination) else {
        throw QbloomError.message("Override requires an existing project directory")
      }
      guard !isSymlink(destination.appendingPathComponent("qbloom.toml")),
        (try? Manifest.read(at: destination))?.layout == "init"
      else { throw QbloomError.message("Override requires a qbloom init project") }
      print(
        L10n.text(
          "Reset the entire qbloom project at \(destination.path)? All existing contents will move to a backup beside the project.\n(Y/N)",
          "\(destination.path)의 qbloom 프로젝트 전체를 초기화할까요? 기존 내용 전체는 프로젝트 옆 백업으로 이동합니다.\n(Y/N)"))
      guard readLine()?.lowercased() == "y" else { throw QbloomError.message("Reset cancelled") }
    }
    let created = try Scaffolder.create(
      name: name, backend: backend, bridge: bridge, parent: parent, reset: reset)
    print(
      "\(L10n.text("Created", "생성됨")) \(created.path)\ncd \(shellQuote(created.path))\nqbloom doctor\nqbloom build\nqbloom run\nqbloom test"
    )
  }
}

struct Init: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "init", aliases: ["in"])
  @OptionGroup var options: CreateOptions
  func run() throws { try options.execute(reset: false) }
}

struct Override: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "override", aliases: ["ovr"])
  @OptionGroup var options: CreateOptions
  func run() throws { try options.execute(reset: true) }
}

struct Add: ParsableCommand {
  static let configuration = CommandConfiguration(commandName: "add")
  @Argument(help: ArgumentHelp(L10n.text("Existing project directory name", "기존 프로젝트 디렉터리 이름")))
  var name: String
  @Flag var cpp = false
  @Flag var rust = false
  @Flag var go = false
  @Flag var python = false
  @Flag var java = false
  @Flag var swift = false
  @Flag var kotlin = false
  @Option(name: .long, help: ArgumentHelp(L10n.text("Parent directory", "상위 디렉터리")))
  var dir: String = "."
  @Option(
    name: .long,
    help: ArgumentHelp(
      L10n.text(
        "auto, native, or ffi (availability depends on backend)",
        "auto, native 또는 ffi (백엔드별 지원 범위가 다름)")))
  var bridge: String = "auto"
  func run() throws {
    let selected: [Backend] = [
      cpp ? .cpp : nil, rust ? .rust : nil, go ? .go : nil,
      python ? .python : nil, java ? .java : nil, swift ? .swift : nil,
      kotlin ? .kotlin : nil,
    ].compactMap { $0 }
    guard selected.count < 2 else {
      throw QbloomError.message("Backend flags are mutually exclusive")
    }
    let backend = selected.first ?? .cpp
    let parent = URL(fileURLWithPath: dir, isDirectory: true)
    let added = try AddScaffolder.add(
      name: name, backend: backend,
      bridge: bridge, parent: parent)
    print(
      "\(L10n.text("Added Qt Quick to", "Qt Quick 추가됨:")) \(added.path)\ncd \(shellQuote(added.path))\nqbloom doctor\nqbloom build\nqbloom run\nqbloom test"
    )
  }
}

enum Toolchain {
  case go, rust, swift, python, cmake, cpp, qt, qtQuick, gradle, jdk

  static func missingToolAdvice(_ name: String) -> String {
    #if os(Windows)
      switch name {
      case "cl": return "Install the Visual Studio C++ tools and open an x64 Developer PowerShell"
      case "qmake6": return "Add the MSVC Qt 6 kit's bin directory to the current shell's Path"
      case "gradle": return "Add the extracted Gradle distribution's bin directory to Path"
      default: break
      }
    #endif
    let tool: Toolchain?
    switch name {
    case "cmake": tool = .cmake
    case "c++", "cl": tool = .cpp
    case "qmake6": tool = .qt
    case "gradle": tool = .gradle
    case "java", "javac": tool = .jdk
    default: tool = nil
    }
    let message = "Install \(name) and add it to PATH"
    return tool?.installationAdvice(message) ?? message
  }

  func installationAdvice(_ message: String) -> String {
    let command: String?
    #if os(macOS)
      switch self {
      case .go: command = "brew install go"
      case .rust: command = "brew install rust / rustup default stable"
      case .swift: command = "xcode-select --install"
      case .python: command = "brew install python@3.12"
      case .cmake: command = "brew install cmake"
      case .cpp: command = "xcode-select --install"
      case .qt, .qtQuick: command = "brew install qt"
      case .gradle: command = "brew install gradle"
      case .jdk: command = "brew install openjdk"
      }
    #elseif os(FreeBSD)
      switch self {
      case .go: command = "pkg install go"
      case .rust: command = "pkg install rust"
      case .swift: command = "pkg install swift6"
      case .python: command = "pkg install python312"
      case .cmake: command = "pkg install cmake"
      case .cpp: command = "pkg install llvm"
      case .qt: command = "pkg install qt6-base"
      case .qtQuick: command = "pkg install qt6-declarative"
      case .gradle: command = "pkg install gradle"
      case .jdk: command = "pkg install openjdk25"
      }
    #else
      command = nil
    #endif
    guard let command else { return message }
    return "\(message) [\(command)]"
  }
}

struct Check: Encodable {
  let name: String
  let status: String
  let version: String?
  let severity: String
  let remediation: String?
}

struct DoctorResult: Encodable {
  let schemaVersion = 1
  let platform: String
  let architecture: String
  let backend: String
  let bridge: String
  let bridgeImplementation: String
  let checks: [Check]
}

func bridgeImplementation(_ backend: Backend) -> String {
  switch backend {
  case .cpp: return "Qt QObject"
  case .python: return "PySide6 QObject"
  case .rust: return "CXX-Qt 0.10.0"
  case .go: return "Go c-shared + C++ QObject"
  case .java, .kotlin: return "JNI + C++ QObject (experimental)"
  case .swift: return "Swift C ABI + C++ QObject (experimental)"
  }
}

func platformEvidenceCheck(
  platform: String, architecture: String, qtVersion: String?
) -> Check? {
  if platform.contains("FreeBSD 15.1"), architecture == "x86_64", qtVersion == "6.11.2" {
    return nil
  }
  return Check(
    name: "platform evidence", status: "unverified",
    version: "\(platform) / \(architecture) / Qt \(qtVersion ?? "unknown")",
    severity: "warning",
    remediation:
      "Run qbloom test --headless on this host and check the recorded results in docs/compatibility.md"
  )
}

func doctorResult(_ manifest: Manifest, checks: [Check]) -> DoctorResult {
  let platform = ProcessInfo.processInfo.operatingSystemVersionString
  let qtVersion: String?
  if manifest.backend == .python {
    qtVersion = checks.first { $0.name == "PySide6" }?.version
  } else {
    qtVersion = qtQmake().flatMap { outputOf($0, ["-query", "QT_VERSION"]) }
  }
  var resultChecks = checks
  if let evidence = platformEvidenceCheck(
    platform: platform, architecture: architecture(), qtVersion: qtVersion)
  {
    resultChecks.append(evidence)
  }
  return DoctorResult(
    platform: platform, architecture: architecture(), backend: manifest.backend.rawValue,
    bridge: manifest.bridge, bridgeImplementation: bridgeImplementation(manifest.backend),
    checks: resultChecks)
}

func doctor(_ manifest: Manifest, in root: URL) -> DoctorResult {
  if manifest.backend == .python {
    return doctorResult(manifest, checks: pythonChecks(in: root))
  }
  if manifest.backend == .rust {
    return doctorResult(manifest, checks: rustChecks(in: root))
  }
  if manifest.backend == .java {
    return doctorResult(manifest, checks: javaChecks(in: root))
  }
  if manifest.backend == .kotlin {
    return doctorResult(manifest, checks: kotlinChecks(in: root))
  }
  if manifest.backend == .swift {
    return doctorResult(manifest, checks: swiftChecks(in: root))
  }
  let tools = [("cmake", ["--version"]), cppCompilerProbe, ("qmake6", ["-query", "QT_VERSION"])]
  var checks = tools.map { name, args -> Check in
    guard let path = name == "qmake6" ? qtQmake() : executable(name) else {
      return Check(
        name: name, status: "missing", version: nil, severity: "error",
        remediation: Toolchain.missingToolAdvice(name))
    }
    guard let output = outputOf(path, args, includeStandardError: name == "cl"),
      let version = output.split(whereSeparator: \.isNewline).first
    else {
      return Check(
        name: name, status: "broken", version: nil, severity: "error",
        remediation: "Repair \(name); it is on PATH but cannot run")
    }
    if name == "qmake6"
      && (version.split(separator: ".").count < 2 || Int(version.split(separator: ".")[0]) != 6
        || (Int(version.split(separator: ".")[1]) ?? 0) < 8)
    {
      return Check(
        name: name, status: "unsupported", version: String(version), severity: "error",
        remediation: Toolchain.qt.installationAdvice("Install Qt 6.8 or newer development tools"))
    }
    return Check(
      name: name, status: "found", version: String(version), severity: "info", remediation: nil)
  }
  checks.append(qtModuleCheck("Qt6Quick"))
  checks.append(qtModuleCheck("Qt6QuickControls2"))
  if manifest.backend == .go { checks += goChecks() }
  #if os(FreeBSD)
    if root.path.contains(" ") {
      let ninja = executable("ninja")
      checks.append(
        Check(
          name: "ninja", status: ninja == nil ? "missing" : "found",
          version: ninja.flatMap { outputOf($0, ["--version"]) },
          severity: ninja == nil ? "error" : "info",
          remediation: ninja == nil
            ? "Install Ninja for Qt CMake builds in paths with spaces on FreeBSD" : nil))
    }
  #endif
  return doctorResult(manifest, checks: checks)
}

struct Doctor: ParsableCommand {
  @Flag var json = false
  @Flag var strict = false
  func run() throws {
    let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    let result = doctor(try Manifest.read(at: root), in: root)
    if json {
      let encoder = JSONEncoder()
      encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
      print(String(decoding: try encoder.encode(result), as: UTF8.self))
    } else {
      print("\(L10n.text("Bridge", "브리지")): \(result.bridgeImplementation) (\(result.bridge))")
      for check in result.checks {
        print(
          "\(L10n.checkName(check.name)): \(L10n.status(check.status)) \(check.remediation.map { L10n.message($0) } ?? "")"
        )
      }
    }
    if strict && result.checks.contains(where: { $0.severity == "error" }) {
      throw QbloomError.message("Required tools are missing")
    }
  }
}

func project() throws -> (URL, Manifest) {
  let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  if isSymlink(root.appendingPathComponent(".qbloom"))
    || isSymlink(root.appendingPathComponent(".qbloom/build"))
  {
    throw QbloomError.message("Refusing a symlinked .qbloom build path")
  }
  return (root, try Manifest.read(at: root))
}

func buildProject(
  _ root: URL, release: Bool, verbose: Bool = false,
  environment: [String: String]? = nil, progress: BuildProgressDisplay? = nil
) throws {
  guard executable("cmake") != nil else {
    throw QbloomError.message("cmake is missing; run qbloom doctor")
  }
  let configuration = release ? "Release" : "Debug"
  let build = root.appendingPathComponent(".qbloom/build")
  #if os(FreeBSD)
    if root.path.contains(" ") && executable("ninja") == nil {
      throw QbloomError.message(
        "Ninja is required for Qt CMake builds in paths with spaces on FreeBSD")
    }
  #endif
  var configure = ["-S", root.path, "-B", build.path, "-DCMAKE_BUILD_TYPE=\(configuration)"]
  if !FileManager.default.fileExists(atPath: build.appendingPathComponent("CMakeCache.txt").path),
    executable("ninja") != nil
  {
    configure += ["-G", "Ninja"]
  }
  progress?.start("CMake config")
  guard try Runner.run(executable("cmake")!, configure, in: root, environment: environment) == 0
  else {
    throw QbloomError.message("CMake configure failed")
  }
  progress?.finish("CMake config")
  progress?.start("Native build")
  let status = try Runner.run(
    executable("cmake")!,
    ["--build", build.path, "--config", configuration] + (verbose ? ["--verbose"] : []),
    in: root, environment: environment,
    onStart: progress.map { display in { display.show() } },
    onOutput: progress.map { display in
      { line in display.output(line, verbose: verbose) }
    })
  guard status == 0 else {
    progress?.fail()
    throw QbloomError.message("Native CMake build failed")
  }
  progress?.finish("Native build")
}

func cmakeApplication(in root: URL, layout: String, release: Bool) -> URL {
  let name = layout == "added" ? "qbloom_quick_app" : "qbloom_app"
  #if os(Windows)
    return cmakeArtifact(in: root, filename: name + ".exe", release: release)
  #else
    return cmakeArtifact(in: root, filename: name, release: release)
  #endif
}

func cmakeArtifact(in root: URL, filename: String, release: Bool) -> URL {
  let build = root.appendingPathComponent(".qbloom/build")
  #if os(Windows)
    let configuration = release ? "Release" : "Debug"
    let configured = build.appendingPathComponent("\(configuration)/\(filename)")
    if FileManager.default.fileExists(atPath: configured.path) { return configured }
  #endif
  return build.appendingPathComponent(filename)
}

struct Build: ParsableCommand {
  @Flag var release = false
  @Flag var verbose = false
  func run() throws {
    let (root, manifest) = try project()
    let progress = BuildProgressDisplay()
    switch manifest.backend {
    case .cpp: try buildProject(root, release: release, verbose: verbose, progress: progress)
    case .python:
      progress.start("Python build")
      try buildPython(root, manifest)
      progress.finish("Python build")
    case .go:
      try buildGo(root, manifest: manifest, release: release, verbose: verbose, progress: progress)
    case .rust: try buildRust(root, manifest: manifest, release: release, progress: progress)
    case .java:
      try buildJava(
        root, manifest: manifest, release: release, verbose: verbose, progress: progress)
    case .swift: try buildSwift(root, release: release, verbose: verbose, progress: progress)
    case .kotlin:
      try buildKotlin(
        root, manifest: manifest, release: release, verbose: verbose, progress: progress)
    }
  }
}

struct Run: ParsableCommand {
  @Flag var release = false
  @Argument(parsing: .remaining) var applicationArgs: [String] = []
  func run() throws {
    let (root, manifest) = try project()
    switch manifest.backend {
    case .cpp:
      try buildProject(root, release: release)
      let app = cmakeApplication(in: root, layout: manifest.layout, release: release)
      let status = try Runner.run(app.path, applicationArgs, in: root)
      if status != 0 { throw ExitCode(status) }
    case .python: try runPython(root, manifest, arguments: applicationArgs)
    case .go: try runGo(root, manifest: manifest, release: release, arguments: applicationArgs)
    case .rust:
      try runRust(root, manifest: manifest, release: release, arguments: applicationArgs)
    case .java: try runJava(root, manifest: manifest, release: release, arguments: applicationArgs)
    case .kotlin:
      try runKotlin(root, manifest: manifest, release: release, arguments: applicationArgs)
    case .swift:
      try runSwift(root, manifest: manifest, release: release, arguments: applicationArgs)
    }
  }
}

struct Test: ParsableCommand {
  @Flag var release = false
  @Flag var headless = false
  func run() throws {
    let (root, manifest) = try project()
    if manifest.backend == .python {
      try testPython(root, manifest, headless: headless)
      return
    }
    if manifest.backend == .go {
      try testGo(root, manifest: manifest, release: release, headless: headless)
      return
    }
    if manifest.backend == .rust {
      try testRust(root, manifest: manifest, release: release, headless: headless)
      return
    }
    if manifest.backend == .java {
      try testJava(root, manifest: manifest, release: release, headless: headless)
      return
    }
    if manifest.backend == .kotlin {
      try testKotlin(root, manifest: manifest, release: release, headless: headless)
      return
    }
    if manifest.backend == .swift {
      try testSwift(root, manifest: manifest, release: release, headless: headless)
      return
    }
    guard manifest.backend == .cpp else { throw QbloomError.message("Backend is unverified") }
    try buildProject(root, release: release)
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
    let env = headless ? ["QT_QPA_PLATFORM": "offscreen", "QT_QUICK_BACKEND": "software"] : [:]
    let status = try Runner.run(app.path, ["--smoke-test"], in: root, environment: env)
    if status != 0 { throw ExitCode(status) }
  }
}

struct Clean: ParsableCommand {
  func run() throws {
    let (root, _) = try project()
    let build = root.appendingPathComponent(".qbloom/build")
    if FileManager.default.fileExists(atPath: build.path) {
      try FileManager.default.removeItem(at: build)
    }
  }
}
