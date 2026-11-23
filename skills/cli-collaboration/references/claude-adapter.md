# Claude Code Adapter

Use this reference when installing, activating, or operating `cli-collaboration` from Claude Code (Anthropic CLI).

## Triggering

Claude Code loads skills by matching the `description` field in `SKILL.md` frontmatter against the user's prompt and repository state, or via explicit `/cli-collaboration` invocation. The `cli-collaboration` description fires on:

- presence of `AGENT_HANDOFF.md` in the project root,
- presence of side-by-side `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` files,
- a dirty worktree from another session,
- explicit user requests like "resume", "continue from the handoff", or "what did the previous agent leave".

If the description does not match (very short or generic prompts), force-trigger with `/cli-collaboration` or `Use the cli-collaboration skill.`

## Install Path

Default install target for Claude Code:

```text
~/.claude/skills/cli-collaboration/
```

Use the package installer:

```bash
skills/cli-collaboration/scripts/install-skill.sh --claude
# or --target "$HOME/.claude/skills/cli-collaboration"
```

The installer backs up divergent targets into a sibling `skills-backups/` folder (outside `skills/`) and rolls back automatically on copy failure. Pass `--dry-run` to preview.

## Project Guidance (`CLAUDE.md`)

Add a concise pointer block to the project's `CLAUDE.md` (see `examples/CLAUDE.md`) so Claude Code always reads the handoff before editing without duplicating `SKILL.md` body content.

## Deterministic Hooks (`SessionStart` + `PreToolUse`)

For projects where reading the handoff and blocking ownership/destructive violations are non-negotiable, configure `.claude/settings.json` using [hook-guard.py](../scripts/hook-guard.py) (template in `examples/hooks/claude.settings.json`):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/skills/cli-collaboration/scripts/hook-guard.py --runtime claude --event session-start"
          }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Bash|Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": "python3 ~/.claude/skills/cli-collaboration/scripts/hook-guard.py --runtime claude --event pre-tool"
          }
        ]
      }
    ]
  }
}
```

- `SessionStart` injects a compact summary of `AGENT_HANDOFF.md` (or pause state) only when `AGENT_HANDOFF.md` is present.
- `PreToolUse` denies edits to foreign-owned, `user-reserved`, or `frozen` files (`--agent Claude`, which matches both `Claude` and `Claude Code`) and prompts (`"permissionDecision": "ask"`) on destructive git commands (`git reset --hard`, `git clean`, `git checkout --`, non-staged `git restore`, `git stash` outside `list`/`show`).

## Slash Command Toggle (Optional UX)

Create `.claude/commands/cli-collaboration.md` (or a project skill wrapper) if you want an explicit `/cli-collaboration on|off` toggle that creates/removes `.cli-collaboration-off` and sets/clears `**Status:** paused`. Pause disables procedural Start Gate/End-of-Shift overhead only; ownership and non-destructive git protections remain active.

## Agent Identity And Script Interaction

Use `Claude` (or `Claude Code` — `parse-ownership.py` normalizes both to `claude`):

```bash
CLAUDE_SKILL_HOME="${CLAUDE_HOME:-$HOME/.claude}/skills/cli-collaboration"
"$CLAUDE_SKILL_HOME/scripts/check-ownership.sh" --agent Claude <files...>
"$CLAUDE_SKILL_HOME/scripts/lang.sh" get
```

Always resolve `<SKILL_DIR>` relative to the installed skill directory when working outside this repository. Script ABI is owned by Codex and documented in `references/codex-adapter.md`.

## Known Limitations

- Claude Code does not consume `agents/claude.yaml` (symmetry-only file).
- Project `.claude/settings.json` hooks and `.claude/commands/` are per-repository unless placed in `~/.claude/settings.json`.
- SessionStart/PreToolUse hooks can be skipped if the user denies hook execution or explicitly overrides the protocol (`User Supersession`).

## Single-Session Variant

Even when Claude Code is the only CLI used on a project, maintain `AGENT_HANDOFF.md` as persistent cross-session project memory.

## Language Preference (documentary)

Binding behavior lives in `SKILL.md` → `## Language Preference`. Run `<SKILL_DIR>/scripts/lang.sh get`; if unset and writable, ask `Choose your language:` in English and run `scripts/lang.sh set "<answer>" --by CLAUDE`.
