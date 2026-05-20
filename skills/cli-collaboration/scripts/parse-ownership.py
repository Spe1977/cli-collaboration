#!/usr/bin/env python3
"""Ownership conflict checker - full Python implementation.

This is the working body of `check-ownership.sh`. After seven rounds of
attempts the Bash-only parser proved unreliable on macOS Bash 3.2.57
whenever a handoff ownership line carried multibyte UTF-8 bytes
(en-dash, em-dash). Each replacement code path - parameter expansion
patterns, POSIX character classes, ASCII-only patterns, controlled
word splitting via `set --`, sed normalization, awk micro-delegation -
hit the same two macOS fixtures. Python handles UTF-8 natively, so the
parser was migrated wholesale.

CLI contract (preserved from the Bash version):
    usage: check-ownership.sh [--handoff PATH] [--agent NAME] FILE...
    env:   CLI_COLLAB_AGENT overrides the default agent name
    exit:  0  no conflict
           1  conflict against agent-owned, user-reserved, or frozen
           2  usage error or malformed/missing ## File ownership section

Glob semantics: `*` is allowed to cross `/`, matching the P1 doc-honest
glob contract enforced by the existing `handoff-glob-crosses-slash`
fixture. `fnmatch.fnmatchcase` replicates this behavior.
"""
from __future__ import annotations

import fnmatch
import os
import sys
from pathlib import Path

USAGE = (
    "usage: check-ownership.sh [--handoff PATH] [--agent NAME] FILE...\n"
    "\n"
    "Exit codes:\n"
    "  0  handoff ownership is valid and no conflicts were detected\n"
    "  1  requested file conflicts with agent-owned, user-reserved, or frozen ownership\n"
    "  2  usage error or malformed/missing ownership section\n"
)


def _print_usage() -> None:
    sys.stderr.write(USAGE)


def _parse_args(argv: list[str]) -> tuple[str, str, list[str]]:
    handoff = "AGENT_HANDOFF.md"
    agent = os.environ.get("CLI_COLLAB_AGENT", "Codex")
    files: list[str] = []

    i = 0
    while i < len(argv):
        arg = argv[i]
        if arg == "--handoff":
            if i + 1 >= len(argv):
                _print_usage()
                sys.exit(2)
            handoff = argv[i + 1]
            i += 2
        elif arg == "--agent":
            if i + 1 >= len(argv):
                _print_usage()
                sys.exit(2)
            agent = argv[i + 1]
            i += 2
        elif arg in ("--help", "-h"):
            _print_usage()
            sys.exit(0)
        elif arg == "--":
            files.extend(argv[i + 1:])
            break
        elif arg.startswith("-"):
            _print_usage()
            sys.exit(2)
        else:
            files.append(arg)
            i += 1

    return handoff, agent, files


def _normalize_owner(value: str) -> str:
    paren_idx = value.find("(")
    if paren_idx >= 0:
        value = value[:paren_idx]
    return value.strip()


def _parse_ownership(handoff_path: Path):
    owned: list[tuple[str, str]] = []
    user_reserved: list[str] = []
    frozen: list[str] = []

    in_ownership = False
    current: str | None = None
    seen = {"agent-owned": False, "user-reserved": False, "frozen": False}
    valid_lines = 0
    malformed = False

    try:
        text = handoff_path.read_text(encoding="utf-8", errors="replace")
    except OSError as exc:
        print(f"cannot read handoff {handoff_path}: {exc}", file=sys.stderr)
        sys.exit(2)

    for raw_line in text.splitlines():
        line = raw_line

        if line == "## File ownership":
            in_ownership = True
            current = None
            continue

        if line.startswith("## ") and in_ownership:
            break

        if not in_ownership:
            continue

        if line == "### agent-owned":
            current = "agent-owned"
            seen["agent-owned"] = True
            continue
        if line == "### user-reserved":
            current = "user-reserved"
            seen["user-reserved"] = True
            continue
        if line == "### frozen":
            current = "frozen"
            seen["frozen"] = True
            continue

        if line == "" or line.startswith(" ") or line.startswith("\t"):
            continue

        if not line.startswith("- "):
            continue

        if current is None:
            malformed = True
            continue

        entry = line[2:]
        if ":" not in entry:
            malformed = True
            continue

        path, _, rest = entry.partition(":")
        if not path or not rest:
            malformed = True
            continue

        tokens = rest.split()
        if not tokens:
            malformed = True
            continue

        owner = _normalize_owner(tokens[0])
        if not owner:
            malformed = True
            continue

        if current == "agent-owned":
            owned.append((path, owner))
        elif current == "user-reserved":
            user_reserved.append(path)
        elif current == "frozen":
            frozen.append(path)
        valid_lines += 1

    if (not in_ownership or not all(seen.values())
            or valid_lines == 0 or malformed):
        print(
            f"malformed or missing ## File ownership section in {handoff_path}",
            file=sys.stderr,
        )
        sys.exit(2)

    return owned, user_reserved, frozen


def main(argv: list[str]) -> int:
    handoff, agent, files = _parse_args(argv)

    handoff_path = Path(handoff)
    if not handoff_path.is_file():
        print(f"handoff not found: {handoff}", file=sys.stderr)
        return 2

    owned, user_reserved, frozen = _parse_ownership(handoff_path)

    conflicts = 0
    for file in files:
        for pattern in frozen:
            if fnmatch.fnmatchcase(file, pattern):
                print(
                    f"conflict: {file} matches frozen ownership {pattern}",
                    file=sys.stderr,
                )
                conflicts = 1
        for pattern in user_reserved:
            if fnmatch.fnmatchcase(file, pattern):
                print(
                    f"conflict: {file} matches user-reserved ownership {pattern}",
                    file=sys.stderr,
                )
                conflicts = 1
        for pattern, owner in owned:
            if fnmatch.fnmatchcase(file, pattern) and owner != agent:
                print(
                    f"conflict: {file} is owned by {owner} via {pattern}, not {agent}",
                    file=sys.stderr,
                )
                conflicts = 1

    return 1 if conflicts else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
