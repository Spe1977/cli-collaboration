# AGENTS.md

Use `cli-collaboration` whenever this repository contains `AGENT_HANDOFF.md`, has work from another agent (`Codex`, `Claude Code`, `Gemini CLI`, `Grok`, or `Antigravity`), or the user asks to resume a previous session.

Before editing:

1. Read `AGENT_HANDOFF.md` first (even if `.cli-collaboration-off` or `Status: paused` reduces procedural overhead).
2. Declare the start gate: handoff read, current task, files to touch, expected red test, reserved zones, and stop condition.
3. Check ownership via `<SKILL_DIR>/scripts/check-ownership.sh --agent <Codex|Grok|Antigravity> <files...>` before touching contested files (`### agent-owned`, `### user-reserved`, `### frozen`).
4. Keep edits inside declared files unless you announce expanded scope first.

Note: Antigravity IDE loads both `AGENTS.md` and `GEMINI.md`; use `--agent Antigravity` in Antigravity sessions, `--agent Codex` in Codex, and `--agent Grok` in Grok Build.

Do not run destructive cleanup commands (`git reset --hard`, `git clean`, unauthorized `git stash`, `git restore`, `git checkout --`) without explicit user approval.

Update `AGENT_HANDOFF.md` last (one parent/coordinator writer only) with exact files changed, tests red/green, open concerns, and the next concrete step.
