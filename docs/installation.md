# Install and package qbloom

The qbloom CLI is a Swift Package Manager executable. Building the CLI does
not require Qt. Building a generated application requires the tools listed in
its generated `README.md` and reported by `qbloom doctor --strict`.

## From a source checkout

Install Swift 6.4, Git, and a C/C++ build toolchain. SwiftPM resolves the
committed `Package.resolved` dependency on the first build unless it is already
cached. From the repository root:

```sh
swift build -c release
sh scripts/install.sh                 # installs under /usr/local/bin
```

Use `PREFIX` for a user-owned destination and add its `bin` directory to
`PATH`. `DESTDIR` stages a package filesystem without changing the final
installation prefix:

```sh
PREFIX="$HOME/.local" sh scripts/install.sh
DESTDIR=/tmp/qbloom-stage PREFIX=/usr/local sh scripts/install.sh
```

`/usr/local` is normally owned by an administrator. If the default install
reports a permission error, use the user-owned prefix above and add
`$HOME/.local/bin` to `PATH`, or run `sudo sh scripts/install.sh` if you intend
to install system-wide. Add `$HOME/.local/share/man` to `MANPATH` when your
system does not discover user-installed manual pages automatically.

If `make` is installed, `make`, `make test`, `make install`, and `make package`
are convenience targets. `make install PREFIX="$HOME/.local"` uses the same
installer. GNU Make is not required by the direct script; the Makefile uses
common GNU/BSD make syntax. The installer copies **both** the executable and
the SwiftPM template directory into the same `bin` directory. The directory
is named `qbloom_QbloomCLI.bundle` or `qbloom_QbloomCLI.resources`, depending on
the SwiftPM build. Copying only the executable breaks template lookup after
leaving the checkout.
The installer prepares all files first, then replaces the executable, template
bundle, and manual pages. If replacement fails, it restores the previous
installation. A successful reinstall replaces those managed files.

The installer also places the English page at `PREFIX/share/man/man1/qbloom.1`
and the Korean page at both `PREFIX/share/man/ko/man1/qbloom.1` and
`PREFIX/share/man/ko_KR.UTF-8/man1/qbloom.1` for man implementations with
different locale search paths. Use `man qbloom` or
`LC_ALL=ko_KR.UTF-8 man qbloom`; the Korean locale must be available on the
host. If a custom `PREFIX` is outside the man search path, set `MANPATH` to
`PREFIX/share/man`. To preview either page without installing, run
`mandoc -Tutf8 man/man1/qbloom.1` or
`mandoc -Tutf8 man/ko/man1/qbloom.1`.

Verify an installed copy without Qt:

```sh
qbloom --help
qbloom init hello --python
```

## Windows x64

Install Swift 6.4.2, Git, the Visual Studio C++ tools, and the Windows SDK.
Build from PowerShell at the repository root:

```powershell
swift build -c release --product qbloom
$bin = swift build -c release --show-bin-path
& "$bin\qbloom.exe" --help
```

If Git cannot create the symlinks in the pinned ArgumentParser checkout,
open a fresh PowerShell session and set the following process-local options
before building the product. The CLI product does not use the dependency's
documentation plugins.

```powershell
$env:GIT_CONFIG_COUNT = '1'
$env:GIT_CONFIG_KEY_0 = 'core.symlinks'
$env:GIT_CONFIG_VALUE_0 = 'false'
swift build --scratch-path .build/windows-product -c release --product qbloom
$bin = swift build --scratch-path .build/windows-product -c release --show-bin-path
```

Copy `qbloom.exe` and `qbloom_QbloomCLI.bundle` together from the directory
reported by SwiftPM. Keep the matching Swift runtime available.

For binary distribution, place both items in `bin/` inside the Windows ZIP,
with `scripts/install.ps1` copied to the archive root as `install.ps1`.
After extraction, run `.\install.ps1` in PowerShell. From a source checkout,
you can also run `.\scripts\install.ps1 -Source $bin`. The installer tests
the executable before replacing the current user installation and adds its
directory to the user's `Path`. Existing installations are saved beside the
new one.

If startup reports a missing or incompatible DLL, rerun with `-InstallSwift`
to authorize installing the pinned Swift 6.4.2 toolchain through WinGet.
This installs the toolchain, including its runtime. The installer retries
Qbloom after Swift installation and stops if startup still fails. When
WinGet is unavailable, use the [official Swift installer](https://www.swift.org/install/windows/).

For native Qt projects, open an x64 Visual Studio Developer PowerShell and
set the Qt kit path for that session. Use an MSVC x64 Qt kit with Qt Quick
development files. Put CMake and Ninja on the session's `Path`, and set
`$bin` to the directory containing `qbloom.exe` and its bundle.
For C++ projects in paths with Korean text, use Kitware CMake 4.4.5 and
Ninja 1.13.2, the versions used to verify those paths.

```powershell
$env:CMAKE_PREFIX_PATH = 'C:\Qt\6.11.2\msvc2022_64'
$env:Path = "$env:CMAKE_PREFIX_PATH\bin;$bin;$env:Path"
qbloom init hello --cpp
Set-Location hello
qbloom doctor --strict
qbloom build --release
qbloom run --release -- --smoke-test
qbloom test --release --headless
```

Python uses PySide6 in its selected Python environment. In a generated
Python project, run `python -m venv .venv` and install the pinned wheel with
`.\.venv\Scripts\python.exe -m pip install PySide6==6.11.2`. See the
[Windows compatibility record](compatibility.md#windows-11-x64) for the
backend toolchain versions.

## Release archive

`sh scripts/package.sh` (or `make package`) creates
`dist/qbloom-VERSION-OS-ARCH.tar.gz` and a `.sha256` file. Set `DIST_DIR` to
write elsewhere. The archive contains `bin/qbloom`, the adjacent template
bundle, the license, README, documentation, and both language versions of
`qbloom(1)` under `share/man`. From an extracted archive, run `sh install.sh`
to install under `~/.local`, then add `~/.local/bin` to your shell's `PATH`.
The archive installer runs the executable before copying it. If startup fails,
install the Swift runtime required by the release for your OS and architecture
and rerun the installer. The Unix installer reports this prerequisite and
leaves dependency installation to the user.

CI checks the checksum,
extracts the archive, and scaffolds projects with the extracted executable
outside the repository. A local check is:

```sh
sh scripts/check-package.sh /absolute/path/to/qbloom-VERSION-OS-ARCH.tar.gz
```

Run `qbloom --version` to see the qbloom release, executable architecture and
target OS, and the OS version of the current host. For example,
`0.2.1 (arm64-apple-macos, Version 27.2 (Build 26B123))`.

These archives are **host-specific**, and the default SwiftPM release build
links to the host Swift runtime. A matching Swift runtime and system libraries
are needed on another machine. Do not treat an untested archive as a portable
binary for every distribution or macOS version. [Swift's build documentation](https://docs.swift.org/latest/documentation/swiftlinux/building/)
explains the dynamic runtime dependency and `--show-bin-path` used by these
scripts. Static Linux SDK packaging may be added only after its own install
and generated-project smoke tests.

The `0.2.1` FreeBSD archive was built on FreeBSD 15.1 amd64 with Swift 6.4.
It links to Swift shared libraries, so installing the matching Swift runtime
is required on another FreeBSD host. The archive does not include Qt; install
Qt and the selected backend toolchain before building a generated application.

The manual release workflow builds and verifies Windows, Ubuntu, and macOS archives
and collects them in a GitHub Release draft. Follow the
[release checklist](releasing.md) to attach a separately verified FreeBSD
archive and publish the draft.
