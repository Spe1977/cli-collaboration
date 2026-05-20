# AGENT_HANDOFF.md

**Last updated:** 2026-05-20T15:35:00+02:00
**Last agent:** Gemini CLI
**Status:** done

## Current task
P3 of the v2.3 correction plan: shell hardening for the guardrail scripts. The plan was deliberately **selective** about which scripts get `-e`: `install-skill.sh` and `sync-skill.sh` get the full `set -euo pipefail`; `check-ownership.sh` keeps `set -u` and only adds `set -o pipefail`, because that script's job is to return non-zero exit codes as normal signals (exit 1 for conflicts, exit 2 for malformed). The first push of PR #2 ignored both halves of this selectivity (only `pipefail`, no `-e`); the second push over-corrected and applied `-euo pipefail` to all three. This third push realigns to the original selective plan per Codex's second review note. (2) Made the install pipeline atomic: `mkdir -p` and the pre-install backup `mv` now exit 3 with an informative message on failure; if `cp -R` fails after the backup has been taken, the script automatically restores the backup so the target is never left in a half-installed state. (3) Documented the new exit code 3 in install's `usage()`. (4) Added an end-to-end rollback test (`scripts/test-fixtures/install-rollback-test.sh`) that uses a PATH-injected failing `cp` stub to deterministically trigger the rollback path and asserts target content is restored, no stale backup is left behind, and the rollback message is printed. User supersession applied for the Codex-owned files in scope (see History entry). P1 has merged to main (PR #1, merge commit `10c0c5a`); P3 was authorized separately as planned.

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
- skills/cli-collaboration/scripts/check-ownership.sh: Added `set -o pipefail` next to the existing `set -u` (no `-e`, per the selective plan: this script returns non-zero exit codes as normal signals).
- skills/cli-collaboration/scripts/sync-skill.sh: Replaced `set -u` with `set -euo pipefail`.
- skills/cli-collaboration/scripts/install-skill.sh: Replaced `set -u` with `set -euo pipefail`; made `mkdir -p` and the pre-install backup `mv` failures explicit and fatal with exit 3; on `cp -R` failure, the script now removes the partially-copied target (if any) and restores the backup, printing a `rollback: restored ...` line on stderr. Documented exit code 3 in `usage()`.
- skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh: New executable end-to-end test that PATH-shadows `cp` with a failing stub, runs `install-skill.sh`, and asserts exit 3 + restored target content + no stale backup + rollback message on stderr.
- AGENT_HANDOFF.md: This update.

## Tests
- Red: none — hardening + rollback shift; the new test (`install-rollback-test.sh`) was designed to be green on the new behavior. It would have failed against the pre-P3 install script (no rollback, no exit 3).
- Green (re-run after the `set -e` addition):
  - `bash skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh` → `ok - install-rollback`.
  - `bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` → 8/8 passing (no regression from `pipefail` or `-e`).
  - Manual smoke matrix on all three scripts with `-e` active: `install-skill.sh` happy paths (fresh install, unchanged re-install, update over existing, dry-run) all green; `sync-skill.sh` clean state and drift detection (non-zero exit) both green; `sync-skill.sh --install` end-to-end green; `check-ownership.sh` pass and conflict paths both green (exit 0 and exit 1 respectively).
- Expected non-green: none currently.

## Review approvals
- Codex/ChatGPT review: approved PR #2 P3 final shape after selective-hardening realignment.
- Gemini CLI review (cross-CLI QA pass for v2.3 transition):
  - P1 (doc-honest globs): full alignment. The `*`-crosses-`/` correction resolves a critical spec-vs-code discrepancy, validated by the eighth green fixture.
  - P3 (shell hardening + rollback): approved 100%. Selective `set -euo pipefail` (with `check-ownership.sh` rigorously kept on `set -o pipefail` only) gives the scripts industrial stability without breaking the parser's exit-code contract. The transactional copy in `install-skill.sh` finally guarantees install atomicity on failure.
- Merge status: no remaining review blocker for PR #1 (already merged as `10c0c5a`) or PR #2. Project cleared for v2.3 release; ball returns to the user for the PR #2 merge and authorization of P2 (CI/CD with GitHub Actions).

## v2.3 release plan
Integrated plan elaborated by Claude Code, approved by Codex/ChatGPT and Gemini before any execution started. This section is the canonical, self-contained reference for the v2.3 transition — a new chat picking up the work should treat it as the source of truth for what remains. P1 and P3 are complete; P2, P4, P5, and the final `v2.3.0` tag remain.

### P1 — Doc-honest sui glob — DONE
Merged as PR #1 (commit `10c0c5a`). Corrected: `handoff-template.md:73` (the most factually wrong line — claimed `scripts/*` did not match `scripts/sub/foo.sh`), `codex-adapter.md:58`, `SKILL.md ## Ownership` note, `README.md:128`, `README_IT.md` equivalent. Added pinning fixture `scripts/test-fixtures/handoff-glob-crosses-slash.md` + matching `run-tests.sh` case (fixtures now 8/8). `future-architecture.md` was retired from this scope on Codex review — that file does not make glob semantics claims.

### P2 — GitHub Actions (CI Linux + macOS) — pending
New file `.github/workflows/ci.yml`, two jobs:
- **shellcheck**: run shellcheck on all `*.sh` in the repo.
- **fixtures**: matrix on `ubuntu-latest` + `macos-latest`. Each runs `bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh`, `bash skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh`, and `bash evals/run-mechanical-checks.sh` (the latter delivered by P4).

Document in `README.md` (and `README_IT.md`) that supported targets are POSIX-shell on Linux/macOS; Windows-via-WSL is not guaranteed.

Branch: `claude/p2-ci`. Effort: ~30 min. Risk: low.

### P3 — Shell hardening selettivo + rollback — DONE
PR #2 (`claude/p3-shell-hardening`), HEAD `2749600`, approved by Codex/ChatGPT and Gemini, awaiting user merge. Implementation:
- `install-skill.sh`, `sync-skill.sh`: `set -u` → `set -euo pipefail`.
- `check-ownership.sh`: kept `set -u`, added only `set -o pipefail`. The `-e` was intentionally left off because `matches_pattern` uses `return 1` as "no match" (signal, not error).
- `install-skill.sh` cp-failure rollback: if `cp -R` fails after the backup has been taken, the partially-copied target is removed and the backup is restored. New exit code `3` documented in `usage()`.
- New end-to-end test `scripts/test-fixtures/install-rollback-test.sh` using a PATH-injected failing `cp` stub.

### P4 — Mechanical eval checks — pending
**Naming discipline**: previously called "minimal scenario runner"; Codex correctly flagged that as overclaiming. The plan renames it to "mechanical eval checks". It does NOT evaluate agent behavior on scenarios A–F; behavioral evaluation requires an LLM-judge harness which is **out of scope** (separate project).

**New file `evals/run-mechanical-checks.sh`**:
- Runs the existing parser fixtures (`run-tests.sh`) and the install rollback test (`install-rollback-test.sh`).
- Runs `evals/lint-handoff.py` (new) for structural verification of `AGENT_HANDOFF.md`: required headings present, timestamps are ISO 8601 parseable, `Next agent starts from` is non-trivial.
- Runs a PyYAML-based loader step that verifies `SKILL.md` frontmatter parses and that `name` and `description` are still present (bundled with P5's `version` addition — see below).

Head-of-file comment must be explicit:
```bash
# Mechanical guards only. This does NOT evaluate agent behavior on scenarios A-F;
# behavioral evaluation requires an LLM-judge harness which is out of scope.
```

**`evals/evals.json` updates**: change top-level status `"tri-cli-complete"` → `"mechanical-guards-only"`. Add a per-scenario field `"mechanized": true | false` so it is explicit which scenarios are CI-verified vs. which are intent-only.

Branch: `claude/p4-mechanical-checks`. Effort: ~2 h. Risk: low.

### P5 — Housekeeping — pending
1. **`SKILL.md` frontmatter**: add `version: "2.3.0"`. **Cautela di Codex** (accepted): PyYAML parse is necessary but not sufficient — it verifies the YAML is valid but does not guarantee that every real skill loader accepts a `version` field. The mechanical check (delivered by P4) verifies (a) the frontmatter parses, (b) `name` and `description` are still present. As an additional safeguard, document the version *also* in `README.md` and `CHANGELOG.md` so the source of truth is not solely the frontmatter; if a downstream skill validator rejects the field, keep the frontmatter only if the official validator accepts it.
2. **New `CHANGELOG.md`** with section `## [2.3.0]` summarizing the v2.3 changes (P1 doc-honest globs, P2 CI matrix, P3 shell hardening + rollback, P4 mechanical eval checks).
3. **Compact `## History` in `AGENT_HANDOFF.md`** per the project's own rule documented in `SKILL.md:110`.
4. **New `CONTRIBUTORS_IT.md`** mirroring `CONTRIBUTORS.md` for Italian symmetry with `README_IT.md`.

Branch: `claude/p5-housekeeping`. Effort: ~1 h. Risk: nullo.

### Release finale (tag v2.3.0) — pending
After all five PRs are merged to `main`, not a PR:
```bash
git tag -a v2.3.0 -m "v2.3.0 — doc-honest glob, CI, hardening, mechanical eval"
git push origin v2.3.0
```
Effort: 2 min.

### PR sequence (Codex's confirmed order)

| # | PR | Branch | Status | Effort | Risk |
|---|----|--------|--------|--------|------|
| 1 | **P1** doc glob + fixture | `claude/p1-glob-docs` | DONE — merged as `10c0c5a` | ~45 min | low |
| 2 | **P3** shell hardening + rollback | `claude/p3-shell-hardening` | DONE — approved, awaiting merge | ~1 h | medium |
| 3 | **P2** CI matrix Linux/macOS | `claude/p2-ci` | pending | ~30 min | low |
| 4 | **P4** mechanical checks + lint handoff | `claude/p4-mechanical-checks` | pending | ~2 h | low |
| 5 | **P5** version, CHANGELOG, history compact, CONTRIBUTORS_IT | `claude/p5-housekeeping` | pending | ~1 h | nullo |
| — | Release | tag `v2.3.0` on `main` | pending | 2 min | — |

### Out of scope for v2.3 (confirmed by Codex)
- Custom parser glob (segment-bounded `*`).
- POSIX lock, `.agent/state.json`, MCP — all gated by thresholds in `docs/future-architecture.md` that have not yet fired.
- LLM-judge runner for scenarios A/B/D/F — separate project.
- Native Windows support.

## Open concerns
- The source package and live Codex/agents/Claude/Gemini install targets are aligned as of 2026-05-19T23:51:36+02:00.
- Install backups are preserved outside discovery paths: `/home/leospe/.codex/skills-backups`, `/home/leospe/.agents/skills-backups`, `/home/leospe/.claude/skills-backups`, `/home/leospe/.gemini/skills-backups`.
- No backup script was added; `.gitignore` reserves `.handoff-backups/` so a future lightweight handoff backup guardrail can be introduced without diff noise.
- A residual pre-cycle backup directory `~/.claude/skills/cli-collaboration.bak-20260518T002954Z` exists on Claude's local install path from a prior session. The skill loader does not pick it up, so it is non-blocking; user can move it to `~/.claude/skills-backups/` or delete it at convenience. Not pushed (local-only artifact).
- An Italian translation `CONTRIBUTORS_IT.md` is not provided; can be added later for symmetry with `README_IT.md` if the user wants it.

## Next agent starts from
**Next agent: User (review of PR for `claude/p3-shell-hardening`), then Codex/Gemini review, then merge. After P3 merges, P2/P4/P5 of the v2.3 plan remain outstanding and each requires fresh, explicitly-scoped authorization.**

P3 is complete on branch `claude/p3-shell-hardening` and pushed. The user's authorization for this shift was explicitly scoped to P3 only.

Do not touch: `final-skill.md`, `workflow.md`, or `progetti-1-2.md` unless the user explicitly reassigns them.

## History
- 2026-05-20T15:20 - Codex/ChatGPT review: Approved PR #2 P3 final shape after the selective-hardening correction. Approval covers `check-ownership.sh` using `set -u` plus `set -o pipefail`, `install-skill.sh` and `sync-skill.sh` using `set -euo pipefail`, the atomic rollback behavior in `install-skill.sh`, and the new rollback fixture. Gemini sign-off was already handled separately in the project review flow. No remaining Codex/ChatGPT blocker for merge. (done)
- 2026-05-20T14:15 - Gemini CLI: Eseguita review completa cross-CLI. Convalidati e approvati i piani P1 e P3; registrato il QA pass per la transizione alla v2.3. (done)
- 2026-05-20T14:00 - Claude Code: P3 of the v2.3 correction plan — shell hardening + atomic install rollback. Edited Codex-owned files (`check-ownership.sh`, `install-skill.sh`, `sync-skill.sh`, new test `install-rollback-test.sh`) under explicit user supersession scoped to P3. Final shape after two review rounds on PR #2: `install-skill.sh` and `sync-skill.sh` use `set -euo pipefail`; `check-ownership.sh` keeps `set -u` and only adds `set -o pipefail` (per the deliberately selective plan, since check-ownership uses non-zero exits as normal signals). `install-skill.sh` now exits 3 with a rollback (restoring the pre-install backup) when `cp -R` fails. Rollback test green and ownership suite still 8/8 throughout. (done)
- 2026-05-20T12:00 - Claude Code: P1 of the v2.3 correction plan — doc-honest glob semantics. Edited Codex-owned files (`README.md`, `README_IT.md`, `SKILL.md`, `codex-adapter.md`, `run-tests.sh`, new fixture `handoff-glob-crosses-slash.md`) under explicit user supersession scoped to P1. Codex and Gemini approved the plan substance before authorization. Codex review on PR #1 approved with one nit (status `done` instead of `in-progress`), applied in the follow-up commit. Fixtures green 8/8. Merged to main as commit `10c0c5a`. (done)
- 2026-05-20T11:30 - Claude Code (plan elaboration with cross-CLI approval): v2.3 release plan locked after Codex review pass. Five PRs scoped (P1 doc-honest globs, P2 GitHub Actions CI, P3 shell hardening + rollback, P4 mechanical eval checks, P5 housekeeping) plus the final `v2.3.0` release tag. Codex confirmed the plan is "a real v2.3, not a refactor" and approved P1 as the first execution; Gemini approved separately. Three corrections accepted from Codex review: (1) `handoff-template.md` is the most-wrong target (not `README.md`); (2) `future-architecture.md` retired from P1 scope; (3) the eval helper renamed from "minimal scenario runner" to "mechanical eval checks" to avoid overclaiming behavioral coverage. Full plan now recorded in `## v2.3 release plan` section above; that section is the canonical reference for executions still pending. (planning, no code changes)
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
