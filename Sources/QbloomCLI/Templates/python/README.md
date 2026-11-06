[English](README.md) | [한국어](README-ko.md)

# {{NAME}}

This Qt Quick application uses the official PySide6 binding. Python owns the Qt event loop; a Python `QObject` supplies `greeting` and `count` to QML, with `countChanged` notifications. No C ABI or embedding layer is needed.

See `QBLOOM_PROJECT_GUIDE.md` for the manifest, commands, and smoke test contract.

Run `qbloom` commands from the directory containing `qbloom.toml`. When this sample was added to an existing project, that directory is the parent of `qbloom_quick`.

Install Python 3.10 through 3.14 and PySide6 6.11.2 for your platform. On platforms with official wheels:

```sh
python3.12 -m venv .venv
.venv/bin/python -m pip install PySide6==6.11.2
qbloom doctor
qbloom build
qbloom run
qbloom test --headless
```

On Windows, activate the virtual environment or use `.venv\\Scripts\\python.exe`. On FreeBSD, use a matching `py*-pyside6` system package if no compatible wheel is offered.

`CMakeLists.txt` is a discoverable integration entry point with a launch target. `qbloom build` validates the Python sources directly and does not compile Python through CMake.

The qbloom-derived starter files are BSD 2-Clause; retain `QBLOOM_TEMPLATE_NOTICE.txt` when redistributing them. Choose a license for your additions and application. PySide6 and Qt have separate LGPL/GPL/commercial terms that you must review before distribution.
