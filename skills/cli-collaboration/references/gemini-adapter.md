# Gemini CLI Adapter

Use this reference when installing, activating, or operating `cli-collaboration` from Gemini CLI.

## Discovery And Activation

Current Gemini CLI releases implement the Agent Skills lifecycle directly:
they discover skill metadata at session start and call `activate_skill` when a
task matches the description. The skill activates when:

- Gemini matches the shared `SKILL.md` description and requests activation.
- `GEMINI.md` instructs the agent to read `AGENT_HANDOFF.md` at the start of a session.
- The `activate_skill` tool is invoked explicitly by the user or an agent plan.
- A dirty worktree or an explicit user request indicates the need to resume work or collaborate with another agent.

## Install Path

Gemini CLI discovers user skills from either of these aliases:

```
~/.gemini/skills/cli-collaboration/
~/.agents/skills/cli-collaboration/
```

Within the user tier, `.agents/skills/` takes precedence. Do not install the
same skill in both paths: Gemini reports a duplicate-name conflict even when
the payloads are identical. The package default uses the interoperable Agents
path, which also works with other skill-aware runtimes.

For a Gemini-only installation, use one explicit target:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.gemini/skills/cli-collaboration"
```

The installer is idempotent and backs up divergent targets before copying. To preview without writing, pass `--dry-run`.

Antigravity CLI installations using the Gemini configuration-tree layout can
be updated explicitly with:

```bash
skills/cli-collaboration/scripts/install-skill.sh \
  --target "$HOME/.gemini/config/skills/cli-collaboration"
```

Verify native Gemini discovery with `gemini skills list --all`.

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
- **Activation Consent:** Native discovery loads only metadata. Gemini may ask for confirmation before injecting the full skill and bundled resources.
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

## Language Preference (documentary)

This adapter does not execute anything. The binding behavior lives in
`SKILL.md` → `## Language Preference`. As the final step of activation, run
`scripts/lang.sh get`; if unset, ask `Choose your language:` in English and run
`scripts/lang.sh set "<answer>" --by GEMINI`. The global config is at
`${XDG_CONFIG_HOME:-$HOME/.config}/cli-collaboration/config.json`.
