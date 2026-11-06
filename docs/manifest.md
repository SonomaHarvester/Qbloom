# Generated project manifest

Every generated project has a `qbloom.toml` at the directory where qbloom
commands run. The CLI reads its selected backend from this file; it does not
infer the backend from source file extensions.

```toml
schema_version = 1
name = "hello"
backend = "cpp"
bridge = "auto"
qt_major = 6
build_dir = ".qbloom/build"
layout = "init"
```

`name` is the display/project directory name. `backend` is one of `cpp`,
`python`, `rust`, `go`, `java`, `kotlin`, or `swift`. `bridge` records the
selected integration mode; `auto` uses the backend's documented default.
`layout` is `init` for a new project or `added` when `qbloom add` connected
Qt Quick to an existing project. `layout` may be absent in older schema 1
manifests, in which case it means `init`.

The schema reader deliberately accepts only these top-level keys, quoted
strings, and the fixed integer values `schema_version = 1` and
`qt_major = 6`. Unknown keys, duplicate keys, tables, and unsupported syntax
are rejected with an error. Unknown major versions are not silently read as
schema 1. Keep `build_dir` at `.qbloom/build`; it is currently fixed. A future
schema version will be needed before custom build paths can be supported.

The generated `README.md` and `QBLOOM_PROJECT_GUIDE.md` describe the
backend-specific native build and test process. The current compatibility
evidence is in [compatibility.md](compatibility.md).
