#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
REPO_ROOT="$(cd "$SKILL_ROOT/../.." && pwd)"
INSTALL_SH="$SKILL_ROOT/scripts/install-skill.sh"
SYNC_SH="$SKILL_ROOT/scripts/sync-skill.sh"
CHECK_SH="$SKILL_ROOT/scripts/check-ownership.sh"
SKILL_MD="$SKILL_ROOT/SKILL.md"

fail() {
  printf 'fail - %s\n' "$1" >&2
  exit 1
}

command -v python3 >/dev/null 2>&1 || fail "python3 not found"
python3 -c "import yaml" 2>/dev/null || fail "PyYAML not installed"

python3 - "$SKILL_MD" <<'PY'
import pathlib
import sys
import yaml

path = pathlib.Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
frontmatter = text.split("---", 2)[1]
data = yaml.safe_load(frontmatter)
allowed = {"name", "description", "metadata"}
unexpected = sorted(set(data) - allowed)
if unexpected:
    raise SystemExit(f"unsupported shared frontmatter keys: {unexpected}")
if data.get("metadata", {}).get("version") != "2.5.0":
    raise SystemExit("metadata.version must be 2.5.0")
PY

if grep -q '^# CLI Collaboration (Grok)$' "$SKILL_MD"; then
  fail "shared SKILL.md is Grok-specific"
fi
if grep -q '^Agent: Grok$' "$SKILL_MD"; then
  fail "shared end-of-shift template hardcodes Grok"
fi
if grep -q '\$GROK_SKILL_HOME' "$SKILL_MD"; then
  fail "shared SKILL.md contains Grok-only paths"
fi
grep -q 'references/grok-adapter.md' "$SKILL_MD" || \
  fail "shared SKILL.md does not route to the Grok adapter"

for doc in \
  README.md README_IT.md CLAUDE.md GEMINI.md \
  examples/CLAUDE.md examples/GEMINI.md; do
  grep -qi 'Grok' "$REPO_ROOT/$doc" || \
    fail "$doc omits Grok from the supported-agent documentation"
done

if ! "$CHECK_SH" --handoff "$SCRIPT_DIR/handoff-clean.md" src/app.js; then
  fail "ownership checker no longer defaults to Codex"
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

GROK_HANDOFF="$WORK/grok-handoff.md"
cat > "$GROK_HANDOFF" <<'EOF'
# AGENT_HANDOFF.md

**Last updated:** 2026-07-20T00:00:00+02:00
**Last agent:** Grok
**Status:** in-progress

## Current task
Grok portability fixture.

## File ownership
### agent-owned
- src/grok.txt: Grok — fixture owner
### user-reserved
No user-reserved files.
### frozen
No frozen files.
EOF

"$CHECK_SH" --handoff "$GROK_HANDOFF" --agent Grok src/grok.txt || \
  fail "explicit Grok identity rejected a Grok-owned file"

GROK_HOME="$WORK/grok" \
CODEX_HOME="$WORK/codex" \
AGENTS_HOME="$WORK/agents" \
GEMINI_HOME="$WORK/gemini" \
  "$INSTALL_SH" >/dev/null

for root in grok codex agents; do
  test -f "$WORK/$root/skills/cli-collaboration/SKILL.md" || \
    fail "default install omitted $root target"
done

if test -e "$WORK/gemini/skills/cli-collaboration"; then
  fail "default install duplicates the Gemini-compatible .agents target"
fi

GROK_HOME="$WORK/grok" \
CODEX_HOME="$WORK/codex" \
AGENTS_HOME="$WORK/agents" \
GEMINI_HOME="$WORK/gemini" \
  "$SYNC_SH" >/dev/null || fail "default sync reported drift after install"

printf 'ok - grok-portability\n'
