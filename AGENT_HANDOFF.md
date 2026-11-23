# AGENT_HANDOFF.md

**Last updated:** 2026-11-23T14:17:47+01:00
**Last agent:** Antigravity
**Status:** done

## Current task
Record final GitHub `v2.6.0` release metadata, green CI verification, updated `CONTRIBUTORS*.md` / docs, and updated GitHub About description and topics under explicit User Supersession.

## Current state
- **User Supersession (2026-11-23):** User authorized Antigravity to reconcile local `main` onto `origin/main`, add/update Antigravity among contributors, refresh `v2.6.0` docs, push to GitHub, verify CI, publish `v2.6.0`, and improve repository description/topics while keeping `### user-reserved` (`final-skill.md`, `workflow.md`, `progetti-1-2.md`), `cli-collaboration.png`, `graphify-out/`, and `.claude/` untouched.
- **GitHub Release `v2.6.0` published as Latest:** Tag `v2.6.0` points to release commit `7a4f8f8` (preceded by atomic commits `62982ed` and `3e9b467` reconciled atop `5954dfd`); release URL `https://github.com/Spe1977/cli-collaboration/releases/tag/v2.6.0` (`isDraft: false`, `isPrerelease: false`). `main` adds only this final release-metadata handoff commit.
- **GitHub Actions CI green (`45181059385`):** `https://github.com/Spe1977/cli-collaboration/actions/runs/45181059385` passed with conclusion `success` across `shellcheck` (12s), `fixtures (ubuntu-latest)` (14s), and `fixtures (macos-latest)` (29s).
- **GitHub About & Topics updated:** Description tightened to 248 chars separating `Gemini CLI` and `Antigravity IDE/CLI` and highlighting deterministic guardrails and lifecycle hooks; topics updated (`+antigravity`, `+grok`, `-github-actions`, `-anthropic`, 20/20 total covering all 5 supported runtimes).
- **Runtime skill homes synced:** User verified `install-skill.sh --all` and `sync-skill.sh --all` across Codex (`~/.codex`), Agents/Gemini CLI (`~/.agents`), Grok (`~/.grok`), Claude Code (`~/.claude`), and Antigravity (`~/.gemini/config`) — all 5 targets `in-sync` with no duplicate `~/.gemini/skills/cli-collaboration`.

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
- `.gitignore`, `brainplan.md`, `docs/superpowers/{plans,specs}/2026-07-20-grok-multicli-compatibility*`: reconciled onto `origin/main` (`5954dfd`) and normalized file permissions (`0644` non-scripts / `0755` scripts).
- `CONTRIBUTORS.md`, `CONTRIBUTORS_IT.md`: restored **Grok Build (xAI)** and added **Antigravity (Google DeepMind)** Phase 5 / `v2.6.0` record.
- `CHANGELOG.md`: restored authentic `[2.5.0] — 2026-07-20` release notes and aligned `[2.6.0]` summary.
- `README.md`, `README_IT.md`: added CI badge and quick nav links, restored `How It Was Developed` / `Come E Stato Sviluppato`, fixed `Package Structure` tree, removed dangling `workflow.md` mention, and documented global hook paths.
- `CLAUDE.md`, `docs/future-architecture.md`: aligned `End of Shift` format with `handoff-template.md` and updated `Current Status` to `v2.6.0`.
- `AGENT_HANDOFF.md`: reconciled ownership/history and recorded verified `v2.6.0` GitHub release, CI, and About metadata.
- GitHub repository & release: pushed commits `62982ed`, `3e9b467`, `7a4f8f8`, tag `v2.6.0`, Latest release `v2.6.0`, and updated About description + topics.

## Tests
- Red: none.
- Green:
  - `python3 evals/lint-handoff.py AGENT_HANDOFF.md` (passed, within 16,000-char budget)
  - `bash evals/run-mechanical-checks.sh` (all 10/10 steps green locally after final handoff edit)
  - GitHub Actions CI run `45181059385` (`7a4f8f8`): `shellcheck` (`success`), `fixtures (ubuntu-latest)` (`success`), `fixtures (macos-latest)` (`success`)
  - `gh release view v2.6.0` & `gh repo view Spe1977/cli-collaboration`: verified `v2.6.0` as Latest (`isDraft: false`, `isPrerelease: false`), updated description, and 20 topics including `antigravity` and `grok`

## Open concerns
- `evals/run-live-evals.py` was verified deterministically via `--self-test` and `--dry-run` against a temporary stub CLI; live execution against external installed CLIs (`claude`, `codex`, `gemini`, `agy`, `grok`) remains opt-in locally (`python3 evals/run-live-evals.py --cli <cli> --mode all`).
- `graphify-out/` predates `v2.5.0`/`v2.6.0` changes and remains untouched locally; `cli-collaboration.png` stays untracked and untouched.

## Next agent starts from
**Next agent: task-fit decides.** Release `v2.6.0` is published on GitHub (`v2.6.0` on `7a4f8f8`) with `main` holding only this final release-metadata handoff commit; all five local user runtime homes are synced. Start from the next user request.

Do not touch: `final-skill.md`, `workflow.md`, `progetti-1-2.md` (`user-reserved`), `cli-collaboration.png`, or `graphify-out/`.

## History
- 2026-11-23T14:17:47+01:00 - Antigravity: Reconciled `main` onto `origin/main` (`5954dfd`), normalized file modes, updated `CONTRIBUTORS*.md`, `CHANGELOG.md`, `README*.md`, `CLAUDE.md`, and `docs/future-architecture.md`, pushed `62982ed`/`3e9b467`/`7a4f8f8` with green CI (`45181059385`), published `v2.6.0` Latest GitHub Release, updated repo About/topics, and closed handoff. (done)
- 2026-11-23T13:37:42+01:00 - Antigravity: Expanded deterministic mechanical tests (`test-lint-handoff.sh` 10 cases, `run-tests.sh` 33 cases, `install-rollback-test.sh` 8 checks, `hook-guard-tests.sh` 11 blocks, Markdown link/`+x` integrity check -> 10-step CI) and added opt-in local live eval harness `evals/run-live-evals.py`. (done)
- 2026-11-23T13:26:52+01:00 - Antigravity: Added first-class Antigravity IDE / App 2.0 / `agy` support, hardened `parse-ownership.py` path/alias normalization, made `lang.sh` sandbox-friendly, moved install backups to `skills-backups/`, and added `hook-guard.py` + `examples/hooks/`. (done)
- 2026-08-19T18:22:00+02:00 - Gemini CLI: Generated local project knowledge graph via graphify (`graphify-out/`) and verified mechanical + language suites. (done)
- 2026-07-21T13:52:15+02:00 - Codex: Published `v2.5.0` as Latest GitHub Release on commit `f5e9024`, updated About metadata with Grok Build and Gemini/Antigravity CLI, and pushed `5954dfd` to `origin/main` with green CI (`shellcheck`, Ubuntu, macOS). (done)
- 2026-05-24T23:48:00+02:00 - Gemini CLI: Resolved ShellCheck SC2295/SC1090 warnings in `lang.sh` and `lang-tests.sh`, committed `v2.4.0` (`e4b85fe` / `7a14464`), pushed to `main`, and synced local installs. (done)
- 2026-05-21T23:32:08+02:00 - v2.3.0 / v2.4.0 transitions & multi-CLI sync (summarized): Codex/Claude/Gemini landed `v2.3.0` (`1f5f198`, Plan C Python `parse-ownership.py`, CI matrix, atomic rollback, `lint-handoff.py`), `brainplan.md` non-code workflows, and `v2.4.0` Language Preference (`lang.sh`). (done)
