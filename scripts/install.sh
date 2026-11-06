#!/bin/sh
set -eu

script_dir=$(CDPATH= cd "$(dirname "$0")" && pwd)
repo=$(CDPATH= cd "$script_dir/.." && pwd)
if [ -f "$script_dir/bin/qbloom" ]; then
  products=$script_dir/bin
  manuals=$script_dir/share/man
  prefix=${PREFIX:-"$HOME/.local"}
else
  products=
  manuals=$repo/man
  prefix=${PREFIX:-/usr/local}
fi
destdir=${DESTDIR:-}
swift=${SWIFT:-swift}
case "$prefix" in
  /*) ;;
  *) echo "PREFIX must be an absolute path" >&2; exit 2 ;;
esac
case "$destdir" in
  ''|/*) ;;
  *) echo "DESTDIR must be an absolute path" >&2; exit 2 ;;
esac

if [ -z "$products" ]; then
  if ! command -v "$swift" >/dev/null 2>&1; then
    echo "Swift 6.4 is required for a source build. See https://www.swift.org/install/" >&2
    exit 1
  fi
  (cd "$repo" && "$swift" build -c release)
  products=$(cd "$repo" && "$swift" build -c release --show-bin-path)
fi
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

if ! "$binary" --version >/dev/null; then
  echo "Qbloom could not start. Check the archive's OS, architecture and matching Swift runtime. See docs/installation.md." >&2
  exit 1
fi

if [ ! -f "$manuals/man1/qbloom.1" ] || [ ! -f "$manuals/ko/man1/qbloom.1" ]; then
  echo "English or Korean qbloom manual page is missing" >&2
  exit 1
fi

root="${destdir}${prefix}"
target="$root/bin"
manroot="$root/share/man"
mkdir -p "$target" "$manroot/man1" "$manroot/ko/man1" "$manroot/ko_KR.UTF-8/man1"
for directory in "$target" "$manroot/man1" "$manroot/ko/man1" "$manroot/ko_KR.UTF-8/man1"; do
  if [ ! -w "$directory" ]; then
    echo "Cannot write to $directory. Use PREFIX=\"\$HOME/.local\" for a user install, or run the installer with administrator privileges." >&2
    exit 1
  fi
done

check_target() {
  destination=$1
  kind=$2
  if [ -L "$destination" ]; then
    echo "Refusing to replace a symlink at $destination" >&2
    exit 1
  fi
  if [ -e "$destination" ]; then
    if [ "$kind" = directory ] && [ ! -d "$destination" ]; then
      echo "Expected a directory at $destination" >&2
      exit 1
    fi
    if [ "$kind" = file ] && [ ! -f "$destination" ]; then
      echo "Expected a regular file at $destination" >&2
      exit 1
    fi
  fi
}
check_target "$target/qbloom" file
check_target "$target/$bundle_name" directory
check_target "$manroot/man1/qbloom.1" file
check_target "$manroot/ko/man1/qbloom.1" file
check_target "$manroot/ko_KR.UTF-8/man1/qbloom.1" file

stage=$(mktemp -d "$root/.qbloom-install.XXXXXX")
mkdir -p "$stage/new" "$stage/backup"
committed=0
started=0
rollback_item() {
  key=$1
  destination=$2
  if [ -e "$stage/backup/$key" ]; then
    rm -rf "$destination" || return 1
    mv "$stage/backup/$key" "$destination" || return 1
  elif [ ! -e "$stage/new/$key" ]; then
    rm -rf "$destination" || return 1
  fi
}
finish() {
  status=$?
  trap - 0
  set +e
  rollback_failed=0
  if [ "$started" -eq 1 ] && [ "$committed" -eq 0 ]; then
    rollback_item binary "$target/qbloom" || rollback_failed=1
    rollback_item bundle "$target/$bundle_name" || rollback_failed=1
    rollback_item english "$manroot/man1/qbloom.1" || rollback_failed=1
    rollback_item korean "$manroot/ko/man1/qbloom.1" || rollback_failed=1
    rollback_item korean_locale "$manroot/ko_KR.UTF-8/man1/qbloom.1" || rollback_failed=1
  fi
  if [ "$rollback_failed" -eq 1 ]; then
    echo "Install rollback failed; previous files remain in $stage/backup" >&2
    exit 1
  fi
  rm -rf "$stage"
  exit "$status"
}
trap finish 0
trap 'exit 1' 1 2 3 15

cp "$binary" "$stage/new/binary"
chmod 755 "$stage/new/binary"
cp -R "$bundle" "$stage/new/bundle"
cp "$manuals/man1/qbloom.1" "$stage/new/english"
cp "$manuals/ko/man1/qbloom.1" "$stage/new/korean"
cp "$manuals/ko/man1/qbloom.1" "$stage/new/korean_locale"
chmod 644 "$stage/new/english" "$stage/new/korean" "$stage/new/korean_locale"

install_item() {
  key=$1
  destination=$2
  if [ -e "$destination" ]; then
    mv "$destination" "$stage/backup/$key"
  fi
  mv "$stage/new/$key" "$destination"
}
started=1
install_item bundle "$target/$bundle_name"
install_item binary "$target/qbloom"
install_item english "$manroot/man1/qbloom.1"
install_item korean "$manroot/ko/man1/qbloom.1"
install_item korean_locale "$manroot/ko_KR.UTF-8/man1/qbloom.1"
committed=1
echo "Installed $target/qbloom, its template bundle, and English/Korean man pages"
