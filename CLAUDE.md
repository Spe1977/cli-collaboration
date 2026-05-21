# CLAUDE.md

This project uses the `cli-collaboration` skill to coordinate Codex, Claude Code, Gemini CLI, and single-agent multi-session work on a shared repository.

## Activation

When `AGENT_HANDOFF.md` exists at the project root, read it before any other file. Apply the `cli-collaboration` skill: declare the start gate, respect `### agent-owned`, `### user-reserved`, and `### frozen` sections, and update the handoff last with files changed, tests, open concerns, and the next concrete step.

If `AGENT_HANDOFF.md` does not exist and the request involves a dirty worktree, work left by another CLI agent, or resume-from-previous-session intent, create the handoff in bootstrap mode (see `skills/cli-collaboration/references/handoff-template.md`, "Bootstrap variant") before any code change.

## Start Gate

Before editing any file, state explicitly:

- **Handoff read:** path and last-updated timestamp.
- **Current task:** one line.
- **Files I will touch:** explicit list, not directories.
- **Expected red test:** name, or "no test for this task" with the reason.
- **Reserved zones confirmed:** user-reserved and frozen areas read.
- **Stop condition:** `task-complete` | `context-budget` | `blocker`.

If you cannot fill one of those fields, read more or ask the user. Do not improvise.

## Ownership

Never edit a file listed under `### user-reserved` or `### frozen` without explicit user approval. For `### agent-owned` files, edit only those assigned to Claude. If the request requires touching a file owned by Codex, Gemini, or another agent, stop, name the file and owner, and ask for reassignment or deferment.

When in doubt, run:

```bash
skills/cli-collaboration/scripts/check-ownership.sh --agent Claude <file...>
```

Exit `0` = no conflict, `1` = ownership conflict, `2` = malformed handoff.

## Destructive Actions

Never run or recommend without explicit user approval:

- `git reset --hard`
- `git clean`
- `git stash` (unauthorized)
- `git restore` (on files not authored in this shift)
- `git checkout --` (on files not authored in this shift)
- lateral overwrite of files authored by another agent or the user

When unfamiliar state appears, assume it is in-progress work. Ask the user.

## Pause

To suspend procedural overhead without disabling protective behavior:

- create `.cli-collaboration-off` at the project root, or
- set `**Status:** paused` at the top of `AGENT_HANDOFF.md`.

Pause never authorizes destructive cleanup or overwrite.

## End of Shift

Update `AGENT_HANDOFF.md` as the last action of the shift:

```text
Agent: Claude Code
Date/time: <ISO 8601 with timezone>
Task: <what you took on>
Status: done | in-progress | blocked
Files changed: <explicit list>
Tests red: <names + reason>
Tests green: <names>
Open concerns: <concrete risks; never "all good">
Next agent starts from: <exact next step, file:line when possible>
Do not touch: <reserved files/areas>
```

Keep the last three detailed handoff blocks; summarize older entries into single `## History` lines as the file grows.

## Single-Session Use

Even if Claude Code is the only CLI on this project, maintain `AGENT_HANDOFF.md`. It is project memory between sessions, not just a coordination artifact between different agents.
