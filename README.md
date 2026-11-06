[English](README.md) | [한국어](README-ko.md)

# qbloom

Scaffold, build, run, and test Qt 6 / Qt Quick desktop apps from the command line. Choose C++, Python, Rust, Go, Java, Swift, or Kotlin. Each starter app gets its greeting and counter from the selected backend, and QML updates through change notifications when you press the buttons.

## Install

Choose a binary archive for your OS and architecture when one is available on the project's [Releases page](https://github.com/SonomaHarvester/Qbloom/releases). Extract it before running the installer.

| OS | From the extracted archive |
| --- | --- |
| Windows x64 | Run `.\install.ps1` in PowerShell. Open a new PowerShell after installation to pick up the updated user Path. |
| macOS, Linux, FreeBSD | Run `sh install.sh` and add `~/.local/bin` to your Path. The installer also copies the English and Korean man pages. |

The CLI requires a compatible Swift runtime. If the Windows installer reports a missing or incompatible runtime DLL, `.\install.ps1 -InstallSwift` lets it install the pinned Swift 6.4.2 toolchain through WinGet and retry. The Unix installer checks that the binary starts and reports a failure before copying files. See [installation and packaging](docs/installation.md) for runtime requirements and source-build instructions.

## Quick start

```sh
qbloom init hello
cd hello
qbloom doctor --strict
qbloom build
qbloom run
qbloom test --headless
```

C++ is the default. For a different backend, start with a fresh directory name and pass one of `--python`, `--rust`, `--go`, `--java`, `--swift`, or `--kotlin`. The generated README lists the tools for that backend. Native Qt templates require Qt 6.8 or later with Qt Quick development files. The Python template uses PySide6.

`qbloom test --headless` requests Qt's offscreen platform plugin. The smoke test checks the backend greeting, the counter sequence `0 → 1 → 2 → 0`, and change notifications.

## Backends and compatibility

| Backend | Qt integration |
| --- | --- |
| C++ | Native QObject |
| Python | PySide6 QObject |
| Rust | CXX-Qt |
| Go | cgo shared library and C++ QObject facade |
| Java, Kotlin | Experimental JNI and C++ QObject facade |
| Swift | Experimental Swift C ABI and C++ QObject facade |

All seven backends passed build and Qt Quick smoke tests through both `init` and `add` on tested configurations of Windows 11 x64, macOS arm64, Fedora x86_64, and FreeBSD x86_64. The Ubuntu and macOS CI results, exact toolchain versions, and platform-specific limitations are recorded in the [compatibility matrix](docs/compatibility.md).

## Project commands

- `qbloom init` (`in`) creates a project in a new directory.
- `qbloom add <existing-directory>` adds a separate Qt Quick target to an existing CMake project. Run Qbloom commands from the parent project.
- `qbloom override` (`ovr`) replaces a project created by `init` after confirmation and moves the previous project, including user files, to a sibling backup.
- `qbloom doctor --json` emits machine-readable diagnostics. Add `--strict` to fail on missing or incompatible prerequisites.
- `qbloom build --release` requests a release build. Use `qbloom run --release` or `qbloom test --release --headless` to use that configuration. `qbloom clean` removes managed build output.

Backend and layout settings live in [`qbloom.toml`](docs/manifest.md). Set `LANG=ko_KR.UTF-8` for Korean CLI messages when a higher-priority locale is unset.

## Build from source

The CLI builds with Swift 6.4 and Git without Qt. From the checkout on macOS, Linux, or FreeBSD, run `make` and `make install PREFIX="$HOME/.local"`, or run `PREFIX="$HOME/.local" sh scripts/install.sh`. Follow the [PowerShell steps](docs/installation.md#windows-x64) on Windows. Use `swift test` to run the CLI tests.

## License

Qbloom is licensed under [BSD 2-Clause](LICENSE). Generated projects carry `QBLOOM_TEMPLATE_NOTICE.txt`. Qt and backend dependencies have separate terms. See the [licensing guide](docs/licensing.md) before distributing a generated application.
