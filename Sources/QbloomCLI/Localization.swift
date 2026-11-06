import Foundation

enum L10n {
  static func isKorean(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool
  {
    let locale =
      ["LC_ALL", "LC_MESSAGES", "LANG"]
      .compactMap { environment[$0] }
      .first { !$0.isEmpty } ?? ""
    guard !locale.isEmpty else { return false }
    let language =
      (locale.split(separator: ".", maxSplits: 1).first ?? "")
      .split(separator: "@", maxSplits: 1).first.map(String.init) ?? ""
    return language.replacingOccurrences(of: "-", with: "_").lowercased() == "ko_kr"
  }

  static func text(_ english: String, _ korean: String) -> String {
    isKorean() ? korean : english
  }

  static var noDisplay: String {
    text(
      "SKIP: No graphical display is available. Try qbloom test --headless if the Qt offscreen plugin is installed.",
      "SKIP: 그래픽 디스플레이가 없습니다. Qt offscreen 플러그인이 설치되어 있다면 qbloom test --headless를 실행하세요.")
  }

  static func status(_ value: String, korean: Bool = isKorean()) -> String {
    guard korean else { return value }
    return [
      "found": "확인됨", "missing": "없음", "broken": "실행 실패",
      "unsupported": "지원 안 됨", "resolved-at-build": "빌드 시 설치",
    ][value] ?? value
  }

  static func checkName(_ value: String, korean: Bool = isKorean()) -> String {
    guard korean else { return value }
    return [
      "JNI headers": "JNI 헤더", "JDK version": "JDK 버전",
      "Gradle version": "Gradle 버전", "Go target": "Go 대상",
      "cgo C compiler": "cgo C 컴파일러", "Kotlin Gradle plugin": "Kotlin Gradle 플러그인",
      "platform evidence": "플랫폼 검증 근거",
      "Qt version": "Qt 버전",
    ][value] ?? value
  }

  /// Keep JSON check identifiers and statuses stable; localize only human-readable output.
  static func message(_ value: String, korean: Bool = isKorean()) -> String {
    guard korean else { return value }
    let fixed: [String: String] = [
      "Backend flags are mutually exclusive": "백엔드 옵션은 하나만 선택할 수 있습니다",
      "CMake config": "CMake 설정",
      "Native build": "네이티브 빌드",
      "Python build": "Python 빌드",
      "Cargo build": "Cargo 빌드",
      "Build": "빌드",
      "Project name must be one safe directory name": "프로젝트 이름은 안전한 디렉터리 이름 하나여야 합니다",
      "Required tools are missing": "필수 도구가 없거나 지원되지 않습니다",
      "CMake configure failed": "CMake 설정에 실패했습니다",
      "Native CMake build failed": "네이티브 CMake 빌드에 실패했습니다",
      "Backend is unverified": "이 백엔드는 검증되지 않았습니다",
      "--qt-dir is not implemented yet; set CMAKE_PREFIX_PATH when building":
        "--qt-dir는 아직 구현되지 않았습니다. 빌드할 때 CMAKE_PREFIX_PATH를 설정하세요",
      "--force is unavailable; use qbloom override for a confirmed reset":
        "--force는 사용할 수 없습니다. 확인 후 초기화하려면 qbloom override를 실행하세요",
      "This project already has qbloom init or add; use override to reset it":
        "이미 qbloom init 또는 add가 적용된 프로젝트입니다. 초기화하려면 qbloom override를 실행하세요",
      "Install Go 1.23 or newer (set GOTOOLCHAIN=local for offline builds)":
        "Go 1.23 이상을 설치하세요. 오프라인 빌드에서는 GOTOOLCHAIN=local을 설정하세요",
      "Install Ninja for Qt CMake builds in paths with spaces on FreeBSD":
        "FreeBSD에서 공백이 포함된 경로로 Qt CMake 빌드를 하려면 Ninja를 설치하세요",
      "Run qbloom test --headless on this host and check the recorded results in docs/compatibility.md":
        "현재 환경에서 qbloom test --headless를 실행하고 docs/compatibility.md에 기록된 결과를 확인하세요",
      "qmake6 is unavailable; CMake will verify the Qt version during build":
        "qmake6가 없어 Qt 버전을 확인할 수 없습니다. 빌드할 때 CMake가 확인합니다",
      "Python is missing": "Python이 없습니다",
      "Swift is missing": "Swift가 없습니다",
      "Gradle is missing": "Gradle이 없습니다",
      "Cargo is missing; run qbloom doctor": "Cargo가 없습니다. qbloom doctor를 실행하세요",
      "Go is missing; run qbloom doctor": "Go가 없습니다. qbloom doctor를 실행하세요",
      "Qt 6 qmake6 is missing; run qbloom doctor": "Qt 6 qmake6가 없습니다. qbloom doctor를 실행하세요",
      "cmake is missing; run qbloom doctor": "CMake가 없습니다. qbloom doctor를 실행하세요",
      "Reset cancelled": "초기화를 취소했습니다",
      "Override requires an existing project directory": "초기화할 기존 프로젝트 디렉터리가 필요합니다",
      "Override requires a real project directory, not a symlink":
        "초기화 대상은 심볼릭 링크가 아닌 실제 프로젝트 디렉터리여야 합니다",
      "Bundled templates are missing": "포함된 템플릿을 찾을 수 없습니다",
      "Refusing a symlinked CMakeLists.txt": "심볼릭 링크인 CMakeLists.txt는 수정하지 않습니다",
      "Refusing a symlinked .gitignore": "심볼릭 링크인 .gitignore는 수정하지 않습니다",
      "Refusing a symlinked .qbloom build path": "심볼릭 링크인 .qbloom 빌드 경로는 사용하지 않습니다",
      "qbloom_quick already exists; add will not overwrite it": "qbloom_quick가 이미 있어 덮어쓰지 않습니다",
      "Install JDK 21 or newer": "JDK 21 이상을 설치하세요",
      "Install Gradle 8.14.2 or newer": "Gradle 8.14.2 이상을 설치하세요",
      "Install Qt 6.8 or newer development tools": "Qt 6.8 이상의 개발 도구를 설치하세요",
      "Install Rust 1.85 or newer for CXX-Qt 0.10.0": "CXX-Qt 0.10.0용 Rust 1.85 이상을 설치하세요",
      "Install Python 3.10 through 3.14 for PySide6 6.11.2":
        "PySide6 6.11.2용 Python 3.10~3.14를 설치하세요",

      "Install Go 1.23 or newer and add go to PATH": "Go 1.23 이상을 설치하고 go를 PATH에 추가하세요",
      "Install Swift 6.4 or newer and add swift to PATH": "Swift 6.4 이상을 설치하고 swift를 PATH에 추가하세요",
      "Install Swift 6.4 or newer for the experimental C ABI adapter":
        "실험적 C ABI 어댑터용 Swift 6.4 이상을 설치하세요",
      "Install PySide6==6.11.2 in the selected Python environment":
        "선택한 Python 환경에 PySide6==6.11.2를 설치하세요",
      "Install the C compiler selected by `go env CC` for cgo":
        "cgo용으로 `go env CC`가 선택한 C 컴파일러를 설치하세요",
      "Set JAVA_HOME to a JDK 21+ installation containing include/jni.h":
        "include/jni.h가 포함된 JDK 21 이상으로 JAVA_HOME을 설정하세요",
      "The first explicit build resolves the pinned Kotlin plugin from Maven Central; later builds can use Gradle's cache":
        "첫 빌드에서 고정된 Kotlin 플러그인을 Maven Central에서 받습니다. 이후에는 Gradle 캐시를 사용할 수 있습니다",
    ]
    if let translated = fixed[value] { return translated }
    if value.contains("; ") {
      return value.components(separatedBy: "; ")
        .map { message($0, korean: true) }.joined(separator: "; ")
    }

    if value.hasSuffix("]"), let hint = value.range(of: " [", options: .backwards) {
      return message(String(value[..<hint.lowerBound]), korean: true) + value[hint.lowerBound...]
    }
    if value.hasPrefix("Install Qt 6 "),
      value.hasSuffix(" development files or set CMAKE_PREFIX_PATH")
    {
      let module = value.dropFirst("Install Qt 6 ".count)
        .dropLast(" development files or set CMAKE_PREFIX_PATH".count)
      return "Qt 6 \(module) 개발 파일을 설치하거나 CMAKE_PREFIX_PATH를 설정하세요"
    }
    if value.hasPrefix("Set GOOS/GOARCH for the native Qt host target ") {
      let target = value.dropFirst("Set GOOS/GOARCH for the native Qt host target ".count)
      return "네이티브 Qt 호스트 대상 \(target)에 맞게 GOOS/GOARCH를 설정하세요"
    }
    if value.hasSuffix(" backend is unverified and has no generated template yet") {
      let backend = value.dropLast(" backend is unverified and has no generated template yet".count)
      return "\(backend) 백엔드는 검증되지 않았고 생성 템플릿이 없습니다"
    }
    if let range = value.range(of: " add supports --bridge ") {
      return
        "\(value[..<range.lowerBound]) add는 --bridge \(value[range.upperBound...].replacingOccurrences(of: " or ", with: " 또는 "))를 지원합니다"
    }
    if let range = value.range(of: " supports --bridge ") {
      return
        "\(value[..<range.lowerBound]) 백엔드는 --bridge \(value[range.upperBound...].replacingOccurrences(of: " or ", with: " 또는 "))를 지원합니다"
    }

    let replacements: [(String, String)] = [
      ("Unsupported qbloom.toml syntax: ", "지원하지 않는 qbloom.toml 구문: "),
      ("Unknown or duplicate qbloom.toml key: ", "알 수 없거나 중복된 qbloom.toml 키: "),
      ("Invalid string in qbloom.toml: ", "qbloom.toml의 잘못된 문자열: "),
      ("Unsupported qbloom.toml value for ", "qbloom.toml에서 지원하지 않는 값: "),
      (
        "Invalid or unsupported qbloom.toml schema; this qbloom supports schema_version = 1",
        "잘못되었거나 지원하지 않는 qbloom.toml 스키마입니다. 이 버전은 schema_version = 1을 지원합니다"
      ),
      ("Parent directory does not exist: ", "상위 디렉터리가 없습니다: "),
      ("Destination exists: ", "대상 디렉터리가 이미 있습니다: "),
      (
        ". Use qbloom override to reset a generated project.",
        ". 생성된 프로젝트를 초기화하려면 qbloom override를 실행하세요."
      ),
      ("No generated project exists at ", "생성된 프로젝트가 없습니다: "),
      ("Template symlink rejected: ", "템플릿 심볼릭 링크를 거부했습니다: "),
      ("Unresolved template variable in ", "치환되지 않은 템플릿 변수가 있습니다: "),
      ("add requires an existing, real project directory: ", "add에는 기존의 실제 프로젝트 디렉터리가 필요합니다: "),
      ("JNI library is missing: ", "JNI 라이브러리가 없습니다: "),
      ("Install ", "설치하세요: "),
      (" and add it to PATH", "; PATH에도 추가하세요"),
      (" and add go to PATH", "; go를 PATH에 추가하세요"),
      ("Repair ", "복구하세요: "),
      ("; it is on PATH but cannot run", "; PATH에 있지만 실행되지 않습니다"),
      ("; it cannot run", "; 실행되지 않습니다"),
      (" is missing; run qbloom doctor", "이(가) 없습니다. qbloom doctor를 실행하세요"),
      (" is missing", "이(가) 없습니다"),
      ("; run qbloom build", "; qbloom build를 실행하세요"),
      ("Native CMake build failed", "네이티브 CMake 빌드에 실패했습니다"),
    ]
    var result = value
    for (source, target) in replacements {
      result = result.replacingOccurrences(of: source, with: target)
    }
    return result
  }
}
