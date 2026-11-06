[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

Qt Quick application with Go-owned greeting and counter logic. The C++ `QObject`
facade exposes Go values to QML and emits `countChanged` on the Qt GUI thread.

See `QBLOOM_PROJECT_GUIDE.md` for the manifest, commands, and smoke test contract.

## Requirements

- Qt 6.8 or newer with Quick, Qml, and QuickControls2 development files
- CMake 3.21 or newer, a C++17 compiler, and Ninja (recommended)
- Go 1.23 or newer and a working C compiler for cgo (`go env CC`)

The `go.mod` file has no external modules. The CMake build sets
`GOTOOLCHAIN=local` and `GOPROXY=off`, so it does not fetch code. On FreeBSD,
the generated library is `libqbloom_go.so` beside the app. The app's build
RPATH points to that local library. On macOS, the executable finds
`@rpath/libqbloom_go.dylib` through its build RPATH. Deployment elsewhere requires bundling
the Go shared library and the applicable Qt runtime and plugins.

On Windows x64, use the MSVC Qt kit from an x64 Visual Studio developer shell.
Add the Qt kit's `bin` directory and a MinGW-compatible C compiler to the shell's
`Path`. For example, with LLVM-MinGW available, set
`$env:CC = 'x86_64-w64-mingw32-clang.exe'` in PowerShell. CMake links the
Go exports through an MSVC import library and places `libqbloom_go.dll` beside
the executable. Keep both files together when deploying the application.

## Commands

```sh
qbloom doctor --strict
qbloom build
qbloom run
qbloom test --headless
```

`qbloom test` runs `go test ./...` and the QML window smoke test when a display
exists. `--headless` requests Qt's offscreen platform plugin; if that plugin
is unavailable, the smoke test fails rather than claiming success.

The exported C ABI returns a newly allocated UTF-8 greeting. The C++ facade
calls `GoFreeString` exactly once. State is referenced by an integer handle;
no Go pointer is kept by C++. Counter functions return status `0` on success
and `-1` for an invalid handle or output pointer. Go owns the counter state;
the facade reports each change with a Qt signal on the GUI thread. Never call
the facade's methods directly from a worker thread.

## Licensing

The qbloom-derived starter files are BSD 2-Clause; retain
`QBLOOM_TEMPLATE_NOTICE.txt` when redistributing them. Choose a license for
your additions and application. Qt is available under separate
LGPL/GPL/commercial terms; review the terms before redistribution, especially
Qt plugins and dynamic library packaging.
The Go toolchain and runtime have their own license. See Qt and Go upstream
license notices for the exact versions you distribute.
