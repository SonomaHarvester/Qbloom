import XCTest

@testable import QbloomCLI

final class QbloomTests: XCTestCase {
  func temporaryRoot() throws -> URL {
    let root = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    return root
  }

  func testIdentifier() {
    XCTAssertEqual(identifier("123 hello"), "app_123_hello")
  }

  func testKoreanLocalePrecedenceAndFallback() {
    XCTAssertTrue(L10n.isKorean(environment: ["LANG": "Ko_KR.UTF-8"]))
    XCTAssertTrue(L10n.isKorean(environment: ["LANG": "C", "LC_MESSAGES": "ko_KR.utf8"]))
    XCTAssertFalse(L10n.isKorean(environment: ["LANG": "ko_KR.UTF-8", "LC_ALL": "C"]))
    XCTAssertFalse(L10n.isKorean(environment: ["LANG": "en_US.UTF-8"]))
    XCTAssertFalse(L10n.isKorean(environment: [:]))
  }

  func testLocalizedCliLabelsAndDiagnostics() {
    XCTAssertEqual(L10n.message("CMake config", korean: true), "CMake 설정")
    XCTAssertEqual(L10n.message("Native build", korean: false), "Native build")
    XCTAssertEqual(L10n.message("Build", korean: true), "빌드")
    XCTAssertEqual(L10n.status("missing", korean: true), "없음")
    XCTAssertEqual(L10n.status("missing", korean: false), "missing")
    XCTAssertEqual(L10n.checkName("JNI headers", korean: true), "JNI 헤더")
    XCTAssertEqual(
      L10n.message("java supports --bridge auto or ffi", korean: true),
      "java 백엔드는 --bridge auto 또는 ffi를 지원합니다")
    XCTAssertEqual(
      L10n.message(
        "Install Qt 6 Qt6Quick development files or set CMAKE_PREFIX_PATH", korean: true),
      "Qt 6 Qt6Quick 개발 파일을 설치하거나 CMAKE_PREFIX_PATH를 설정하세요")
    XCTAssertEqual(
      L10n.message("Install JDK 21 or newer; Install Gradle 8.14.2 or newer", korean: true),
      "JDK 21 이상을 설치하세요; Gradle 8.14.2 이상을 설치하세요")
  }

  func testBuildProgressParsesOnlyNativeFractions() {
    XCTAssertEqual(BuildProgress.fraction(in: "[3/12] Building CXX"), 25)
    XCTAssertEqual(BuildProgress.fraction(in: "[ 42%] Building CXX"), 42)
    XCTAssertNil(BuildProgress.fraction(in: "> Task :compileKotlin"))
    XCTAssertNil(BuildProgress.fraction(in: "[0/0] no work"))
    XCTAssertTrue(BuildProgress.bar(50, nerdFont: true).contains("\u{EE04}"))
    XCTAssertEqual(BuildProgress.bar(50, nerdFont: false), "[#####-----]")
  }

  func testProgressGlyphSelection() {
    XCTAssertTrue(
      BuildProgress.useNerdFont(
        environment: ["TERM": "xterm-256color", "LANG": "ko_KR.UTF-8"], isTerminal: true))
    XCTAssertTrue(BuildProgress.useNerdFont(environment: ["TERM": "xterm"], isTerminal: true))
    XCTAssertFalse(BuildProgress.useNerdFont(environment: ["LANG": "C"], isTerminal: true))
    XCTAssertFalse(
      BuildProgress.useNerdFont(environment: ["LANG": "en_US.ISO-8859-1"], isTerminal: true))
    XCTAssertFalse(
      BuildProgress.useNerdFont(
        environment: ["TERM": "dumb", "LANG": "en_US.UTF-8"], isTerminal: true))
    XCTAssertFalse(
      BuildProgress.useNerdFont(environment: ["LANG": "ko_KR.UTF-8"], isTerminal: false))
    XCTAssertTrue(
      BuildProgress.useNerdFont(
        environment: ["UNICODE_PROGRESS_BAR": "true", "LANG": "C"], isTerminal: false))
    XCTAssertFalse(
      BuildProgress.useNerdFont(
        environment: ["UNICODE_PROGRESS_BAR": "false", "LANG": "ko_KR.UTF-8"], isTerminal: true))
    XCTAssertFalse(
      BuildProgress.useNerdFont(
        environment: ["LC_ALL": "C", "LANG": "ko_KR.UTF-8"], isTerminal: true))
    XCTAssertTrue(
      BuildProgress.useNerdFont(
        environment: ["LC_CTYPE": "ko_KR.UTF-8", "LANG": "C"], isTerminal: true))
  }

  func testPlatformEvidenceCheckUsesTestedQtProfile() {
    XCTAssertNil(
      platformEvidenceCheck(
        platform: "FreeBSD 15.1-RELEASE", architecture: "x86_64", qtVersion: "6.11.2"))
    XCTAssertEqual(
      platformEvidenceCheck(
        platform: "FreeBSD 15.1-RELEASE", architecture: "x86_64", qtVersion: "6.10.0"
      )?.status, "unverified")
    XCTAssertEqual(
      platformEvidenceCheck(
        platform: "Ubuntu 24.04", architecture: "x86_64", qtVersion: "6.11.2")?.severity,
      "warning")
  }

  func testDoctorToolchainInstallationAdvice() {
    let go = Toolchain.go.installationAdvice("Install Go 1.23 or newer and add go to PATH")
    let rust = Toolchain.rust.installationAdvice("Install Rust 1.85 or newer for CXX-Qt 0.10.0")
    let swift = Toolchain.swift.installationAdvice(
      "Install Swift 6.4 or newer and add swift to PATH")
    let koreanGo = L10n.message(go, korean: true)
    #if os(macOS)
      XCTAssertTrue(go.hasSuffix("[brew install go]"))
      XCTAssertTrue(rust.hasSuffix("[brew install rust / rustup default stable]"))
      XCTAssertTrue(swift.hasSuffix("[xcode-select --install]"))
      XCTAssertEqual(koreanGo, "Go 1.23 이상을 설치하고 go를 PATH에 추가하세요 [brew install go]")
    #elseif os(FreeBSD)
      XCTAssertTrue(go.hasSuffix("[pkg install go]"))
      XCTAssertTrue(rust.hasSuffix("[pkg install rust]"))
      XCTAssertTrue(swift.hasSuffix("[pkg install swift6]"))
      XCTAssertEqual(koreanGo, "Go 1.23 이상을 설치하고 go를 PATH에 추가하세요 [pkg install go]")
    #else
      XCTAssertEqual(go, "Install Go 1.23 or newer and add go to PATH")
      XCTAssertEqual(rust, "Install Rust 1.85 or newer for CXX-Qt 0.10.0")
      XCTAssertEqual(swift, "Install Swift 6.4 or newer and add swift to PATH")
      XCTAssertEqual(koreanGo, "Go 1.23 이상을 설치하고 go를 PATH에 추가하세요")
    #endif
  }

  func testDoctorNativeAndJVMInstallationAdvice() {
    #if os(macOS)
      XCTAssertTrue(Toolchain.missingToolAdvice("c++").hasSuffix("[xcode-select --install]"))
      XCTAssertTrue(Toolchain.missingToolAdvice("cmake").hasSuffix("[brew install cmake]"))
      XCTAssertTrue(Toolchain.missingToolAdvice("qmake6").hasSuffix("[brew install qt]"))
      XCTAssertTrue(Toolchain.missingToolAdvice("gradle").hasSuffix("[brew install gradle]"))
      XCTAssertTrue(Toolchain.missingToolAdvice("javac").hasSuffix("[brew install openjdk]"))
    #elseif os(FreeBSD)
      XCTAssertTrue(Toolchain.missingToolAdvice("c++").hasSuffix("[pkg install llvm]"))
      XCTAssertTrue(Toolchain.missingToolAdvice("cmake").hasSuffix("[pkg install cmake]"))
      XCTAssertTrue(Toolchain.missingToolAdvice("qmake6").hasSuffix("[pkg install qt6-base]"))
      XCTAssertTrue(Toolchain.missingToolAdvice("gradle").hasSuffix("[pkg install gradle]"))
      XCTAssertTrue(Toolchain.missingToolAdvice("javac").hasSuffix("[pkg install openjdk25]"))
    #elseif os(Windows)
      XCTAssertTrue(Toolchain.missingToolAdvice("cl").contains("Developer PowerShell"))
      XCTAssertTrue(Toolchain.missingToolAdvice("qmake6").contains("MSVC Qt 6"))
      XCTAssertTrue(Toolchain.missingToolAdvice("gradle").contains("distribution"))
    #endif
  }

  func testPythonDoctorRejectsInterpreterTooNewForPinnedPySide() {
    let checks = pythonChecks(executable: "python") { _, arguments in
      XCTAssertEqual(arguments, ["--version"])
      return "Python 3.15.2"
    }
    XCTAssertEqual(checks.map(\.name), ["python"])
    XCTAssertEqual(checks.first?.status, "unsupported")
    XCTAssertTrue(checks.first?.remediation?.contains("3.10 through 3.14") == true)
  }

  #if os(Windows)
    func testWindowsToolSearchAcceptsPathAndExeSuffix() throws {
      let root = try temporaryRoot()
      defer { try? FileManager.default.removeItem(at: root) }
      let bin = root.appendingPathComponent("tools with spaces")
      try FileManager.default.createDirectory(at: bin, withIntermediateDirectories: false)
      let tool = bin.appendingPathComponent("test-tool.exe")
      try FileManager.default.copyItem(
        at: URL(fileURLWithPath: CommandLine.arguments[0]), to: tool)
      let environment = ["Path": "\(root.path);\(bin.path)"]
      XCTAssertEqual(executable("test-tool", environment: environment), tool.path)
      XCTAssertEqual(executable("test-tool.exe", environment: environment), tool.path)
    }
  #endif

  func testDoctorNamesActualBridgeImplementation() {
    XCTAssertEqual(bridgeImplementation(.python), "PySide6 QObject")
    XCTAssertEqual(bridgeImplementation(.kotlin), "JNI + C++ QObject (experimental)")
    XCTAssertEqual(bridgeImplementation(.swift), "Swift C ABI + C++ QObject (experimental)")
  }

  func testDoctorJSONKeepsMachineReadableStatusAndBridgeFields() throws {
    let result = DoctorResult(
      platform: "Ubuntu 24.04", architecture: "x86_64", backend: "kotlin",
      bridge: "auto", bridgeImplementation: bridgeImplementation(.kotlin),
      checks: [
        Check(
          name: "platform evidence", status: "unverified", version: nil,
          severity: "warning", remediation: "run smoke test")
      ])
    let value =
      try JSONSerialization.jsonObject(with: JSONEncoder().encode(result)) as? [String: Any]
    XCTAssertEqual(value?["schemaVersion"] as? Int, 1)
    XCTAssertEqual(value?["backend"] as? String, "kotlin")
    XCTAssertEqual(value?["bridge"] as? String, "auto")
    XCTAssertEqual(value?["bridgeImplementation"] as? String, "JNI + C++ QObject (experimental)")
    let checks = value?["checks"] as? [[String: Any]]
    XCTAssertEqual(checks?.first?["status"] as? String, "unverified")
  }

  func testKotlinScaffoldOwnsBackendAndPinsPlugin() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try Scaffolder.create(
      name: "Kotlin 세계", backend: .kotlin, bridge: "ffi", parent: root, reset: false)
    XCTAssertEqual(try Manifest.read(at: project).backend, .kotlin)
    let backend = try String(
      contentsOf: project.appendingPathComponent("src/main/kotlin/qbloom/app/Backend.kt"),
      encoding: .utf8)
    XCTAssertTrue(backend.contains("fun increment()"))
    XCTAssertTrue(backend.contains("fun greeting(): String"))
    let gradle = try String(
      contentsOf: project.appendingPathComponent("build.gradle.kts"), encoding: .utf8)
    XCTAssertTrue(gradle.contains("org.jetbrains.kotlin.jvm") && gradle.contains("2.4.10"))
    XCTAssertTrue(gradle.contains("-XstartOnFirstThread"))
    let cmake = try String(
      contentsOf: project.appendingPathComponent("CMakeLists.txt"), encoding: .utf8)
    XCTAssertTrue(cmake.contains("NAMES gradle gradle.bat"))
    XCTAssertTrue(cmake.contains("RUNTIME_OUTPUT_DIRECTORY"))
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "bad-kotlin", backend: .kotlin, bridge: "native", parent: root, reset: false))
  }

  func testErrorCommandHighlighting() {
    let message = "Use qbloom override, then qbloom run --release."
    let colored = CLIStyle.decorateError(message, enabled: true)
    XCTAssertTrue(colored.contains("\u{001B}[1;36mqbloom override\u{001B}[0m"))
    XCTAssertTrue(colored.contains("\u{001B}[1;36mqbloom run\u{001B}[0m"))
    XCTAssertTrue(colored.contains("\u{001B}[1;36m--release\u{001B}[0m"))
    XCTAssertEqual(CLIStyle.decorateError(message, enabled: false), message)
  }

  func testTemplateLicenseNoticeIsGenerated() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let initialized = try Scaffolder.create(
      name: "licensed-cpp", backend: .cpp, bridge: "auto", parent: root, reset: false)
    let initNotice = try String(
      contentsOf: initialized.appendingPathComponent("QBLOOM_TEMPLATE_NOTICE.txt"),
      encoding: .utf8)
    let initGuide = try String(
      contentsOf: initialized.appendingPathComponent("QBLOOM_PROJECT_GUIDE.md"),
      encoding: .utf8)
    XCTAssertTrue(initGuide.contains("Working with licensed-cpp"))
    XCTAssertTrue(initGuide.contains("qbloom test --headless"))
    XCTAssertTrue(initNotice.contains("BSD 2-Clause License"))
    XCTAssertTrue(initNotice.contains("Copyright (c) 2026 sonomaharvester"))

    let existing = root.appendingPathComponent("existing-python")
    try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)
    _ = try AddScaffolder.add(
      name: "existing-python", backend: .python, bridge: "auto", parent: root)
    let addNotice = try String(
      contentsOf: existing.appendingPathComponent("qbloom_quick/QBLOOM_TEMPLATE_NOTICE.txt"),
      encoding: .utf8)
    XCTAssertEqual(addNotice, initNotice)
    XCTAssertTrue(
      FileManager.default.fileExists(
        atPath: existing.appendingPathComponent("qbloom_quick/QBLOOM_PROJECT_GUIDE.md").path))
  }

  func testGeneratedReadmesOfferBothLanguagesForEveryBackend() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let selector = "[English](README.md) | [한국어](README-ko.md)"

    for backend in Backend.allCases {
      let name = "readme-\(backend.rawValue)"
      let project = try Scaffolder.create(
        name: name, backend: backend, bridge: "auto", parent: root, reset: false)
      for filename in ["README.md", "README-ko.md"] {
        let contents = try String(
          contentsOf: project.appendingPathComponent(filename), encoding: .utf8)
        XCTAssertTrue(contents.hasPrefix(selector), "\(backend): \(filename)")
        XCTAssertTrue(contents.contains("# \(name)"), "\(backend): \(filename)")
        XCTAssertFalse(contents.contains("{{"), "\(backend): \(filename)")
      }

      let existing = root.appendingPathComponent("added-\(backend.rawValue)")
      try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)
      _ = try AddScaffolder.add(
        name: "added-\(backend.rawValue)", backend: backend, bridge: "auto", parent: root)
      let addedReadme = existing.appendingPathComponent("qbloom_quick/README-ko.md")
      let korean = try String(contentsOf: addedReadme, encoding: .utf8)
      XCTAssertTrue(korean.hasPrefix(selector), "\(backend): add")
      XCTAssertTrue(korean.contains("상위 프로젝트 디렉터리에서"), "\(backend): add")
      XCTAssertFalse(korean.contains("{{"), "\(backend): add")
    }
  }

  func testOverrideRequiresInitMarkerAndBacksUpUserFiles() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try Scaffolder.create(
      name: "Hello 세계", backend: .cpp, bridge: "auto", parent: root, reset: false)
    XCTAssertEqual(try Manifest.read(at: project).backend, .cpp)
    XCTAssertFalse(
      try String(contentsOf: project.appendingPathComponent("qbloom.toml"), encoding: .utf8)
        .contains("\\/"))
    XCTAssertTrue(
      try String(contentsOf: project.appendingPathComponent("CMakeLists.txt"), encoding: .utf8)
        .contains("project(Hello___"))
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "Hello 세계", backend: .cpp, bridge: "auto", parent: root, reset: false))
    let marker = project.appendingPathComponent("qbloom.toml")
    let originalMarker = try String(contentsOf: marker, encoding: .utf8)
    try "user content".write(
      to: project.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)
    try FileManager.default.removeItem(at: marker)
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "Hello 세계", backend: .python, bridge: "auto", parent: root, reset: true))
    XCTAssertEqual(
      try String(contentsOf: project.appendingPathComponent("notes.txt"), encoding: .utf8),
      "user content")
    try originalMarker.write(to: marker, atomically: true, encoding: .utf8)
    _ = try Scaffolder.create(
      name: "Hello 세계", backend: .python, bridge: "auto", parent: root, reset: true)
    XCTAssertEqual(try Manifest.read(at: project).backend, .python)
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: project.appendingPathComponent("notes.txt").path))
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: project.appendingPathComponent("src/main.cpp").path))
    let backups = try FileManager.default.contentsOfDirectory(atPath: root.path)
      .filter { $0.hasPrefix(".qbloom-override-backup-") }
    XCTAssertEqual(backups.count, 1)
    XCTAssertTrue(
      FileManager.default.fileExists(
        atPath: root.appendingPathComponent(backups[0] + "/src/main.cpp").path))
    XCTAssertEqual(
      try String(
        contentsOf: root.appendingPathComponent(backups[0] + "/notes.txt"), encoding: .utf8),
      "user content")
  }

  func testOverrideRejectsAddedProjectsAndResetsEntireInitProject() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let existing = root.appendingPathComponent("existing")
    try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)
    try "keep".write(
      to: existing.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)
    _ = try AddScaffolder.add(name: "existing", backend: .cpp, bridge: "auto", parent: root)
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "existing", backend: .python, bridge: "auto", parent: root, reset: true))
    XCTAssertEqual(
      try String(contentsOf: existing.appendingPathComponent("notes.txt"), encoding: .utf8),
      "keep")

    let project = try Scaffolder.create(
      name: "fresh", backend: .cpp, bridge: "auto", parent: root, reset: false)
    let userFile = project.appendingPathComponent("custom/backend.py")
    try FileManager.default.createDirectory(
      at: userFile.deletingLastPathComponent(), withIntermediateDirectories: true)
    try "user code".write(to: userFile, atomically: true, encoding: .utf8)
    _ = try Scaffolder.create(
      name: "fresh", backend: .python, bridge: "auto", parent: root, reset: true)
    XCTAssertEqual(try Manifest.read(at: project).backend, .python)
    XCTAssertFalse(FileManager.default.fileExists(atPath: userFile.path))
    let backups = try FileManager.default.contentsOfDirectory(atPath: root.path)
      .filter { $0.hasPrefix(".qbloom-override-backup-") }
    XCTAssertEqual(backups.count, 1)
    XCTAssertEqual(
      try String(
        contentsOf: root.appendingPathComponent(backups[0] + "/custom/backend.py"), encoding: .utf8),
      "user code")
  }

  func testAddCppPreservesExistingFilesAndRejectsSecondAdd() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = root.appendingPathComponent("existing")
    try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
    let cmake = project.appendingPathComponent("CMakeLists.txt")
    try "cmake_minimum_required(VERSION 3.21)\nproject(existing LANGUAGES CXX)\n".write(
      to: cmake, atomically: true, encoding: .utf8)
    try "keep".write(
      to: project.appendingPathComponent("main.cpp"), atomically: true, encoding: .utf8)
    try "*.o\n".write(
      to: project.appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)
    _ = try AddScaffolder.add(name: "existing", backend: .cpp, bridge: "auto", parent: root)
    XCTAssertEqual(try Manifest.read(at: project).layout, "added")
    XCTAssertTrue(
      try String(contentsOf: cmake, encoding: .utf8).contains("add_subdirectory(qbloom_quick)"))
    XCTAssertEqual(
      try String(contentsOf: project.appendingPathComponent("main.cpp"), encoding: .utf8), "keep")
    XCTAssertEqual(
      try String(contentsOf: project.appendingPathComponent(".gitignore"), encoding: .utf8),
      "*.o\n.qbloom/\n")
    XCTAssertTrue(
      FileManager.default.fileExists(
        atPath: project.appendingPathComponent("qbloom_quick/src/main.cpp").path))
    let quickCMake = try String(
      contentsOf: project.appendingPathComponent("qbloom_quick/CMakeLists.txt"), encoding: .utf8)
    XCTAssertTrue(quickCMake.contains("if(WIN32 AND Qt6_VERSION VERSION_EQUAL \"6.11.2\")"))
    XCTAssertTrue(quickCMake.contains("SHARED_LIBRARY"))
    XCTAssertTrue(quickCMake.contains("NO_IMPORT_SCAN"))
    XCTAssertThrowsError(
      try AddScaffolder.add(name: "existing", backend: .cpp, bridge: "auto", parent: root))
  }

  func testPythonInitAndAddTemplates() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let initialized = try Scaffolder.create(
      name: "python-init", backend: .python, bridge: "auto", parent: root, reset: false)
    XCTAssertTrue(
      FileManager.default.fileExists(
        atPath: initialized.appendingPathComponent("qbloom_app/backend.py").path))
    XCTAssertThrowsError(
      try AddScaffolder.add(name: "python-init", backend: .python, bridge: "auto", parent: root))
    let existing = root.appendingPathComponent("python-existing")
    try FileManager.default.createDirectory(at: existing, withIntermediateDirectories: true)
    try "print('user source')".write(
      to: existing.appendingPathComponent("app.py"), atomically: true, encoding: .utf8)
    _ = try AddScaffolder.add(
      name: "python-existing", backend: .python, bridge: "native", parent: root)
    XCTAssertTrue(
      FileManager.default.fileExists(
        atPath: existing.appendingPathComponent("qbloom_quick/qbloom_app/__main__.py").path))
    XCTAssertTrue(
      try String(contentsOf: existing.appendingPathComponent("CMakeLists.txt"), encoding: .utf8)
        .contains("add_subdirectory(qbloom_quick)"))
    XCTAssertEqual(
      try String(contentsOf: existing.appendingPathComponent(".gitignore"), encoding: .utf8),
      ".qbloom/\n")
  }

  func testGoScaffoldAndBridgeValidation() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try Scaffolder.create(
      name: "go-sample", backend: .go, bridge: "auto", parent: root, reset: false)
    XCTAssertEqual(try Manifest.read(at: project).backend, .go)
    XCTAssertTrue(
      FileManager.default.fileExists(
        atPath: project.appendingPathComponent("backend/logic/counter.go").path))
    let cmake = try String(
      contentsOf: project.appendingPathComponent("CMakeLists.txt"), encoding: .utf8)
    XCTAssertTrue(cmake.contains("-buildmode=c-shared"))
    XCTAssertTrue(cmake.contains("-install_name,@rpath/libqbloom_go.dylib"))
    XCTAssertTrue(cmake.contains("BUILD_RPATH"))
    XCTAssertTrue(cmake.contains("IMPORTED_IMPLIB"))
    let exports = try String(
      contentsOf: project.appendingPathComponent("backend/exports.def"), encoding: .utf8)
    XCTAssertTrue(exports.contains("LIBRARY libqbloom_go.dll"))
    XCTAssertTrue(exports.contains("GoIncrement"))
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "invalid-go-bridge", backend: .go, bridge: "native", parent: root, reset: false))
  }

  func testRustScaffoldUsesPinnedCxxQt() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try Scaffolder.create(
      name: "rust-sample", backend: .rust, bridge: "native", parent: root, reset: false)
    XCTAssertEqual(try Manifest.read(at: project).backend, .rust)
    let cargo = try String(
      contentsOf: project.appendingPathComponent("Cargo.toml"), encoding: .utf8)
    XCTAssertTrue(cargo.contains("cxx-qt = \"=0.10.0\""))
    XCTAssertTrue(
      try String(contentsOf: project.appendingPathComponent("Cargo.lock"), encoding: .utf8)
        .contains("name = \"rust_sample\""))
    XCTAssertTrue(
      try String(contentsOf: project.appendingPathComponent("qml/Main.qml"), encoding: .utf8)
        .contains("import Qbloom.Rust"))
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "bad-rust", backend: .rust, bridge: "ffi", parent: root, reset: false))
  }

  func testJavaScaffoldAndBridgeValidation() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try Scaffolder.create(
      name: "Java 세계", backend: .java, bridge: "ffi", parent: root, reset: false)
    XCTAssertEqual(try Manifest.read(at: project).backend, .java)
    XCTAssertTrue(
      FileManager.default.fileExists(
        atPath:
          project.appendingPathComponent("src/main/java/qbloom/app/Backend.java").path))
    let cmake = try String(
      contentsOf: project.appendingPathComponent("CMakeLists.txt"), encoding: .utf8)
    XCTAssertTrue(cmake.contains("find_package(JNI REQUIRED)"))
    XCTAssertTrue(cmake.contains("NAMES gradle gradle.bat"))
    XCTAssertTrue(cmake.contains("RUNTIME_OUTPUT_DIRECTORY"))
    let gradle = try String(
      contentsOf: project.appendingPathComponent("build.gradle.kts"),
      encoding: .utf8)
    XCTAssertTrue(gradle.contains("logicTest"))
    XCTAssertTrue(gradle.contains("-XstartOnFirstThread"))
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "bad-java", backend: .java, bridge: "native", parent: root, reset: false))
  }

  func testAddRustGoJavaSwiftPreservesExistingProject() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    for backend in [Backend.rust, .go, .java, .swift, .kotlin] {
      let name = "existing-\(backend.rawValue)"
      let project = root.appendingPathComponent(name)
      try FileManager.default.createDirectory(at: project, withIntermediateDirectories: true)
      let userFile = project.appendingPathComponent("user.txt")
      try "keep".write(to: userFile, atomically: true, encoding: .utf8)
      try "cmake_minimum_required(VERSION 3.21)\nproject(user_project LANGUAGES CXX)\n".write(
        to: project.appendingPathComponent("CMakeLists.txt"), atomically: true, encoding: .utf8)
      _ = try AddScaffolder.add(name: name, backend: backend, bridge: "auto", parent: root)
      XCTAssertEqual(try Manifest.read(at: project).backend, backend)
      XCTAssertEqual(try Manifest.read(at: project).layout, "added")
      XCTAssertEqual(try String(contentsOf: userFile, encoding: .utf8), "keep")
      XCTAssertTrue(
        try String(
          contentsOf: project.appendingPathComponent("CMakeLists.txt"),
          encoding: .utf8
        ).contains("add_subdirectory(qbloom_quick)"))
      XCTAssertTrue(
        try String(
          contentsOf: project.appendingPathComponent("CMakeLists.txt"),
          encoding: .utf8
        ).contains("project(user_project LANGUAGES CXX)"))
      XCTAssertTrue(
        try String(
          contentsOf: project.appendingPathComponent("qbloom_quick/README.md"),
          encoding: .utf8
        ).contains("from the parent project directory"))
      XCTAssertThrowsError(
        try AddScaffolder.add(
          name: name, backend: backend, bridge: "auto", parent: root))
    }
    let rustQml = try String(
      contentsOf:
        root.appendingPathComponent("existing-rust/qbloom_quick/qml/Main.qml"), encoding: .utf8)
    XCTAssertTrue(rustQml.contains("Backend { id: backend }"))
    let goCmake = try String(
      contentsOf:
        root.appendingPathComponent("existing-go/qbloom_quick/CMakeLists.txt"), encoding: .utf8)
    XCTAssertTrue(goCmake.contains("qt_add_executable(qbloom_quick_app"))
    let javaCmake = try String(
      contentsOf:
        root.appendingPathComponent("existing-java/qbloom_quick/CMakeLists.txt"), encoding: .utf8)
    XCTAssertTrue(javaCmake.contains("URI Qbloom.Quick"))
    let swiftCmake = try String(
      contentsOf:
        root.appendingPathComponent("existing-swift/qbloom_quick/CMakeLists.txt"), encoding: .utf8)
    XCTAssertTrue(swiftCmake.contains("qt_add_executable(qbloom_quick_app"))
    XCTAssertThrowsError(
      try AddScaffolder.add(
        name: "existing-java", backend: .java, bridge: "native", parent: root))
  }

  func testSwiftScaffoldUsesExperimentalCAbi() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let project = try Scaffolder.create(
      name: "swift-example", backend: .swift, bridge: "ffi", parent: root, reset: false)
    XCTAssertEqual(try Manifest.read(at: project).backend, .swift)
    let swiftSource = try String(
      contentsOf: project.appendingPathComponent("Sources/QbloomSwiftBackend/Backend.swift"),
      encoding: .utf8)
    XCTAssertTrue(swiftSource.contains("@_cdecl(\"qbloom_swift_increment\")"))
    XCTAssertTrue(swiftSource.contains("Hello, world!"))
    let cmake = try String(
      contentsOf: project.appendingPathComponent("CMakeLists.txt"), encoding: .utf8)
    XCTAssertTrue(cmake.contains("libQbloomSwiftBackend"))
    XCTAssertTrue(cmake.contains("IMPORTED_NO_SONAME TRUE"))
    XCTAssertTrue(cmake.contains("--show-bin-path"))
    XCTAssertTrue(cmake.contains("QbloomSwiftBackend.dll"))
    XCTAssertTrue(cmake.contains("IMPORTED_IMPLIB"))
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "bad-swift", backend: .swift, bridge: "native", parent: root, reset: false))
    try "old content".write(
      to: project.appendingPathComponent("notes.txt"), atomically: true, encoding: .utf8)
    _ = try Scaffolder.create(
      name: "swift-example", backend: .swift, bridge: "auto", parent: root, reset: true)
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: project.appendingPathComponent("notes.txt").path))
  }

  func testUnsafeDestinationsAndUnsupportedBackends() throws {
    let root = FileManager.default.temporaryDirectory
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "../escape", backend: .cpp, bridge: "auto", parent: root, reset: false))
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "not-generated", backend: .cpp, bridge: "ffi", parent: root, reset: false))
  }

  func testManifestRejectsUnknownSchema() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    try "schema_version = 2\n".write(
      to: root.appendingPathComponent("qbloom.toml"), atomically: true, encoding: .utf8)
    XCTAssertThrowsError(try Manifest.read(at: root))
  }

  func testOverrideRejectsSymlinkedDestination() throws {
    let root = try temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let elsewhere = root.appendingPathComponent("elsewhere")
    try FileManager.default.createDirectory(at: elsewhere, withIntermediateDirectories: true)
    do {
      try FileManager.default.createSymbolicLink(
        at: root.appendingPathComponent("sample"), withDestinationURL: elsewhere)
    } catch {
      #if os(Windows)
        if (error as NSError).code == NSFileWriteUnknownError {
          throw XCTSkip("Windows could not create the directory symlink: \(error)")
        }
      #endif
      throw error
    }
    XCTAssertThrowsError(
      try Scaffolder.create(
        name: "sample", backend: .cpp, bridge: "auto", parent: root, reset: true))
  }
}
