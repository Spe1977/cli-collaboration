#!/usr/bin/env bash
# Mechanical guards only. This does NOT evaluate agent behavior on scenarios A-F;
# behavioral evaluation requires an LLM-judge harness which is out of scope.
#
# Runs:
#   1. Ownership parser fixtures (run-tests.sh)
#   2. Install rollback fixture (install-rollback-test.sh)
#   3. Structural lint on AGENT_HANDOFF.md (lint-handoff.py)
#   4. SKILL.md frontmatter parse + required-fields check (inline Python)
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
require_file "skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh"
require_file "evals/lint-handoff.py"
require_file "skills/cli-collaboration/SKILL.md"
require_file "AGENT_HANDOFF.md"

command -v python3 >/dev/null 2>&1 || fail "python3 not found on PATH" 2
python3 -c "import yaml" 2>/dev/null || fail "PyYAML not installed (pip install pyyaml)" 2

step() { printf '\n== %s ==\n' "$1"; }

step "1/4 ownership parser fixtures"
bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh

step "2/4 install rollback fixture"
bash skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh

step "3/4 AGENT_HANDOFF.md structural lint"
python3 evals/lint-handoff.py AGENT_HANDOFF.md

step "4/4 SKILL.md frontmatter check"
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

printf '\nAll mechanical checks passed.\n'
