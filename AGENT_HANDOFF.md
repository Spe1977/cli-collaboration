# AGENT_HANDOFF.md

**Last updated:** 2026-05-19T23:37:53+02:00
**Last agent:** Codex CLI
**Status:** done

## Current task
Applied Claude's README review items R7-R12 to close the remaining README-level gaps after the parser/Git/concurrency cleanup shift.

## Current state
- The project is fully bootstrapped, with all Phase 1 (Codex), Phase 2 (Claude), and Phase 3 (Gemini) deliverables implemented.
- `examples/GEMINI.md` and `skills/cli-collaboration/references/gemini-adapter.md` are added, matching the parallel structure of Claude and Codex adapters.
- Cross-CLI consistency verified: all adapters define the same trigger semantics, pause mechanism (`.cli-collaboration-off` and `Status: paused`), destructive-action bans, and ownership taxonomy.
- QA completed: Ran `run-tests.sh` locally which validated `agent-conflict` (Scenario C), `clean`, `missing`, `user-reserved`, `frozen`, `missing-frozen-section`, and `endash-owner` scenarios. All tests passed. Scenario F (user supersession) logic is correctly semantically embedded in `GEMINI.md` and `validation-scenarios.md`.
- The package is now complete from a tri-CLI symmetry standpoint.
- Codex post-completion verification completed on 2026-05-19T23:31:25+02:00.
- `README.md` was updated to remove stale "later phases" wording now that Claude/Gemini deliverables exist.
- `evals/evals.json` was updated from `0.1.0-phase1` / `technical-wiring` to `0.1.0` / `tri-cli-complete`.
- Default installed targets are not current: `sync-skill.sh` reports drift for `/home/leospe/.codex/skills/cli-collaboration` and `/home/leospe/.agents/skills/cli-collaboration`; `/home/leospe/.gemini/skills/cli-collaboration` also differs from the local package. This verification did not install or overwrite those directories.
- `README.md` now includes a synthesis of `workflow.md`: task-fit bootstrap, handoff-first flow, single-LLM cross-session use, filesystem-based pause/resume, and the Codex/Claude/Gemini ownership split.
- Claude reviewed `README.md` semantically without editing it, respecting Codex ownership.
- Codex accepted and implemented Claude review items R1-R6: neutral CLI loading wording, clearer final verification wording, more reproducible release-gate wording, canonical single-agent phrasing, sharper destructive-assertion wording, and a maintenance/update section.
- `git init` was run successfully after adding `.gitignore`; the repository has no commits yet and all package files are currently untracked.
- `check-ownership.sh` now requires all three ownership headings, normalizes common dash variants in ownership lines, and keeps recursive `**` globs out of the v2.2 contract.
- Concurrency policy remains procedural in v2.2: one active writer for `AGENT_HANDOFF.md`; flock-based locking is promoted only after a documented concurrent-write incident.
- `README.md` now exposes the single-writer policy in Core Protocol, Gemini forced activation in Activation And Pause, the stricter exit code 2 semantics, `.gitignore` ownership, parser fixture coverage beyond scenarios A-F, and a single-level glob ownership example.

## File ownership
### agent-owned
- skills/cli-collaboration/SKILL.md: Codex — core protocol and trigger body
- skills/cli-collaboration/scripts/*: Codex — guardrail scripts and executable fixture tests
- skills/cli-collaboration/scripts/test-fixtures/*: Codex — ownership checker fixtures
- evals/evals.json: Codex — technical eval wiring for scenarios A-F
- skills/cli-collaboration/agents/openai.yaml: Codex — OpenAI metadata
- skills/cli-collaboration/references/codex-adapter.md: Codex — Codex-specific adapter notes and script ABI
- examples/AGENTS.md: Codex — Codex/AGENTS project guidance example
- README.md: Codex — package entry point, install commands, release gates
- .gitignore: Codex — repository hygiene for local guardrail artifacts
- skills/cli-collaboration/references/handoff-template.md: Claude — canonical human handoff template
- skills/cli-collaboration/references/handoff-anti-patterns.md: Claude — semantic failure modes
- skills/cli-collaboration/references/validation-scenarios.md: Claude — textual scenarios A-F and negative asserts
- skills/cli-collaboration/agents/claude.yaml: Claude — documentation-only Claude metadata
- skills/cli-collaboration/references/claude-adapter.md: Claude — Claude Code adapter notes
- examples/AGENT_HANDOFF.md: Claude — filled handoff example
- examples/CLAUDE.md: Claude — Claude project guidance example
- docs/future-architecture.md: Claude — v3 thresholds and sidecar policy
- examples/GEMINI.md: Gemini — Gemini project guidance example
- skills/cli-collaboration/references/gemini-adapter.md: Gemini — Gemini adapter notes

### user-reserved
- final-skill.md: user — approved source specification
- workflow.md: user — workflow decisions and voting record
- progetti-1-2.md: user — user-reserved source if reintroduced

### frozen
No frozen files currently declared.

## Files changed this shift
- README.md: Applied Claude review items R7-R12.
- AGENT_HANDOFF.md: Recorded the README review follow-up.

## Tests
- Red: none intentional for this documentation-only README follow-up.
- Green: README `rg` check for R7-R12 wording; `run-tests.sh` fixture suite (7/7); `quick_validate.py skills/cli-collaboration`; `git status --short --branch`.
- Expected non-green: `sync-skill.sh` exits `1` because default install targets drift from the local package. Manual diff also shows `/home/leospe/.gemini/skills/cli-collaboration` is drifted after local changes.

## Open concerns
- Git is initialized, but no initial commit exists yet. `git status --short --branch` reports `No commits yet on master` and all package files are untracked.
- Package validates locally and can be installed to target directories, but the live Codex/agents/Gemini install targets still need an explicit install/sync step if the user wants this new version active.
- No backup script was added; `.gitignore` reserves `.handoff-backups/` so a future lightweight backup guardrail can be introduced without diff noise.

## Next agent starts from
**Next agent: User.**

Review the local changes, then choose the next operational step: create the initial Git commit, run `sync-skill.sh --install` for Codex/agents targets, install explicitly to Gemini, or define the next project.

Do not touch: `final-skill.md`, `workflow.md`, or `progetti-1-2.md` unless the user explicitly reassigns them.

## History
- 2026-05-19T23:37 - Codex CLI: Applied Claude README review items R7-R12 and re-ran README/skill checks. (done)
- 2026-05-19T23:31 - Codex CLI: Implemented accepted parser/documentation/Git/concurrency cleanup plan; initialized Git; verified fixture suite 7/7. (done)
- 2026-05-19T22:52 - Gemini CLI: Installata la skill nel percorso predefinito (~/.gemini/skills/cli-collaboration) e verificata la compatibilità. (done)
- 2026-05-19T12:15 - Codex CLI: Applied Claude semantic review items R1-R6 to README and re-ran validation gates. (done)
- 2026-05-19T12:11 - Codex CLI: Expanded README with workflow synthesis, development history, usage model, and test evidence; re-ran validation gates. (done)
- 2026-05-19T12:05 - Codex CLI: Performed post-completion verification, fixed stale README/evals Phase 1 labels, verified scripts/metadata/install behavior, and recorded default install-target drift. (done)
- 2026-05-19T20:00 - Gemini CLI: Implemented Phase 3 deliverables (GEMINI.md, gemini-adapter.md). Ran test suite verifying ownership guards (Scenario C). Verified cross-CLI consistency. Marked project as done. (done)
- 2026-05-19T13:05 - Claude Code: Implemented Phase 2 semantic/reference package. Created handoff-template.md, handoff-anti-patterns.md, validation-scenarios.md, claude.yaml, claude-adapter.md, examples/AGENT_HANDOFF.md, examples/CLAUDE.md, docs/future-architecture.md. (in-progress)
- 2026-05-19T11:18 - Codex: Implemented Phase 1 technical package; froze ownership parser format, script ABI, 110-line SKILL.md, single-LLM wording, README, Codex adapter, OpenAI metadata, fixture tests, and eval wiring. (in-progress)
- 2026-05-19T19:45 - Gemini: Lettura e convalida finale dell'allineamento pre-Fase 1. Confermati i ruoli. (in-progress)
