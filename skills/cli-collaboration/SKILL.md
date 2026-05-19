---
name: cli-collaboration
description: "Use when multiple CLI agents or assistants alternate on the same repository — especially with a dirty worktree, an AGENT_HANDOFF.md, side-by-side CLAUDE.md/AGENTS.md/GEMINI.md, ownership notes, red tests, resume/continue requests, or any signal that another agent or the user left state you must preserve."
---

# CLI Collaboration

Use a written handoff as the source of truth when CLI agents, or one agent across sessions, work in the same project. The goal is continuity without destroying state left by the user or another agent.

## Core Rule

Read `AGENT_HANDOFF.md` before interpreting `git status`. Never infer ownership from a dirty worktree alone.

If collaboration is paused via `.cli-collaboration-off` or `Status: paused` in the handoff, still preserve existing work and ask before touching shared files.

## Start Gate

Before editing, state:

```text
Handoff read: <path, last-updated timestamp>
Current task: <one line>
Files I will touch: <explicit file list>
Expected red test: <test name, or no test with reason>
Reserved zones confirmed: <user-reserved/frozen areas>
Stop condition: <task-complete | context-budget | blocker>
```

If you cannot fill a field, read more or ask. Do not improvise.

## Bootstrap Without Handoff

If no handoff exists, create or propose `AGENT_HANDOFF.md` before normal work. Include the user's request, current path, `git status --short --branch` if available, declared ownership, and the next concrete action. Mark it as bootstrap state, not authoritative history.

## Ownership

Use this exact line shape:

```text
- <path-or-glob>: <agent-name> — <reason>
```

Sections:

- `### agent-owned`: files assigned to Codex, Claude, Gemini, or another named agent. Globs are allowed. Parenthetical notes like `(pending Phase 2)` are advisory.
- `### user-reserved`: user-owned files. Stop before editing.
- `### frozen`: published or protected files. Stop before editing.

Run `scripts/check-ownership.sh --agent <name> <files...>` when the file list intersects handoff ownership or before risky edits. Exit `0` means no conflict detected, `1` means ownership conflict, `2` means malformed handoff or usage error.

## Conflict Handling

When a file is owned by someone else, user-reserved, frozen, or unexpectedly changed:

1. Stop before editing.
2. Name the file, owner, and risk.
3. Offer reassignment, deferment, or a smaller scope.
4. Wait for the user or owning agent to decide.

Do not resolve ownership conflicts by overwriting, reverting, stashing, or cleaning.

## Work Discipline

- Keep edits inside declared files.
- If a new file becomes necessary, announce it before editing.
- Use tests for implementation work when possible. A failing test is a good handoff artifact.
- Prefer a small complete task plus precise handoff over a broad half-finished refactor.
- The single-agent case still uses the handoff: it is project memory between sessions.

## User Supersession

The user's latest instruction wins. If it changes scope mid-turn, write a brief supersession note in the final handoff and adjust the declared file list before editing new files.

## Destructive Actions

Never run or recommend these without explicit user approval:

- `git reset --hard`
- `git clean`
- `git stash`
- `git restore`
- `git checkout --`
- lateral overwrite of files you did not author

## Adapters

Load adapter notes only when relevant:

- `references/codex-adapter.md`: Codex install paths, AGENTS.md, and script usage.
- `references/claude-adapter.md`: Claude Code hooks and command guidance.
- `references/gemini-adapter.md`: Gemini activation and GEMINI.md guidance.

## End Of Shift

Update `AGENT_HANDOFF.md` last with:

```text
Agent: <Codex | Claude Code | Gemini CLI | other>
Date/time: <ISO 8601 with timezone>
Task: <what you took on>
Status: <done | in-progress | blocked>
Files changed: <explicit list>
Tests red: <names + reason>
Tests green: <names>
Open concerns: <concrete risks>
Next agent starts from: <exact next step>
Do not touch: <reserved files/areas>
```

Keep recent history useful: preserve the last three detailed handoff blocks and summarize older entries if the file gets large.
