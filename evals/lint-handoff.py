#!/usr/bin/env python3
"""Structural lint for AGENT_HANDOFF.md.

Mechanical guards only. This does NOT evaluate semantic correctness of the
handoff content; it only verifies the structural invariants that the project
contract relies on:

  1. Required top-level headings are present.
  2. Every timestamp in `## History` is ISO 8601 parseable.
  3. The `## Next agent starts from` section has non-trivial content.
  4. The `## File ownership` block contains the three required subsections
     (agent-owned, user-reserved, frozen).

Exit codes:
  0  all checks passed
  1  one or more structural checks failed
  2  usage error (missing or unreadable file)
"""
from __future__ import annotations

import argparse
import datetime as _dt
import re
import sys
from pathlib import Path

REQUIRED_TOP_HEADINGS = [
    "## Current task",
    "## File ownership",
    "## Files changed this shift",
    "## Tests",
    "## Next agent starts from",
    "## History",
]

REQUIRED_OWNERSHIP_SUBHEADINGS = [
    "### agent-owned",
    "### user-reserved",
    "### frozen",
]

# Matches the leading "YYYY-MM-DDTHH:MM[:SS][±HH:MM|Z]" portion of a History
# entry. We accept entries without seconds (the project mixes both forms) and
# entries without an explicit offset (interpreted as local time when parsed).
TIMESTAMP_RE = re.compile(
    r"^- (?P<ts>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:?\d{2})?)\b"
)

# Sentinel placeholders that would make `## Next agent starts from` trivial.
TRIVIAL_NEXT_AGENT_TOKENS = {"", "tbd", "todo", "n/a", "none"}


def _read(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except OSError as exc:
        print(f"lint-handoff: cannot read {path}: {exc}", file=sys.stderr)
        raise SystemExit(2)


def _section(content: str, heading: str) -> str | None:
    """Return the body of a top-level `## heading` section, or None if absent.

    The body runs from the line after the heading up to (but not including) the
    next `## ` heading or end of file.
    """
    lines = content.splitlines()
    start = None
    for i, line in enumerate(lines):
        if line.strip() == heading:
            start = i + 1
            break
    if start is None:
        return None
    end = len(lines)
    for j in range(start, len(lines)):
        if lines[j].startswith("## ") and not lines[j].startswith("### "):
            end = j
            break
    return "\n".join(lines[start:end])


def check_required_headings(content: str) -> list[str]:
    missing = []
    for heading in REQUIRED_TOP_HEADINGS:
        if heading not in content:
            missing.append(heading)
    return [f"missing required heading: {h}" for h in missing]


def check_ownership_subsections(content: str) -> list[str]:
    body = _section(content, "## File ownership")
    if body is None:
        return []  # already reported by the required-headings check
    return [
        f"missing required ownership subsection: {sub}"
        for sub in REQUIRED_OWNERSHIP_SUBHEADINGS
        if sub not in body
    ]


def check_history_timestamps(content: str) -> list[str]:
    body = _section(content, "## History")
    if body is None:
        return []  # already reported
    errors: list[str] = []
    entry_lines = [ln for ln in body.splitlines() if ln.startswith("- ")]
    if not entry_lines:
        errors.append("`## History` has no entries")
        return errors
    for ln in entry_lines:
        m = TIMESTAMP_RE.match(ln)
        if not m:
            errors.append(f"history entry without parseable leading timestamp: {ln[:80]}")
            continue
        ts = m.group("ts")
        # datetime.fromisoformat in Python 3.11+ handles trailing `Z` natively;
        # older versions don't. Normalize for safety.
        normalized = ts.replace("Z", "+00:00") if ts.endswith("Z") else ts
        try:
            _dt.datetime.fromisoformat(normalized)
        except ValueError:
            errors.append(f"timestamp not ISO 8601 parseable: {ts}")
    return errors


def check_next_agent_nontrivial(content: str) -> list[str]:
    body = _section(content, "## Next agent starts from")
    if body is None:
        return []
    stripped = body.strip()
    if not stripped:
        return ["`## Next agent starts from` section is empty"]
    # A non-trivial section has at least one alphabetic character beyond the
    # known placeholder tokens and is at least 40 characters long after
    # collapsing whitespace.
    collapsed = " ".join(stripped.split())
    if collapsed.lower() in TRIVIAL_NEXT_AGENT_TOKENS:
        return [f"`## Next agent starts from` is a trivial placeholder ({collapsed!r})"]
    if len(collapsed) < 40:
        return [
            f"`## Next agent starts from` is too short to be useful "
            f"({len(collapsed)} chars; require >= 40)"
        ]
    return []


CHECKS = (
    ("required-headings", check_required_headings),
    ("ownership-subsections", check_ownership_subsections),
    ("history-timestamps", check_history_timestamps),
    ("next-agent-nontrivial", check_next_agent_nontrivial),
)


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument(
        "handoff",
        nargs="?",
        default="AGENT_HANDOFF.md",
        help="path to AGENT_HANDOFF.md (default: ./AGENT_HANDOFF.md)",
    )
    args = parser.parse_args(argv)

    path = Path(args.handoff)
    if not path.is_file():
        print(f"lint-handoff: not a file: {path}", file=sys.stderr)
        return 2

    content = _read(path)

    all_errors: list[str] = []
    for name, fn in CHECKS:
        errs = fn(content)
        if errs:
            for e in errs:
                print(f"FAIL [{name}] {e}", file=sys.stderr)
            all_errors.extend(errs)
        else:
            print(f"ok   [{name}]")

    if all_errors:
        print(f"lint-handoff: {len(all_errors)} structural check(s) failed", file=sys.stderr)
        return 1
    print("lint-handoff: all structural checks passed")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
