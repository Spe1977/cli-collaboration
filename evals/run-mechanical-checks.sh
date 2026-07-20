#!/usr/bin/env bash
# Mechanical guards only. This does NOT evaluate agent behavior on scenarios A-F;
# behavioral evaluation requires an LLM-judge harness which is out of scope.
#
# Runs:
#   1. Ownership parser fixtures (run-tests.sh)
#   2. Grok/multi-CLI portability fixture (grok-portability-tests.sh)
#   3. Install rollback fixture (install-rollback-test.sh)
#   4. Structural lint on AGENT_HANDOFF.md (lint-handoff.py)
#   5. SKILL.md frontmatter parse + required-fields check (inline Python)
#   6. check-ownership.sh source-guard: refuses literal U+2013/U+2014 in
#      patterns (re-introducing them broke macOS Bash 3.2). Implemented in
#      Python rather than `grep -P` because BSD grep on macOS lacks -P.
#
# Exit codes:
#   0  all mechanical checks passed
#   1  at least one mechanical check failed
#   2  setup error (missing python3 / PyYAML / required files)

set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit "${2:-1}"
}

require_file() {
  [ -f "$1" ] || fail "required file missing: $1" 2
}

require_file "skills/cli-collaboration/scripts/test-fixtures/run-tests.sh"
require_file "skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh"
require_file "skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh"
require_file "evals/lint-handoff.py"
require_file "skills/cli-collaboration/SKILL.md"
require_file "AGENT_HANDOFF.md"

command -v python3 >/dev/null 2>&1 || fail "python3 not found on PATH" 2
python3 -c "import yaml" 2>/dev/null || fail "PyYAML not installed (pip install pyyaml)" 2

step() { printf '\n== %s ==\n' "$1"; }

step "1/6 ownership parser fixtures"
bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh

step "2/6 Grok and multi-CLI portability fixture"
bash skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh

step "3/6 install rollback fixture"
bash skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh

step "4/6 AGENT_HANDOFF.md structural lint"
python3 evals/lint-handoff.py AGENT_HANDOFF.md

step "5/6 SKILL.md frontmatter check"
python3 - <<'PY'
import sys, pathlib, yaml

skill = pathlib.Path("skills/cli-collaboration/SKILL.md")
text = skill.read_text(encoding="utf-8")

if not text.startswith("---\n"):
    print("FAIL: SKILL.md does not start with a YAML frontmatter delimiter", file=sys.stderr)
    sys.exit(1)

end = text.find("\n---", 4)
if end == -1:
    print("FAIL: SKILL.md frontmatter is not terminated by a closing '---'", file=sys.stderr)
    sys.exit(1)

frontmatter_text = text[4:end]
try:
    data = yaml.safe_load(frontmatter_text)
except yaml.YAMLError as exc:
    print(f"FAIL: SKILL.md frontmatter is not valid YAML: {exc}", file=sys.stderr)
    sys.exit(1)

if not isinstance(data, dict):
    print("FAIL: SKILL.md frontmatter must be a YAML mapping", file=sys.stderr)
    sys.exit(1)

errors = []
for required in ("name", "description"):
    value = data.get(required)
    if not isinstance(value, str) or not value.strip():
        errors.append(f"missing or empty required field: {required}")

if errors:
    for e in errors:
        print(f"FAIL: {e}", file=sys.stderr)
    sys.exit(1)

extra = sorted(set(data.keys()) - {"name", "description"})
print(f"ok   frontmatter parses; name+description present; extra fields: {extra or 'none'}")
PY

step "6/6 check-ownership.sh source-guard"
python3 - <<'PY'
"""Refuse literal en-dash (U+2013, bytes E2 80 93) or em-dash (U+2014,
bytes E2 80 94) anywhere in check-ownership.sh. The parser now ignores
the separator entirely and extracts the first whitespace-delimited token
after the colon as the owner, so the script source should contain no
literal multibyte dash bytes at all. Comment lines that mention these
characters in ASCII prose ("en-dash", "em-dash", "U+2013", "U+2014") are
allowlisted in case a future maintainer chooses to also use a literal in
prose; otherwise the guard treats any U+2013/U+2014 byte as a regression.

This guard is what prevents the macOS Bash 3.2 multibyte-pattern bug
from being silently reintroduced. Implemented in Python because BSD
grep on macOS lacks -P, and we want byte-level matching that works
identically on Linux and macOS runners.
"""
import sys
from pathlib import Path

target = Path("skills/cli-collaboration/scripts/check-ownership.sh")
allow_substrings = (
    "multibyte",
    "en-dash",
    "em-dash",
    "U+2013",
    "U+2014",
)

bad = []
for lineno, raw in enumerate(target.read_bytes().splitlines(), 1):
    if b"\xe2\x80\x93" not in raw and b"\xe2\x80\x94" not in raw:
        continue
    text = raw.decode("utf-8", errors="replace")
    if any(token in text for token in allow_substrings):
        continue
    bad.append((lineno, text))

if bad:
    print("FAIL: literal multibyte dash characters in check-ownership.sh:", file=sys.stderr)
    for lineno, text in bad:
        print(f"    {lineno}: {text}", file=sys.stderr)
    sys.exit(1)

print("ok   no literal en-/em-dash in check-ownership.sh outside allowlisted definitions")
PY

printf '\nAll mechanical checks passed.\n'
