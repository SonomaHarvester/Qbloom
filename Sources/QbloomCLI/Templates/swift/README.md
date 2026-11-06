[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

Qt Quick application with Swift-owned greeting and counter logic. This is an
experimental C ABI adapter: it uses Swift's underscored `@_cdecl` export and a
C++ `QObject` facade. It does not use Qt Bridge for Swift.

See `QBLOOM_PROJECT_GUIDE.md` for the manifest, commands, and smoke test contract.

## Requirements and commands

- Swift 6.4, CMake 3.21, C++17, and Qt 6.8 or newer with Quick, Qml, and QuickControls2.
- Tested on FreeBSD 15.1 x86_64 and, for `init`, on macOS 27.2 arm64 with Apple Swift 6.4.2 and Qt 6.12.0.

```sh
qbloom doctor --strict
qbloom build
qbloom run
qbloom test --headless
```

SwiftPM builds the dynamic library with no external package dependencies.
CMake builds the Qt application and links that library. `qbloom test` runs
Swift unit tests and a Qt Quick smoke test when a display exists. `--headless`
requests Qt's offscreen platform plugin. The smoke test checks Swift-provided
greeting, two button increments, reset, QML bindings and notifications.

The C ABI passes an opaque retained Swift object handle. C++ destroys the
handle once after the QML engine stops using the facade. Greeting uses a
caller-owned buffer, so there is no cross-language allocation to free. Calls
and Qt notifications stay on the GUI thread. Package the Swift runtime, Qt
libraries and plugins alongside the app for deployment.

## Licensing

The qbloom-derived starter files are BSD 2-Clause; retain
`QBLOOM_TEMPLATE_NOTICE.txt` when redistributing them. Choose a license for
your application. Qt has separate LGPL/GPL/commercial terms, and the Swift
toolchain and runtime have their own licenses.
