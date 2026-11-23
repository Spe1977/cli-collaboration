# AGENT_HANDOFF.md

**Last updated:** 2026-11-23T14:04:39+01:00
**Last agent:** Antigravity
**Status:** in-progress

## Current task
Reconcile `main` onto `origin/main` (`5954dfd`, `v2.5.0`), update contributors and release documentation for `v2.6.0`, run local mechanical checks, and prepare GitHub CI verification, release publication (`v2.6.0`), and repository About updates under explicit User Supersession.

## Current state
- **User Supersession (2026-11-23):** User authorized Antigravity to reconcile local `main` onto `origin/main`, add/update Antigravity in contributors, refresh `v2.6.0` documentation, verify CI, publish the `v2.6.0` GitHub Release, and improve repository description/topics while keeping `### user-reserved` (`final-skill.md`, `workflow.md`, `progetti-1-2.md`), `cli-collaboration.png`, `graphify-out/`, and `.claude/` untouched.
- **Git history & hygiene reconciled:** Fast-forwarded local `main` index cleanly onto `origin/main` (`5954dfd`), restored `docs/superpowers/{plans,specs}/2026-07-20-grok-multicli-compatibility*`, `.gitignore`, and `brainplan.md`, normalized file modes (`0644` non-scripts / `0755` scripts), and preserved authentic `v2.5.0` history in `CHANGELOG.md` and `CONTRIBUTORS*.md`.
- **Runtime skill homes synced:** User verified `install-skill.sh --all` and `sync-skill.sh --all` across Codex (`~/.codex`), Agents/Gemini CLI (`~/.agents`), Grok (`~/.grok`), Claude Code (`~/.claude`), and Antigravity (`~/.gemini/config`) — all 5 targets `in-sync` with no duplicate `~/.gemini/skills/cli-collaboration`.
- **Documentation aligned for `v2.6.0`:** Updated `CONTRIBUTORS.md`, `CONTRIBUTORS_IT.md` (restoring Grok Build + updating Antigravity), `CHANGELOG.md`, `README.md`, `README_IT.md` (added CI badge, language/changelog/contributor links, `How It Was Developed`, accurate repo tree, global hook paths), `CLAUDE.md`, and `docs/future-architecture.md`.

## File ownership
### agent-owned
- skills/cli-collaboration/SKILL.md: Codex — core protocol and trigger body
- skills/cli-collaboration/scripts/*: Codex — guardrail scripts, hook-guard.py, and executable fixture tests
- skills/cli-collaboration/scripts/test-fixtures/*: Codex — ownership, rollback, lang, portability, and hook fixtures
- evals/evals.json: Codex — technical eval wiring for scenarios A-F
- evals/test-lint-handoff.sh: Codex — positive/negative unit tests for lint-handoff.py
- evals/run-live-evals.py: Codex — opt-in local live eval harness for scenarios A-F & trigger_evals
- skills/cli-collaboration/agents/openai.yaml: Codex — OpenAI metadata
- skills/cli-collaboration/agents/grok.yaml: Grok — documentation-only Grok metadata
- skills/cli-collaboration/references/codex-adapter.md: Codex — Codex-specific adapter notes and script ABI
- skills/cli-collaboration/references/grok-adapter.md: Grok — Grok discovery, identity, tools, and Bluefin guidance
- skills/cli-collaboration/references/alternate-workflows.md: Codex — explicit non-code handoff workflow reference
- docs/superpowers/specs/*: Codex — approved implementation design records
- docs/superpowers/plans/*: Codex — executable implementation plans
- examples/AGENTS.md: Codex — Codex/Grok/Antigravity project guidance example
- README.md: Codex — package entry point, install commands, release gates
- README_IT.md: Codex — Italian package entry point translation
- LICENSE: user/GitHub — MIT license generated during repository creation
- .gitignore: Codex — repository hygiene for local guardrail artifacts
- CLAUDE.md: Claude — Claude project guidance in the root
- GEMINI.md: Gemini — Gemini & Antigravity project guidance in the root
- CONTRIBUTORS.md: Claude — multi-agent contribution record
- CONTRIBUTORS_IT.md: Claude — Italian mirror of the multi-agent contribution record
- CHANGELOG.md: Claude — release changelog (v2.3.0 through v2.6.0)
- skills/cli-collaboration/references/handoff-template.md: Claude — canonical human handoff template
- skills/cli-collaboration/references/handoff-anti-patterns.md: Claude — semantic failure modes
- skills/cli-collaboration/references/validation-scenarios.md: Claude — textual scenarios A-F and negative asserts
- skills/cli-collaboration/agents/claude.yaml: Claude — documentation-only Claude metadata
- skills/cli-collaboration/references/claude-adapter.md: Claude — Claude Code adapter notes
- examples/AGENT_HANDOFF.md: Claude — filled handoff example
- examples/CLAUDE.md: Claude — lean Claude project guidance example
- docs/future-architecture.md: Claude — v3 thresholds and `.cli-collaboration/` sidecar policy
- examples/GEMINI.md: Gemini — lean Gemini & Antigravity project guidance example
- skills/cli-collaboration/references/gemini-adapter.md: Gemini — Gemini CLI adapter notes
- skills/cli-collaboration/agents/antigravity.yaml: Antigravity — documentation-only Antigravity metadata
- skills/cli-collaboration/references/antigravity-adapter.md: Antigravity — Antigravity IDE / App 2.0 / agy CLI adapter
- examples/hooks/*: Antigravity — deterministic hook templates for Antigravity, Claude Code, and Gemini CLI
- brainplan.md: Codex — review plan for brainstorming workflow documentation integration

### user-reserved
- final-skill.md: user — approved source specification
- workflow.md: user — workflow decisions and voting record
- progetti-1-2.md: user — user-reserved source if reintroduced

### frozen
No frozen files currently declared.

## Files changed this shift
- `.gitignore`, `brainplan.md`, `docs/superpowers/{plans,specs}/2026-07-20-grok-multicli-compatibility*`: reconciled onto `origin/main` (`5954dfd`) and normalized file permissions.
- `CONTRIBUTORS.md`, `CONTRIBUTORS_IT.md`: restored **Grok Build (xAI)** and added **Antigravity (Google DeepMind)** Phase 5 / `v2.6.0` record.
- `CHANGELOG.md`: restored authentic `[2.5.0] — 2026-07-20` release notes and aligned `[2.6.0]` summary.
- `README.md`, `README_IT.md`: added CI badge and quick nav links, restored `How It Was Developed` / `Come E Stato Sviluppato`, fixed `Package Structure` tree, removed dangling `workflow.md` mention, and documented global hook paths.
- `CLAUDE.md`, `docs/future-architecture.md`: aligned `End of Shift` format with `handoff-template.md` and updated `Current Status` to `v2.6.0`.

## Tests
- Red: none (reconciliation and documentation/release prep shift).
- Green: pending final 10-step `bash evals/run-mechanical-checks.sh` run before commits and GitHub Actions CI verification after push.

## Open concerns
- GitHub Actions `shellcheck`, `fixtures (ubuntu-latest)`, and `fixtures (macos-latest)` must pass on `main` before tagging and publishing `v2.6.0`.
- `graphify-out/` predates `v2.5.0`/`v2.6.0` changes and remains untouched locally; `cli-collaboration.png` stays untracked and untouched.

## Next agent starts from
**Next agent: Antigravity (current shift continuation).** Run `bash evals/run-mechanical-checks.sh` and `git diff --check`, split changes into clean atomic commits on `main`, push `origin main`, watch GitHub Actions CI until all 3 jobs pass, then tag/publish `v2.6.0`, update GitHub About metadata, and record the final release commit/URLs in `AGENT_HANDOFF.md`.

Do not touch: `final-skill.md`, `workflow.md`, `progetti-1-2.md` (`user-reserved`), `cli-collaboration.png`, or `graphify-out/`.

## History
- 2026-11-23T14:04:39+01:00 - Antigravity: Reconciled `main` index onto `origin/main` (`5954dfd`), normalized permissions, restored `v2.5.0` history/docs, updated `CONTRIBUTORS*.md`, `CHANGELOG.md`, `README*.md`, `CLAUDE.md`, and `docs/future-architecture.md` for `v2.6.0` release prep. (in-progress)
- 2026-11-23T13:37:42+01:00 - Antigravity: Expanded deterministic mechanical tests (`test-lint-handoff.sh` 10 cases, `run-tests.sh` 33 cases, `install-rollback-test.sh` 8 checks, `hook-guard-tests.sh` 11 blocks, Markdown link/`+x` integrity check -> 10-step CI) and added opt-in local live eval harness `evals/run-live-evals.py`. (done)
- 2026-11-23T13:26:52+01:00 - Antigravity: Added first-class Antigravity IDE / App 2.0 / `agy` support, hardened `parse-ownership.py` path/alias normalization, made `lang.sh` sandbox-friendly, moved install backups to `skills-backups/`, and added `hook-guard.py` + `examples/hooks/`. (done)
- 2026-08-19T18:22:00+02:00 - Gemini CLI: Generated local project knowledge graph via graphify (`graphify-out/`) and verified mechanical + language suites. (done)
- 2026-07-21T13:52:15+02:00 - Codex: Published `v2.5.0` as Latest GitHub Release on commit `f5e9024`, updated About metadata with Grok Build and Gemini/Antigravity CLI, and pushed `5954dfd` to `origin/main` with green CI (`shellcheck`, Ubuntu, macOS). (done)
- 2026-05-24T23:48:00+02:00 - Gemini CLI: Resolved ShellCheck SC2295/SC1090 warnings in `lang.sh` and `lang-tests.sh`, committed `v2.4.0` (`e4b85fe` / `7a14464`), pushed to `main`, and synced local installs. (done)
- 2026-05-21T23:32:08+02:00 - v2.3.0 / v2.4.0 transitions & multi-CLI sync (summarized): Codex/Claude/Gemini landed `v2.3.0` (`1f5f198`, Plan C Python `parse-ownership.py`, CI matrix, atomic rollback, `lint-handoff.py`), `brainplan.md` non-code workflows, and `v2.4.0` Language Preference (`lang.sh`). (done)
