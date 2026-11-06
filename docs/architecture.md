# Architecture

Swift ArgumentParser handles commands. `Scaffolder` copies text templates from `Bundle.module` into a temporary sibling directory, renders a small set of typed values, then renames the directory into place. `Manifest.read` accepts only the documented schema subset. `Runner` uses Foundation `Process` with an executable and argument array.

The C++ template creates one `Backend` QObject before the QML engine. Its read-only `greeting` and `count` properties are available to QML under the name `backend`; `countChanged` updates the bound QML label. `--smoke-test` loads the real QML module and checks the label after backend mutations.

The shared `Templates/common/qml/Main.qml` is copied into both C++ and Python projects. The Python adapter uses PySide6 `QObject`, `Property`, `Signal`, and `Slot`; Python owns the event loop. Its top-level CMake entry point defines a launch target, while `qbloom build` checks Python sources through Python itself.

The Rust adapter uses CXX-Qt 0.10.0 to generate a Qt-facing `QObject` from Rust properties and invokable methods. The [Qt Bridge for Rust repository](https://github.com/qt/qtbridge-rust) does not list FreeBSD among its supported hosts, while [CXX-Qt's Cargo integration](https://kdab.github.io/cxx-qt/book/getting-started/4-cargo-executable.html) could be compiled and exercised here. Cargo and its committed lockfile own the native build; CMake provides a Cargo integration target. Rust has a QML variant that instantiates the registered Rust type directly and exercises the same greeting, counter, and button contract.

The Go adapter builds a cgo `c-shared` library. Go owns greeting and counter state. A C++ `QObject` facade holds an opaque integer handle, converts the allocated greeting string and frees it through the Go ABI, and emits `countChanged` on the Qt GUI thread. CMake builds the Go library before linking the Qt Quick executable, with a local runtime library path.

The Java and Kotlin adapters use Gradle to compile their backend state. A small JNI library owns the Qt event loop on the JVM main thread and exposes the backend through a C++ `QObject` facade. Java or Kotlin owns the greeting and counter; the facade emits Qt notifications after invoking the corresponding JVM method. This path is experimental and was smoke tested on FreeBSD 15.1 x86_64. Kotlin pins its Gradle plugin to 2.4.10. The first explicit Kotlin build may resolve that plugin from Maven Central.

The Swift generated backend is separate from the Swift CLI host. Its FreeBSD adapter uses SwiftPM to build a dynamic library with an experimental `@_cdecl` C ABI and a C++ `QObject` facade. Swift owns the state; the facade exposes it and notifies QML on the GUI thread. It does not use Qt Bridge for Swift. Other platforms remain unverified.

The CLI package bundles templates with `Bundle.module`. A release install must keep `qbloom_QbloomCLI.bundle` adjacent to the executable. The install and packaging scripts locate SwiftPM products with `swift build -c release --show-bin-path`, then copy the executable and bundle together. See [installation.md](installation.md).

`add` installs the generated app in `qbloom_quick`, appends one `add_subdirectory(qbloom_quick)` line to an existing top-level CMake file (or creates it), adds `.qbloom/` to the root `.gitignore`, and writes `qbloom.toml` at the existing project root. It rejects a pre-existing marker or generated directory and rolls back its own files if integration writing fails. `override` accepts only a valid `init` layout. After confirmation it moves the full original project to a sibling backup and replaces it with a newly generated project, rolling back if the replacement move fails.
