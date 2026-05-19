# Handoff Anti-Patterns

Eight failure modes that a `cli-collaboration` shift can produce, plus a closing note on user supersession. They are the negative companion to `SKILL.md`: each anti-pattern names a behavior that destroys handoff value, even when the surface output looks fine.

Use this reference when reviewing another agent's shift, when self-auditing before writing your end-of-shift block, or when scoring eval scenarios A–F.

---

## 1. "All good" handoff

**Symptom.** The end-of-shift block says everything is fine, the tests pass, no concerns. `## Open concerns` is empty or absent.

**Why it fails.** The next agent has no signal about where the risk lives. Either the previous agent didn't look, or they looked and stripped the signal. Both outcomes are equally bad: the next shift restarts discovery from scratch and rediscovers the same risks the slow way.

**Correct behavior.** Every shift names at least one concrete concern, even if minor. Examples: an untested edge case, an assumption that held this shift but might not next time, a frozen contract whose rationale is not yet written down. If you genuinely cannot name a concern, you did not look hard enough.

---

## 2. Inferring ownership from `git status`

**Symptom.** Agent sees modified files in the worktree, assumes they are leftovers from a previous shift, and edits or reverts them without checking `## File ownership`.

**Why it fails.** A dirty worktree may contain in-progress user work, another agent's pending change, or a half-finished refactor whose tests are intentionally red. `git status` shows *what* changed; the handoff says *who owns it* and *why it's allowed to be unfinished*.

**Correct behavior.** Read `## File ownership` first. If a modified file appears under `### user-reserved`, `### frozen`, or another agent's name, stop and surface it. Run `scripts/check-ownership.sh --agent <name> <files>` before editing files near ownership boundaries.

---

## 3. Destructive cleanup as a shortcut

**Symptom.** Agent encounters unexpected state — a stale branch, a stashed change, an untracked file, an unfamiliar lock — and uses `git reset --hard`, `git clean`, `git stash` (without authorization), `git restore`, `git checkout --`, or lateral overwrite to "tidy up" before starting work.

**Why it fails.** Destructive operations cannot be undone by the next agent. They are not cleanup; they are erasure. The cost of pausing to ask is low; the cost of an unwanted reset is hours of lost work.

**Correct behavior.** Never run destructive git operations without explicit user approval. If the worktree is dirty in a way that blocks your task, stop, name the files and the apparent owner, and ask. Treat unfamiliar state as in-progress work, not as garbage to remove.

---

## 4. Handoff edited first instead of last

**Symptom.** Agent opens `AGENT_HANDOFF.md` at the start of the shift and rewrites it as a plan ("Next agent will…", "I will now do…"). The handoff describes intent, not what happened.

**Why it fails.** Plans drift. Half-finished plans confuse the next agent into either following obsolete steps or wasting effort verifying what was actually done. The handoff loses its function as a *record* and becomes a *forecast* — and forecasts are not auditable.

**Correct behavior.** Plans go in plan files (`docs/`, `plans/`, a TodoWrite list). `AGENT_HANDOFF.md` is updated last with what *actually* changed, what tests *actually* ran, what concerns *actually* remain. Read at the start, write at the end.

---

## 5. Vague "next agent starts from"

**Symptom.** `## Next agent starts from` reads as "continue the work", "polish the implementation", "fix what's left", or any phrase that requires the next agent to re-derive context.

**Why it fails.** The next agent re-reads the diff, re-runs the tests, re-builds the mental model — often arriving at a different next step than the previous agent intended. This is one of the most common reasons two CLIs produce drift on the same project.

**Correct behavior.** Name a file and ideally a line number. State the agent expected to take the next step ("Claude should write…", "Codex should run…"). State which files the next shift must NOT touch. If the next step depends on a decision, name the decision and who must make it.

---

## 6. Out-of-scope edits without announcement

**Symptom.** Agent declares a `Files I will touch` list in the start gate, then silently edits a file outside that list because it was "needed". The handoff lists the extra file under `Files changed this shift` but offers no rationale.

**Why it fails.** Other agents and the user trust the declared scope. Silent expansion breaks that trust and makes ownership disputes harder to resolve later: the next agent cannot tell whether the extra edit was legitimate or accidental.

**Correct behavior.** If a new file becomes necessary mid-shift, announce it before editing — even one sentence is enough ("touching `foo.sh` because the script ABI requires…"). Record the rationale in `Files changed this shift` so the audit trail is complete.

---

## 7. Ignoring red tests as if they were green

**Symptom.** Tests are failing, but the handoff says `Tests green: all` or doesn't mention them. Or the agent fixes the symptom of a red test (deletes it, marks it `xfail`, comments it out) instead of recording the failure mode.

**Why it fails.** A red test you wrote is the cheapest handoff artifact: it tells the next agent exactly what behavior is missing or broken. Suppressing the red test destroys that signal and leaves the next agent unable to reproduce the failure they would otherwise pick up immediately.

**Correct behavior.** Record red tests by name and brief failure mode in the `Tests` block. If a test is intentionally red (e.g. TDD scaffold, awaiting Phase 2 implementation), say so. Never delete or skip a red test as a workaround for closing a handoff.

---

## 8. Single-agent amnesia

**Symptom.** Only one CLI agent works on the project, so the agent skips the handoff entirely: "no other agents involved, no coordination needed."

**Why it fails.** Sessions are not continuous. The agent forgets prior decisions, repeats prior mistakes, and re-derives context from `git log` and file inspection — often arriving at a slightly different interpretation each time. The handoff is project memory, not just inter-agent coordination.

**Correct behavior.** Maintain the handoff even with a single agent. Use `## History` as a session log. Treat the next session as if it were a different agent: write the handoff so a stranger could resume the work.

---

## Supersession note

User instructions override the previous handoff. If the user changes scope mid-turn — new task, different file, abandoned feature — the agent must:

1. Acknowledge the new instruction immediately.
2. Adjust the declared `Files I will touch` list before editing any new file.
3. Record a brief supersession note in the start of the end-of-shift block, e.g. `Supersession: original task replaced by user request at <timestamp>. Original task: <one line>.`
4. Still write the end-of-shift block. Do not skip the handoff on the grounds that the original plan was abandoned — the next agent needs the record more than ever.

Supersession is not an anti-pattern when handled correctly. It becomes an anti-pattern when the agent silently pivots, when the handoff omits the supersession, or when the agent uses "the user changed scope" as justification for skipping the end-of-shift update.
