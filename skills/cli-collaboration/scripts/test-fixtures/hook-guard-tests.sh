#!/usr/bin/env bash
# Test suite for hook-guard.py across Antigravity, Claude Code, and Gemini CLI.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
HOOK_GUARD="$SCRIPTS_ROOT/hook-guard.py"
REPO_ROOT="$(cd "$SCRIPTS_ROOT/../../.." && pwd)"

[ -f "$HOOK_GUARD" ] || { echo "fail - hook-guard.py missing" >&2; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "fail - python3 not found" >&2; exit 1; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

python3 - "$HOOK_GUARD" "$WORK" "$REPO_ROOT" <<'PY'
import json
import shlex
import subprocess
import sys
from pathlib import Path

hook_guard = Path(sys.argv[1])
work = Path(sys.argv[2])
repo_root = Path(sys.argv[3])


def run_hook_raw(
    runtime: str,
    event: str,
    raw_stdin: str,
    extra_args: list[str] | None = None,
    cwd: Path | None = None,
) -> dict:
    cmd = ["python3", str(hook_guard), "--runtime", runtime, "--event", event]
    if extra_args:
        cmd.extend(extra_args)
    res = subprocess.run(
        cmd,
        input=raw_stdin,
        text=True,
        capture_output=True,
        cwd=str(cwd) if cwd else None,
        check=False,
    )
    if res.returncode != 0:
        raise AssertionError(
            f"{runtime}/{event} exited {res.returncode}; stderr={res.stderr}"
        )
    try:
        return json.loads(res.stdout)
    except json.JSONDecodeError as exc:
        raise AssertionError(
            f"{runtime}/{event} invalid JSON stdout {res.stdout!r}: {exc}"
        ) from exc


def run_hook(
    runtime: str,
    event: str,
    payload: dict,
    extra_args: list[str] | None = None,
    cwd: Path | None = None,
) -> dict:
    return run_hook_raw(runtime, event, json.dumps(payload), extra_args, cwd)


# 1. SessionStart without AGENT_HANDOFF.md -> empty {}
empty_ws = work / "empty-ws"
empty_ws.mkdir()
for rt in ("antigravity", "claude", "gemini"):
    out = run_hook(rt, "session-start", {"cwd": str(empty_ws)})
    assert out == {}, f"{rt} expected {{}} without handoff, got {out}"
print("ok - hook-session-start-empty")

# 2. SessionStart with active AGENT_HANDOFF.md
ws = work / "repo"
ws.mkdir()
handoff = ws / "AGENT_HANDOFF.md"
handoff.write_text(
    """# AGENT_HANDOFF.md

**Last updated:** 2026-11-23T12:00:00+01:00
**Last agent:** Codex
**Status:** in-progress

## Current task
Implement hook guards.

## File ownership
### agent-owned
- src/ide.ts: Antigravity — IDE adapter
- src/claude.ts: Claude Code — Claude module
- src/cli.ts: Gemini CLI — Gemini CLI module
### user-reserved
- .env: user — secrets
### frozen
- CHANGELOG.md: frozen — released

## Files changed this shift
- src/ide.ts: initial stub

## Tests
- Red: none
- Green: none ran

## Open concerns
- Needs cross-runtime hook tests.

## Next agent starts from
Next agent: Antigravity. Continue at src/ide.ts:1. Do not touch src/cli.ts or .env.

## History
- 2026-11-23T12:00:00+01:00 - Codex: setup ownership fixture. (in-progress)
""",
    encoding="utf-8",
)

ag_ss = run_hook("antigravity", "session-start", {"workspacePaths": [str(ws)]})
assert "AGENT_HANDOFF.md found" in ag_ss["injectSteps"][0]["systemMessage"]["systemMessage"]
cl_ss = run_hook("claude", "session-start", {"cwd": str(ws)})
assert "AGENT_HANDOFF.md found" in cl_ss["hookSpecificOutput"]["additionalContext"]
gm_ss = run_hook("gemini", "session-start", {"projectDir": str(ws)})
assert "AGENT_HANDOFF.md found" in gm_ss["systemMessage"]
assert "AGENT_HANDOFF.md found" in gm_ss["context"]
print("ok - hook-session-start-active")

# 3. SessionStart paused notice
sentinel = ws / ".cli-collaboration-off"
sentinel.touch()
ag_paused = run_hook("antigravity", "session-start", {"cwd": str(ws)})
assert "paused" in ag_paused["injectSteps"][0]["systemMessage"]["systemMessage"].lower()
sentinel.unlink()
print("ok - hook-session-start-paused")

# 4. PreToolUse / BeforeTool file ownership across all 3 runtimes (relative, ./, absolute)
assert run_hook(
    "antigravity",
    "pre-tool",
    {"cwd": str(ws), "toolCall": {"name": "write_file", "args": {"Path": str(ws / "src/ide.ts")}}},
) == {"decision": "allow"}
assert run_hook(
    "claude",
    "pre-tool",
    {"cwd": str(ws), "tool_name": "Edit", "tool_input": {"file_path": "./src/claude.ts"}},
) == {}
assert run_hook(
    "gemini",
    "pre-tool",
    {"projectDir": str(ws), "toolName": "write_file", "toolInput": {"path": "src/cli.ts"}},
) == {"decision": "allow"}

# AGENT_HANDOFF.md itself always allowed
assert run_hook(
    "antigravity",
    "pre-tool",
    {"cwd": str(ws), "toolCall": {"name": "edit_file", "args": {"Path": str(handoff)}}},
) == {"decision": "allow"}

# Antigravity blocked from Gemini-owned file (via absolute path), user-reserved, and frozen
for target in (str(ws / "src/cli.ts"), "./.env", "CHANGELOG.md"):
    res = run_hook(
        "antigravity",
        "pre-tool",
        {"cwd": str(ws), "toolCall": {"name": "edit_file", "args": {"Path": target}}},
    )
    assert res["decision"] == "deny", f"expected deny for {target}, got {res}"

# Claude blocked from Antigravity-owned file
cl_deny = run_hook(
    "claude",
    "pre-tool",
    {"cwd": str(ws), "tool_name": "Write", "tool_input": {"file_path": "src/ide.ts"}},
)
assert cl_deny["hookSpecificOutput"]["permissionDecision"] == "deny"

# Gemini blocked from Claude-owned file
gm_deny = run_hook(
    "gemini",
    "pre-tool",
    {"projectDir": str(ws), "toolName": "replace", "toolInput": {"file_path": "src/claude.ts"}},
)
assert gm_deny["decision"] == "deny"
print("ok - hook-pre-tool-ownership")

# 5. PreToolUse / BeforeTool destructive git guards
destructive_cmds = [
    "git reset --hard",
    "git clean -fd",
    "git checkout -- src/ide.ts",
    "git restore src/ide.ts",
    "git stash",
    "echo ok && git reset --hard HEAD~1",
]
for cmd in destructive_cmds:
    ag_g = run_hook(
        "antigravity",
        "pre-tool",
        {"cwd": str(ws), "toolCall": {"name": "run_command", "args": {"CommandLine": cmd}}},
    )
    assert ag_g["decision"] == "force_ask", f"antigravity expected force_ask for {cmd!r}, got {ag_g}"

    ag_d = run_hook(
        "antigravity",
        "pre-tool",
        {"cwd": str(ws), "toolCall": {"name": "run_command", "args": {"CommandLine": cmd}}},
        ["--destructive-mode", "deny"],
    )
    assert ag_d["decision"] == "deny"

    cl_g = run_hook(
        "claude",
        "pre-tool",
        {"cwd": str(ws), "tool_name": "Bash", "tool_input": {"command": cmd}},
    )
    assert cl_g["hookSpecificOutput"]["permissionDecision"] == "ask"

    gm_g = run_hook(
        "gemini",
        "pre-tool",
        {"projectDir": str(ws), "toolName": "run_shell_command", "toolInput": {"command": cmd}},
    )
    assert gm_g["decision"] == "deny"

safe_cmds = [
    "git status --short",
    "git diff",
    "git stash list",
    "git stash show",
    "git restore --staged src/ide.ts",
    'git commit -m "never run git reset --hard here"',
]
for cmd in safe_cmds:
    assert run_hook(
        "antigravity",
        "pre-tool",
        {"cwd": str(ws), "toolCall": {"name": "run_command", "args": {"CommandLine": cmd}}},
    ) == {"decision": "allow"}, f"false positive for {cmd!r}"
    assert run_hook(
        "claude",
        "pre-tool",
        {"cwd": str(ws), "tool_name": "Bash", "tool_input": {"command": cmd}},
    ) == {}, f"claude false positive for {cmd!r}"
print("ok - hook-pre-tool-destructive-git")

# 6. Antigravity Stop hook validation in a temp git repository
subprocess.run(["git", "-C", str(ws), "init", "-q"], check=True)
subprocess.run(["git", "-C", str(ws), "config", "user.email", "test@example.com"], check=True)
subprocess.run(["git", "-C", str(ws), "config", "user.name", "Test"], check=True)
subprocess.run(["git", "-C", str(ws), "add", "AGENT_HANDOFF.md"], check=True)
subprocess.run(["git", "-C", str(ws), "commit", "-q", "-m", "init"], check=True)

assert run_hook(
    "antigravity",
    "stop",
    {"cwd": str(ws), "terminationReason": "NO_TOOL_CALL", "continuationActive": False},
) == {"decision": "allow"}

saved = handoff.read_text(encoding="utf-8")
handoff.write_text("# AGENT_HANDOFF.md\nbroken\n", encoding="utf-8")
stop_cont = run_hook(
    "antigravity",
    "stop",
    {"cwd": str(ws), "terminationReason": "NO_TOOL_CALL", "continuationActive": False},
)
assert stop_cont["decision"] == "continue", f"expected continue on broken handoff, got {stop_cont}"

# Anti-loop: continuationActive=True must allow even if handoff is broken
assert run_hook(
    "antigravity",
    "stop",
    {"cwd": str(ws), "terminationReason": "NO_TOOL_CALL", "continuationActive": True},
) == {"decision": "allow"}

handoff.write_text(saved + "\n", encoding="utf-8")
assert run_hook(
    "antigravity",
    "stop",
    {"cwd": str(ws), "terminationReason": "NO_TOOL_CALL", "continuationActive": False},
) == {"decision": "allow"}
print("ok - hook-stop-validation")

# 7. PreToolUse while paused STILL enforces ownership and destructive git
sentinel.touch()
paused_deny = run_hook(
    "antigravity",
    "pre-tool",
    {"cwd": str(ws), "toolCall": {"name": "edit_file", "args": {"Path": "src/cli.ts"}}},
)
assert paused_deny["decision"] == "deny", f"paused mode weakened ownership: {paused_deny}"
paused_git = run_hook(
    "antigravity",
    "pre-tool",
    {"cwd": str(ws), "toolCall": {"name": "run_command", "args": {"CommandLine": "git reset --hard"}}},
)
assert paused_git["decision"] == "force_ask", f"paused mode weakened git guard: {paused_git}"
sentinel.unlink()
print("ok - hook-pre-tool-while-paused")

# 8. PreToolUse with malformed AGENT_HANDOFF.md
mal_ws = work / "malformed-ws"
mal_ws.mkdir()
(mal_ws / "AGENT_HANDOFF.md").write_text(
    "# AGENT_HANDOFF.md\n\n## File ownership\n### agent-owned\n- a.txt: Codex — x\n",
    encoding="utf-8",
)
assert run_hook(
    "antigravity",
    "pre-tool",
    {"cwd": str(mal_ws), "toolCall": {"name": "edit_file", "args": {"Path": "a.txt"}}},
)["decision"] == "force_ask"
assert run_hook(
    "claude",
    "pre-tool",
    {"cwd": str(mal_ws), "tool_name": "Edit", "tool_input": {"file_path": "a.txt"}},
)["hookSpecificOutput"]["permissionDecision"] == "ask"
assert run_hook(
    "gemini",
    "pre-tool",
    {"projectDir": str(mal_ws), "toolName": "write_file", "toolInput": {"path": "a.txt"}},
)["decision"] == "deny"
print("ok - hook-pre-tool-malformed-handoff")

# 9. Tricky git variants, dry-run clean allow, and unclosed quote regex fallback
tricky_destructive = [
    "git -C /tmp/repo reset --hard",
    "FOO=1 git clean -fdx",
    "/usr/bin/git restore src/ide.ts",
    "git restore --staged --worktree src/ide.ts",
    'git stash push -m "wip"',
    "git stash drop",
    "git stash clear",
    'git reset --hard "unclosed',
]
for cmd in tricky_destructive:
    out = run_hook(
        "antigravity",
        "pre-tool",
        {"cwd": str(ws), "toolCall": {"name": "run_command", "args": {"CommandLine": cmd}}},
    )
    assert out["decision"] == "force_ask", f"expected force_ask for {cmd!r}, got {out}"

for dry_clean in ("git clean -n", "git clean --dry-run"):
    out = run_hook(
        "antigravity",
        "pre-tool",
        {"cwd": str(ws), "toolCall": {"name": "run_command", "args": {"CommandLine": dry_clean}}},
    )
    assert out == {"decision": "allow"}, f"dry-run clean blocked: {dry_clean!r} -> {out}"
print("ok - hook-pre-tool-tricky-git")

# 10. Empty/invalid stdin JSON + non-NO_TOOL_CALL Stop termination reasons
for raw in ("", "   ", "{not valid json"):
    out = run_hook_raw("antigravity", "session-start", raw, cwd=empty_ws)
    assert out == {}, f"expected {{}} for invalid stdin {raw!r}, got {out}"

handoff.write_text("# AGENT_HANDOFF.md\nbroken\n", encoding="utf-8")
for term in ("USER_CANCELED", "ERROR"):
    out = run_hook(
        "antigravity",
        "stop",
        {"cwd": str(ws), "terminationReason": term, "continuationActive": False},
    )
    assert out == {"decision": "allow"}, f"stop on {term} should allow: {out}"
handoff.write_text(saved + "\n", encoding="utf-8")
print("ok - hook-invalid-stdin-and-stop-reasons")

# 11. Validate CLI flags inside examples/hooks/*.json templates
hooks_dir = repo_root / "examples" / "hooks"
if hooks_dir.is_dir():
    def _collect_commands(obj: object) -> list[str]:
        cmds: list[str] = []
        if isinstance(obj, dict):
            if obj.get("type") == "command" and isinstance(obj.get("command"), str):
                cmds.append(obj["command"])
            for v in obj.values():
                cmds.extend(_collect_commands(v))
        elif isinstance(obj, list):
            for item in obj:
                cmds.extend(_collect_commands(item))
        return cmds

    template_files = sorted(hooks_dir.glob("*.json"))
    assert len(template_files) == 3, f"expected 3 hook templates, found {template_files}"
    for tf in template_files:
        data = json.loads(tf.read_text(encoding="utf-8"))
        cmds = _collect_commands(data)
        assert cmds, f"no hook commands found in {tf}"
        for cmd_str in cmds:
            tokens = shlex.split(cmd_str)
            idx = next(i for i, t in enumerate(tokens) if t.endswith("hook-guard.py"))
            flags = tokens[idx + 1:]
            res = subprocess.run(
                ["python3", str(hook_guard), *flags],
                input=json.dumps({"cwd": str(empty_ws)}),
                text=True,
                capture_output=True,
                check=False,
            )
            assert res.returncode == 0, f"template {tf.name} failed with flags {flags}: {res.stderr}"
            json.loads(res.stdout)
    print("ok - hook-example-templates-valid")
PY
