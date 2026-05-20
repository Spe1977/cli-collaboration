# AGENT_HANDOFF.md

**Last updated:** 2026-05-20T12:00:00+02:00
**Last agent:** Claude Code
**Status:** in-progress

## Current task
P1 of the v2.3 correction plan: align documentation with the parser's actual glob semantics. The parser uses `case "$path" in $pattern)`, where `*` matches `/`; previous docs claimed `scripts/*` did not cover `scripts/sub/foo.sh`, which is factually wrong. Updated `handoff-template.md`, `codex-adapter.md`, `SKILL.md`, `README.md`, and `README_IT.md`; added a pinning fixture `handoff-glob-crosses-slash.md` and a matching `run-tests.sh` case so the behavior is now a tested contract. User supersession applied for the Codex-owned files in scope (see History entry).

## Current state
- The project is fully bootstrapped, with all Phase 1 (Codex), Phase 2 (Claude), and Phase 3 (Gemini) deliverables implemented.
- `examples/GEMINI.md` and `skills/cli-collaboration/references/gemini-adapter.md` are added, matching the parallel structure of Claude and Codex adapters.
- Cross-CLI consistency verified: all adapters define the same trigger semantics, pause mechanism (`.cli-collaboration-off` and `Status: paused`), destructive-action bans, and ownership taxonomy.
- QA completed: Ran `run-tests.sh` locally which validated `agent-conflict` (Scenario C), `clean`, `missing`, `user-reserved`, `frozen`, `missing-frozen-section`, and `endash-owner` scenarios. All tests passed. Scenario F (user supersession) logic is correctly semantically embedded in `GEMINI.md` and `validation-scenarios.md`.
- The package is now complete from a tri-CLI symmetry standpoint.
- Codex post-completion verification completed on 2026-05-19T23:31:25+02:00.
- `README.md` was updated to remove stale "later phases" wording now that Claude/Gemini deliverables exist.
- `evals/evals.json` was updated from `0.1.0-phase1` / `technical-wiring` to `0.1.0` / `tri-cli-complete`.
- Installed targets are current: `sync-skill.sh` reports `ok` for `/home/leospe/.codex/skills/cli-collaboration` and `/home/leospe/.agents/skills/cli-collaboration`; `diff -qr` reports no differences for `/home/leospe/.gemini/skills/cli-collaboration` or `/home/leospe/.claude/skills/cli-collaboration`.
- `README.md` now includes a synthesis of `workflow.md`: task-fit bootstrap, handoff-first flow, single-LLM cross-session use, filesystem-based pause/resume, and the Codex/Claude/Gemini ownership split.
- Claude reviewed `README.md` semantically without editing it, respecting Codex ownership.
- Codex accepted and implemented Claude review items R1-R6: neutral CLI loading wording, clearer final verification wording, more reproducible release-gate wording, canonical single-agent phrasing, sharper destructive-assertion wording, and a maintenance/update section.
- Git baseline commit created: `e7bd2e7 feat: cli-collaboration v2.2 baseline`.
- `check-ownership.sh` now requires all three ownership headings, normalizes common dash variants in ownership lines, and keeps recursive `**` globs out of the v2.2 contract.
- Concurrency policy remains procedural in v2.2: one active writer for `AGENT_HANDOFF.md`; flock-based locking is promoted only after a documented concurrent-write incident.
- `README.md` now exposes the single-writer policy in Core Protocol, Gemini forced activation in Activation And Pause, the stricter exit code 2 semantics, `.gitignore` ownership, parser fixture coverage beyond scenarios A-F, and a single-level glob ownership example.
- Backup directories were moved from each CLI's `skills/` directory into sibling `skills-backups/` directories so only the definitive v2.2 skill remains discoverable.
- `README_IT.md` was added as the Italian translation of `README.md`, with current Git publication steps reflected in both README files.
- Remote `origin` is set to `https://github.com/Spe1977/cli-collaboration.git`; the local branch was renamed to `main` to match GitHub.
- The GitHub `LICENSE` commit was merged locally with `chore: merge GitHub repository license`.
- `main` was pushed successfully to `https://github.com/Spe1977/cli-collaboration.git` at commit `2c9ad1f`.
- `CONTRIBUTORS.md` added to credit human + AI agent collaboration explicitly, since GitHub's contributors view can only credit committer accounts (no AI identities). Git authorship remains unfalsified.

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
- README_IT.md: Codex — Italian package entry point translation
- LICENSE: user/GitHub — MIT license generated during repository creation
- .gitignore: Codex — repository hygiene for local guardrail artifacts
- CONTRIBUTORS.md: Claude — multi-agent contribution record
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
- skills/cli-collaboration/references/handoff-template.md: Rewrote the line 73 glob claim. Old text said `scripts/*` did not match `scripts/sub/foo.sh`; new text documents the actual bash `case`-pattern semantics (`*` crosses `/`).
- skills/cli-collaboration/references/codex-adapter.md: Aligned the glob paragraph (line 58) with the corrected semantics.
- skills/cli-collaboration/SKILL.md: Added a glob-semantics note to the `## Ownership` section.
- README.md, README_IT.md: Replaced the negative-only `**` statement with a positive description of what `*` matches.
- skills/cli-collaboration/scripts/test-fixtures/handoff-glob-crosses-slash.md: New fixture pinning the cross-slash behavior.
- skills/cli-collaboration/scripts/test-fixtures/run-tests.sh: Added `glob-crosses-slash` case asserting exit 0 for `scripts/sub/foo.sh` under `--agent Codex`.
- AGENT_HANDOFF.md: This update.

## Tests
- Red: none — documentation alignment + one positive fixture, no behavioral change.
- Green: `bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` reports 8/8 passing, including the new `glob-crosses-slash` case.
- Expected non-green: none currently.

## Open concerns
- The source package and live Codex/agents/Claude/Gemini install targets are aligned as of 2026-05-19T23:51:36+02:00.
- Install backups are preserved outside discovery paths: `/home/leospe/.codex/skills-backups`, `/home/leospe/.agents/skills-backups`, `/home/leospe/.claude/skills-backups`, `/home/leospe/.gemini/skills-backups`.
- No backup script was added; `.gitignore` reserves `.handoff-backups/` so a future lightweight handoff backup guardrail can be introduced without diff noise.
- A residual pre-cycle backup directory `~/.claude/skills/cli-collaboration.bak-20260518T002954Z` exists on Claude's local install path from a prior session. The skill loader does not pick it up, so it is non-blocking; user can move it to `~/.claude/skills-backups/` or delete it at convenience. Not pushed (local-only artifact).
- An Italian translation `CONTRIBUTORS_IT.md` is not provided; can be added later for symmetry with `README_IT.md` if the user wants it.

## Next agent starts from
**Next agent: User (review of PR `claude/p1-glob-docs`), then Claude Code for P3 (shell hardening + rollback in `install-skill.sh`/`sync-skill.sh`, plus `set -o pipefail` in `check-ownership.sh`).**

P1 is complete on branch `claude/p1-glob-docs` and pushed. P2–P5 of the v2.3 plan remain outstanding; the user's authorization for this shift was explicitly scoped to P1 only, so the next planned PRs require fresh authorization.

Do not touch: `final-skill.md`, `workflow.md`, or `progetti-1-2.md` unless the user explicitly reassigns them.

## History
- 2026-05-20T12:00 - Claude Code: P1 of the v2.3 correction plan — doc-honest glob semantics. Edited Codex-owned files (`README.md`, `README_IT.md`, `SKILL.md`, `codex-adapter.md`, `run-tests.sh`, new fixture `handoff-glob-crosses-slash.md`) under explicit user supersession scoped to P1. Codex and Gemini approved the plan substance before authorization. Fixtures green 8/8. (in-progress)
- 2026-05-20T10:30 - Claude Code: Untracked internal design notes (`analisi.md`, `final-skill.md`, `workflow.md`) from Git; added them to `.gitignore`. User supersession over Codex-owned `.gitignore` and user-reserved design notes. Files preserved locally. (done)
- 2026-05-20T00:35 - Claude Code: Closing review pass — added CONTRIBUTORS.md crediting human + AI multi-agent collaboration (user supersession; Codex out of context); verified 7/7 fixtures; surfaced residual local backup as open concern. (done)
- 2026-05-20T00:13 - Codex CLI: Pushed main to the dedicated GitHub repository Spe1977/cli-collaboration. (done)
- 2026-05-20T00:12 - Codex CLI: Added README_IT.md, merged GitHub MIT license commit, and prepared origin/main push. (done)
- 2026-05-20T00:10 - Codex CLI: Added README_IT.md translation and refreshed README publication wording before GitHub push. (done)
- 2026-05-19T23:55 - Codex CLI: Moved cli-collaboration backup directories out of skill discovery paths into skills-backups. (done)
- 2026-05-19T23:51 - Codex CLI: Installed committed v2.2 package into the explicit Claude target and verified all four install targets aligned. (done)
- 2026-05-19T23:48 - Gemini CLI: Verified Git baseline, cross-agent skill sync, and GEMINI.md cleanup. Confirmed v2.2 stability. (done)
- 2026-05-19T23:43 - Codex CLI: Created baseline commit e7bd2e7 and synchronized Codex/agents/Gemini install targets. (done)
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
