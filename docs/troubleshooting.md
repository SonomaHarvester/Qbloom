# Troubleshooting

- `cmake is missing`: install CMake and add it to `PATH`.
- Qt package not found during `qbloom build`: install Qt 6 Quick, Qml and QuickControls2 development packages. Set `CMAKE_PREFIX_PATH` for nonstandard Qt installs.
- `qbloom test --headless` cannot load a platform plugin: install the Qt offscreen plugin or run the GUI test in a graphical session. The test must pass before calling the target verified.
- `PySide6` missing: install the pinned PySide6 6.11.2 package in the Python environment selected by `qbloom doctor`. On FreeBSD, use a matching platform package where a wheel is unavailable.
- Rust build fails before compiling the app: run `qbloom doctor --strict`, then check the pinned Cargo dependencies, C++ compiler, `qmake6`, and Qt development files. `cargo build --locked` uses the generated `Cargo.lock`; dependency downloads may be needed on the first explicit build.
- Go build reports a cgo compiler or target mismatch: check `go env CC GOOS GOARCH` and use a C compiler plus a native Go target matching the Qt host. The generated Go module has no external dependencies.
- `add` says the project already has qbloom: `add` only applies once to a project without `qbloom.toml`. `override` replaces the project after a Y/N warning.
- `qbloom init` works in a checkout but fails after copying only the executable: install the adjacent `qbloom_QbloomCLI.bundle` too. Use `sh scripts/install.sh` or the complete release archive.
- A downloaded CLI binary fails to start before printing help: the default release build needs a compatible Swift runtime and system libraries on the target. Build from source on that host or use an artifact tested for that OS and architecture.
- Kotlin's first build cannot resolve `org.jetbrains.kotlin.jvm:2.4.10`: allow Gradle access to Maven Central for the explicit build or prepopulate its cache. Scaffolding itself never downloads the plugin.
- Java or Kotlin JNI build fails to locate headers: set `JAVA_HOME` to a JDK 21 or newer containing `include/jni.h`; `qbloom doctor --strict` reports this check.
- `doctor --json` contains `unverified`. Run `qbloom test --headless` on the current host and compare the result with the recorded environments in [the compatibility matrix](compatibility.md).
- Progress glyphs render as boxes: the terminal's active font lacks Fira Code progress glyphs. Set `UNICODE_PROGRESS_BAR=false` for ASCII.

## Go dylib lookup on macOS

If an older Go project builds but exits with `Library not loaded: libqbloom_go.dylib`, update its Go CMake rule. In `CMakeLists.txt` for `init` projects or `qbloom_quick/CMakeLists.txt` for `add` projects, put this before the Go library's `add_custom_command`:

```cmake
if(APPLE)
    set(GO_LINK_FLAGS "-ldflags=-extldflags=-Wl,-install_name,@rpath/libqbloom_go.dylib")
endif()
```

Insert `${GO_LINK_FLAGS}` after `-buildmode=c-shared` in that command and keep
the existing `BUILD_RPATH`. Run `qbloom clean`, `qbloom build`, and
`qbloom test --headless`.

## Python and JVM prerequisites on macOS

PySide6 6.11.2 requires Python 3.10 through 3.14. If the default interpreter is
Python 3.15, install `python@3.12` with Homebrew and create a fresh project
virtual environment with `python3.12 -m venv .venv`. Then install the pinned
binding with `.venv/bin/python -m pip install PySide6==6.11.2`. Move any old
`.venv` aside before recreating it.

Java and Kotlin require both Gradle and a JDK 21 or newer. qbloom honors
`JAVA_HOME` and can discover the unversioned Homebrew `openjdk` formula when
the system Java launcher has no configured runtime. For a versioned formula
or another JDK, set `JAVA_HOME` to that JDK's `Contents/Home`.

If an older Java or Kotlin project aborts while setting the AppKit menu,
add this inside `qtRun` in its `build.gradle.kts`:

```kotlin
if (System.getProperty("os.name").startsWith("Mac")) {
    jvmArgs("-XstartOnFirstThread")
}
```
