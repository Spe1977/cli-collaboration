#!/usr/bin/env python3
"""Deterministic lifecycle hook guard for cli-collaboration.

Supports Antigravity (hooks.json), Claude Code (.claude/settings.json), and
Gemini CLI (.gemini/settings.json) across SessionStart, PreToolUse/BeforeTool,
and Stop events.

Contract:
- Reads JSON payload from stdin.
- Writes ONLY valid JSON to stdout.
- Sends any diagnostics to stderr.
- Imports sibling `parse-ownership.py` so ownership rules stay single-source.
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import os
import re
import shlex
import subprocess
import sys
sys.dont_write_bytecode = True
from pathlib import Path
from typing import Any

DEFAULT_AGENT_BY_RUNTIME = {
    "antigravity": "Antigravity",
    "claude": "Claude",
    "gemini": "Gemini",
}

SHELL_TOOLS = {
    "run_command",
    "bash",
    "run_shell_command",
    "execute_command",
}

FILE_EDIT_TOOLS = {
    "write_file",
    "edit_file",
    "write",
    "edit",
    "multiedit",
    "replace",
}

REQUIRED_HANDOFF_HEADINGS = (
    "## Current task",
    "## File ownership",
    "## Files changed this shift",
    "## Tests",
    "## Open concerns",
    "## Next agent starts from",
    "## History",
)

GIT_VALUE_FLAGS = {"-C", "-c", "--git-dir", "--work-tree", "--namespace"}
STATUS_PAUSED_RE = re.compile(r"^\*\*Status:\*\*\s*paused\b", re.IGNORECASE)


def _load_ownership_module() -> Any:
    helper = Path(__file__).resolve().with_name("parse-ownership.py")
    spec = importlib.util.spec_from_file_location("parse_ownership", helper)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load {helper}")
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _read_stdin_json() -> dict[str, Any]:
    raw = sys.stdin.read().strip()
    if not raw:
        return {}
    try:
        data = json.loads(raw)
        return data if isinstance(data, dict) else {}
    except json.JSONDecodeError as exc:
        print(f"hook-guard: invalid stdin JSON: {exc}", file=sys.stderr)
        return {}


def _find_handoff_dir(payload: dict[str, Any]) -> Path:
    candidates: list[Path] = []
    cwd = payload.get("cwd")
    if isinstance(cwd, str) and cwd.strip():
        candidates.append(Path(cwd))

    ws_paths = payload.get("workspacePaths")
    if isinstance(ws_paths, list):
        for entry in ws_paths:
            if isinstance(entry, str) and entry.strip():
                candidates.append(Path(entry))

    project_dir = payload.get("projectDir")
    if isinstance(project_dir, str) and project_dir.strip():
        candidates.append(Path(project_dir))

    if not candidates:
        candidates.append(Path.cwd())

    for cand in candidates:
        if (cand / "AGENT_HANDOFF.md").is_file():
            return cand
    return candidates[0]


def _is_paused(handoff_dir: Path, handoff_text: str) -> bool:
    if (handoff_dir / ".cli-collaboration-off").exists():
        return True
    for line in handoff_text.splitlines()[:20]:
        if STATUS_PAUSED_RE.match(line.strip()):
            return True
    return False


def _first_lines_in_section(text: str, heading: str, limit: int = 1) -> str:
    lines = text.splitlines()
    start = None
    for idx, line in enumerate(lines):
        if line.strip() == heading:
            start = idx + 1
            break
    if start is None:
        return ""
    collected: list[str] = []
    for line in lines[start:]:
        if line.startswith("## ") and not line.startswith("### "):
            break
        stripped = line.strip()
        if stripped:
            collected.append(stripped)
            if len(collected) >= limit:
                break
    return " ".join(collected)


def _extract_session_summary(handoff_dir: Path, handoff_path: Path) -> str:
    text = handoff_path.read_text(encoding="utf-8", errors="replace")
    if _is_paused(handoff_dir, text):
        return (
            "cli-collaboration is paused (.cli-collaboration-off or Status: paused). "
            "Start Gate and End-of-Shift overhead are suspended, but File ownership "
            "(user-reserved/frozen/agent-owned) and non-destructive git rules remain active."
        )

    last_updated = ""
    last_agent = ""
    status = ""
    for line in text.splitlines()[:20]:
        s = line.strip()
        if s.startswith("**Last updated:**"):
            last_updated = s.split("**Last updated:**", 1)[1].strip()
        elif s.startswith("**Last agent:**"):
            last_agent = s.split("**Last agent:**", 1)[1].strip()
        elif s.startswith("**Status:**"):
            status = s.split("**Status:**", 1)[1].strip()

    task_line = _first_lines_in_section(text, "## Current task", limit=1)
    next_lines = _first_lines_in_section(text, "## Next agent starts from", limit=2)

    parts = [
        "cli-collaboration active (AGENT_HANDOFF.md found).",
        f"Last updated: {last_updated or 'unknown'} | Last agent: {last_agent or 'unknown'} | Status: {status or 'unknown'}",
    ]
    if task_line:
        parts.append(f"Current task: {task_line[:180]}")
    if next_lines:
        parts.append(f"Next agent starts from: {next_lines[:220]}")
    parts.append(
        "Read AGENT_HANDOFF.md first, declare the Start Gate before editing, "
        "respect File ownership, and update AGENT_HANDOFF.md last."
    )
    return "\n".join(parts)


def _emit_session_start(runtime: str, message: str | None) -> dict[str, Any]:
    if not message:
        return {}
    if runtime == "antigravity":
        return {"injectSteps": [{"systemMessage": {"systemMessage": message}}]}
    if runtime == "claude":
        return {
            "hookSpecificOutput": {
                "hookEventName": "SessionStart",
                "additionalContext": message,
            }
        }
    return {"systemMessage": message, "context": message}


def _extract_tool_call(
    runtime: str, payload: dict[str, Any]
) -> tuple[str, dict[str, Any]]:
    if runtime == "antigravity":
        tc = payload.get("toolCall")
        if isinstance(tc, dict):
            name = str(tc.get("name") or "")
            args = tc.get("args")
            return name, args if isinstance(args, dict) else {}
    elif runtime == "claude":
        name = str(payload.get("tool_name") or "")
        args = payload.get("tool_input")
        return name, args if isinstance(args, dict) else {}

    name = str(payload.get("toolName") or payload.get("tool_name") or "")
    args = payload.get("toolInput") or payload.get("tool_input")
    return name, args if isinstance(args, dict) else {}


def _split_shell_segments(command: str) -> list[list[str]]:
    lexer = shlex.shlex(command, posix=True, punctuation_chars=";|&")
    lexer.whitespace_split = True
    segments: list[list[str]] = []
    current: list[str] = []
    for token in lexer:
        if token in {";", "&&", "||", "|", "&", ";;", "\n"}:
            if current:
                segments.append(current)
                current = []
        else:
            current.append(token)
    if current:
        segments.append(current)
    return segments


def _inspect_git_segment(tokens: list[str]) -> str | None:
    idx = 0
    while idx < len(tokens) and "=" in tokens[idx] and not tokens[idx].startswith("-"):
        key = tokens[idx].split("=", 1)[0]
        if key.replace("_", "").isalnum():
            idx += 1
        else:
            break
    if idx >= len(tokens):
        return None
    if Path(tokens[idx]).name != "git":
        return None

    idx += 1
    while idx < len(tokens):
        tok = tokens[idx]
        if tok in GIT_VALUE_FLAGS:
            idx += 2
            continue
        if tok.startswith("-"):
            idx += 1
            continue
        break

    if idx >= len(tokens):
        return None

    subcmd = tokens[idx]
    rest = tokens[idx + 1:]

    if subcmd == "reset" and "--hard" in rest:
        return "git reset --hard"

    if subcmd == "clean":
        has_dry_run = any(a in {"-n", "--dry-run"} for a in rest)
        has_force = any(
            a == "--force" or (a.startswith("-") and not a.startswith("--") and "f" in a[1:])
            for a in rest
        )
        if has_force or not has_dry_run:
            return "git clean"

    if subcmd == "checkout" and "--" in rest:
        return "git checkout --"

    if subcmd == "restore":
        has_staged = any(a in {"--staged", "-S"} for a in rest)
        has_worktree = any(a in {"--worktree", "-W"} for a in rest)
        if not (has_staged and not has_worktree):
            return "git restore"

    if subcmd == "stash":
        sub_action = next((a for a in rest if not a.startswith("-")), "")
        if sub_action not in {"list", "show"}:
            return "git stash"

    return None


def _detect_destructive_git(command: str) -> str | None:
    try:
        segments = _split_shell_segments(command)
    except ValueError:
        for pattern, label in (
            (r"\bgit\b[^;\n|]*\breset\b[^;\n|]*--hard\b", "git reset --hard"),
            (r"\bgit\b[^;\n|]*\bclean\b", "git clean"),
            (r"\bgit\b[^;\n|]*\bcheckout\b[^;\n|]*--(?:\s|$)", "git checkout --"),
            (r"\bgit\b[^;\n|]*\brestore\b", "git restore"),
            (r"\bgit\b[^;\n|]*\bstash\b", "git stash"),
        ):
            if re.search(pattern, command):
                return label
        return None

    for seg in segments:
        hit = _inspect_git_segment(seg)
        if hit:
            return hit
    return None


def _emit_pre_tool_allow(runtime: str) -> dict[str, Any]:
    if runtime == "claude":
        return {}
    return {"decision": "allow"}


def _emit_pre_tool_decision(
    runtime: str, decision: str, reason: str
) -> dict[str, Any]:
    if runtime == "claude":
        return {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": decision,
                "permissionDecisionReason": reason,
            }
        }
    if runtime == "gemini":
        mapped = "deny" if decision in {"deny", "ask", "force_ask"} else "allow"
        return {"decision": mapped, "reason": reason}
    return {"decision": decision, "reason": reason}


def _handle_session_start(runtime: str, payload: dict[str, Any]) -> dict[str, Any]:
    handoff_dir = _find_handoff_dir(payload)
    handoff_path = handoff_dir / "AGENT_HANDOFF.md"
    if not handoff_path.is_file():
        return _emit_session_start(runtime, None)
    summary = _extract_session_summary(handoff_dir, handoff_path)
    return _emit_session_start(runtime, summary)


def _handle_pre_tool(
    runtime: str,
    payload: dict[str, Any],
    agent: str,
    destructive_mode: str,
    ownership_mod: Any,
) -> dict[str, Any]:
    handoff_dir = _find_handoff_dir(payload)
    handoff_path = handoff_dir / "AGENT_HANDOFF.md"
    if not handoff_path.is_file():
        return _emit_pre_tool_allow(runtime)

    tool_name, tool_args = _extract_tool_call(runtime, payload)
    tool_key = tool_name.lower()

    if tool_key in SHELL_TOOLS:
        cmd = str(tool_args.get("CommandLine") or tool_args.get("command") or "")
        if cmd:
            hit = _detect_destructive_git(cmd)
            if hit:
                if destructive_mode == "deny":
                    decision = "deny"
                elif runtime == "antigravity":
                    decision = "force_ask"
                else:
                    decision = "ask"
                reason = (
                    f"cli-collaboration guardrail: '{hit}' requires explicit user "
                    "approval when AGENT_HANDOFF.md is active."
                )
                return _emit_pre_tool_decision(runtime, decision, reason)

    if tool_key in FILE_EDIT_TOOLS:
        raw_path = str(
            tool_args.get("Path")
            or tool_args.get("file_path")
            or tool_args.get("path")
            or ""
        )
        if raw_path:
            norm_path = ownership_mod.normalize_target_path(raw_path, handoff_dir)
            if norm_path == "AGENT_HANDOFF.md":
                return _emit_pre_tool_allow(runtime)
            try:
                conflicts = ownership_mod.find_conflicts(
                    handoff_path, agent, [raw_path]
                )
            except ownership_mod.OwnershipFormatError as exc:
                decision = "force_ask" if runtime == "antigravity" else "ask"
                return _emit_pre_tool_decision(
                    runtime, decision, f"cli-collaboration guardrail: {exc}"
                )
            if conflicts:
                reason = (
                    f"cli-collaboration ownership conflict for {agent}: "
                    f"{'; '.join(conflicts)}. Stop and ask the user or owning "
                    "agent for reassignment."
                )
                return _emit_pre_tool_decision(runtime, "deny", reason)

    return _emit_pre_tool_allow(runtime)


def _handle_stop(
    runtime: str, payload: dict[str, Any], ownership_mod: Any
) -> dict[str, Any]:
    if runtime != "antigravity":
        return {}

    if payload.get("continuationActive"):
        return {"decision": "allow"}

    term_reason = payload.get("terminationReason")
    if isinstance(term_reason, str) and term_reason and term_reason != "NO_TOOL_CALL":
        return {"decision": "allow"}

    handoff_dir = _find_handoff_dir(payload)
    handoff_path = handoff_dir / "AGENT_HANDOFF.md"
    if not handoff_path.is_file():
        return {"decision": "allow"}

    try:
        res = subprocess.run(
            ["git", "-C", str(handoff_dir), "status", "--porcelain", "--", "AGENT_HANDOFF.md"],
            capture_output=True,
            text=True,
            timeout=3,
            check=False,
        )
    except (OSError, subprocess.SubprocessError):
        return {"decision": "allow"}

    if res.returncode != 0 or not res.stdout.strip():
        return {"decision": "allow"}

    problems: list[str] = []
    text = handoff_path.read_text(encoding="utf-8", errors="replace")
    for heading in REQUIRED_HANDOFF_HEADINGS:
        if heading not in text:
            problems.append(f"missing '{heading}'")

    try:
        ownership_mod.parse_ownership(handoff_path)
    except ownership_mod.OwnershipFormatError as exc:
        problems.append(str(exc))

    if problems:
        return {
            "decision": "continue",
            "reason": (
                "cli-collaboration guardrail: AGENT_HANDOFF.md was modified this "
                f"shift but failed structural validation ({'; '.join(problems)}). "
                "Fix AGENT_HANDOFF.md before finishing."
            ),
        }

    return {"decision": "allow"}


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--runtime",
        required=True,
        choices=("antigravity", "claude", "gemini"),
    )
    parser.add_argument(
        "--event",
        required=True,
        choices=("session-start", "pre-tool", "stop"),
    )
    parser.add_argument("--agent", default=None)
    parser.add_argument(
        "--destructive-mode",
        default="ask",
        choices=("ask", "deny"),
    )
    args = parser.parse_args(argv)

    payload = _read_stdin_json()
    agent = (
        args.agent
        or os.environ.get("CLI_COLLAB_AGENT")
        or DEFAULT_AGENT_BY_RUNTIME[args.runtime]
    )

    if args.event == "session-start":
        out = _handle_session_start(args.runtime, payload)
    elif args.event == "pre-tool":
        ownership_mod = _load_ownership_module()
        out = _handle_pre_tool(
            args.runtime, payload, agent, args.destructive_mode, ownership_mod
        )
    else:
        ownership_mod = _load_ownership_module()
        out = _handle_stop(args.runtime, payload, ownership_mod)

    sys.stdout.write(json.dumps(out) + "\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
