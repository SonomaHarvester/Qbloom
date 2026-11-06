#!/bin/sh
set -eu

repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
swift=${SWIFT:-swift}
dist=${DIST_DIR:-$repo/dist}
case "$dist" in
  /*) ;;
  *) dist="$repo/$dist" ;;
esac

(cd "$repo" && "$swift" build -c release)
products=$(cd "$repo" && "$swift" build -c release --show-bin-path)
binary="$products/qbloom"
bundle="$products/qbloom_QbloomCLI.bundle"
if [ ! -d "$bundle" ]; then
  bundle="$products/qbloom_QbloomCLI.resources"
fi
bundle_name=${bundle##*/}
if [ ! -x "$binary" ] || {
  [ ! -d "$bundle/Templates/common" ] && [ ! -d "$bundle/Contents/Resources/Templates/common" ]
}; then
  echo "SwiftPM executable or template bundle is missing from $products" >&2
  exit 1
fi

version_output=$("$binary" --version)
version=${version_output%% *}
case "$version" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "Unexpected qbloom version: $version" >&2; exit 1 ;;
esac
platform=$(uname -s | tr '[:upper:]' '[:lower:]')
arch=$(uname -m)
name="qbloom-$version-$platform-$arch"
mkdir -p "$dist"
stage=$(mktemp -d "$dist/.qbloom-package.XXXXXX")
trap 'rm -rf "$stage"' EXIT HUP INT TERM
mkdir -p "$stage/$name/bin"
cp "$binary" "$stage/$name/bin/qbloom"
chmod 755 "$stage/$name/bin/qbloom"
cp -R "$bundle" "$stage/$name/bin/$bundle_name"
cp "$repo/README.md" "$repo/README-ko.md" "$repo/LICENSE" "$stage/$name/"
cp "$repo/scripts/install.sh" "$stage/$name/install.sh"
cp -R "$repo/docs" "$stage/$name/docs"
mkdir -p "$stage/$name/share/man/man1" "$stage/$name/share/man/ko/man1" "$stage/$name/share/man/ko_KR.UTF-8/man1"
cp "$repo/man/man1/qbloom.1" "$stage/$name/share/man/man1/qbloom.1"
cp "$repo/man/ko/man1/qbloom.1" "$stage/$name/share/man/ko/man1/qbloom.1"
cp "$repo/man/ko/man1/qbloom.1" "$stage/$name/share/man/ko_KR.UTF-8/man1/qbloom.1"
archive="$dist/$name.tar.gz"
tar -czf "$archive" -C "$stage" "$name"
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$dist" && sha256sum "$name.tar.gz") > "$archive.sha256"
elif command -v shasum >/dev/null 2>&1; then
  (cd "$dist" && shasum -a 256 "$name.tar.gz") > "$archive.sha256"
elif command -v sha256 >/dev/null 2>&1; then
  printf '%s  %s\n' "$(sha256 -q "$archive")" "$name.tar.gz" > "$archive.sha256"
else
  echo "No SHA-256 tool found (sha256sum, shasum, or sha256)" >&2
  exit 1
fi
echo "Created $archive and $archive.sha256"
