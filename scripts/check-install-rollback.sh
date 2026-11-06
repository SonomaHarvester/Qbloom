#!/bin/sh
set -eu

repo=$(CDPATH= cd "$(dirname "$0")/.." && pwd)
work=$(mktemp -d "${TMPDIR:-/tmp}/qbloom-install-rollback.XXXXXX")
trap 'rm -rf "$work"' EXIT HUP INT TERM
prefix="$work/prefix"
PREFIX="$prefix" sh "$repo/scripts/install.sh" >/dev/null
cp "$prefix/bin/qbloom" "$work/old-qbloom"
cp "$prefix/share/man/man1/qbloom.1" "$work/old-man"
bundle="$prefix/bin/qbloom_QbloomCLI.bundle"
if [ ! -d "$bundle" ]; then
  bundle="$prefix/bin/qbloom_QbloomCLI.resources"
fi
printf 'previous bundle\n' > "$bundle/install-sentinel"

mkdir "$work/fakebin"
cat > "$work/fakebin/mv" <<'EOF'
#!/bin/sh
case "$1" in
  */new/english) exit 42 ;;
esac
exec /bin/mv "$@"
EOF
chmod +x "$work/fakebin/mv"
if env PATH="$work/fakebin:$PATH" PREFIX="$prefix" sh "$repo/scripts/install.sh" > "$work/install.log" 2>&1; then
  echo "Expected injected install failure" >&2
  exit 1
fi
cmp "$work/old-qbloom" "$prefix/bin/qbloom"
cmp "$work/old-man" "$prefix/share/man/man1/qbloom.1"
test -f "$bundle/install-sentinel"
test -z "$(find "$prefix" -name '.qbloom-install.*' -print)"
echo "PASS: failed install restored executable, template bundle, and manual pages"
