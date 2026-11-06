#!/bin/sh
set -eu

if [ "$#" -ne 1 ] || [ ! -f "$1" ]; then
  echo "Usage: sh scripts/check-package.sh /absolute/path/to/archive.tar.gz" >&2
  exit 2
fi
archive=$1
case "$archive" in
  /*) ;;
  *) echo "Archive path must be absolute" >&2; exit 2 ;;
esac
directory=$(dirname "$archive")
filename=$(basename "$archive")
if [ ! -f "$archive.sha256" ]; then
  echo "Missing checksum: $archive.sha256" >&2
  exit 1
fi
if command -v sha256sum >/dev/null 2>&1; then
  (cd "$directory" && sha256sum -c "$filename.sha256")
elif command -v shasum >/dev/null 2>&1; then
  (cd "$directory" && shasum -a 256 -c "$filename.sha256")
else
  expected=$(cut -d ' ' -f 1 "$archive.sha256")
  actual=$(sha256 -q "$archive")
  test "$actual" = "$expected"
fi
work=$(mktemp -d "${TMPDIR:-/tmp}/qbloom-archive.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
tar -xzf "$archive" -C "$work"
name=${filename%.tar.gz}
bundle="$work/$name/bin/qbloom_QbloomCLI.bundle"
if [ ! -d "$bundle" ]; then
  bundle="$work/$name/bin/qbloom_QbloomCLI.resources"
fi
test -d "$bundle/Templates/common" || test -d "$bundle/Contents/Resources/Templates/common"
test -f "$work/$name/share/man/man1/qbloom.1"
test -f "$work/$name/share/man/ko/man1/qbloom.1"
test -f "$work/$name/share/man/ko_KR.UTF-8/man1/qbloom.1"
sh "$(dirname "$0")/check-install.sh" "$work/$name/bin/qbloom"
