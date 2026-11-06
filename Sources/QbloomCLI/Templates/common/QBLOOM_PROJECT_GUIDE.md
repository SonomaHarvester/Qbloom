# Working with {{NAME}}

Run `qbloom` from the directory containing `qbloom.toml`. For a project created
with `qbloom add`, that is the original project root; qbloom's new application
sources live under `qbloom_quick/`.

```sh
qbloom doctor --strict   # Check required local tools and versions
qbloom build             # Build the selected backend and Qt integration
qbloom run               # Build if needed, then open the real Qt Quick window
qbloom test --headless   # Logic test plus Qt Quick window/button smoke test
qbloom clean             # Remove .qbloom/build
```

`qbloom.toml` selects the backend. Its schema version is `1`, `qt_major` is `6`,
and `build_dir` is `.qbloom/build`. `layout` is `init` or `added`; older files
without `layout` mean `init`. Keep the manifest with the project so commands do
not have to guess the language from filenames. See the generated `README.md`
for this backend's native build tools, supported environment and bridge.

The QML window must display a backend-provided `Hello, world!` and a counter
starting at zero. Its buttons must move the counter through `0 → 1 → 2 → 0`
with change notifications. `qbloom test` runs logic tests first. Without a
display, the GUI step reports `SKIP`; use `--headless` when the Qt offscreen
platform plugin is available. A successful logic test alone does not verify
the GUI integration.

The starter files and this guide are covered by `QBLOOM_TEMPLATE_NOTICE.txt`.
Choose your application's license separately and review the Qt and backend
dependency licenses before distributing it.
