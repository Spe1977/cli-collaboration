# Gemini CLI Adapter

Use this reference when installing, activating, or operating `cli-collaboration` from Gemini CLI.

## Triggering

Gemini CLI does not have an automatic description-matching skill loader. Instead, it relies on project-level contextual instructions. The skill activates when:

- `GEMINI.md` instructs the agent to read `AGENT_HANDOFF.md` at the start of a session.
- The `activate_skill` tool is invoked by the user or through an agent plan targeting the `cli-collaboration` skill (when installed as a native extension).
- A dirty worktree or an explicit user request indicates the need to resume work or collaborate with another agent.

## Install Path

Default install target for Gemini CLI (as a contextual extension):

```
~/.gemini/skills/cli-collaboration/
```

Use the package installer:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.gemini/skills/cli-collaboration"
```

The installer is idempotent and backs up divergent targets before copying. To preview without writing, pass `--dry-run`.

## Project Guidance (`GEMINI.md`)

Add this paragraph to the project's `GEMINI.md` (or workspace contextual file) so that Gemini CLI reads the handoff at the start of every session:

```markdown
When `AGENT_HANDOFF.md` exists at the project root, read it before any other
file. Apply the `cli-collaboration` skill: declare the start gate, respect
`### agent-owned`, `### user-reserved`, and `### frozen` sections, and update
the handoff last with files changed, tests, open concerns, and the next
concrete step.
```

`GEMINI.md` is loaded into Gemini CLI's context automatically and guarantees "always-on" adherence to the handoff protocol.

## Known Limitations

- **No Custom Slash Commands:** Gemini CLI does not natively support custom slash commands like `/cli-collaboration on|off`. Toggling must be done via the filesystem (e.g., `.cli-collaboration-off` sentinel file or `Status: paused` in the handoff).
- **Manual Triggering:** If the skill is not injected via `GEMINI.md`, the user must explicitly ask the agent to `activate_skill cli-collaboration` or instruct it to read the handoff.
- **Parallel Subagents:** Gemini CLI can dispatch parallel subagents. The handoff must be respected and updated sequentially; parallel subagents must not mutate `AGENT_HANDOFF.md` concurrently.

## Forced Activation

When Gemini does not automatically pick up the project guidance, use this exact prompt before work begins:

```text
Activate the cli-collaboration skill and read AGENT_HANDOFF.md before doing anything.
```

Only one active writer should update `AGENT_HANDOFF.md` at a time. If Gemini subagents run in parallel, designate one parent session as the handoff writer and have subagents report back instead of editing the handoff directly.

## Pause and Resume

Two CLI-neutral pause mechanisms, in order of preference (same as Claude and Codex):

1. **`.cli-collaboration-off`** in the project root — a zero-byte sentinel file. Easy to grep for, easy to git-ignore, works in every CLI.
2. **`**Status:** paused`** at the top of `AGENT_HANDOFF.md` — survives across worktrees and is visible in the handoff itself.

Pause never authorizes destructive cleanup. The ownership and reserved-zones guarantees remain in force.

## Script Interaction

Gemini CLI can invoke the Codex-authored scripts directly:

- `scripts/check-ownership.sh --agent Gemini <files...>` before editing files near ownership boundaries. Exit `0` = clear, `1` = conflict, `2` = malformed handoff.
- `scripts/install-skill.sh --dry-run` to preview installation, then drop `--dry-run` to apply.
- `scripts/sync-skill.sh` to report drift against all configured install targets without modifying them.

Script ABI is owned by Codex and documented in `references/codex-adapter.md`.

## Single-Session Variant

Even when Gemini CLI is the only CLI used on a project, install the skill and maintain `AGENT_HANDOFF.md`. The handoff functions as cross-session project memory, ensuring the agent resumes its exact thought process and state across restarts.
