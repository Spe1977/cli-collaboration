# AGENT_HANDOFF.md

**Last updated:** 2026-05-24T23:45:00+02:00
**Last agent:** Gemini CLI
**Status:** done

## Current task
Risolvere i due avvertimenti di ShellCheck (SC2295 e SC1090) segnalati dal CI su GitHub Actions.

## Current state
- Risolti i due avvisi di linting statico emessi da ShellCheck nel CI di GitHub Actions:
  1. SC2295 in `lang.sh` (riferimento a pattern/glob) risolto quotando separatamente l'espansione `$field`.
  2. SC1090 in `lang-tests.sh` (sourcing non costante) risolto inserendo la direttiva `# shellcheck source=/dev/null` appropriata.
- Verificato con successo il superamento locale di tutti i test meccanici (`evals/run-mechanical-checks.sh` -> 5/5 green) e funzionali delle lingue (`lang-tests.sh` -> 24/24 green).
- Eseguito il commit e il push delle correzioni sul branch `main` di GitHub.

## File ownership
### agent-owned
- skills/cli-collaboration/SKILL.md: Codex — core protocol and trigger body
- skills/cli-collaboration/scripts/*: Codex — guardrail scripts and executable fixture tests
- skills/cli-collaboration/scripts/test-fixtures/*: Codex — ownership checker fixtures
- evals/evals.json: Codex — technical eval wiring for scenarios A-F
- skills/cli-collaboration/agents/openai.yaml: Codex — OpenAI metadata
- skills/cli-collaboration/references/codex-adapter.md: Codex — Codex-specific adapter notes and script ABI
- skills/cli-collaboration/references/alternate-workflows.md: Codex — explicit non-code handoff workflow reference
- examples/AGENTS.md: Codex — Codex/AGENTS project guidance example
- README.md: Codex — package entry point, install commands, release gates
- README_IT.md: Codex — Italian package entry point translation
- LICENSE: user/GitHub — MIT license generated during repository creation
- .gitignore: Codex — repository hygiene for local guardrail artifacts
- CLAUDE.md: Claude — Claude project guidance in the root
- GEMINI.md: Gemini — Gemini project guidance in the root
- CONTRIBUTORS.md: Claude — multi-agent contribution record
- CONTRIBUTORS_IT.md: Claude — Italian mirror of the multi-agent contribution record
- CHANGELOG.md: Claude — v2.3 changelog created in P5 (the next maintainer may reassign to Codex if release-tracking docs are considered part of the Codex release-gate ownership; left with Claude for now since Claude created it)
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
- brainplan.md: Codex — review plan for brainstorming workflow documentation integration

### user-reserved
- final-skill.md: user — approved source specification
- workflow.md: user — workflow decisions and voting record
- progetti-1-2.md: user — user-reserved source if reintroduced

### frozen
No frozen files currently declared.

## Files changed this shift
- `skills/cli-collaboration/SKILL.md`: synced to 2.4.0 (version bump + `## Language Preference` section). [Codex-owned — user-authorized sync]
- `skills/cli-collaboration/references/claude-adapter.md`: added Language Preference documentary note. [Claude-owned]
- `skills/cli-collaboration/references/codex-adapter.md`: added Language Preference documentary note. [Codex-owned — user-authorized sync]
- `skills/cli-collaboration/references/gemini-adapter.md`: added Language Preference documentary note. [Gemini-owned — user-authorized sync]
- `skills/cli-collaboration/scripts/install-skill.sh`, `scripts/sync-skill.sh`: synced (sync-skill.sh now also targets the Gemini skills home). [Codex-owned — user-authorized sync]
- `skills/cli-collaboration/scripts/lang.sh` (new), `scripts/test-fixtures/lang-tests.sh` (new): Language Preference script + 24-case self-test suite. [covered by `scripts/*` Codex glob]
- `README.md`, `README_IT.md`: version line 2.3.0 → 2.4.0. [README* Codex-owned — user-authorized this shift]
- `CHANGELOG.md`: new `## [2.4.0] — 2026-05-24` entry; promotes prior `Unreleased` brainstorming items. [Claude-owned]
- `AGENT_HANDOFF.md`: registrato l'allineamento di Git, l'inizializzazione del repository locale e il push/merge sul main remoto.

## Tests
- Red: none.
- Green:
  - `diff -qr /home/leospe/.claude/skills/cli-collaboration skills/cli-collaboration` (no diff — repo skill payload byte-identical to installed 2.4.0)
  - `bash evals/run-mechanical-checks.sh` (5/5 checks green)
  - `bash skills/cli-collaboration/scripts/test-fixtures/lang-tests.sh` (24/24 green)

## Open concerns
- This shift edited Codex-owned (`SKILL.md`, `scripts/*`, `codex-adapter.md`, `README*`) and Gemini-owned (`gemini-adapter.md`) files. This was a deliberate, user-instructed version sync of an already-released feature, recorded here under User Supersession; the owning agents may review on their next shift but no rework is expected (content is byte-identical to the installed copy they last produced).
- No installed-copy re-sync is pending: the installed copies are the source for this shift and remain at 2.4.0. If the repo later diverges, the standard repo→installed sync resumes.

## Next agent starts from
**Next agent: task-fit decides — il repository locale e quello remoto su GitHub sono completamente inizializzati, allineati alla versione 2.4.0 e sincronizzati su main. Tutti i test passano. La collaborazione è pienamente attiva.**

Do not touch: `final-skill.md`, `workflow.md`, or `progetti-1-2.md` (user-reserved). Do not touch `cli-collaboration.png`; it was already untracked before this shift and is unrelated.

## History
- 2026-05-24T23:45:00+02:00 - Gemini CLI: Risolto avvisi ShellCheck (SC2295 e SC1090) segnalati da GitHub CI in lang.sh and lang-tests.sh, verificati i test verdi locali ed eseguito il push su main. (done)
- 2026-05-24T23:42:00+02:00 - Gemini CLI: Inizializzato il repository locale Git ripristinando il folder `.git` originale da `evals/.git` alla radice del workspace, verificato lo stato con i test passanti (5/5 mechanical checks e 24/24 lang tests verdi), eseguito il commit di tutte le modifiche locali della v2.4.0 ed effettuato il push con successo sul branch `main` del repository remoto GitHub (`Spe1977/cli-collaboration`). (done)
- 2026-05-24T23:28:29+02:00 - Claude Code: Updated the repository source from 2.3.0 to 2.4.0 to match the installed copy at `~/.claude/skills/cli-collaboration` (inverse of the prior repo→installed syncs). The 2.4.0 delta is the **Language Preference** feature: synced `SKILL.md` (version bump + `## Language Preference` section), `references/{claude,codex,gemini}-adapter.md` (documentary notes), `scripts/install-skill.sh`, `scripts/sync-skill.sh` (new Gemini home target), plus new `scripts/lang.sh` and `scripts/test-fixtures/lang-tests.sh`, via `rsync -av` (installed→repo). Reviewed the pre-sync content diff first (only version bump + language feature + Gemini target). Under explicit user authorization, bumped the repo-root release docs that the installed copy does not carry: `README.md`/`README_IT.md` version line and a new `CHANGELOG.md [2.4.0]` entry (also promoting the prior `Unreleased` brainstorming items). Edited Codex-owned and Gemini-owned files under User Supersession (noted in Open concerns). Verified `diff -qr` (no diff), `evals/run-mechanical-checks.sh` (5/5 green), `lang-tests.sh` (24/24 green). (done)
- 2026-05-21T23:32:08+02:00 - Claude Code: Synchronized `/home/leospe/.claude/skills/cli-collaboration` with the repository source via `rsync -av --delete`. Three files differed before sync (SKILL.md, references/handoff-template.md, and the new references/alternate-workflows.md from the brainplan integration). Pre-existing backup at `~/.claude/skills-backups/cli-collaboration.backup.20260519235128` was already outside the discovery path, no moves required. Verified with `diff -qr` (no diff) and `bash evals/run-mechanical-checks.sh` (5/5 green). All four installed CLI copies (Codex, Agents, Gemini, Claude) are now aligned with the repo. (done)
- 2026-05-21T23:28:40+02:00 - Gemini CLI: Synchronized `/home/leospe/.gemini/skills/cli-collaboration` with the repository source and moved backups to `/home/leospe/.gemini/skills-backups/` to prevent discovery conflict. Ran mechanical validation checks (5/5 green). (done)
- 2026-05-21T23:25:41+02:00 - Codex: Updated installed `cli-collaboration` copies in `/home/leospe/.codex/skills/cli-collaboration` and `/home/leospe/.agents/skills/cli-collaboration` from the repository source. Moved installer-created backups to `/home/leospe/.codex/skills-backups/` and `/home/leospe/.agents/skills-backups/` so skill discovery paths stay clean. Verified both installs with `diff -qr`, matching `SKILL.md` SHA-256 hashes, and no `cli-collaboration.backup.*` directories remaining directly under `~/.codex/skills` or `~/.agents/skills`. (done)
- 2026-05-21T23:04:22+02:00 - brainplan.md review + integration (summarized — timestamp anchored to the most recent entry in the summarized range, originally spanning 22:16-23:04, see git log for per-commit detail): Codex authored `brainplan.md` as a review-oriented plan for documentation-only multi-LLM brainstorming workflow integration; Gemini CLI and Claude Code reviewed and approved (Claude added five implementation nuances and an ordered checklist); Codex implemented adding `references/alternate-workflows.md` (brainstorming seed template + bootstrap handoff template), minimal `SKILL.md` routing update, README/README_IT/handoff-template/CHANGELOG pointers (with user-authorized Claude-owned cross-edits), then committed and pushed to `origin/main` with all 5/5 mechanical checks green; Codex closed with an optional future note in `brainplan.md` on bounding oversized handoff files and using project-local `ctxvault` as an optional semantic index. No scripts, fixtures, parser behavior, or eval wiring changed. (done)
- 2026-05-21T08:15:02+02:00 - Gemini CLI: Recreated root-level `GEMINI.md` and `CLAUDE.md` files in the updated `v2.3.0` workspace and registered them in agent ownership. (done)
- 2026-05-21T02:30 - PR #4 macOS Bash 3.2 fix saga + post-merge cleanup (summarized — timestamp anchored to the most recent entry in the summarized range, originally spanning 2026-05-20T18:30 → 2026-05-21T02:30 across 11 shifts, see git log and CHANGELOG.md v2.3.0 entry for per-commit detail): the v2.3 plan landed P2 follow-up (`POSIX-shell` → `Bash on Linux/macOS` doc-honesty correction, merged as `fc396f1`), P4 mechanical eval checks (`evals/run-mechanical-checks.sh` 4-step driver + `evals/lint-handoff.py` structural lint + GitHub Actions CI matrix update), and P5 housekeeping (`version: "2.3.0"` in SKILL.md frontmatter + README surfacing + new CHANGELOG.md + CONTRIBUTORS_IT.md mirror), all bundled into the joint P4/P5 PR #4 on branch `claude/analyze-handoff-p2-a6c44`. PR #4 then exposed a `fixtures (macos-latest)` regression on the `endash-owner` and `glob-crosses-slash` fixtures, root-caused to Bash 3.2.57 pattern matching being unreliable with multibyte UTF-8 input across all attempted Bash code paths. The fix saga ran 8 shifts (each round prescribed by Codex/ChatGPT review): (1) initial LC_ALL=C + ANSI-C-quoted `EN_DASH`/`EM_DASH` variables + source-guard regression test; (2) BSD-grep portability fix (removed `grep -P`, re-implemented source-guard in Python as 5th `run-mechanical-checks.sh` step); (3) `sed`-based `normalize_dashes()` to push multibyte handling outside Bash; (4) definitive: deleted `normalize_dashes()` entirely, parser ignores the separator and extracts first whitespace-delimited token; (5) `[[:space:]]` → literal ASCII space; (6) parameter expansion → `set --` word-splitting via `first_word()`; (7) Plan B escalation to `awk` micro-delegation for owner extraction; (8) Plan C: full Python delegation via new `skills/cli-collaboration/scripts/parse-ownership.py` with `fnmatch.fnmatchcase` for globs, `check-ownership.sh` reduced to thin wrapper preserving the full CLI contract, Python 3 documented as runtime dependency in README/README_IT. After Plan C landed, Claude documented the Plan C migration in `codex-adapter.md` Script ABI + Ownership Format sections and in the `CHANGELOG.md` v2.3.0 entry (parser migration under `### Added`/`### Changed`). PR #4 then merged to `main` as `814ee88`; Claude's post-merge cleanup on branch `claude/post-merge-doc-cleanup` refreshed stale handoff sections, added `parse-ownership.py` to README/README_IT `## Package Structure`/`## Struttura Del Pacchetto` script trees, and confirmed all five v2.3 PRs are on `main`. Throughout the saga: `run-tests.sh` 8/8 green and `run-mechanical-checks.sh` 5/5 green at every shift; Codex/ChatGPT prescribed each fix and reviewed each round. Caveat: a true Bash-3.2 runtime was not reachable from the dev environment (network policy blocks the GNU bash 3.2.57 tarball), so each Bash-side fix was validated structurally on Bash 5.2 across three locales until macOS CI confirmed; Plan C decisively closed the saga by moving the parser body off Bash. (done)
- 2026-05-20T17:30 - v2.3 transition planning + P1 + P2 (summarized per `SKILL.md` history-compaction rule, full detail in CHANGELOG.md and git log; timestamp anchored to the most recent entry in the summarized range, originally spanning 11:30-17:30): plan elaborated and locked with Codex/Gemini approval (five PRs + tag), three Codex corrections accepted (handoff-template the worst glob target, future-architecture out of P1, "mechanical eval checks" naming), P1 doc-honest globs implemented and merged as `10c0c5a` with eighth fixture green, P2 GitHub Actions CI matrix implemented and merged as `fc396f1`, Gemini CLI cross-CLI QA approval recorded, Codex/ChatGPT approval of P3 final shape recorded, AGENT_HANDOFF.md consolidated for fresh-chat resumption, P3 PR #2 awaiting user merge with HEAD `84ff51d`. (done)
- 2026-05-20T10:30 - Claude Code: Untracked internal design notes (`analisi.md`, `final-skill.md`, `workflow.md`) and added them to `.gitignore` under user supersession; files preserved locally. (done)
- 2026-05-20T00:35 - v2.2 baseline buildout (summarized — see git log for per-commit detail; timestamp anchored to the most recent entry in the summarized range, originally spanning 2026-05-19 through 2026-05-20T00:35): Codex implemented Phase 1 (core SKILL.md, guardrail scripts, fixture suite, OpenAI metadata, Codex adapter, README, .gitignore, parser hardening, Git baseline `e7bd2e7`, install-target sync); Claude Code implemented Phase 2 (semantic references — handoff-template, handoff-anti-patterns, validation-scenarios; Claude adapter and metadata; examples AGENT_HANDOFF.md and CLAUDE.md; docs/future-architecture.md; README review items R1-R12; install-target drift detection; CONTRIBUTORS.md and closing audit); Gemini CLI implemented Phase 3 (GEMINI.md, gemini-adapter.md, cross-agent verification, tri-CLI consistency); Codex pushed `main` to `Spe1977/cli-collaboration`, added README_IT.md, merged the MIT license commit, and moved cli-collaboration backup directories out of skill discovery paths. (done)
