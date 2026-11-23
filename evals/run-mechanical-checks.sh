#!/usr/bin/env bash
# Mechanical guards only. This does NOT evaluate real external LLM behavior
# on scenarios A-F; use `evals/run-live-evals.py` locally for live evals.
#
# Runs (10 steps):
#   1. Ownership parser fixtures (run-tests.sh)
#   2. Install rollback, backup hygiene, dry-run & sync fixtures (install-rollback-test.sh)
#   3. Language preference & sandbox fallback fixtures (lang-tests.sh)
#   4. Cross-CLI portability fixtures (grok-portability-tests.sh)
#   5. Deterministic hook guard & template fixtures (hook-guard-tests.sh)
#   6. lint-handoff.py unit tests (test-lint-handoff.sh) + repo handoff lint
#   7. Opt-in live eval harness deterministic self-test (run-live-evals.py --self-test)
#   8. SKILL.md strict frontmatter + YAML/JSON asset validation
#   9. Markdown relative link & script executable-bit integrity check
#  10. check-ownership.sh multibyte source-guard
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
require_file "skills/cli-collaboration/scripts/test-fixtures/lang-tests.sh"
require_file "skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh"
require_file "skills/cli-collaboration/scripts/test-fixtures/hook-guard-tests.sh"
require_file "evals/test-lint-handoff.sh"
require_file "evals/lint-handoff.py"
require_file "evals/run-live-evals.py"
require_file "skills/cli-collaboration/SKILL.md"
require_file "AGENT_HANDOFF.md"
require_file "examples/AGENT_HANDOFF.md"

command -v python3 >/dev/null 2>&1 || fail "python3 not found on PATH" 2
python3 -c "import yaml" 2>/dev/null || fail "PyYAML not installed (pip install pyyaml)" 2

step() { printf '\n== %s ==\n' "$1"; }

step "1/10 ownership parser fixtures"
bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh

step "2/10 install rollback, backup hygiene, dry-run & sync fixtures"
bash skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh

step "3/10 language preference fixtures"
bash skills/cli-collaboration/scripts/test-fixtures/lang-tests.sh

step "4/10 cross-CLI portability fixtures"
bash skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh

step "5/10 deterministic hook guard & template fixtures"
bash skills/cli-collaboration/scripts/test-fixtures/hook-guard-tests.sh

step "6/10 AGENT_HANDOFF.md linter unit tests & structural lint"
bash evals/test-lint-handoff.sh
python3 evals/lint-handoff.py AGENT_HANDOFF.md
python3 evals/lint-handoff.py examples/AGENT_HANDOFF.md

step "7/10 live eval harness self-test"
python3 evals/run-live-evals.py --self-test

step "8/10 SKILL.md frontmatter + YAML/JSON asset validation"
python3 - <<'PY'
import json
import pathlib
import sys
import yaml

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

allowed_keys = {"name", "description", "metadata"}
unexpected = sorted(set(data.keys()) - allowed_keys)
if unexpected:
    print(f"FAIL: unexpected SKILL.md frontmatter keys: {unexpected}", file=sys.stderr)
    sys.exit(1)

errors = []
if data.get("name") != "cli-collaboration":
    errors.append(f"SKILL.md name must be 'cli-collaboration', got {data.get('name')!r}")

desc = data.get("description")
if not isinstance(desc, str) or not desc.strip():
    errors.append("missing or empty required field: description")
elif len(desc) > 1024:
    errors.append(f"description exceeds 1024 chars ({len(desc)})")

meta = data.get("metadata")
if not isinstance(meta, dict) or not str(meta.get("version", "")).strip():
    errors.append("metadata.version must be a non-empty string")
else:
    for k, v in meta.items():
        if not isinstance(k, str) or not isinstance(v, str):
            errors.append(f"metadata entry {k!r} must map string -> string")

for yaml_path in sorted(pathlib.Path("skills/cli-collaboration/agents").glob("*.yaml")):
    try:
        yaml.safe_load(yaml_path.read_text(encoding="utf-8"))
    except yaml.YAMLError as exc:
        errors.append(f"invalid YAML in {yaml_path}: {exc}")

for json_path in [pathlib.Path("evals/evals.json"), *sorted(pathlib.Path("examples/hooks").glob("*.json"))]:
    try:
        json.loads(json_path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        errors.append(f"invalid JSON in {json_path}: {exc}")

if errors:
    for e in errors:
        print(f"FAIL: {e}", file=sys.stderr)
    sys.exit(1)

print(
    f"ok   frontmatter valid (description={len(desc)} chars, version={meta['version']}); "
    "YAML and JSON assets valid"
)
PY

step "9/10 markdown relative links & script executable bits"
python3 - <<'PY'
import os
import pathlib
import re
import sys

errors: list[str] = []
checked_links = 0

md_files = [
    pathlib.Path("skills/cli-collaboration/SKILL.md"),
    *sorted(pathlib.Path("skills/cli-collaboration/references").glob("*.md")),
]

fence_open_re = re.compile(r"^\s*(`{3,}|~{3,})")
link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")
inline_code_re = re.compile(r"`[^`]*`")

for md in md_files:
    lines = md.read_text(encoding="utf-8").splitlines()
    fence_char = ""
    fence_len = 0
    for lineno, line in enumerate(lines, 1):
        if fence_len:
            close_re = re.compile(rf"^\s*{re.escape(fence_char)}{{{fence_len},}}\s*$")
            if close_re.match(line):
                fence_char = ""
                fence_len = 0
            continue
        m_open = fence_open_re.match(line)
        if m_open:
            seq = m_open.group(1)
            fence_char = seq[0]
            fence_len = len(seq)
            continue

        cleaned = inline_code_re.sub("", line)
        for m in link_re.finditer(cleaned):
            raw_target = m.group(1).strip()
            if raw_target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            if "<" in raw_target or ">" in raw_target:
                continue
            rel = raw_target.split("#", 1)[0].split("?", 1)[0].strip()
            if not rel:
                continue
            checked_links += 1
            resolved = (md.parent / rel).resolve()
            if not resolved.exists():
                errors.append(f"{md}:{lineno} broken relative link '{raw_target}'")

exec_targets = [
    *sorted(pathlib.Path("skills/cli-collaboration/scripts").glob("*.sh")),
    *sorted(pathlib.Path("skills/cli-collaboration/scripts").glob("*.py")),
    *sorted(pathlib.Path("skills/cli-collaboration/scripts/test-fixtures").glob("*.sh")),
    *sorted(pathlib.Path("evals").glob("*.sh")),
    *sorted(pathlib.Path("evals").glob("*.py")),
]

for script in exec_targets:
    if not os.access(script, os.X_OK):
        errors.append(f"script missing executable permission (+x): {script}")

if errors:
    for err in errors:
        print(f"FAIL: {err}", file=sys.stderr)
    sys.exit(1)

print(
    f"ok   checked {checked_links} markdown relative links across {len(md_files)} files "
    f"and +x bits on {len(exec_targets)} scripts"
)
PY

step "10/10 check-ownership.sh source-guard"
python3 - <<'PY'
"""Refuse literal en-dash (U+2013, bytes E2 80 93) or em-dash (U+2014,
bytes E2 80 94) anywhere in check-ownership.sh. The parser now ignores
the separator entirely and extracts the owner phrase before it, so the
script source should contain no literal multibyte dash bytes at all.
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
