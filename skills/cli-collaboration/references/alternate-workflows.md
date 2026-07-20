# Alternate Workflows

These workflows reuse the existing `cli-collaboration` handoff protocol. They do not add new execution logic, parser behavior, ownership syntax, or script requirements.

Use this reference only when the user explicitly asks for an alternate workflow, `AGENT_HANDOFF.md` declares one, or a known workflow seed file such as `brainstorming.md` exists in the same folder where `AGENT_HANDOFF.md` is missing.

## Field Mapping

| Code field | Non-code equivalent |
|---|---|
| Files I will touch | Artifact files or sections I will edit |
| Expected red test | Validation method, or `no test: non-code workflow` |
| Tests green | Checks/review completed |
| Ownership | File, section, or contribution ownership |
| Stop condition | Turn complete, blocker, context budget, or user decision needed |

## Multi-LLM Brainstorming

The one-file seed model starts with a dedicated topic folder:

```text
topic-folder/
└── brainstorming.md
```

After the first invocation:

```text
topic-folder/
├── brainstorming.md
└── AGENT_HANDOFF.md
```

The first agent reads `brainstorming.md`, follows its bootstrap block, creates `AGENT_HANDOFF.md`, writes the first turn, and updates the handoff last. Later agents read `AGENT_HANDOFF.md` first, then append their own turn to `brainstorming.md`.

### Safety Rules

- Append turns only; do not rewrite earlier turns.
- Do not edit another participant's name, identity row, or contribution unless the user explicitly asks.
- Do not run tests, edit code, create files beyond the handoff, or commit unless the workflow file or user explicitly changes scope.
- Update `AGENT_HANDOFF.md` last.
- Stop on ambiguous format, conflicting instructions, missing bootstrap data, or unclear participant identity.

## `brainstorming.md` Seed Template

Copy this file into an empty topic folder as `brainstorming.md`.

````markdown
# Brainstorming

## Mode And Rules

This folder uses `cli-collaboration` for sequential multi-LLM brainstorming.

Rules:

- Use append-only turns.
- Do not edit previous turns.
- Do not edit other participant names, identity rows, or contributions unless the user explicitly asks.
- Do not run tests, edit code, create files beyond `AGENT_HANDOFF.md`, or commit.
- Update `AGENT_HANDOFF.md` last.
- Stop if the format is ambiguous, instructions conflict, bootstrap data is missing, or participant identity is unclear.

## Participants

Each agent self-registers before writing its first turn.

| Participant | CLI/model | Role | First turn |
|---|---|---|---|
| <name> | <CLI/model if known> | <role in this brainstorm> | <ISO 8601 timestamp with timezone> |

## Self-Identification

Before adding a turn, identify yourself in one line:

```text
Participant: <name>; CLI/model: <CLI/model if known>; role: <role>; timestamp: <ISO 8601 timestamp with timezone>
```

## User Intervention

User instructions override prior agent turns. When the user intervenes:

- Record the instruction under the next turn.
- Treat it as the new constraint for later turns.
- Mention the supersession in `AGENT_HANDOFF.md`.

## Topic

<Write the brainstorming topic, question, or decision to explore. Include constraints and desired output shape.>

## Turns

### Turn 1 — <participant> — <ISO 8601 timestamp with timezone>

Participant: <name>; CLI/model: <CLI/model if known>; role: <role>; timestamp: <ISO 8601 timestamp with timezone>

<Append the first contribution here.>

## Bootstrap Instructions For First Agent

If `AGENT_HANDOFF.md` is missing:

1. Read this file fully.
2. Create `AGENT_HANDOFF.md` in the same folder using the template below.
3. Register yourself in `## Participants` if no suitable row exists.
4. Append your first turn under `## Turns`.
5. Update `AGENT_HANDOFF.md` last with files changed, validation notes, concerns, and the next agent's starting point.

### Initial `AGENT_HANDOFF.md` Template

```markdown
# AGENT_HANDOFF.md

**Last updated:** <ISO 8601 timestamp with timezone>
**Last agent:** <Codex | Claude Code | Gemini CLI | Grok | other>
**Status:** bootstrap

## Current task
Sequential multi-LLM brainstorming for the topic declared in `brainstorming.md`.

## Current state
- bootstrap: no prior handoff existed in this folder.
- workflow: non-code brainstorming; append-only turns in `brainstorming.md`.
- seed file: `brainstorming.md` in the same folder as this handoff.
- validation: review format and append-only discipline; no code tests expected.

## File ownership
### agent-owned
- brainstorming.md: <agent-name> — current turn contributor; append-only workflow
- AGENT_HANDOFF.md: <agent-name> — handoff maintainer for this shift

### user-reserved
No user-reserved files currently declared.

### frozen
No frozen files currently declared.

## Files changed this shift
- brainstorming.md: <registered participant and appended first turn>
- AGENT_HANDOFF.md: <created bootstrap handoff>

## Tests
- Red: none
- Green: no test: non-code workflow; reviewed append-only format and handoff fields

## Open concerns
- First handoff is bootstrap state, not authoritative history before this turn.

## Next agent starts from
Next agent: task-fit decides. Read `AGENT_HANDOFF.md`, then append the next turn to `brainstorming.md`. Do not edit previous turns.

## History
- <ISO 8601 timestamp with timezone> - <agent>: Created bootstrap brainstorming handoff and appended first turn. (bootstrap)
```
````

## Other Possible Patterns

The same handoff discipline can coordinate research synthesis, structured debate, editorial review, or model comparison when the workflow is explicitly requested or declared in the handoff. Do not add templates for those patterns here until one has been exercised and reviewed in a real workflow.
