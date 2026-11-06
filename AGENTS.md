# Contributing to Qbloom

Qbloom is a SwiftPM CLI for scaffolding and working with Qt 6 / Qt Quick desktop projects. The CLI itself needs Swift and Git. Generated apps need the tools for their selected backend.

## Before editing

- Read [README.md](README.md), [docs/compatibility.md](docs/compatibility.md), and the relevant source, templates, and tests. Use [docs/architecture.md](docs/architecture.md) for the CLI layout and [docs/manifest.md](docs/manifest.md) for the project schema.
- Keep changes focused. For toolchain or bridge changes, consult upstream documentation for the exact versions and keep dependency pins and applicable lockfiles in sync.
- Work against the intended remote. Public releases belong to `SonomaHarvester/Qbloom`.

## CLI and template contracts

- Keep `init` (`in`), `add`, and `override` (`ovr`) distinct. Init creates a fresh project. Add preserves the existing CMake project and adds a separate Qt Quick target. Override requires confirmation and a valid init project, then saves the original as a sibling backup.
- Preserve the supported backend flags for C++, Python, Rust, Go, Java, Swift, and Kotlin. C++ is the default. The Swift flag selects a generated backend. Keep the CLI host and backend toolchain requirements separate.
- Dispatch from `qbloom.toml`. Preserve schema compatibility, reject unsupported bridge selections, and keep diagnostics actionable. Use argument arrays for native processes and preserve their failure status. Keep template rendering offline and bundle the templates with SwiftPM.
- Protect user files with path and symlink checks, staging, and rollback. Cover paths with spaces and Unicode in filesystem and packaging changes.
- Keep the shared QML contract. The selected backend provides `greeting` and `count`, implements `increment()` and `reset()`, and notifies QML of count changes on the GUI thread. A generated project must have a meaningful CMake entry point and the native build files its backend needs.
- Update English and Korean user-facing docs, CLI messages, and man pages where affected. Keep generated README commands, licensing notices, and pinned toolchain requirements consistent with the actual templates.

## Verification

- For CLI changes, run `swift build`, `swift test`, `swift format lint --strict --recursive Sources Tests`, and `swift build -c release` with the documented Swift toolchain.
- Pair adapter and template changes with a regression test. On a suitable host, generate a fresh project and run `doctor --strict`, `build`, `run -- --smoke-test`, and `test --headless`. Exercise `add` when its path is affected. The smoke test must check the backend greeting and notified count changes through `0 → 1 → 2 → 0`.
- Record the OS, architecture, Qt and language toolchain versions, and actual outcome before updating compatibility claims. Report unavailable checks as skipped with the reason. CLI package checks and Qt application smoke tests verify separate things.
- For installer and package changes, verify the checksum and run the extracted CLI outside the checkout. Verify that it can scaffold with the bundled resources. See [docs/installation.md](docs/installation.md) and [docs/releasing.md](docs/releasing.md).
- Keep releases tied to existing tags and collect verified packages in a draft. A maintainer reviews and publishes the draft.
