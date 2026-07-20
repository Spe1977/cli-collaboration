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

# Note: the source-level regression guard that prevents literal multibyte
# en-dash/em-dash characters from being reintroduced into check-ownership.sh
# is intentionally NOT in this file. It lives in evals/run-mechanical-checks.sh,
# where Python 3 is already a hard dependency. An earlier draft used
# `grep -nP` here, which is not portable to macOS/BSD grep — moving the
# guard out keeps this file free of GNU-grep-only flags so the fixture
# suite runs identically on Linux and macOS without an extra dependency.

if [ "$failures" -ne 0 ]; then
  exit 1
fi
