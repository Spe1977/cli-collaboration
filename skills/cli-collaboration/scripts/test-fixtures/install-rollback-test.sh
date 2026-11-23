#!/usr/bin/env bash
# Verifies:
#   1. install-skill.sh rolls back the backup when cp -R fails after an existing
#      target has been moved aside, leaving neither TARGET_PARENT nor
#      skills-backups/ polluted.
#   2. A successful overwrite places the backup into a sibling `skills-backups/`
#      directory outside TARGET_PARENT (so discovery paths stay clean).
#   3. Preset flags (--all, --antigravity, --claude, --gemini, dedup) and
#      sync-skill.sh work against isolated homes without duplicating ~/.gemini/skills.
#   4. --dry-run performs no writes, repeat installs are idempotent, sync detects
#      missing/drift and fixes via --install, and missing SKILL.md exits 2.

set -u
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SH="$SCRIPTS_ROOT/install-skill.sh"
SYNC_SH="$SCRIPTS_ROOT/sync-skill.sh"

fail() { echo "fail - $1" >&2; exit 1; }

[ -x "$INSTALL_SH" ] || fail "install-skill.sh not executable at $INSTALL_SH"
[ -x "$SYNC_SH" ] || fail "sync-skill.sh not executable at $SYNC_SH"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# Source: a minimal "skill" directory.
SRC="$WORK/source"
mkdir -p "$SRC"
echo "version=2" > "$SRC/marker.txt"
printf '%s\n' '---' 'name: cli-collaboration' \
  'description: rollback fixture' '---' > "$SRC/SKILL.md"

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

# 1. Run install with the fake cp first on PATH. Expect exit code 3.
set +e
PATH="$FAKEBIN:$PATH" "$INSTALL_SH" --source "$SRC" --target "$TARGET" >/dev/null 2>"$WORK/stderr"
rc=$?
set -e

[ "$rc" -eq 3 ] || fail "expected exit 3, got $rc; stderr: $(cat "$WORK/stderr")"

# Target must be restored to its original content.
[ -f "$TARGET/marker.txt" ] || fail "target marker missing after rollback"
content="$(cat "$TARGET/marker.txt")"
[ "$content" = "version=1" ] || fail "target content not restored; got: $content"

# No backup leftovers in TARGET_PARENT or skills-backups/ after rollback.
shopt -s nullglob
leftovers=("$TARGET_PARENT"/cli-collaboration.backup.* "$WORK"/skills-backups/cli-collaboration.backup.*)
shopt -u nullglob
if [ "${#leftovers[@]}" -ne 0 ]; then
  fail "stale backup left behind after rollback: ${leftovers[*]}"
fi

# Rollback message must appear on stderr.
grep -q "rollback: restored" "$WORK/stderr" || fail "missing rollback message in stderr"
echo "ok - install-rollback"

# 2. Successful overwrite moves backup outside TARGET_PARENT into skills-backups/.
"$INSTALL_SH" --source "$SRC" --target "$TARGET" >/dev/null || \
  fail "real install overwrite failed"
[ "$(cat "$TARGET/marker.txt")" = "version=2" ] || \
  fail "new version marker missing after overwrite"

shopt -s nullglob
in_parent=("$TARGET_PARENT"/cli-collaboration.backup.*)
out_tree=("$WORK"/skills-backups/cli-collaboration.backup.*)
shopt -u nullglob

if [ "${#in_parent[@]}" -ne 0 ]; then
  fail "backup placed inside TARGET_PARENT: ${in_parent[*]}"
fi
if [ "${#out_tree[@]}" -ne 1 ]; then
  fail "expected 1 backup in skills-backups, found ${#out_tree[@]}"
fi
[ "$(cat "${out_tree[0]}/marker.txt")" = "version=1" ] || \
  fail "out-of-tree backup does not hold original marker"
echo "ok - out-of-tree-backup"

# 3. Preset flags (--all) and sync-skill.sh.
HOMES="$WORK/homes"
CODEX_HOME="$HOMES/codex" \
AGENTS_HOME="$HOMES/agents" \
GROK_HOME="$HOMES/grok" \
CLAUDE_HOME="$HOMES/claude" \
ANTIGRAVITY_CONFIG_HOME="$HOMES/antigravity" \
GEMINI_HOME="$HOMES/gemini" \
  "$INSTALL_SH" --source "$SRC" --all >/dev/null || \
  fail "install --all failed"

for sub in codex agents grok claude antigravity; do
  [ -f "$HOMES/$sub/skills/cli-collaboration/SKILL.md" ] || \
    fail "install --all missed $sub target"
done
if [ -e "$HOMES/gemini/skills/cli-collaboration" ]; then
  fail "install --all duplicated GEMINI_HOME alongside AGENTS_HOME"
fi

CODEX_HOME="$HOMES/codex" \
AGENTS_HOME="$HOMES/agents" \
GROK_HOME="$HOMES/grok" \
CLAUDE_HOME="$HOMES/claude" \
ANTIGRAVITY_CONFIG_HOME="$HOMES/antigravity" \
GEMINI_HOME="$HOMES/gemini" \
  "$SYNC_SH" --source "$SRC" --all >/dev/null || \
  fail "sync --all reported unexpected drift"
echo "ok - preset-flags-all"

# 4. --dry-run performs no writes.
"$INSTALL_SH" --dry-run --source "$SRC" --target "$WORK/dry/cli-collaboration" >/dev/null || \
  fail "install --dry-run failed"
[ ! -e "$WORK/dry" ] || fail "install --dry-run created files on disk"
echo "ok - dry-run-no-writes"

# 5. Repeat install is idempotent and creates no extra backup.
idemp_out="$("$INSTALL_SH" --source "$SRC" --target "$TARGET")"
echo "$idemp_out" | grep -q "unchanged: $TARGET" || \
  fail "repeat install did not report unchanged: $idemp_out"
shopt -s nullglob
out_tree_after=("$WORK"/skills-backups/cli-collaboration.backup.*)
shopt -u nullglob
[ "${#out_tree_after[@]}" -eq 1 ] || \
  fail "repeat install created extra backup (${#out_tree_after[@]})"
echo "ok - idempotent-unchanged-no-extra-backup"

# 6. sync-skill.sh reports missing (exit 1), drift (exit 1), and fixes with --install.
ABSENT_TARGET="$WORK/sync-test/cli-collaboration"
set +e
sync_missing="$("$SYNC_SH" --source "$SRC" --target "$ABSENT_TARGET")"
rc=$?
set -e
[ "$rc" -eq 1 ] || fail "sync missing expected exit 1, got $rc"
echo "$sync_missing" | grep -q "missing: $ABSENT_TARGET" || \
  fail "sync missing output unexpected: $sync_missing"

"$INSTALL_SH" --source "$SRC" --target "$ABSENT_TARGET" >/dev/null
echo "version=99" > "$ABSENT_TARGET/marker.txt"

set +e
sync_drift="$("$SYNC_SH" --source "$SRC" --target "$ABSENT_TARGET")"
rc=$?
set -e
[ "$rc" -eq 1 ] || fail "sync drift expected exit 1, got $rc"
echo "$sync_drift" | grep -q "drift: $ABSENT_TARGET" || \
  fail "sync drift output unexpected: $sync_drift"

"$SYNC_SH" --install --source "$SRC" --target "$ABSENT_TARGET" >/dev/null || \
  fail "sync --install failed"
"$SYNC_SH" --source "$SRC" --target "$ABSENT_TARGET" >/dev/null || \
  fail "sync after --install still reported drift"
echo "ok - sync-missing-drift-and-fix"

# 7. Target deduplication (--codex --all) and explicit --gemini opt-in.
dedup_out="$(CODEX_HOME="$HOMES/codex" \
  AGENTS_HOME="$HOMES/agents" \
  GROK_HOME="$HOMES/grok" \
  CLAUDE_HOME="$HOMES/claude" \
  ANTIGRAVITY_CONFIG_HOME="$HOMES/antigravity" \
  "$INSTALL_SH" --dry-run --source "$SRC" --codex --all)"
codex_count="$(printf '%s\n' "$dedup_out" | grep -c "$HOMES/codex/skills/cli-collaboration" || true)"
[ "$codex_count" -eq 1 ] || fail "expected deduped single codex line, got $codex_count"

GEMINI_HOME="$HOMES/gemini" "$INSTALL_SH" --source "$SRC" --gemini >/dev/null || \
  fail "explicit --gemini install failed"
[ -f "$HOMES/gemini/skills/cli-collaboration/SKILL.md" ] || \
  fail "explicit --gemini missed SKILL.md"
echo "ok - preset-dedup-and-gemini-opt-in"

# 8. Invalid source missing SKILL.md -> exit 2.
BAD_SRC="$WORK/no-skill-md"
mkdir -p "$BAD_SRC"
set +e
"$INSTALL_SH" --source "$BAD_SRC" --target "$WORK/bad-out/cli-collaboration" >/dev/null 2>&1
rc=$?
set -e
[ "$rc" -eq 2 ] || fail "missing SKILL.md expected exit 2, got $rc"
echo "ok - invalid-source-missing-skill-md"
