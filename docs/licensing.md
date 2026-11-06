# Licensing

qbloom's original CLI code, documentation, and project templates are licensed
under [BSD 2-Clause](../LICENSE), with copyright attributed to sonomaharvester.
The license permits commercial and closed-source use, subject to its source
and binary redistribution notice requirements.

Each generated project includes `QBLOOM_TEMPLATE_NOTICE.txt` with the BSD
2-Clause terms for code and QML copied from qbloom's templates. The file does
not choose a license for code you add or for your application as a whole. If
you redistribute the copied template files or an application built from them,
preserve the applicable qbloom copyright notice and license terms. You may
choose a separate license for your own code.

Qt is not part of qbloom's BSD license. Qt libraries and QML modules have
their own LGPL, GPL, or commercial terms depending on the component and the
Qt distribution. PySide6 also has LGPLv3/GPLv3/commercial options. Using a
BSD-licensed `Main.qml` with `import QtQuick` does not relicense Qt or turn
your QML source into LGPL source. If you distribute Qt libraries, plugins,
or a packaged application, review the applicable Qt license obligations,
including notices, source availability and users' ability to replace or
relink LGPL-covered components where required. Dynamic linking alone is not
a complete compliance plan.

Other dependencies also keep their own licenses. The Swift CLI uses
swift-argument-parser (Apache-2.0 with Runtime Library Exception). The Rust
template uses CXX-Qt (MIT OR Apache-2.0). The generated Go template has no
third-party Go modules. Dependency source code is not vendored by qbloom.

Before publishing a built app, identify the exact Qt modules, plugins,
packages, and runtime libraries shipped for that platform and provide their
required notices and license texts. See the [Qt licensing overview](https://doc.qt.io/qt-6/licensing.html),
[Qt LGPL obligations](https://www.qt.io/development/open-source-lgpl-obligations),
and [Qt for Python licensing](https://doc.qt.io/qtforpython-6/).
