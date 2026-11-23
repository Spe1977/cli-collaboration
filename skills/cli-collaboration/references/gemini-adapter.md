# Gemini CLI Adapter

Use this reference when installing, activating, or operating `cli-collaboration` from **Gemini CLI** (`gemini`).

> **Note:** For **Antigravity IDE / Antigravity 2.0 / `agy` CLI**, see [references/antigravity-adapter.md](./antigravity-adapter.md) and use agent identity `Antigravity` (kept distinct from `Gemini`).

## Discovery And Activation

Current Gemini CLI releases implement the Agent Skills lifecycle directly: they discover skill metadata at session start and call `activate_skill` when a task matches the description. The skill activates when:

- Gemini matches the shared `SKILL.md` description and requests activation.
- `GEMINI.md` instructs the agent to read `AGENT_HANDOFF.md` at the start of a session.
- The `activate_skill` tool is invoked explicitly by the user or an agent plan.
- A dirty worktree or an explicit user request indicates the need to resume work or collaborate with another agent.

## Install Path

Gemini CLI discovers user skills from either of these aliases:

```text
~/.gemini/skills/cli-collaboration/
~/.agents/skills/cli-collaboration/
```

Within the user tier, `.agents/skills/` takes precedence. **Do not install the same skill in both paths:** Gemini reports a duplicate-name conflict even when the payloads are identical. The default `install-skill.sh` run installs to the interoperable `~/.agents/skills/cli-collaboration` path.

For a Gemini-only installation (without `~/.agents/skills/`), use `--gemini` or an explicit `--target`:

```bash
skills/cli-collaboration/scripts/install-skill.sh --gemini
# or:
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.gemini/skills/cli-collaboration"
```

Verify native Gemini discovery with `gemini skills list --all`.

## Project Guidance (`GEMINI.md`)

Add a concise pointer block to the project's `GEMINI.md` (see `examples/GEMINI.md`) so Gemini CLI reads `AGENT_HANDOFF.md` at session start without duplicating the full `SKILL.md` protocol.

## Deterministic Hooks (`SessionStart` + `BeforeTool`)

Gemini CLI supports deterministic JSON hooks in `.gemini/settings.json` (or `~/.gemini/settings.json`). You can wire [hook-guard.py](../scripts/hook-guard.py) directly (ready-to-copy template in `examples/hooks/gemini.settings.json`):

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|resume",
        "hooks": [
          {
            "name": "cli-collaboration-session",
            "type": "command",
            "command": "python3 ~/.agents/skills/cli-collaboration/scripts/hook-guard.py --runtime gemini --event session-start"
          }
        ]
      }
    ],
    "BeforeTool": [
      {
        "matcher": "write_file|replace|run_shell_command|execute_command",
        "hooks": [
          {
            "name": "cli-collaboration-guard",
            "type": "command",
            "command": "python3 ~/.agents/skills/cli-collaboration/scripts/hook-guard.py --runtime gemini --event pre-tool"
          }
        ]
      }
    ]
  }
}
```

`BeforeTool` emits `{"decision": "deny", "reason": ...}` when a write targets a file owned by another agent, `user-reserved`, or `frozen` (`--agent Gemini`), or when a shell command runs a banned destructive git operation.

## Known Limitations

- **No Custom Toggle Slash Command:** Toggling pause state is filesystem-based (`.cli-collaboration-off` or `**Status:** paused` in `AGENT_HANDOFF.md`).
- **Activation Consent:** Native discovery loads only metadata; Gemini CLI prompts for consent before `activate_skill` injects the full skill body and bundled resources.
- **Parallel Subagents:** Parallel subagents must report back to one parent session; never mutate `AGENT_HANDOFF.md` concurrently.

## Forced Activation

When Gemini does not automatically pick up project guidance, use:

```text
Activate the cli-collaboration skill and read AGENT_HANDOFF.md before doing anything.
```

## Pause And Resume

1. `.cli-collaboration-off` in the project root.
2. `**Status:** paused` at the top of `AGENT_HANDOFF.md`.

Pause never authorizes destructive cleanup or bypassing `## File ownership`.

## Agent Identity And Script Interaction

Use `Gemini` (or `Gemini CLI` — `parse-ownership.py` normalizes both to `gemini`, distinct from `antigravity`):

```bash
GEMINI_SKILL_HOME="${AGENTS_HOME:-$HOME/.agents}/skills/cli-collaboration"
"$GEMINI_SKILL_HOME/scripts/check-ownership.sh" --agent Gemini <files...>
"$GEMINI_SKILL_HOME/scripts/lang.sh" get
```

Script ABI is owned by Codex and documented in `references/codex-adapter.md`.

## Single-Session Variant

Even when Gemini CLI is the only CLI used on a project, maintain `AGENT_HANDOFF.md` as cross-session project memory.

## Language Preference (documentary)

Binding behavior lives in `SKILL.md` → `## Language Preference`. Run `<SKILL_DIR>/scripts/lang.sh get`; if unset and writable, ask `Choose your language:` in English and run `scripts/lang.sh set "<answer>" --by GEMINI`.
