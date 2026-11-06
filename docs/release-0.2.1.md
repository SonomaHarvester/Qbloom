# qbloom 0.2.1 — FreeBSD release

This archive targets FreeBSD 15.1 amd64. It contains the qbloom CLI, its
SwiftPM template bundle, documentation, and English/Korean manual pages.

Changes since 0.2.0:

- `override` resets only a valid qbloom `init` project, confirms the full
  replacement, and keeps the original project in a sibling backup.
- Interactive native builds use one updating progress gauge.
- The source installer stages its managed files and restores the previous
  installation if a replacement command fails.

The archive passed its SHA-256, extraction, and installed-scaffolding checks.
On FreeBSD 15.1 amd64, a project created from the extracted CLI passed
`doctor --strict`, `build`, `test --headless`, and the QML button smoke test.
The Swift test suite passed 24 tests.

The executable links to the Swift 6.4 shared runtime. Install a compatible
Swift runtime on the target FreeBSD system. Qt and backend toolchains are not
included. Linux, macOS, and Windows are not verified by this FreeBSD release.
