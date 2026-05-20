# AGENT_HANDOFF.md

**Last updated:** 2026-05-20T22:00:00+02:00
**Last agent:** Claude Code
**Status:** in-progress

## Current task
**v2.3 transition — fix shift addressing Codex/ChatGPT's two REQUEST CHANGES blockers on PR #4.** State summary:

- **P1 (doc-honest globs)** — DONE. Merged to `main` as commit `10c0c5a` (PR #1, branch `claude/p1-glob-docs`).
- **P3 (shell hardening + atomic install rollback)** — DONE. Merged to `main` as merge commit `8ae7e59` (PR #2, branch `claude/p3-shell-hardening`).
- **P2 (GitHub Actions CI Linux + macOS)** — DONE. Merged to `main` as merge commit `fc396f1` (PR #3, branch `claude/analyze-handoff-p2-a6c44` — session-allocated branch in place of the plan's `claude/p2-ci`). Codex post-merge review approved P2 with one documentation correction: the platform wording in `README.md`, `README_IT.md`, and this handoff was changed from "POSIX-shell" to "Bash on Linux/macOS" because the scripts use Bash-only features (`mapfile`, `[[ ... ]]`) and are not strictly POSIX `sh`. The wording correction is on the same branch as P4+P5 below (commit `a7e6436`) and will go in the same PR.
- **P4 (mechanical eval checks)** — implemented on branch `claude/analyze-handoff-p2-a6c44` (commit `75721cf`). Added `evals/run-mechanical-checks.sh` (parser fixtures + install rollback + lint-handoff + SKILL.md frontmatter check, with explicit "mechanical guards only" head comment), `evals/lint-handoff.py` (structural lint), updated `evals/evals.json` (`status` → `"mechanical-guards-only"`, added per-scenario `mechanized` field), and wired the new script into `.github/workflows/ci.yml` (Python setup + PyYAML install + new step in the `fixtures` job).
- **P5 (housekeeping)** — implemented on the same branch (this shift). Added `version: "2.3.0"` to `SKILL.md` frontmatter, surfaced the version also in `README.md`, `README_IT.md`, and a new `CHANGELOG.md` (per Codex's cautela — multiple sources of truth in case a downstream skill validator rejects the frontmatter field). New `CONTRIBUTORS_IT.md` mirrors `CONTRIBUTORS.md` for IT symmetry. Compacted `## History` per the project's own rule in `SKILL.md`: kept the last three detailed entries (P5 = this shift, P4, P2 follow-up) and summarized older entries.

- **Release tag `v2.3.0`** — pending after the bundled P4+P5 PR merges.

**Per user direction (2026-05-20T20:00)**: P4 and P5 are bundled into a single PR (#4) off `claude/analyze-handoff-p2-a6c44` for one combined Codex/ChatGPT + Gemini review pass, instead of two separate review cycles. The bundled PR also carries the P2 doc-correction commit `a7e6436`. Once #4 merges, the only remaining step is the `v2.3.0` release tag.

**Review outcome on PR #4 (2026-05-20T21:00)**: Gemini approved the bundle in full. Codex/ChatGPT requested changes citing two blockers — Blocker 1: `fixtures (macos-latest)` failed on Bash 3.2.57 (`endash-owner` and `glob-crosses-slash` returned exit 1 instead of 0 because multibyte UTF-8 literals in `check-ownership.sh` patterns are unreliable under Bash 3.2's pattern matching); Blocker 2: this `AGENT_HANDOFF.md` carried stale contradictions (P4/P5 listed as both implemented and pending, P3 still "awaiting user merge", an open concern claiming `CONTRIBUTORS_IT.md` was missing even though P5 added it). Both blockers addressed in the fix shift recorded below.

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

### user-reserved
- final-skill.md: user — approved source specification
- workflow.md: user — workflow decisions and voting record
- progetti-1-2.md: user — user-reserved source if reintroduced

### frozen
No frozen files currently declared.

## Files changed this shift
- skills/cli-collaboration/scripts/check-ownership.sh: **macOS Bash 3.2 portability fix (Codex Blocker 1)**. Added `export LC_ALL=C` at the top to force byte-mode regardless of inherited locale. Defined `EN_DASH=$'\xe2\x80\x93'` and `EM_DASH=$'\xe2\x80\x94'` via ANSI-C quoting so the script source has zero literal multibyte characters in patterns. Replaced every literal en-dash / em-dash inside `${rest//pat/rep}`, `[[ rest == *pat* ]]`, and `${rest%%pat*}` with the variable references (`"$EM_DASH"`, `"$EN_DASH"`). Edited under Codex's explicit textual request ("Fix consigliato: sistemare `check-ownership.sh`...") which constitutes valid supersession for this Codex-owned file. Modern Bash on Linux/macOS is unaffected; Bash 3.2.57 stops misbehaving on multibyte pattern ops in C locale.
- skills/cli-collaboration/scripts/test-fixtures/run-tests.sh: Added a **source-level regression guard** that runs `grep -nP '[\xe2][\x80][\x93\x94]' check-ownership.sh` after the eight fixture cases, with allowlist exceptions for the `EN_DASH=`/`EM_DASH=` definition lines and the comments describing them. A future commit that reintroduces a literal en-dash or em-dash anywhere in the script outside those allowlisted lines will fail this new test case (`source-guard`). Edited under the same Codex supersession.
- AGENT_HANDOFF.md: **Semantic cleanup (Codex Blocker 2)**: removed three stale "pending" bullets at the end of `## Current task` that contradicted the bullets just above them (P4 + P5 listed as both implemented and pending); corrected the `## v2.3 release plan > P3` section that still said "awaiting user merge" (P3 was merged as `8ae7e59` earlier in this PR cycle); updated the `## Review approvals` section to reflect both Gemini's APPROVED verdict and Codex's REQUEST CHANGES with the two blockers and their resolutions; resolved the `## Open concerns` line that claimed `CONTRIBUTORS_IT.md` was missing (P5 added it); refreshed the lead summary in `## v2.3 release plan` to acknowledge the fix shift; added a new entry to `## History` and refreshed `## Next agent starts from`.

## Tests
- Red (pre-fix, on macOS Bash 3.2.57 only — observed in Codex's CI log on commit `1c3a635`):
  - `not ok - endash-owner expected 0 got 1`
  - `not ok - glob-crosses-slash expected 0 got 1`
  - Root cause: bash 3.2 multibyte handling in `${var//pat/rep}` and `${var%%pat*}` patterns when the pattern contains literal UTF-8 en-dash/em-dash bytes. The substitution silently fails, the owner extraction returns the whole rest of the line (e.g. `Codex — tooling owner; …` instead of `Codex`), and the agent-equality check then reports a phantom conflict.
- Green (post-fix, local):
  - `bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` → 9/9 (the eight existing fixtures plus the new `source-guard` regression case). The `source-guard` case actively catches the introduction of a literal en-/em-dash into `check-ownership.sh` outside the allowlisted `EN_DASH=`/`EM_DASH=` definitions — verified by injecting a fake `# bad — pattern` line into a copy of the script and confirming the guard fires.
  - `bash skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh` → `ok - install-rollback`.
  - `bash evals/run-mechanical-checks.sh` → all 4 steps pass.
  - `bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` repeated under `LC_ALL=C` and `LANG=POSIX` → all 9 still green; confirms the script no longer depends on the inherited locale for correctness.
  - `shellcheck --exclude=SC2254` on the modified `check-ownership.sh` and the modified `run-tests.sh` → clean (SC2295 quoting suggestion accepted on the new `"$EM_DASH"` expansions).
  - `python3 evals/lint-handoff.py AGENT_HANDOFF.md` → all 4 structural checks pass on the cleaned-up handoff.
- Caveat: a true Bash-3.2 runtime is not reachable from this environment (network policy blocks the GNU bash 3.2.57 tarball download). The fix is validated structurally — no literal multibyte in patterns, byte-mode forced, ANSI-C quoting introduced in bash 3.0 — and operationally — green under Bash 5.2 in C/POSIX/UTF-8 locales. **Final confirmation is the next macOS CI run on PR #4 after this push.**

## Review approvals
- **PR #4 (bundled P2 doc correction + P4 + P5) — Gemini APPROVED, Codex/ChatGPT REQUEST CHANGES (two blockers, addressed in this shift):**
  - Gemini CLI (2026-05-20T20:30): approved in full. Validated the lint-handoff behavior that auto-caught the bad date-range timestamp in the compacted history.
  - Codex/ChatGPT (2026-05-20T21:00): request changes. Blocker 1 — `fixtures (macos-latest)` failed on Bash 3.2.57: `endash-owner` and `glob-crosses-slash` returned exit 1 instead of 0 because literal multibyte UTF-8 characters (en-dash, em-dash) in `check-ownership.sh` patterns broke under Bash 3.2's multibyte handling. Blocker 2 — this `AGENT_HANDOFF.md` carried stale contradictions (P4/P5 listed as both implemented and pending, P3 still "awaiting user merge", an open concern incorrectly claiming `CONTRIBUTORS_IT.md` was missing). Both fixed in this shift.
- P2 (CI matrix): Codex/ChatGPT post-merge approval with one documentation correction (wording "POSIX-shell" → "Bash on Linux/macOS"). Applied. Gemini sign-off folded into the standard cross-CLI v2.3 pass recorded earlier.
- Codex/ChatGPT: approved PR #2 P3 final shape after selective-hardening realignment.
- Gemini CLI review (cross-CLI QA pass for v2.3 transition):
  - P1 (doc-honest globs): full alignment. The `*`-crosses-`/` correction resolves a critical spec-vs-code discrepancy, validated by the eighth green fixture.
  - P3 (shell hardening + rollback): approved 100%. Selective `set -euo pipefail` (with `check-ownership.sh` rigorously kept on `set -o pipefail` only) gives the scripts industrial stability without breaking the parser's exit-code contract. The transactional copy in `install-skill.sh` finally guarantees install atomicity on failure.
- Merge status: PR #1 (P1) merged as `10c0c5a`. PR #2 (P3) merged as `8ae7e59`. PR #3 (P2) merged as `fc396f1`. PR #4 (bundled P2 doc correction + P4 + P5) is the only remaining PR; pending second-round review after this fix shift.

## v2.3 release plan
Integrated plan elaborated by Claude Code, approved by Codex/ChatGPT and Gemini before any execution started. This section is the canonical, self-contained reference for the v2.3 transition. P1, P2, P3 are complete on `main`. P4 and P5 are implemented on PR #4 and pending merge after the macOS-portability + handoff-cleanup fix shift (recorded below). Only the `v2.3.0` tag remains after #4 merges.

### P1 — Doc-honest sui glob — DONE
Merged as PR #1 (commit `10c0c5a`). Corrected: `handoff-template.md:73` (the most factually wrong line — claimed `scripts/*` did not match `scripts/sub/foo.sh`), `codex-adapter.md:58`, `SKILL.md ## Ownership` note, `README.md:128`, `README_IT.md` equivalent. Added pinning fixture `scripts/test-fixtures/handoff-glob-crosses-slash.md` + matching `run-tests.sh` case (fixtures now 8/8). `future-architecture.md` was retired from this scope on Codex review — that file does not make glob semantics claims.

### P2 — GitHub Actions (CI Linux + macOS) — DONE
Merged as PR #3 (merge commit `fc396f1` on `main`). `.github/workflows/ci.yml` with two jobs:
- **shellcheck**: runs shellcheck on all `*.sh` in the repo. SC2254 is excluded with an inline-commented justification because `check-ownership.sh` deliberately uses dynamic `case` patterns as globs.
- **fixtures**: matrix on `ubuntu-latest` + `macos-latest`. Each runs `bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` and `bash skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh`. The `bash evals/run-mechanical-checks.sh` step is deferred to P4's PR (which will add the file and the workflow step in the same change).

`README.md` and `README_IT.md` carry a `## Supported Platforms` / `## Piattaforme Supportate` section. Per Codex's post-merge review the wording was corrected to "Bash on Linux/macOS" (scripts use Bash-only features like `mapfile` and `[[ ... ]]`, not strictly POSIX `sh`).

Branch (merged): `claude/analyze-handoff-p2-a6c44` (session-allocated branch in place of the plan's `claude/p2-ci`).

### P3 — Shell hardening selettivo + rollback — DONE
Merged as PR #2 (merge commit `8ae7e59` on `main`), approved by Codex/ChatGPT and Gemini. Implementation:
- `install-skill.sh`, `sync-skill.sh`: `set -u` → `set -euo pipefail`.
- `check-ownership.sh`: kept `set -u`, added only `set -o pipefail`. The `-e` was intentionally left off because `matches_pattern` uses `return 1` as "no match" (signal, not error).
- `install-skill.sh` cp-failure rollback: if `cp -R` fails after the backup has been taken, the partially-copied target is removed and the backup is restored. New exit code `3` documented in `usage()`.
- New end-to-end test `scripts/test-fixtures/install-rollback-test.sh` using a PATH-injected failing `cp` stub.

### P4 — Mechanical eval checks — implemented, awaiting review/merge
**Naming discipline**: previously called "minimal scenario runner"; Codex correctly flagged that as overclaiming. The plan renames it to "mechanical eval checks". It does NOT evaluate agent behavior on scenarios A–F; behavioral evaluation requires an LLM-judge harness which is **out of scope** (separate project).

Implementation:
- `evals/run-mechanical-checks.sh` — Bash driver with the mandated head comment. Runs parser fixtures, install rollback, lint-handoff, and the SKILL.md frontmatter PyYAML check.
- `evals/lint-handoff.py` — Python 3 structural lint over `AGENT_HANDOFF.md` (required headings, ownership subsections, ISO 8601 timestamps in `## History`, non-trivial `## Next agent starts from`).
- `evals/evals.json` — `status` → `"mechanical-guards-only"`; added per-scenario `"mechanized"` (only C is `true`); added `status_note` and `mechanized_by` (for C) for transparency.
- `.github/workflows/ci.yml` — `fixtures` job now also sets up Python, installs PyYAML, and runs `evals/run-mechanical-checks.sh`.

Branch: `claude/analyze-handoff-p2-a6c44` (session-allocated branch in place of the plan's `claude/p4-mechanical-checks`). The P2 doc-correction commit `a7e6436` is stacked on the same branch and will go in the same PR.

### P5 — Housekeeping — implemented, bundled with P4 awaiting review/merge
Implementation (all four sub-tasks done):
1. **`SKILL.md` frontmatter**: added `version: "2.3.0"`. P4's mechanical check confirms PyYAML parses the new frontmatter cleanly and that `name` + `description` are still present (the check reports `version` as an extra field but does not fail — exactly the safety net Codex's cautela called for). The version is also surfaced in `README.md`, `README_IT.md`, and `CHANGELOG.md` so the source of truth is not solely the frontmatter.
2. **`CHANGELOG.md`** created with a `## [2.3.0] — 2026-05-20` section organized as Added / Changed / Out of scope, summarizing P1 doc-honest globs, P2 CI matrix, P3 shell hardening + rollback, P4 mechanical eval checks, and P5 housekeeping itself.
3. **`## History` compaction**: applied per the rule in `skills/cli-collaboration/SKILL.md` — last three detailed entries preserved (P5, P4, P2 follow-up); older entries summarized into two lines covering the v2.3 transition (P1+P2+P3 approval window) and the v2.2 baseline buildout (Codex Phase 1, Claude Phase 2, Gemini Phase 3).
4. **`CONTRIBUTORS_IT.md`** created as the Italian mirror of `CONTRIBUTORS.md`.

Branch: `claude/analyze-handoff-p2-a6c44` (session-allocated branch in place of the plan's `claude/p5-housekeeping`). Bundled with P4 in a single PR per user direction.

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
| 2 | **P3** shell hardening + rollback | `claude/p3-shell-hardening` | DONE — merged as `8ae7e59` | ~1 h | medium |
| 3 | **P2** CI matrix Linux/macOS | `claude/analyze-handoff-p2-a6c44` | DONE — merged as `fc396f1` | ~30 min | low |
| 4 | **P4** mechanical checks + lint handoff | `claude/analyze-handoff-p2-a6c44` | implemented, awaiting review/merge | ~2 h | low |
| 5 | **P5** version, CHANGELOG, history compact, CONTRIBUTORS_IT | `claude/analyze-handoff-p2-a6c44` (bundled with P4) | implemented, awaiting review/merge | ~1 h | nullo |
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
- (Resolved in P5) An Italian translation `CONTRIBUTORS_IT.md` was added on branch `claude/analyze-handoff-p2-a6c44` (PR #4); pending merge.

## Next agent starts from
**Next agent: PR #4 second-round review.** The two blockers Codex/ChatGPT raised on 2026-05-20T21:00 are both addressed in the new fix commit on `claude/analyze-handoff-p2-a6c44`. After PR #4 merges, only the `v2.3.0` release tag remains.

**Concrete next steps:**

1. **Wait for the GitHub Actions run on the fix commit to finish.** The critical signal is `fixtures (macos-latest)` going green: it was failing on `endash-owner` and `glob-crosses-slash` under Bash 3.2.57; the fix removes literal multibyte UTF-8 from `check-ownership.sh` patterns and forces `LC_ALL=C`. If macOS CI still fails, the next investigation step is to capture the actual `od -An -tx1` output of the affected lines on the macOS runner — it would indicate an even subtler bash 3.2 quirk than the patterns issue.
2. **Codex/ChatGPT second-round review** focused on:
   - Blocker 1 resolution: the new `LC_ALL=C` export and `EN_DASH`/`EM_DASH` ANSI-C variables in `check-ownership.sh`; the new `source-guard` test case in `run-tests.sh`; confirmation that the macOS CI run is green.
   - Blocker 2 resolution: this `AGENT_HANDOFF.md` is now self-consistent — no "P4/P5 pending" claims, P3 marked as merged, `## Review approvals` reflects both Gemini APPROVED and Codex REQUEST CHANGES, the `CONTRIBUTORS_IT.md` open concern is resolved.
3. **Gemini second-round courtesy review** (optional — Gemini already approved the previous bundle; this round is to confirm the fix doesn't introduce a regression Gemini would catch).
4. **User merge of PR #4**.
5. **Cut the `v2.3.0` release tag** per `## Release finale (tag v2.3.0) — pending`. The exact wording is open between two candidates:
   - From the original plan: `v2.3.0 — doc-honest glob, CI, hardening, mechanical eval`
   - From Gemini's approval note: `Release v2.3.0: CI/CD, Shell Hardening, and Mechanical Eval Guards` (note: omits P1 doc-honest globs from the summary)
   User to decide; both are valid.

**Do not touch:** `final-skill.md`, `workflow.md`, or `progetti-1-2.md` unless the user explicitly reassigns them. These remain user-reserved.

## History
- 2026-05-20T22:00 - Claude Code: Fix shift on PR #4 addressing Codex/ChatGPT's two REQUEST CHANGES blockers. **Blocker 1 (macOS Bash 3.2 portability)**: `fixtures (macos-latest)` was failing on `endash-owner` and `glob-crosses-slash` with exit 1 instead of 0. Root cause: Bash 3.2.57's pattern matching (`${var//pat/rep}`, `${var%%pat*}`, `[[ str == *pat* ]]`) is unreliable with literal multibyte UTF-8 characters embedded in the script source. The substitution silently fails, the owner extraction returns the entire rest of the line (e.g. `Codex — tooling owner; …` instead of `Codex`), and the agent-equality check then reports a phantom conflict. Fix in `skills/cli-collaboration/scripts/check-ownership.sh`: (a) `export LC_ALL=C` at the top to force byte-mode regardless of inherited locale; (b) introduced `EN_DASH=$'\xe2\x80\x93'` and `EM_DASH=$'\xe2\x80\x94'` via ANSI-C quoting (supported since Bash 3.0); (c) every pattern that previously contained a literal en-dash or em-dash now references those variables (e.g. `"$EM_DASH"` instead of `—`). The script source no longer carries any literal multibyte character inside a pattern. Added a `source-guard` test case in `skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` that grep's the script for `[\xe2][\x80][\x93\x94]` with an allowlist for the `EN_DASH=`/`EM_DASH=` definitions and the comments naming them — this catches any future commit that reintroduces a literal en-/em-dash anywhere in the script. **Blocker 2 (stale `AGENT_HANDOFF.md` contradictions)**: removed three stale "pending" bullets at the end of `## Current task` that contradicted the bullets just above (P4 + P5 listed as both implemented and pending); corrected `## v2.3 release plan > P3` from "awaiting user merge" to "merged as `8ae7e59`"; updated `## Review approvals` to reflect both Gemini's APPROVED verdict and Codex's REQUEST CHANGES with the two blockers and their resolutions; resolved the `## Open concerns` line that claimed `CONTRIBUTORS_IT.md` was missing; refreshed `## v2.3 release plan` lead summary, `## Next agent starts from`, and added this entry. Edited `check-ownership.sh` and `run-tests.sh` (Codex-owned) under Codex's explicit textual request to "sistemare check-ownership.sh" — that request constitutes the supersession trigger. Local verification: `bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` 9/9 green (8 existing + new source-guard) under default locale, LC_ALL=C, and LANG=POSIX; the source-guard was independently verified by injecting a fake `# bad — pattern` line into a copy of the script and confirming the guard fires; `bash evals/run-mechanical-checks.sh` all 4 steps green; shellcheck clean on the two modified scripts. **Caveat**: a true Bash-3.2 runtime is not reachable from this environment (network policy blocks the GNU bash 3.2.57 tarball download), so the fix is validated structurally + operationally on Bash 5.2 in three locales rather than directly on Bash 3.2 — final confirmation is the next macOS CI run on PR #4. (in-progress)
- 2026-05-20T20:30 - Claude Code: P5 of the v2.3 plan — housekeeping. Added `version: "2.3.0"` to `skills/cli-collaboration/SKILL.md` frontmatter and surfaced the same version in `README.md`, `README_IT.md`, and the new `CHANGELOG.md` (multiple sources of truth per Codex's cautela). Created `CHANGELOG.md` with a `## [2.3.0] — 2026-05-20` section organized as Added / Changed / Out of scope summarizing P1-P5. Created `CONTRIBUTORS_IT.md` mirroring `CONTRIBUTORS.md` for IT symmetry. Compacted `## History` in this file per the rule in `skills/cli-collaboration/SKILL.md`: preserved the last three detailed entries (P5 = this shift, P4, P2 follow-up) and summarized older entries into two lines covering (a) the v2.3 transition planning + P1 + P2 + P3-approval window and (b) the v2.2 baseline buildout (Codex Phase 1, Claude Phase 2, Gemini Phase 3). Bundled with P4 on branch `claude/analyze-handoff-p2-a6c44` for a single joint Codex/ChatGPT + Gemini review pass per user direction. Local pre-push: `bash evals/run-mechanical-checks.sh` all 4 steps green; the SKILL.md frontmatter check correctly reports `extra fields: ['version']` without failing — exactly the safety net the cautela was designed for. (in-progress)
- 2026-05-20T19:30 - Claude Code: P4 of the v2.3 plan — mechanical eval checks. Added `evals/run-mechanical-checks.sh` with the mandated "Mechanical guards only" head comment, running four steps: ownership parser fixtures, install rollback fixture, `evals/lint-handoff.py` structural lint on `AGENT_HANDOFF.md`, and a PyYAML-based check on `skills/cli-collaboration/SKILL.md` frontmatter (asserts `name` and `description`). Added `evals/lint-handoff.py` checking required top-level headings, the three ownership subsections, ISO 8601 timestamps in `## History`, and non-trivial `## Next agent starts from`. Updated `evals/evals.json`: `status` → `"mechanical-guards-only"`, added `status_note`, added per-scenario `mechanized` (only C `true`, with `mechanized_by` naming the fixture set). Extended `.github/workflows/ci.yml > fixtures` with `actions/setup-python@v5`, `pip install pyyaml`, and a `bash evals/run-mechanical-checks.sh` step. Branch is the session-allocated `claude/analyze-handoff-p2-a6c44` rather than the plan's `claude/p4-mechanical-checks`; the P2 doc-correction commit `a7e6436` is stacked on the same branch and will be in the same PR. Local pre-push: shellcheck clean across all 6 scripts, JSON valid, `run-mechanical-checks.sh` all 4 steps green. (in-progress)
- 2026-05-20T18:30 - Claude Code: P2 follow-up after Codex post-merge approval-with-correction (summarized per history-compaction rule): reworded `## Supported Platforms` / `## Piattaforme Supportate` from "POSIX-shell" to "Bash on Linux/macOS" with a parenthetical on the Bash-only features used (`mapfile`, `[[ ... ]]`); refreshed the handoff to mark PR #3 (P2) as merged to `main` as `fc396f1`. Doc-only changes. (in-progress)
- 2026-05-20T17:30 - v2.3 transition planning + P1 + P2 (summarized per `SKILL.md` history-compaction rule, full detail in CHANGELOG.md and git log; timestamp anchored to the most recent entry in the summarized range, originally spanning 11:30-17:30): plan elaborated and locked with Codex/Gemini approval (five PRs + tag), three Codex corrections accepted (handoff-template the worst glob target, future-architecture out of P1, "mechanical eval checks" naming), P1 doc-honest globs implemented and merged as `10c0c5a` with eighth fixture green, P2 GitHub Actions CI matrix implemented and merged as `fc396f1`, Gemini CLI cross-CLI QA approval recorded, Codex/ChatGPT approval of P3 final shape recorded, AGENT_HANDOFF.md consolidated for fresh-chat resumption, P3 PR #2 awaiting user merge with HEAD `84ff51d`. (done)
- 2026-05-20T10:30 - Claude Code: Untracked internal design notes (`analisi.md`, `final-skill.md`, `workflow.md`) and added them to `.gitignore` under user supersession; files preserved locally. (done)
- 2026-05-20T00:35 - v2.2 baseline buildout (summarized — see git log for per-commit detail; timestamp anchored to the most recent entry in the summarized range, originally spanning 2026-05-19 through 2026-05-20T00:35): Codex implemented Phase 1 (core SKILL.md, guardrail scripts, fixture suite, OpenAI metadata, Codex adapter, README, .gitignore, parser hardening, Git baseline `e7bd2e7`, install-target sync); Claude Code implemented Phase 2 (semantic references — handoff-template, handoff-anti-patterns, validation-scenarios; Claude adapter and metadata; examples AGENT_HANDOFF.md and CLAUDE.md; docs/future-architecture.md; README review items R1-R12; install-target drift detection; CONTRIBUTORS.md and closing audit); Gemini CLI implemented Phase 3 (GEMINI.md, gemini-adapter.md, cross-agent verification, tri-CLI consistency); Codex pushed `main` to `Spe1977/cli-collaboration`, added README_IT.md, merged the MIT license commit, and moved cli-collaboration backup directories out of skill discovery paths. (done)
