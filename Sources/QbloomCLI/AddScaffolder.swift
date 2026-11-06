import Foundation

/// Installs a separate Qt Quick target in an existing project without replacing its sources.
struct AddScaffolder {
  static func add(name: String, backend: Backend, bridge: String, parent: URL) throws -> URL {
    guard !name.isEmpty, name != ".", name != "..", !name.contains("/"),
      !name.contains("\\"),
      !name.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) })
    else { throw QbloomError.message("Project name must be one safe directory name") }
    let allowedBridges =
      backend == .go || backend == .java || backend == .swift || backend == .kotlin
      ? ["auto", "ffi"] : ["auto", "native"]
    guard allowedBridges.contains(bridge) else {
      throw QbloomError.message(
        "\(backend.rawValue) add supports --bridge \(allowedBridges.joined(separator: " or "))")
    }

    let fm = FileManager.default
    let root = parent.standardizedFileURL.appendingPathComponent(name)
    guard !isSymlink(root), isDirectoryAt(root) else {
      throw QbloomError.message("add requires an existing, real project directory: \(root.path)")
    }
    let marker = root.appendingPathComponent("qbloom.toml")
    guard !fm.fileExists(atPath: marker.path), !isSymlink(marker) else {
      throw QbloomError.message(
        "This project already has qbloom init or add; use override to reset it")
    }
    let generated = root.appendingPathComponent("qbloom_quick")
    guard !fm.fileExists(atPath: generated.path), !isSymlink(generated) else {
      throw QbloomError.message("qbloom_quick already exists; add will not overwrite it")
    }

    let topCmake = root.appendingPathComponent("CMakeLists.txt")
    guard !isSymlink(topCmake) else {
      throw QbloomError.message("Refusing a symlinked CMakeLists.txt")
    }
    let originalCmake: String?
    if fm.fileExists(atPath: topCmake.path) {
      originalCmake = try String(contentsOf: topCmake, encoding: .utf8)
    } else {
      originalCmake = nil
    }
    let entry: String
    if let originalCmake {
      entry =
        originalCmake + (originalCmake.hasSuffix("\n") ? "" : "\n")
        + "\n# qbloom Qt Quick integration\nadd_subdirectory(qbloom_quick)\n"
    } else {
      entry = """
        cmake_minimum_required(VERSION 3.21)
        project(\(identifier(name)) LANGUAGES NONE)
        add_subdirectory(qbloom_quick)

        """
    }
    let gitignore = root.appendingPathComponent(".gitignore")
    guard !isSymlink(gitignore) else {
      throw QbloomError.message("Refusing a symlinked .gitignore")
    }
    let originalIgnore =
      fm.fileExists(atPath: gitignore.path)
      ? try String(contentsOf: gitignore, encoding: .utf8) : nil
    let ignoreEntry: String
    if let originalIgnore, originalIgnore.split(separator: "\n").contains(".qbloom/") {
      ignoreEntry = originalIgnore
    } else {
      let existing = originalIgnore ?? ""
      ignoreEntry =
        existing + (existing.isEmpty || existing.hasSuffix("\n") ? "" : "\n") + ".qbloom/\n"
    }

    let stage = root.deletingLastPathComponent()
      .appendingPathComponent(".qbloom-add-stage-\(UUID().uuidString)")
    try fm.createDirectory(at: stage, withIntermediateDirectories: false)
    defer { try? fm.removeItem(at: stage) }
    let templates = Bundle.module.url(forResource: "Templates", withExtension: nil)!
    let variables = [
      "{{NAME}}": name, "{{TARGET}}": identifier(name),
      "{{QML_NAME}}": qmlString(name), "{{EXECUTABLE}}": "qbloom_quick_app",
      "{{MODULE_URI}}": "Qbloom.Quick",
    ]
    try Scaffolder.copyTemplates(
      from: templates.appendingPathComponent("common"),
      to: stage, variables: variables)
    try Scaffolder.copyTemplates(
      from: templates.appendingPathComponent(backend.rawValue),
      to: stage, variables: variables)
    let readme = stage.appendingPathComponent("README.md")
    if fm.fileExists(atPath: readme.path) {
      let existing = try String(contentsOf: readme, encoding: .utf8)
      try
        (existing
        + "\nFor an added project, run `qbloom doctor`, `qbloom build`, `qbloom run`, and `qbloom test` from the parent project directory. The generated application lives in `qbloom_quick/`.\n")
        .write(to: readme, atomically: true, encoding: .utf8)
    }
    let koreanReadme = stage.appendingPathComponent("README-ko.md")
    if fm.fileExists(atPath: koreanReadme.path) {
      let existing = try String(contentsOf: koreanReadme, encoding: .utf8)
      try
        (existing
        + "\n기존 프로젝트에 추가했다면 상위 프로젝트 디렉터리에서 `qbloom doctor`, `qbloom build`, `qbloom run`, `qbloom test`를 실행하세요. 생성된 애플리케이션은 `qbloom_quick/`에 있습니다.\n")
        .write(to: koreanReadme, atomically: true, encoding: .utf8)
    }
    let manifest = Manifest(
      name: name, backend: backend, bridge: bridge,
      buildDir: ".qbloom/build", layout: "added")

    try fm.moveItem(at: stage, to: generated)
    do {
      try entry.write(to: topCmake, atomically: true, encoding: .utf8)
      try ignoreEntry.write(to: gitignore, atomically: true, encoding: .utf8)
      try manifest.contents.write(to: marker, atomically: true, encoding: .utf8)
    } catch {
      if let originalCmake {
        try? originalCmake.write(to: topCmake, atomically: true, encoding: .utf8)
      } else {
        try? fm.removeItem(at: topCmake)
      }
      if let originalIgnore {
        try? originalIgnore.write(to: gitignore, atomically: true, encoding: .utf8)
      } else {
        try? fm.removeItem(at: gitignore)
      }
      try? fm.removeItem(at: marker)
      try? fm.removeItem(at: generated)
      throw error
    }
    return root
  }
}
