#!/usr/bin/env bash
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHECK="$ROOT/check-ownership.sh"
FIXTURES="$ROOT/test-fixtures"

failures=0

run_case() {
  local name="$1"
  local expected="$2"
  shift 2

  "$CHECK" "$@" >"$FIXTURES/$name.out" 2>"$FIXTURES/$name.err"
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

# Source-level regression guard: literal multibyte dash characters in
# `[[ ... ]]` or `${var//pat/rep}` patterns broke macOS Bash 3.2 (the
# patterns are not matched/substituted correctly under that bash + C
# locale). The script now defines $EM_DASH and $EN_DASH via ANSI-C
# quoting and uses those variables in patterns. Block reintroduction by
# refusing literal U+2013/U+2014 anywhere outside the documented
# definition lines.
if grep -nP '[\xe2][\x80][\x93\x94]' "$ROOT/check-ownership.sh" \
     | grep -v '^[0-9]\+:[A-Z_]\+_DASH=' \
     | grep -v 'multibyte\|en-dash\|em-dash\|U+201[34]' \
     >/tmp/dashes-in-script.txt; then
  if [ -s /tmp/dashes-in-script.txt ]; then
    echo "not ok - source-guard literal multibyte dash characters in check-ownership.sh:"
    sed 's/^/    /' /tmp/dashes-in-script.txt
    failures=$((failures + 1))
  else
    echo "ok - source-guard no literal multibyte dashes outside definitions"
  fi
else
  echo "ok - source-guard no literal multibyte dashes outside definitions"
fi
rm -f /tmp/dashes-in-script.txt

rm -f "$FIXTURES"/*.out "$FIXTURES"/*.err

if [ "$failures" -ne 0 ]; then
  exit 1
fi
