# Compatibility and evidence

Status is based on actual build and smoke results. The C++ test creates a Qt Quick window, reads the backend-provided greeting through QML, invokes the QML button signals, and observes bound counter text and three change notifications for `0 → 1 → 2 → 0`.

| Backend | Bridge | OS | Architecture | Qt | Toolchain | Status | Evidence |
| --- | --- | --- | --- | --- | --- | --- | --- |
| C++ `init` and `add` | native QObject | FreeBSD 15.1 | x86_64 | 6.11.2 | Clang 19.1.7, CMake 3.31.12, Ninja 1.13.2 | verified | Fresh `init` and existing-project `add` passed QML button smoke tests on 2026-11-05. An installed M7 release build also passed `doctor --strict`, `build`, `run -- --smoke-test`, and `test --headless` from a fresh project with spaces and Unicode on 2026-11-06. |
| C++ `init` and `add` | native QObject | Ubuntu 24.04 | x86_64 | 6.8.3 | Clang/GCC, CMake, Ninja | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| C++ `init` and `add` | native QObject | macOS 15 | arm64 | 6.11.2 | Apple Clang, CMake, Ninja | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| C++ `init` and `add` | native QObject | macOS 27.2 | arm64 | 6.12.0 | Apple Clang 21.0.0, CMake 4.4.5, Ninja 1.13.2 | verified | `doctor --strict`, build, and offscreen QML greeting/button smoke test passed in a path with spaces and Korean text on 2026-11-06. The graphical-session smoke test also passed. |
| C++ `init` and `add` | native QObject | Windows 11 (26300) | x64 | 6.11.2 | MSVC 19.51.36260, CMake 3.31.6-msvc6, Ninja 1.12.1 | verified | Both layouts passed Windows and offscreen Qt Quick smoke tests. See the [Windows verification record](#windows-11-x64). |
| Rust `init` | CXX-Qt 0.10.0 | FreeBSD 15.1 | x86_64 | 6.11.2 | rustc/cargo 1.98.1, Clang 19.1.7, Ninja 1.13.2 | verified | Fresh project in a path with spaces and Unicode passed `doctor --strict`, `build`, `run -- --smoke-test`, `test --headless`, and CMake configure/build on 2026-11-06. Rust unit test and QML greeting/button `0 → 1 → 2 → 0` passed. |
| Rust `add` | CXX-Qt 0.10.0 | FreeBSD 15.1 | x86_64 | 6.11.2 | rustc/cargo 1.98.1, Clang 19.1.7, Ninja 1.13.2 | verified | Existing project preserved its user file; `doctor --strict`, `build`, `test --headless`, and QML `0 → 1 → 2 → 0` passed on 2026-11-06. |
| Rust `init` and `add` | CXX-Qt 0.10.0 | Ubuntu 24.04 | x86_64 | 6.8.3 | Rust 1.98.1, CMake, C++ | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Rust `init` and `add` | CXX-Qt 0.10.0 | macOS 15 | arm64 | 6.11.2 | Rust 1.98.1 | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Rust `init` and `add` | CXX-Qt 0.10.0 | macOS 27.2 | arm64 | 6.12.0 | rustc/cargo 1.99.1, Apple Clang 21.0.0 | verified | `doctor --strict`, build, graphical-session `run -- --smoke-test`, and `test --headless` passed on 2026-11-06 in a path with spaces and Korean text. CXX-Qt compiled and the Rust unit test passed. |
| Rust `init` and `add` | CXX-Qt 0.10.0 | Windows 11 (26300) | x64 | 6.11.2 | rustc/cargo 1.98.1, MSVC 19.51.36260 | verified | Both layouts passed Windows and offscreen Qt Quick smoke tests. See the [Windows verification record](#windows-11-x64). |
| Go `init` | Go c-shared + C++ QObject | FreeBSD 15.1 | x86_64 | 6.11.2 | Go 1.26.10, Clang 19.1.7, Ninja 1.13.2 | verified | Fresh project in a path with spaces and Unicode passed `doctor --strict`, `build`, `run -- --smoke-test`, `test --headless`, Go unit/vet checks and QML `0 → 1 → 2 → 0` on 2026-11-06. Exported symbols were inspected. |
| Go `add` | Go c-shared + C++ QObject | FreeBSD 15.1 | x86_64 | 6.11.2 | Go 1.26.10, Clang 19.1.7, Ninja 1.13.2 | verified | Existing project with Unicode path preserved its user file; `doctor --strict`, `build`, `test --headless`, and QML `0 → 1 → 2 → 0` passed on 2026-11-06. |
| Go `init` and `add` | Go c-shared + C++ QObject | Ubuntu 24.04 | x86_64 | 6.8.3 | Go 1.26.10, CMake, C++ | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Go `init` and `add` | Go c-shared + C++ QObject | macOS 15 | arm64 | 6.11.2 | Go 1.26.10 | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Go `init` and `add` | Go c-shared + C++ QObject | macOS 27.2 | arm64 | 6.12.0 | Go 1.27.3, Apple Clang 21.0.0, CMake 4.4.5, Ninja 1.13.2 | verified | On 2026-11-06, before Homebrew installation `doctor --strict` exited 1 for missing Go. With Go installed and the dylib install name fixed, both layouts passed `doctor --strict`, build, offscreen `run -- --smoke-test`, and `test --headless`, including Go unit tests and QML greeting/button transitions in paths with spaces and Korean text. Both layouts also passed `run -- --smoke-test` in a macOS graphical session. |
| Go `init` and `add` | Go c-shared + C++ QObject | Windows 11 (26300) | x64 | 6.11.2 | Go 1.26.10, LLVM-MinGW 20260908, MSVC 19.51.36260 | verified | Both layouts passed Windows and offscreen Qt Quick smoke tests. See the [Windows verification record](#windows-11-x64). |
| Swift `init` | SwiftPM dynamic library + C ABI + C++ QObject facade (experimental) | FreeBSD 15.1 | x86_64 | 6.11.2 | Swift 6.4, Clang 19.1.7, CMake 3.31.12, Ninja 1.13.2 | verified | Fresh project in a path with spaces and Unicode passed `doctor --strict`, `build`, `run -- --smoke-test`, `test --headless` and Swift unit tests on 2026-11-06. QML greeting and button `0 → 1 → 2 → 0` passed. |
| Swift `add` | SwiftPM dynamic library + C ABI + C++ QObject facade (experimental) | FreeBSD 15.1 | x86_64 | 6.11.2 | Swift 6.4, Clang 19.1.7, CMake 3.31.12, Ninja 1.13.2 | verified | Existing project with Unicode path preserved its user file; `doctor --strict`, `build`, `run -- --smoke-test`, `test --headless` and `test --release --headless` passed on 2026-11-06. |
| Swift `init` and `add` | experimental C ABI adapter | Ubuntu 24.04 | x86_64 | 6.8.3 | Swift 6.4.2, CMake, C++ | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Swift `init` and `add` | experimental C ABI adapter | macOS 15 | arm64 | 6.11.2 | Swift 6.4.2 | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Swift `init` and `add` | experimental C ABI adapter | macOS 27.2 | arm64 | 6.12.0 | Apple Swift 6.4.2, Apple Clang 21.0.0, CMake 4.4.5, Ninja 1.13.2 | verified | `doctor --strict`, build, graphical-session `run -- --smoke-test`, and `test --headless` passed on 2026-11-06 in a path with spaces and Korean text. Swift backend unit tests passed. Both layouts also passed the offscreen test with the Qt 6.11.2 desktop SDK on 2026-11-07. |
| Swift `init` and `add` | experimental C ABI adapter | Windows 11 (26300) | x64 | 6.11.2 | Swift 6.4.2, MSVC 19.51.36260 | verified | Both layouts passed Windows and offscreen Qt Quick smoke tests. See the [Windows verification record](#windows-11-x64). |
| Python `init` and `add` | PySide6 QObject | FreeBSD 15.1 | x86_64 | 6.11.2 | Python 3.12.15, PySide6 6.11.2 | verified | Fresh `init` and existing-project `add` passed `doctor --strict`, `build`, `run -- --smoke-test`, and `test --headless` on 2026-11-05. QML button transitions and notifications passed. `init` ran from a path with spaces and Unicode; `add` preserved the original file and its CMake configuration passed. |
| Python `init` and `add` | PySide6 QObject | Ubuntu 24.04 | x86_64 | PySide6 6.11.2 | Python 3.12 | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Python `init` and `add` | PySide6 QObject | macOS 15 | arm64 | PySide6 6.11.2 | Python 3.12 | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Python `init` and `add` | PySide6 QObject | macOS 27.2 | arm64 | PySide6 6.11.2 | Python 3.12.16 | verified | `doctor --strict`, build, graphical-session `run -- --smoke-test`, and `test --headless` passed on 2026-11-06 in a path with spaces and Korean text. The Python contract and notification unit test passed. Python 3.15.2 is incompatible with the pinned wheel. |
| Python `init` and `add` | PySide6 QObject | Windows 11 (26300) | x64 | PySide6 6.11.2 | Python 3.10.11, PySide6 6.11.2 | verified | Both layouts passed Windows and offscreen Qt Quick smoke tests. See the [Windows verification record](#windows-11-x64). |
| Java `init` | Java JNI + C++ QObject facade (experimental) | FreeBSD 15.1 | x86_64 | 6.11.2 | OpenJDK 25.0.5, Gradle 9.8.0, Clang 19.1.7, CMake 3.31.12, Ninja 1.13.2 | verified | Fresh project in a path with spaces and Unicode passed `doctor --strict`, `build`, `test --headless` including Java logic and QML button `0 → 1 → 2 → 0` on 2026-11-06. |
| Java `add` | Java JNI + C++ QObject facade (experimental) | FreeBSD 15.1 | x86_64 | 6.11.2 | OpenJDK 25.0.5, Gradle 9.8.0, Clang 19.1.7, CMake 3.31.12, Ninja 1.13.2 | verified | Existing project with Unicode path preserved its user file; `doctor --strict`, `build`, `test --headless`, Java unit test and QML `0 → 1 → 2 → 0` passed on 2026-11-06. |
| Java `init` and `add` | JNI facade | Ubuntu 24.04 | x86_64 | 6.8.3 | JDK 25, Gradle 9.8.0 | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Java `init` and `add` | JNI facade | macOS 15 | arm64 | 6.11.2 | JDK 25, Gradle 9.8.0 | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Java `init` and `add` | JNI facade (experimental) | macOS 27.2 | arm64 | 6.12.0 | OpenJDK 27.0.1.0.3, Gradle 9.8.2, Apple Clang 21.0.0, CMake 4.4.5 | verified | `doctor --strict`, build, graphical-session `run -- --smoke-test`, and `test --headless` passed on 2026-11-06 in a path with spaces and Korean text. The Homebrew JDK was discovered with `JAVA_HOME` unset. `qtRun` used the AppKit thread and the Java logic test passed. |
| Java `init` and `add` | JNI facade | Windows 11 (26300) | x64 | 6.11.2 | Temurin JDK 25.0.4.1+1, Gradle 9.8.0, MSVC 19.51.36260 | verified | Both layouts passed Windows and offscreen Qt Quick smoke tests. See the [Windows verification record](#windows-11-x64). |
| Kotlin `init` | Kotlin JVM 2.4.10 + JNI + C++ QObject facade (experimental) | FreeBSD 15.1 | x86_64 | 6.11.2 | OpenJDK 25.0.5, Gradle 9.8.0, Clang 19.1.7, CMake 3.31.12, Ninja 1.13.2 | verified | Fresh project passed `doctor --strict`, `build`, and `test --headless` on 2026-11-06. Kotlin logic and QML greeting/button `0 → 1 → 2 → 0` passed. |
| Kotlin `add` | Kotlin JVM 2.4.10 + JNI + C++ QObject facade (experimental) | FreeBSD 15.1 | x86_64 | 6.11.2 | same as above | verified | Existing project passed `build` and `test --headless` on 2026-11-06. Kotlin logic and QML greeting/button `0 → 1 → 2 → 0` passed. |
| Kotlin `init` and `add` | JNI facade | Ubuntu 24.04 | x86_64 | 6.8.3 | JDK 25, Gradle 9.8.0, Kotlin plugin 2.4.10 | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Kotlin `init` and `add` | JNI facade | macOS 15 | arm64 | 6.11.2 | JDK 25, Gradle 9.8.0, Kotlin plugin 2.4.10 | verified | Reported GitHub Actions pass for `init` and `add` offscreen Qt Quick smoke tests. |
| Kotlin `init` and `add` | JNI facade (experimental) | macOS 27.2 | arm64 | 6.12.0 | OpenJDK 27.0.1.0.3, Gradle 9.8.2, Kotlin plugin 2.4.10, Apple Clang 21.0.0, CMake 4.4.5 | verified | `doctor --strict`, build, graphical-session `run -- --smoke-test`, and `test --headless` passed on 2026-11-06 in a path with spaces and Korean text. The Homebrew JDK was discovered with `JAVA_HOME` unset. `qtRun` used the AppKit thread and the Kotlin logic test passed. |
| Kotlin `init` and `add` | JNI facade | Windows 11 (26300) | x64 | 6.11.2 | Temurin JDK 25.0.4.1+1, Gradle 9.8.0, Kotlin JVM plugin 2.4.10, MSVC 19.51.36260 | verified | Both layouts passed Windows and offscreen Qt Quick smoke tests. See the [Windows verification record](#windows-11-x64). |

The Swift CLI itself builds on FreeBSD 15.1 x86_64 with Swift 6.4. The `0.2.1` FreeBSD amd64 archive passed checksum and extracted-install checks outside the checkout on 2026-11-06. Its installed C++ project passed `doctor --strict`, `build`, `test --headless`, and the QML `run -- --smoke-test` on that host. The Ubuntu 24.04 x86_64 and macOS 15 arm64 CLI jobs were reported passing with Swift 6.4.2, including debug and release builds, tests, lint, install, rollback, and archive checks. On macOS 27.2 arm64 with Apple Swift 6.4.2, the CLI built and its 27 tests passed on 2026-11-06. The Windows x64 CLI results are recorded below.

The C++ template requires Qt 6.8 or newer. CI configuration alone does not change a row to `verified`; a completed native build and QML smoke result is required.

On 2026-11-06, the extracted macOS 27.2 arm64 release archive passed
`doctor --strict`, `build`, graphical-session `run -- --smoke-test`, and
`test --headless` for all 14 backend/layout combinations outside the checkout.
Project paths included spaces and Korean text. Each `add` preserved the
original source and CMake target, appended the Qt Quick integration, and
rejected a second `add`. The original CMake executables were also built and
run, using a separate CMake invocation for the Python and Rust projects.

## Ubuntu 24.04 and macOS 15 CI

The repository maintainer reported that the GitHub Actions matrix passed for
checkout commit `cdfbf68` on Ubuntu 24.04 x86_64 and macOS 15 arm64. The matrix
covers the CLI and all seven backends in both layouts. Native Qt jobs use
Qt 6.8.3 on Ubuntu and Qt 6.11.2 on macOS. The Python job uses PySide6 6.11.2
on both runners and installs `libegl1` on Ubuntu. The GUI evidence on these
runners is from offscreen smoke tests. The public GitHub Actions API did not
provide the run record for independent inspection.

## Fedora 45 and Hyprland

The Fedora 45 x86_64 validation on 2026-11-07 used Hyprland 0.57.1 and
Qt 6.11.2. The Qt SDK used GCC 16.2.1, CMake 4.3.0, and Ninja 1.13.2.
Projects were generated outside the checkout in paths containing spaces and
Korean text. The desktop smoke tests selected `QT_QPA_PLATFORM=wayland`
explicitly. The offscreen tests used `qbloom test --headless`.

| Backend | Bridge | Toolchain | Status | Layouts |
| --- | --- | --- | --- | --- |
| C++ | Native QObject | GCC 16.2.1 | verified | `init`, `add` |
| Python | PySide6 QObject | Python 3.14.10, PySide6 6.11.2 wheel | verified | `init`, `add` |
| Rust | CXX-Qt 0.10.0 | rustc/cargo 1.99.1 | verified | `init`, `add` |
| Go | c-shared and C++ QObject | Fedora Go 1.27.3, GCC 16.2.1 | verified | `init`, `add` |
| Swift | C ABI and C++ QObject (experimental) | Swift 6.4, GCC 16.2.1 | verified | `init`, `add` |
| Java | JNI and C++ QObject (experimental) | OpenJDK 25.0.4.1, Gradle 9.8.0 | verified | `init`, `add` |
| Kotlin | JNI and C++ QObject (experimental) | OpenJDK 25.0.4.1, Gradle 9.8.0, Kotlin JVM plugin 2.4.10 | verified | `init`, `add` |

All 14 combinations passed `doctor --strict --json`, `build`,
`run -- --smoke-test`, and `test --headless`. The QML smoke tests checked the
backend greeting, button-driven counter updates from 0 to 1 to 2 to 0, and
change notifications. Wayland protocol traces confirmed window buffer
submission during smoke tests or a separate normal launch. Each `add` kept the
original user file and CMake target, and the original executable built and ran.

The Qt Quick development files, Go, full JDK, and Gradle were staged in a
temporary directory. The Python test used a staged Python 3.14 interpreter
because qbloom rejects Fedora's default Python 3.15 for the pinned PySide6 wheel.
Go needed `GOFLAGS=-buildvcs=false` after VCS stamping failed in the temporary
test directories. The Fedora profile still produces qbloom's generic
`unverified` compatibility warning in `doctor`, even when strict prerequisite
checks pass.

Swift 6.4 built the CLI in debug and release, passed all 27 CLI tests, and
passed strict formatting, staged installation, rollback, and extracted archive
checks. With Fedora binutils 2.47, the default SwiftPM build failed while
parsing the GNU linker's `-version_details` output. The CLI and generated Swift
package were tested with `--build-system native`. The installed CLI and extracted
archive scaffolded projects with the original build directory's template
resources hidden.

## Windows 11 x64

On 2026-11-07, native Windows 11 x64 build 26300 used Swift 6.4.2,
Windows SDK 10.0.28000.0, Visual Studio 2026 with MSVC 19.51.36260,
CMake 3.31.6-msvc6, Ninja 1.12.1, and the Qt 6.11.2 MSVC 2022 x64 kit.
The Qt kit and backend-specific tools were made available in the validation
shell. Python used the Qt runtime in the PySide6 6.11.2 wheel.

All 14 backend and layout combinations passed `doctor --strict --json`,
`build`, `run -- --smoke-test` with `QT_QPA_PLATFORM=windows`, and
`test --headless`. The applications ran from paths with spaces. The Python
projects also ran from paths with Korean text. C++ passed both layouts in
paths with Korean text using Kitware CMake 4.4.5 and Ninja 1.13.2. The Visual
Studio-bundled CMake 3.31.6-msvc6 crashed during a direct configure in that
path. For the shared Qt 6.11.2 kit, the C++ template skips the import scan
on non-ASCII paths because the scanner decodes its response file with the
Windows local code page. The QML smoke tests checked
the backend greeting, the button-driven counter changes from 0 to 1 to 2 to
0, and change notifications. Rust used Cargo's debug profile. The CMake
backends used Release builds. The Go DLL's seven exported functions were
checked with `dumpbin`. Java and Kotlin used the JNI adapters, and Swift
used the experimental C ABI adapter with a SwiftPM-built DLL.

SwiftPM built the CLI in debug and release. The release executable and
template bundle were copied together to a separate directory. There,
`--help` and scaffolding a Python project with a Korean name succeeded.
Of 28 CLI tests, 27 passed and the directory-symlink test was skipped
because the account lacked the Windows privilege to create the fixture.
Strict formatting passed on LF copies of the checkout's Swift sources.
See the [Windows PowerShell instructions](installation.md#windows-x64) for
the product build on accounts without symlink privileges. The generic
`unverified` advisory in `doctor` still appears on Windows even when strict
prerequisite checks pass.

## Java bridge decision

[Qt Bridge for Java/Kotlin](https://doc.qt.io/qtbridges/) is alpha and its [source documentation](https://github.com/qt/qtbridge-java) lists macOS, Linux, and Windows. [QtJambi](https://www.qtjambi.io/doc/Modules.md) publishes native components for Windows, Linux, macOS, and Android; the published FreeBSD binary path is absent. QtJambi's source build system mentions FreeBSD, but that is not a tested Qt Quick runtime here. The FreeBSD adapter therefore uses a small JNI boundary. Java owns the greeting and counter. A C++ `QObject` invokes Java methods on the GUI thread and emits `countChanged` after actual Java state changes. The macOS result above verifies the same JNI adapter.

## Swift bridge decision

[Qt Bridge for Swift](https://github.com/qt/qtbridge-swift) documents a 0.2.0-beta Swift/C++ interoperability integration and lists macOS, Linux, and Windows; FreeBSD is absent. The [Qt Bridges overview](https://doc.qt.io/qtbridges/) still labels Swift alpha and lists a narrower macOS target. The FreeBSD adapter uses an isolated, experimental `@_cdecl` C ABI with no Qt Bridge dependency. Swift owns the greeting and counter; the C++ `QObject` only exposes them to QML and emits notifications on the GUI thread. The ABI uses an opaque retained handle and caller-owned greeting buffer. This implementation does not verify the upstream bridge or other platforms.
