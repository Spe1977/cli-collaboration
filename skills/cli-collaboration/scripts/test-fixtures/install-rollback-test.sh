#!/usr/bin/env bash
# Verifies install-skill.sh rolls back the backup when cp -R fails after an
# existing target has been moved aside. Uses a PATH-injected failing `cp` so
# the failure is deterministic and portable.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SH="$(cd "$SCRIPT_DIR/.." && pwd)/install-skill.sh"

fail() { echo "fail - $1" >&2; exit 1; }

[ -x "$INSTALL_SH" ] || fail "install-skill.sh not executable at $INSTALL_SH"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Source: a minimal "skill" directory.
SRC="$WORK/source"
mkdir -p "$SRC"
echo "version=2" > "$SRC/marker.txt"

# Target: pre-existing install with different content (forces backup+cp path).
TARGET_PARENT="$WORK/install"
mkdir -p "$TARGET_PARENT"
TARGET="$TARGET_PARENT/cli-collaboration"
mkdir -p "$TARGET"
echo "version=1" > "$TARGET/marker.txt"

# Fake bin shadowing `cp` with a failing stub.
FAKEBIN="$WORK/fakebin"
mkdir -p "$FAKEBIN"
cat > "$FAKEBIN/cp" <<'EOF'
#!/usr/bin/env bash
echo "fake cp: forced failure" >&2
exit 1
EOF
chmod +x "$FAKEBIN/cp"

# Run install with the fake cp first on PATH. Expect exit code 3.
set +e
PATH="$FAKEBIN:$PATH" "$INSTALL_SH" --source "$SRC" --target "$TARGET" >/dev/null 2>"$WORK/stderr"
rc=$?
set -e

[ "$rc" -eq 3 ] || fail "expected exit 3, got $rc; stderr: $(cat "$WORK/stderr")"

# Target must be restored to its original content.
[ -f "$TARGET/marker.txt" ] || fail "target marker missing after rollback"
content="$(cat "$TARGET/marker.txt")"
[ "$content" = "version=1" ] || fail "target content not restored; got: $content"

# Backup must have been removed by the rollback (mv backup -> target).
shopt -s nullglob
leftovers=("$TARGET_PARENT"/cli-collaboration.backup.*)
shopt -u nullglob
if [ "${#leftovers[@]}" -ne 0 ]; then
  fail "stale backup left behind: ${leftovers[*]}"
fi

# Rollback message must appear on stderr.
grep -q "rollback: restored" "$WORK/stderr" || fail "missing rollback message in stderr"

echo "ok - install-rollback"
