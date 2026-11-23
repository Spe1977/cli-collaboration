#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/check-ownership.sh"
FIXTURES="$ROOT/test-fixtures"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

failures=0

run_case() {
  local name="$1"
  local expected="$2"
  shift 2

  "$CHECK" "$@" >"$WORK/$name.out" 2>"$WORK/$name.err"
  local actual=$?

  if [ "$actual" -ne "$expected" ]; then
    echo "not ok - $name expected $expected got $actual"
    if [ -s "$WORK/$name.err" ]; then
      sed 's/^/  err: /' "$WORK/$name.err"
    fi
    failures=$((failures + 1))
  else
    echo "ok - $name"
  fi
}

run_case_env() {
  local name="$1"
  local expected="$2"
  local agent_env="$3"
  shift 3

  CLI_COLLAB_AGENT="$agent_env" "$CHECK" "$@" >"$WORK/$name.out" 2>"$WORK/$name.err"
  local actual=$?

  if [ "$actual" -ne "$expected" ]; then
    echo "not ok - $name expected $expected got $actual"
    if [ -s "$WORK/$name.err" ]; then
      sed 's/^/  err: /' "$WORK/$name.err"
    fi
    failures=$((failures + 1))
  else
    echo "ok - $name"
  fi
}

run_case clean 0 --handoff "$FIXTURES/handoff-clean.md" --agent Codex src/app.js README.md
run_case missing 2 --handoff "$FIXTURES/handoff-missing.md" --agent Codex src/app.js
run_case agent-conflict 1 --handoff "$FIXTURES/handoff-agent-conflict.md" --agent Codex src/app.js
run_case user-reserved 1 --handoff "$FIXTURES/handoff-user-reserved.md" --agent Codex workflow.md
run_case frozen 1 --handoff "$FIXTURES/handoff-frozen.md" --agent Codex release-notes.md
run_case missing-frozen-section 2 --handoff "$FIXTURES/handoff-missing-frozen-section.md" --agent Codex src/app.js
run_case endash-owner 0 --handoff "$FIXTURES/handoff-endash.md" --agent Claude src/app.js
run_case glob-crosses-slash 0 --handoff "$FIXTURES/handoff-glob-crosses-slash.md" --agent Codex scripts/sub/foo.sh

# v2.6.0 path normalization & agent alias fixtures
cat > "$WORK/handoff-antigravity.md" <<'EOF'
# AGENT_HANDOFF.md

**Last updated:** 2026-11-23T12:00:00+01:00
**Last agent:** Antigravity
**Status:** in-progress

## Current task
Fixture for Antigravity vs Gemini distinctness and alias normalization.

## File ownership
### agent-owned
- src/ide.ts: Antigravity — IDE integration
- src/cli.ts: Gemini CLI — Gemini CLI adapter
- docs/guide.md: Claude Code — documentation
### user-reserved
- .env: user — secrets
### frozen
No frozen files currently declared.
EOF

run_case dot-slash-prefix-clean 0 --handoff "$FIXTURES/handoff-clean.md" --agent Codex ./src/app.js
run_case dot-slash-prefix-conflict 1 --handoff "$FIXTURES/handoff-agent-conflict.md" --agent Codex ./src/app.js
run_case abs-path-conflict 1 --handoff "$FIXTURES/handoff-user-reserved.md" --agent Codex "$FIXTURES/workflow.md"
run_case abs-path-owned-clean 0 --handoff "$FIXTURES/handoff-clean.md" --agent Codex "$FIXTURES/src/app.js"
run_case alias-claude-code 0 --handoff "$FIXTURES/handoff-endash.md" --agent "Claude Code" src/app.js
run_case alias-gemini-cli 0 --handoff "$WORK/handoff-antigravity.md" --agent Gemini src/cli.ts
run_case alias-antigravity-ide 0 --handoff "$WORK/handoff-antigravity.md" --agent "Antigravity IDE" src/ide.ts
run_case alias-agy 0 --handoff "$WORK/handoff-antigravity.md" --agent agy src/ide.ts
run_case antigravity-blocked-on-gemini-file 1 --handoff "$WORK/handoff-antigravity.md" --agent Antigravity src/cli.ts
run_case gemini-blocked-on-antigravity-file 1 --handoff "$WORK/handoff-antigravity.md" --agent "Gemini CLI" src/ide.ts
run_case multiword-owner-claude-code 0 --handoff "$WORK/handoff-antigravity.md" --agent Claude docs/guide.md

# Additional edge cases: parenthetical notes, env override, separators, .. / //, malformed lines
cat > "$WORK/handoff-edge.md" <<'EOF'
# AGENT_HANDOFF.md

**Last updated:** 2026-11-23T13:30:00+01:00
**Last agent:** Codex
**Status:** in-progress

## File ownership
### agent-owned
- docs/spec.md: Claude (pending Phase 2) — specification
- qa/check.md: Gemini CLI (Phase 3) — QA verification
- a.txt: OpenAI Codex -- double hyphen separator
- b.txt: Grok Build - ascii hyphen separator
### user-reserved
No user-reserved files currently declared.
### frozen
No frozen files currently declared.
EOF

cat > "$WORK/handoff-malformed-colon.md" <<'EOF'
# AGENT_HANDOFF.md

## File ownership
### agent-owned
- src/app.js Codex
### user-reserved
No user-reserved files currently declared.
### frozen
No frozen files currently declared.
EOF

cat > "$WORK/handoff-malformed-bullet.md" <<'EOF'
# AGENT_HANDOFF.md

## File ownership
- orphan.txt: Codex — placed before any subsection
### agent-owned
- src/app.js: Codex — owner
### user-reserved
No user-reserved files currently declared.
### frozen
No frozen files currently declared.
EOF

run_case parenthetical-owner-note 0 --handoff "$WORK/handoff-edge.md" --agent Claude docs/spec.md
run_case multiword-parenthetical-match 0 --handoff "$WORK/handoff-edge.md" --agent Gemini qa/check.md
run_case multiword-parenthetical-conflict 1 --handoff "$WORK/handoff-edge.md" --agent Antigravity qa/check.md
run_case_env env-agent-override-clean 0 Antigravity --handoff "$WORK/handoff-antigravity.md" src/ide.ts
run_case_env env-agent-override-conflict 1 Antigravity --handoff "$WORK/handoff-antigravity.md" src/cli.ts
run_case separator-double-hyphen 0 --handoff "$WORK/handoff-edge.md" --agent Codex a.txt
run_case separator-ascii-hyphen 0 --handoff "$WORK/handoff-edge.md" --agent Grok b.txt
run_case redundant-slash-clean 0 --handoff "$FIXTURES/handoff-clean.md" --agent Codex src//app.js
run_case dotdot-clean 0 --handoff "$FIXTURES/handoff-clean.md" --agent Codex src/sub/../app.js
run_case redundant-slash-conflict 1 --handoff "$FIXTURES/handoff-agent-conflict.md" --agent Codex src//app.js
run_case dotdot-conflict 1 --handoff "$FIXTURES/handoff-agent-conflict.md" --agent Codex src/sub/../app.js
run_case abs-path-outside-handoff-dir 0 --handoff "$FIXTURES/handoff-clean.md" --agent Codex /tmp/unrelated-cli-collab-check.txt
run_case malformed-missing-colon 2 --handoff "$WORK/handoff-malformed-colon.md" --agent Codex src/app.js
run_case malformed-bullet-before-subsection 2 --handoff "$WORK/handoff-malformed-bullet.md" --agent Codex src/app.js

if [ "$failures" -ne 0 ]; then
  exit 1
fi
