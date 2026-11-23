# GEMINI.md

This project uses `cli-collaboration` to coordinate `Codex`, `Claude Code`, `Gemini CLI`, `Grok`, `Antigravity`, and single-agent multi-session work on a shared repository.

## Protocol Pointers

1. **Read `AGENT_HANDOFF.md` first** before interpreting `git status` or editing files. If missing and a dirty worktree or resume intent exists, bootstrap it using the `cli-collaboration` skill before code edits.
2. **Declare the Start Gate** before editing: handoff read + timestamp, current task, explicit files to touch, expected red test, reserved zones confirmed, and stop condition (`task-complete | context-budget | blocker`).
3. **Use distinct identity & check ownership:**
   - **Gemini CLI:** `--agent Gemini` (`**Last agent:** Gemini CLI`)
   - **Antigravity IDE / App / `agy`:** `--agent Antigravity` (`**Last agent:** Antigravity`)
   Run `<SKILL_DIR>/scripts/check-ownership.sh --agent <Gemini|Antigravity> <files...>` before editing contested files. Never edit `### user-reserved`, `### frozen`, or another agent's files without approval.
4. **No destructive cleanup:** never run or recommend `git reset --hard`, `git clean`, unauthorized `git stash`, `git restore`, or `git checkout --`.
5. **Pause:** `.cli-collaboration-off` or `**Status:** paused` suspends Start Gate and End-of-Shift overhead only; ownership and non-destructive rules stay active.
6. **Single-session & single-writer:** maintain `AGENT_HANDOFF.md` even in solo sessions, and update it **last** from one parent/coordinator session (never concurrently from parallel subagents or swarms).

Note: Antigravity automatically loads both `AGENTS.md` and `GEMINI.md`; keep project rules concise to stay within the 20,000-token rules budget.
