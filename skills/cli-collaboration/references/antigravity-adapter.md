# Antigravity Adapter (IDE / App 2.0 / `agy` CLI)

Use this reference when installing, configuring, or operating `cli-collaboration` inside **Antigravity IDE**, **Antigravity 2.0**, or **`agy` CLI**.

## Discovery And Install Paths

Antigravity discovers skills via progressive disclosure (`name` + `description` in `SKILL.md` frontmatter) from:

- **Global machine config:** `${ANTIGRAVITY_CONFIG_HOME:-$HOME/.gemini/config}/skills/cli-collaboration/`
- **Workspace project config:** `.agents/skills/cli-collaboration/` (or `.agent/skills/`, highest precedence; ideal for team VCS sharing)

Install or sync the global Antigravity target from this repository with:

```bash
skills/cli-collaboration/scripts/install-skill.sh --antigravity
# or update Codex, Agents, Grok, Claude, and Antigravity together:
skills/cli-collaboration/scripts/install-skill.sh --all
```

Divergent pre-existing copies are backed up into a sibling `skills-backups/` directory outside `skills/` so backup folders never trigger duplicate-skill discovery collisions.

## Dual Rule Loading And Token Budget

Antigravity automatically walks upward from active files to the repository root and loads **both** `GEMINI.md` and `AGENTS.md` (plus `.agents/rules/*.md`), deduplicating by resolved path.

- Keep project `GEMINI.md` / `AGENTS.md` concise: each rule file is capped at **24 KB** (`24,000` bytes), and all active rules share an aggregate **20,000-token** budget before Antigravity demotes rules to file pointers.
- Avoid duplicating `SKILL.md` or `handoff-template.md` prose inside root `GEMINI.md` or `AGENTS.md`; use thin pointers (see `examples/AGENTS.md` and `examples/GEMINI.md`).

## Agent Identity

Keep **Antigravity** distinct from **Gemini CLI** so ownership boundaries between IDE sessions and standalone Gemini CLI sessions stay explicit:

| Context | Value |
| --- | --- |
| Handoff `Agent:` / `**Last agent:**` | `Antigravity` |
| `### agent-owned` owner | `Antigravity` |
| `check-ownership.sh --agent` | `Antigravity` |
| `lang.sh set ... --by` | `Antigravity` |
| Environment override | `CLI_COLLAB_AGENT=Antigravity` |

`parse-ownership.py` normalizes `Antigravity`, `Antigravity IDE`, `Antigravity App`, `Antigravity 2.0`, `Antigravity CLI`, and `agy` to `antigravity` while keeping `Gemini` / `Gemini CLI` separate (`gemini`).

## Plan/Execute Mode And Artifacts

Antigravity separates planning turns from execution turns (`exit_plan_mode` / `enter_plan_mode`) and stores session artifacts under `<appDataDir>/brain/<conversation-id>/`:

- **`AGENT_HANDOFF.md` always lives in the repository root**, never solely in the conversation artifact directory. Other CLIs (`Codex`, `Claude Code`, `Gemini CLI`, `Grok`) cannot read Antigravity's private brain directory.
- When planning multi-step work in Plan Mode, include the `cli-collaboration` **Start Gate** fields (files to touch, ownership confirmation, reserved zones, verification plan, and `AGENT_HANDOFF.md` end-of-shift update) directly inside the approved execution plan.
- Treat `AGENT_HANDOFF.md` as authoritative over an older plan artifact when both exist (Validation Scenario B).

## Subagents And Native Swarms

Antigravity supports `invoke_subagent`, `run_workflow`, and native `swarm` coordination:

- **Single-writer rule:** Only the parent/coordinator agent updates `AGENT_HANDOFF.md` at end of shift. Subagents and swarm workers report changed files, tests, and open concerns back to the coordinator instead of writing to `AGENT_HANDOFF.md` concurrently.
- **Isolated workspaces:** When spawning writers with `workspace: "share"` or `"branch"`, remember that worker edits land in the coordinator's working copy only after merge/integration; wait until edits land before recording final `Files changed this shift` and `Tests` in `AGENT_HANDOFF.md`.

## Terminal Sandbox Compatibility

Antigravity's `run_command` executes in Standard Sandbox Mode (`BypassSandbox: false`) by default, with read/write access limited to the workspace and `/tmp`:

- **Absolute paths:** Antigravity file tools pass absolute workspace paths. `check-ownership.sh` (`parse-ownership.py`) automatically relativizes absolute paths under the handoff directory and strips `./` prefixes before matching ownership globs.
- **Language preference (`scripts/lang.sh`):**
  - If `~/.config/cli-collaboration/config.json` is readable, `lang.sh get` reads it without writing outside the sandbox.
  - When `~/.config` is absent or read-only inside the sandbox, `lang.sh set` exits cleanly with code `4` (and supports `--local` for `.cli-collaboration.json` or `CLI_COLLAB_LANG`).
  - **Never** run `lang.sh` with `BypassSandbox: true` just to persist language preferences; simply reply in the user's prompt language.

## Deterministic Lifecycle Hooks (`hooks.json`)

For hard enforcement beyond prompt instructions, configure Antigravity lifecycle hooks in `.agents/hooks.json` (workspace) or `~/.gemini/config/hooks.json` (global) using [hook-guard.py](../scripts/hook-guard.py) (ready-to-copy template: `examples/hooks/antigravity.hooks.json`):

- **`SessionStart`**: injects a compact summary of `AGENT_HANDOFF.md` (or pause notice) at session startup when `AGENT_HANDOFF.md` exists.
- **`PreToolUse`** (`matcher: "write_file|edit_file|run_command"`):
  - Denies edits to files owned by other agents, `user-reserved`, or `frozen` (always permits editing `AGENT_HANDOFF.md` itself).
  - Prompts (`"decision": "force_ask"`) before `git reset --hard`, `git clean`, `git checkout --`, `git restore` (allowing `--staged`), or `git stash` (allowing `list`/`show`).
- **`Stop`**: if `AGENT_HANDOFF.md` was modified during the turn and fails structural validation (`## File ownership` or required headings), injects one continuation request so the agent fixes the handoff before finishing (guarded by `continuationActive` to prevent loops).
