# Release checklist

1. Run the CLI checks in CI and review the applicable backend build and Qt
   Quick smoke results. Record actual OS, architecture, Qt and toolchain
   versions in [compatibility.md](compatibility.md) when adding evidence.
2. Update the CLI version and release notes as needed. Push an existing
   version tag such as `v0.2.1` or `0.2.1` whose numeric version matches
   `qbloom --version`. Keep the tag fixed once builds start.
3. In the public repository, open **Actions → Draft release → Run
   workflow** on the default branch and enter the tag. The workflow builds
   that commit with Swift 6.4.2 on Windows Server 2025 x64, Ubuntu 24.04
   x64, and macOS 15 arm64. Each job verifies the extracted CLI with
   `--help` and scaffolds C++ and Python projects outside the checkout.
4. When all three jobs pass, the workflow verifies the downloaded SHA-256
   files and attaches the Windows ZIP, the Unix tarballs, and their
   individual `.sha256` files to the draft for that tag. A rerun can
   replace those six assets in the same draft. A published release is
   rejected. The draft URL appears in the run summary.
5. Review the draft, the assets, and [installation.md](installation.md)
   before publishing manually. Archives require a compatible Swift runtime.
   CLI packaging smoke tests establish that the CLI starts and scaffolds
   on the runner. Use separate Qt application tests for backend claims.

## Attach a separate FreeBSD build

On the target FreeBSD host, check out the same tag in a clean checkout
and use the documented Swift toolchain. Build and verify the archive there.

```sh
git switch --detach refs/tags/v0.2.1
make package
sh scripts/check-package.sh "$PWD"/dist/qbloom-0.2.1-freebsd-amd64.tar.gz
```

In **Releases**, edit the existing draft for that tag and attach both
`qbloom-0.2.1-freebsd-amd64.tar.gz` and its `.sha256` file. Substitute the
actual version and architecture. Save the draft and record the FreeBSD
version, architecture, Swift version, and smoke result in the release notes.
Hosted workflow reruns preserve the separately attached FreeBSD assets.
