#!/bin/sh
set -eu

if [ "$#" -ne 1 ] || [ ! -x "$1" ]; then
  echo "Usage: sh scripts/check-install.sh /absolute/path/to/qbloom" >&2
  exit 2
fi
case "$1" in
  /*) binary=$1 ;;
  *) echo "Executable path must be absolute" >&2; exit 2 ;;
esac
prefix=$(dirname "$(dirname "$binary")")
test -f "$prefix/share/man/man1/qbloom.1"
test -f "$prefix/share/man/ko/man1/qbloom.1"
test -f "$prefix/share/man/ko_KR.UTF-8/man1/qbloom.1"
work=$(mktemp -d "${TMPDIR:-/tmp}/qbloom-installed.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
cd "$work"
"$binary" --help >/dev/null
version=$("$binary" --version)
case $(uname -s) in
  Darwin) target=apple-macos ;;
  FreeBSD) target=unknown-freebsd ;;
  Linux) target=unknown-linux ;;
  *) target=unknown-unknown ;;
esac
case $(uname -m) in
  aarch64|arm64) arch=arm64 ;;
  amd64|x86_64) arch=x86_64 ;;
  *) arch=unknown ;;
esac
case "$version" in
  [0-9]*.[0-9]*.[0-9]*" ($arch-$target, "?*")") ;;
  *) echo "Unexpected qbloom version: $version" >&2; exit 1 ;;
esac
"$binary" init 'Hello 세계' --cpp >/dev/null
"$binary" init python_smoke --python >/dev/null
test -f 'Hello 세계/qbloom.toml'
test -f 'Hello 세계/qml/Main.qml'
test -f python_smoke/qbloom_app/backend.py
echo "PASS: installed qbloom and both man pages; C++ and Python scaffold outside the checkout"
