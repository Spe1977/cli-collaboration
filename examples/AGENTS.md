# AGENTS.md

Use `cli-collaboration` whenever this repository contains `AGENT_HANDOFF.md`, has work from another CLI agent, or the user asks to resume a previous session.

Before editing:

1. Read `AGENT_HANDOFF.md`.
2. Declare the start gate: handoff read, current task, files to touch, expected red test, reserved zones, and stop condition.
3. Check ownership before touching files listed under `agent-owned`, `user-reserved`, or `frozen`.
4. Keep edits inside declared files unless you announce the expanded scope first.

Do not run destructive cleanup commands without explicit user approval.

Update `AGENT_HANDOFF.md` last with exact files changed, tests red/green, open concerns, and the next concrete step.
