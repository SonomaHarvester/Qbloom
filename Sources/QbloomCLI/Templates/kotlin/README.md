[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

Qt Quick application with Kotlin-owned greeting and counter logic. A small JNI
bridge exposes the Kotlin `Backend` through a C++ `QObject`. The bridge is
experimental and has been smoke tested on FreeBSD 15.1 x86_64 with Qt 6.11.2,
OpenJDK 25, Gradle 9.8, and Kotlin Gradle plugin 2.4.10.

The `init` project also passed on macOS 27.2 arm64 with Qt 6.12.0,
Homebrew OpenJDK 27, and Gradle 9.8.2. On macOS, `qtRun` starts the JVM
application on the first thread for AppKit.

See `QBLOOM_PROJECT_GUIDE.md` for the manifest, commands, and smoke test contract.

## Requirements and commands

Install a JDK 21 or newer, Gradle 8.14.2 or newer, CMake 3.21 or newer, a C++17
compiler, and Qt 6.8 or newer with Quick, Qml and QuickControls2 development
files. `JAVA_HOME` should point to the JDK containing `include/jni.h` if Java
discovery cannot find it. `CMAKE_PREFIX_PATH` may locate a nonstandard Qt.

```sh
qbloom doctor --strict
qbloom build
qbloom run
qbloom test --headless
```

Gradle compiles and tests Kotlin; CMake builds the Qt/JNI library and invokes
Gradle's `classes` task. `qbloom test` runs the Kotlin logic test, then the real
QML window smoke test when a display is available. `--headless` requests Qt's
offscreen plugin. The smoke test checks Kotlin-provided greeting, two button
increments, reset, bound QML text and three change notifications. The first
explicit build resolves the pinned Kotlin Gradle plugin from Maven Central;
subsequent `run` and `test` commands use Gradle's local cache.

The JVM calls the JNI library on its main thread. The library creates and owns
the Qt event loop on that same thread, keeps a global reference to the Kotlin
backend until the QML engine is destroyed, clears JVM exceptions after JNI
calls, and emits Qt notifications only from the Qt GUI thread. The native
library and Qt runtime/plugins must be packaged together for deployment.
Other OS/architecture combinations are unverified.

## Licensing

The qbloom-derived starter files are BSD 2-Clause; retain
`QBLOOM_TEMPLATE_NOTICE.txt` when redistributing them. Choose a license for
your application. Qt has separate LGPL/GPL/commercial terms. OpenJDK, Gradle,
and dependencies have their own terms; review those before distribution.
