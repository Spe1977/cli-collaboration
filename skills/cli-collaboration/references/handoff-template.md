# AGENT_HANDOFF.md Template

Copy this skeleton into the root of a project that does not yet have an `AGENT_HANDOFF.md`. The file is the source of truth across agents and across sessions of the same agent. Read it first, update it last.

The structure below is the contract parsed by `scripts/check-ownership.sh`. Keep the section names, the ownership line shape, and the `## File ownership` heading exactly as shown.

---

```markdown
# AGENT_HANDOFF.md

**Last updated:** <ISO 8601 timestamp with timezone>
**Last agent:** <Codex | Claude Code | Gemini CLI | other>
**Status:** <bootstrap | in-progress | done | blocked | paused>

## Current task
<One paragraph. What the active shift is delivering, in plain language.>

## Current state
- <Decisions already taken, with date if useful.>
- <Constraints the next agent must respect.>
- <Frozen contracts (script ABI, parser format, line counts, naming).>
- <Anything that changes the meaning of the code but is not visible from `git status` alone.>

## File ownership
### agent-owned
- <path-or-glob>: <agent-name> — <reason>
- <path-or-glob>: <agent-name> (pending Phase N) — <reason>

### user-reserved
- <path>: user — <reason>

### frozen
- <path>: frozen — <reason it is frozen, e.g. "published v1.0">

## Files changed this shift
- <path>: <one-line summary of the change>

## Tests
- Red: <name + brief failure mode, or "none">
- Green: <name, or "none ran">

## Open concerns
- <Concrete risk, ambiguity, or unfinished thread. Never write "all good".>

## Next agent starts from
<Exact next step. Reference a file and, when possible, a line number. Name the agent expected to pick it up. Name files the next agent must NOT touch.>

## History
- <ISO timestamp> - <agent>: <one-line shift summary> (<status>)
```

---

## Field rules

**Header**
- `Last updated` is an ISO 8601 timestamp with timezone (`2026-05-19T11:18:50+02:00`). Local time without offset is malformed.
- `Status: paused` (or a `.cli-collaboration-off` sentinel in the repo root) signals that procedural overhead is paused. It does not authorize destructive cleanup.
- `Status: bootstrap` is reserved for the very first handoff written into a fresh repository (see "Bootstrap variant" below).

**Current task**
- One paragraph. Not a roadmap. If the shift covers more than one task, list them and mark the active one.

**Current state**
- Bullets, not prose. Each bullet is a fact, a decision, or a frozen contract.
- Convert relative dates ("yesterday", "next Thursday") to absolute ones before writing.
- If a contract is frozen for downstream agents (script CLI, parser format, line-count budgets), say so explicitly. This prevents the next agent from drifting it without noticing.

**File ownership**
- `### agent-owned`, `### user-reserved`, `### frozen` are the only three subsections accepted by the parser, and all three headings are required. Empty subsections are allowed; write `No frozen files currently declared.` rather than deleting the heading.
- Line shape, parsed exactly: `- <path-or-glob>: <agent-name> — <reason>`. The canonical separator is the em-dash `—` (U+2014). The parser tolerates en-dash (`–`), a regular hyphen surrounded by spaces (` - `), and `--`, but generated handoffs should still use the canonical em-dash.
- Globs use shell pattern semantics: `scripts/*` matches `scripts/foo.sh` but not `scripts/sub/foo.sh`. Recursive `**` globs are not part of the v2.2 parser contract; list recursive paths explicitly instead.
- Parenthetical annotations (e.g. `Claude (pending Phase 2)`) are advisory: the parser strips them, so the owner above compares as `Claude`.
- Reassignment is a handoff event. Note the previous owner in the `## History` block when changing an ownership line.

**Files changed this shift**
- Every file you touched, including documentation. The diff is in git; the *intent* is here.

**Tests**
- Name the red test and how it fails. "Tests pass" is not enough.
- If no test runs (documentation shift, scaffold-only), write the reason explicitly so future agents know whether to expect coverage.

**Open concerns**
- One bullet per concern. Include risks you did not fix. A handoff with no open concerns is almost always a sign you forgot to write them down.

**Next agent starts from**
- Exact next step. Reference a file and ideally a line number.
- Name the expected next agent. If unknown, say "any — task-fit decides" and describe the task profile.
- Include a `Do not touch:` line listing reserved files or files owned by other agents that the next shift must leave alone.

**History**
- Append-only, newest first. Each entry is one line: `- <timestamp> - <agent>: <one-line summary> (<status>)`.
- Keep the last three detailed handoff blocks above; collapse older shifts into one-line history entries when the file grows large.

## Bootstrap variant

When you are the first agent in a fresh repository:

1. Write the template above with `Status: bootstrap`.
2. Put the user's original request verbatim under `## Current task`.
3. List yourself as the only entry under `### agent-owned`.
4. Mark `## Current state` with `- bootstrap: no prior agent has worked here.`
5. Include `git status --short --branch` output if the directory is a git repo.
6. Name the expected next agent under `## Next agent starts from`, even if it is yourself in the next session.

Do this *before* any code changes. The bootstrap handoff is not authoritative history — it is a declaration that the protocol now applies.

## Single-agent variant

If only one CLI agent works in the project, the handoff is still required: it is project memory between sessions, not a coordination artifact between different agents. Keep `### agent-owned` to a single agent name and use `## History` as a session log.
