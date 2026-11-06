import ArgumentParser
import Foundation

func pythonExecutable(in root: URL) -> String? {
  let local = [
    root.appendingPathComponent(".venv/bin/python"),
    root.appendingPathComponent(".venv/Scripts/python.exe"),
    root.appendingPathComponent("qbloom_quick/.venv/bin/python"),
    root.appendingPathComponent("qbloom_quick/.venv/Scripts/python.exe"),
  ]
  if let selected = local.first(where: { FileManager.default.isExecutableFile(atPath: $0.path) }) {
    return selected.path
  }
  return executable("python3") ?? executable("python")
}

func codeRoot(_ root: URL, _ manifest: Manifest) -> URL {
  manifest.layout == "added" ? root.appendingPathComponent("qbloom_quick") : root
}

func pythonChecks(in root: URL) -> [Check] {
  pythonChecks(executable: pythonExecutable(in: root)) { outputOf($0, $1) }
}

func pythonChecks(
  executable python: String?, probe: (String, [String]) -> String?
) -> [Check] {
  let installation = Toolchain.python.installationAdvice(
    "Install Python 3.10 through 3.14 for PySide6 6.11.2")
  guard let python else {
    return [
      Check(
        name: "python", status: "missing", version: nil, severity: "error",
        remediation: installation)
    ]
  }
  let version = probe(python, ["--version"])
  let parts = version?.split(separator: " ").last?.split(separator: ".") ?? []
  let supported = parts.count >= 2 && Int(parts[0]) == 3 && (10...14).contains(Int(parts[1]) ?? 0)
  let pythonCheck = Check(
    name: "python", status: supported ? "found" : "unsupported",
    version: version, severity: supported ? "info" : "error",
    remediation: supported ? nil : installation)
  guard supported else { return [pythonCheck] }
  let pysideVersion = probe(python, ["-c", "import PySide6; print(PySide6.__version__)"])
  let pysideGood = pysideVersion == "6.11.2"
  #if os(FreeBSD)
    let pysideAdvice =
      "Install PySide6==6.11.2 in the selected Python environment [pkg install py312-pyside6]"
  #else
    let pysideAdvice =
      "Install PySide6==6.11.2 in the selected Python environment [python -m pip install PySide6==6.11.2]"
  #endif
  let pysideCheck = Check(
    name: "PySide6",
    status: pysideGood ? "found" : (pysideVersion == nil ? "missing" : "unsupported"),
    version: pysideVersion, severity: pysideGood ? "info" : "error",
    remediation: pysideGood ? nil : pysideAdvice)
  return [pythonCheck, pysideCheck]
}

func buildPython(_ root: URL, _ manifest: Manifest) throws {
  let checks = pythonChecks(in: root)
  guard checks.allSatisfy({ $0.severity != "error" }), let python = pythonExecutable(in: root)
  else {
    throw QbloomError.message(checks.compactMap(\.remediation).joined(separator: "; "))
  }
  let source = codeRoot(root, manifest)
  let status = try Runner.run(
    python, ["-m", "compileall", "-q", "qbloom_app", "tests"], in: source)
  if status != 0 { throw ExitCode(status) }
}

func runPython(_ root: URL, _ manifest: Manifest, arguments: [String]) throws {
  try buildPython(root, manifest)
  guard let python = pythonExecutable(in: root) else {
    throw QbloomError.message("Python is missing")
  }
  let status = try Runner.run(
    python, ["-m", "qbloom_app"] + arguments, in: codeRoot(root, manifest))
  if status != 0 { throw ExitCode(status) }
}

func testPython(_ root: URL, _ manifest: Manifest, headless: Bool) throws {
  try buildPython(root, manifest)
  guard let python = pythonExecutable(in: root) else {
    throw QbloomError.message("Python is missing")
  }
  let source = codeRoot(root, manifest)
  let unitStatus = try Runner.run(
    python, ["-m", "unittest", "discover", "-s", "tests", "-v"], in: source)
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
  let env = headless ? ["QT_QPA_PLATFORM": "offscreen", "QT_QUICK_BACKEND": "software"] : [:]
  let smokeStatus = try Runner.run(
    python, ["-m", "qbloom_app", "--smoke-test"],
    in: source, environment: env)
  if smokeStatus != 0 { throw ExitCode(smokeStatus) }
}
