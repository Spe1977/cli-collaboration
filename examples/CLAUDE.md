# CLAUDE.md

This project uses `cli-collaboration` to coordinate `Codex`, `Claude Code`, `Gemini CLI`, `Grok`, `Antigravity`, and single-agent multi-session work on a shared repository.

## Protocol Pointers

1. **Read `AGENT_HANDOFF.md` first** before interpreting `git status` or editing files. If missing and a dirty worktree or resume intent exists, bootstrap it using the `cli-collaboration` skill before code edits.
2. **Declare the Start Gate** before editing: handoff read + timestamp, current task, explicit files to touch, expected red test, reserved zones confirmed, and stop condition (`task-complete | context-budget | blocker`).
3. **Check ownership** before editing contested files: run `<SKILL_DIR>/scripts/check-ownership.sh --agent Claude <files...>` (usually `~/.claude/skills/cli-collaboration/scripts/check-ownership.sh`). Never touch `### user-reserved`, `### frozen`, or another agent's files without explicit approval.
4. **No destructive cleanup:** never run or recommend `git reset --hard`, `git clean`, unauthorized `git stash`, `git restore`, or `git checkout --`.
5. **Pause:** `.cli-collaboration-off` or `**Status:** paused` suspends Start Gate and End-of-Shift overhead only; ownership and non-destructive rules stay active.
6. **Single-session & single-writer:** maintain `AGENT_HANDOFF.md` even in solo sessions, and update it **last** from the parent session only.

See `skills/cli-collaboration/SKILL.md` (or `~/.claude/skills/cli-collaboration/SKILL.md`) for full details and optional `.claude/settings.json` hooks (`examples/hooks/claude.settings.json`).
