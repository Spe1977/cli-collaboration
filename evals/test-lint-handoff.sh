#!/usr/bin/env bash
# Positive and negative unit tests for evals/lint-handoff.py.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINT_PY="$SCRIPT_DIR/lint-handoff.py"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

failures=0

run_lint_case() {
  local name="$1"
  local expected_rc="$2"
  local target="$3"
  local expected_err="${4:-}"
  local out_file="$WORK/$name.out"
  local err_file="$WORK/$name.err"

  python3 "$LINT_PY" "$target" >"$out_file" 2>"$err_file"
  local actual_rc=$?

  if [ "$actual_rc" -ne "$expected_rc" ]; then
    echo "not ok - $name (expected exit $expected_rc, got $actual_rc)"
    sed 's/^/  err: /' "$err_file"
    failures=$((failures + 1))
    return
  fi

  if [ -n "$expected_err" ] && ! grep -Fq "$expected_err" "$err_file"; then
    echo "not ok - $name (missing expected stderr text: $expected_err)"
    sed 's/^/  err: /' "$err_file"
    failures=$((failures + 1))
    return
  fi

  echo "ok - $name"
}

write_base_handoff() {
  cat <<'EOF'
# AGENT_HANDOFF.md

**Last updated:** 2026-11-23T13:00:00+01:00
**Last agent:** Codex
**Status:** in-progress

## Current task
Implement deterministic checks for AGENT_HANDOFF.md.

## File ownership
### agent-owned
- src/app.py: Codex — core logic
### user-reserved
- .env: user — secrets
### frozen
No frozen files currently declared.

## Files changed this shift
- src/app.py: added validation helper

## Tests
- Red: none
- Green: pytest tests/test_app.py

## Open concerns
- Edge case handling for empty payloads needs a dedicated test.

## Next agent starts from
Next agent: Antigravity. Continue at src/app.py:42 and add negative test cases. Do not touch .env.

## History
- 2026-11-23T13:00:00+01:00 - Codex: Added validation helper. (in-progress)
EOF
}

# 1. Valid handoff
write_base_handoff > "$WORK/valid.md"
run_lint_case valid-handoff 0 "$WORK/valid.md"

# 2. Missing file -> exit 2
run_lint_case missing-file 2 "$WORK/does-not-exist.md"

# 3. Missing timezone offset -> exit 1 (header-metadata)
sed 's/2026-11-23T13:00:00+01:00/2026-11-23T13:00:00/' "$WORK/valid.md" > "$WORK/no-tz.md"
run_lint_case missing-timezone-offset 1 "$WORK/no-tz.md" "header-metadata"

# 4. Missing Last agent -> exit 1 (header-metadata)
grep -v '^\*\*Last agent:\*\*' "$WORK/valid.md" > "$WORK/no-agent.md"
run_lint_case missing-last-agent 1 "$WORK/no-agent.md" "header-metadata"

# 5. Invalid status -> exit 1 (header-metadata)
sed 's/\*\*Status:\*\* in-progress/**Status:** wip/' "$WORK/valid.md" > "$WORK/bad-status.md"
run_lint_case invalid-status 1 "$WORK/bad-status.md" "header-metadata"

# 6. Banned placeholder in Open concerns -> exit 1 (open-concerns)
sed 's/^- Edge case handling.*/- all good/' "$WORK/valid.md" > "$WORK/banned-concerns.md"
run_lint_case banned-open-concerns-all-good 1 "$WORK/banned-concerns.md" "open-concerns"

# 7. Empty Open concerns -> exit 1 (open-concerns)
sed 's/^- Edge case handling.*//' "$WORK/valid.md" > "$WORK/empty-concerns.md"
run_lint_case empty-open-concerns 1 "$WORK/empty-concerns.md" "open-concerns"

# 8. Trivial Next agent starts from -> exit 1 (next-agent-nontrivial)
sed 's/^Next agent: Antigravity.*/continue/' "$WORK/valid.md" > "$WORK/trivial-next.md"
run_lint_case trivial-next-agent 1 "$WORK/trivial-next.md" "next-agent-nontrivial"

# 9. Bad History timestamp -> exit 1 (history-timestamps)
sed 's/^- 2026-11-23T13:00:00+01:00 - Codex.*/- yesterday - Codex: Added validation helper. (done)/' "$WORK/valid.md" > "$WORK/bad-history.md"
run_lint_case bad-history-timestamp 1 "$WORK/bad-history.md" "history-timestamps"

# 10. Oversized valid handoff (>16000 chars) -> exit 0 + WARN [size-budget]
cp "$WORK/valid.md" "$WORK/oversized.md"
python3 - "$WORK/oversized.md" <<'PY'
import pathlib, sys
p = pathlib.Path(sys.argv[1])
text = p.read_text(encoding="utf-8")
filler = "- 2026-11-23T12:00:00+01:00 - Codex: " + ("x" * 160) + " (done)\n"
p.write_text(text + (filler * 90), encoding="utf-8")
PY
run_lint_case oversized-soft-warning 0 "$WORK/oversized.md" "WARN [size-budget]"

if [ "$failures" -ne 0 ]; then
  exit 1
fi
