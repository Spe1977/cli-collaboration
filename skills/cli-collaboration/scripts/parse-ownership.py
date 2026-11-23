#!/usr/bin/env python3
"""Ownership conflict checker - full Python implementation.

This is the working body of `check-ownership.sh`. After seven rounds of
attempts the Bash-only parser proved unreliable on macOS Bash 3.2.57
whenever a handoff ownership line carried multibyte UTF-8 bytes
(en-dash, em-dash). Python handles UTF-8 natively, so the parser lives
here and is also reusable as a library by `hook-guard.py`.

CLI contract (preserved from the Bash version):
    usage: check-ownership.sh [--handoff PATH] [--agent NAME] FILE...
    env:   CLI_COLLAB_AGENT overrides the default agent name
    exit:  0  no conflict
           1  conflict against agent-owned, user-reserved, or frozen
           2  usage error or malformed/missing ## File ownership section

Glob semantics: `*` is allowed to cross `/`, matching the P1 doc-honest
glob contract enforced by the existing `handoff-glob-crosses-slash`
fixture. `fnmatch.fnmatchcase` replicates this behavior.

v2.6.0 enhancements:
- Case-insensitive agent alias normalization (keeping `Antigravity`
  distinct from `Gemini` / `Gemini CLI`).
- Relative `./` prefix cleanup and absolute-path relativization against
  the handoff directory.
"""
from __future__ import annotations

import fnmatch
import os
import posixpath
import re
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

AGENT_ALIASES: dict[str, str] = {
    "codex": "codex",
    "openai codex": "codex",
    "codex cli": "codex",
    "claude": "claude",
    "claude code": "claude",
    "anthropic claude": "claude",
    "gemini": "gemini",
    "gemini cli": "gemini",
    "grok": "grok",
    "grok build": "grok",
    "grok cli": "grok",
    "antigravity": "antigravity",
    "antigravity ide": "antigravity",
    "antigravity app": "antigravity",
    "antigravity 2.0": "antigravity",
    "antigravity cli": "antigravity",
    "agy": "antigravity",
}

SEPARATOR_RE = re.compile(r"\s*(?:—|–|--)\s*|\s+-(?:\s|$)")
PAREN_RE = re.compile(r"\([^)]*\)")


class OwnershipFormatError(ValueError):
    """Raised when AGENT_HANDOFF.md is unreadable or lacks valid ownership."""


def canonical_agent(value: str) -> str:
    """Normalize an agent name or alias to its canonical lowercase identifier."""
    stripped = PAREN_RE.sub(" ", value)
    unclosed = stripped.find("(")
    if unclosed >= 0:
        stripped = stripped[:unclosed]
    cleaned = " ".join(stripped.split()).lower()
    return AGENT_ALIASES.get(cleaned, cleaned)


def _normalize_pattern(pattern: str) -> str:
    cleaned = pattern.strip().replace("\\", "/")
    while cleaned.startswith("./"):
        cleaned = cleaned[2:]
    return cleaned


def normalize_target_path(raw_path: str, handoff_dir: Path) -> str:
    """Normalize `./` and absolute paths within the handoff directory."""
    if not raw_path:
        return raw_path
    p = Path(raw_path)
    if p.is_absolute():
        try:
            rel = p.resolve().relative_to(handoff_dir.resolve())
            return rel.as_posix()
        except ValueError:
            return p.resolve().as_posix()
    cleaned = posixpath.normpath(raw_path.replace("\\", "/"))
    while cleaned.startswith("./"):
        cleaned = cleaned[2:]
    return cleaned


def _extract_owner(rest: str) -> str:
    """Extract the owner phrase prior to the separator, stripping notes."""
    match = SEPARATOR_RE.search(rest)
    if match:
        candidate = rest[:match.start()].strip()
    else:
        stripped = PAREN_RE.sub(" ", rest)
        unclosed = stripped.find("(")
        if unclosed >= 0:
            stripped = stripped[:unclosed]
        full_cleaned = " ".join(stripped.split()).lower()
        if full_cleaned in AGENT_ALIASES:
            return " ".join(stripped.split())
        tokens = rest.split()
        candidate = tokens[0] if tokens else ""

    stripped = PAREN_RE.sub(" ", candidate)
    unclosed = stripped.find("(")
    if unclosed >= 0:
        stripped = stripped[:unclosed]
    return " ".join(stripped.split())


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


def parse_ownership(
    handoff_path: Path,
) -> tuple[list[tuple[str, str]], list[str], list[str]]:
    """Parse `## File ownership` subsections from a handoff file."""
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
        raise OwnershipFormatError(
            f"cannot read handoff {handoff_path}: {exc}"
        ) from exc

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

        raw_pattern, _, rest = entry.partition(":")
        pattern = _normalize_pattern(raw_pattern)
        if not pattern or not rest.strip():
            malformed = True
            continue

        owner = _extract_owner(rest)
        if not owner:
            malformed = True
            continue

        if current == "agent-owned":
            owned.append((pattern, owner))
        elif current == "user-reserved":
            user_reserved.append(pattern)
        elif current == "frozen":
            frozen.append(pattern)
        valid_lines += 1

    if (
        not in_ownership
        or not all(seen.values())
        or valid_lines == 0
        or malformed
    ):
        raise OwnershipFormatError(
            f"malformed or missing ## File ownership section in {handoff_path}"
        )

    return owned, user_reserved, frozen


def find_conflicts(
    handoff_path: Path, agent: str, files: list[str]
) -> list[str]:
    """Return human-readable ownership conflict descriptions for `files`."""
    owned, user_reserved, frozen = parse_ownership(handoff_path)
    handoff_dir = handoff_path.parent
    caller = canonical_agent(agent)
    conflicts: list[str] = []

    for raw_file in files:
        norm_file = normalize_target_path(raw_file, handoff_dir)
        for pattern in frozen:
            if fnmatch.fnmatchcase(norm_file, pattern):
                conflicts.append(
                    f"conflict: {norm_file} matches frozen ownership {pattern}"
                )
        for pattern in user_reserved:
            if fnmatch.fnmatchcase(norm_file, pattern):
                conflicts.append(
                    f"conflict: {norm_file} matches user-reserved ownership {pattern}"
                )
        for pattern, owner in owned:
            if fnmatch.fnmatchcase(norm_file, pattern) and canonical_agent(owner) != caller:
                conflicts.append(
                    f"conflict: {norm_file} is owned by {owner} via {pattern}, not {agent}"
                )

    return conflicts


def main(argv: list[str]) -> int:
    handoff, agent, files = _parse_args(argv)

    handoff_path = Path(handoff)
    if not handoff_path.is_file():
        print(f"handoff not found: {handoff}", file=sys.stderr)
        return 2

    try:
        conflicts = find_conflicts(handoff_path, agent, files)
    except OwnershipFormatError as exc:
        print(str(exc), file=sys.stderr)
        return 2

    for msg in conflicts:
        print(msg, file=sys.stderr)

    return 1 if conflicts else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
