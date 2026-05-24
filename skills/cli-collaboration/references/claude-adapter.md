# Claude Code Adapter

Use this reference when installing, activating, or operating `cli-collaboration` from Claude Code (Anthropic CLI).

## Triggering

Claude Code loads skills by matching the `description` field in `SKILL.md` frontmatter against the user's prompt and the current repository state. The `cli-collaboration` description fires on:

- presence of `AGENT_HANDOFF.md` in the project root,
- presence of side-by-side `CLAUDE.md` / `AGENTS.md` / `GEMINI.md` files,
- a dirty worktree from another session,
- explicit user requests like "resume", "continue from the handoff", or "what did the previous agent leave".

If the description does not match (very short or generic prompts), force-trigger with an explicit invocation: `Use the cli-collaboration skill.`

## Install Path

Default install target for Claude Code:

```
~/.claude/skills/cli-collaboration/
```

Use the package installer:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.claude/skills/cli-collaboration"
```

The installer is idempotent and backs up divergent targets before copying. To preview without writing, pass `--dry-run`.

## Project Guidance (`CLAUDE.md`)

Add this paragraph to the project's `CLAUDE.md` so that Claude Code reads the handoff at the start of every session, regardless of whether the skill-loader has already triggered:

```markdown
When `AGENT_HANDOFF.md` exists at the project root, read it before any other
file. Apply the `cli-collaboration` skill: declare the start gate, respect
`### agent-owned`, `### user-reserved`, and `### frozen` sections, and update
the handoff last with files changed, tests, open concerns, and the next
concrete step.
```

`CLAUDE.md` is loaded into Claude Code's context automatically, so this directive is the cheapest "always-on" mechanism available without harness configuration.

## SessionStart Hook (Optional)

For projects where reading the handoff is non-negotiable, configure a SessionStart hook in `.claude/settings.json`:

```jsonc
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "test -f AGENT_HANDOFF.md && cat AGENT_HANDOFF.md || true"
          }
        ]
      }
    ]
  }
}
```

The hook injects the handoff into the session opening so the agent cannot proceed without seeing it. Pair this with the `CLAUDE.md` directive above for defense in depth.

## Slash Command (Optional UX)

A project-level slash command can toggle the procedural overhead without disabling the protective behavior. Create `.claude/commands/cli-collaboration.md`:

```markdown
---
description: Toggle cli-collaboration procedural overhead on/off
---

# /cli-collaboration

Usage:
- `/cli-collaboration on` — remove `.cli-collaboration-off` if present, clear `Status: paused` from `AGENT_HANDOFF.md`.
- `/cli-collaboration off` — create `.cli-collaboration-off` at repo root, set `Status: paused` in the handoff.

Pause only disables the overhead of declaring the start gate and writing the
end-of-shift block. It does NOT authorize destructive cleanup or overwrite of
existing work. The handoff still protects files listed in `## File ownership`.
```

The same semantics must be implementable in Codex and Gemini via their respective mechanisms (or the filesystem sentinel alone for environments without custom commands).

## Pause and Resume

Two CLI-neutral pause mechanisms, in order of preference:

1. **`.cli-collaboration-off`** in the project root — a zero-byte sentinel file. Easy to grep for, easy to git-ignore, works in every CLI.
2. **`**Status:** paused`** at the top of `AGENT_HANDOFF.md` — survives across worktrees and is visible in the handoff itself.

Pause never authorizes destructive cleanup. The ownership and reserved-zones guarantees remain in force.

## Script Interaction

Claude Code can invoke the Codex-authored scripts directly:

- `scripts/check-ownership.sh --agent Claude <files...>` before editing files near ownership boundaries. Exit `0` = clear, `1` = conflict, `2` = malformed handoff.
- `scripts/install-skill.sh --dry-run` to preview installation, then drop `--dry-run` to apply.
- `scripts/sync-skill.sh` to report drift against all configured install targets without modifying them.

Script ABI is owned by Codex and documented in `references/codex-adapter.md`. Do not duplicate the ABI here; refer to that file as the source of truth.

## Known Limitations

- Claude Code does not consume an `agents/claude.yaml` schema at this time. The file in this package exists for symmetry only (see `agents/claude.yaml` header).
- Slash commands are project-scoped; they do not propagate across repositories. Each project that wants the toggle UX must add its own `.claude/commands/cli-collaboration.md`.
- SessionStart hooks require user approval on first run and may be disabled by the user. Treat the `CLAUDE.md` directive as the more reliable baseline.
- The skill-loader can be overridden by user instructions. If the user explicitly says "ignore the handoff for now", Claude Code will comply; the protocol depends on the user respecting it as well.

## Single-Session Variant

Even when Claude Code is the only CLI used on a project, install the skill and maintain `AGENT_HANDOFF.md`. The handoff functions as cross-session project memory: the next Claude Code session reads it and resumes precisely instead of re-deriving state from `git log` and file inspection.

## Language Preference (documentary)

This adapter does not execute anything. The binding behavior lives in
`SKILL.md` → `## Language Preference`. As the final step of activation, run
`scripts/lang.sh get`; if unset, ask `Choose your language:` in English and run
`scripts/lang.sh set "<answer>" --by CLAUDE`. The global config is at
`${XDG_CONFIG_HOME:-$HOME/.config}/cli-collaboration/config.json`.
