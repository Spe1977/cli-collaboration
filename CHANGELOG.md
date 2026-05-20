# Changelog

All notable changes to `cli-collaboration` are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project follows semantic versioning where it makes sense for a protocol-and-scripts package.

## [2.3.0] — 2026-05-20

This release tightens the gap between the documented protocol and the actual behavior of the guardrail scripts, adds continuous integration, makes the install path crash-safe, and adds mechanical structural checks for `AGENT_HANDOFF.md` and `SKILL.md`.

### Added

- **CI matrix (P2)**: new `.github/workflows/ci.yml` with two jobs.
  - `shellcheck` (Ubuntu) lints every `*.sh` in the repo. `SC2254` is excluded because `check-ownership.sh` deliberately uses dynamic `case` patterns as globs — that is the parser's contract.
  - `fixtures` matrix on `ubuntu-latest` and `macos-latest` runs the ownership parser fixtures, the install rollback fixture, and the new mechanical eval checks (Python 3 + PyYAML provisioned in the job).
- **Atomic install rollback (P3)**: `install-skill.sh` now exits with code `3` and restores the pre-install backup if `cp -R` fails. The system is left in either the "old target + no backup" or "backup + new target" state, never an intermediate state. Documented in `usage()`.
- **Install rollback fixture (P3)**: new `scripts/test-fixtures/install-rollback-test.sh` PATH-shadows `cp` with a failing stub to assert the rollback contract.
- **Glob-crosses-slash fixture (P1)**: new `scripts/test-fixtures/handoff-glob-crosses-slash.md` and corresponding `run-tests.sh` case that pins the actual behavior of bash `case` glob matching across `/`, so the documented semantics cannot drift from the parser again.
- **Mechanical eval checks (P4)**: new `evals/run-mechanical-checks.sh` driver with an explicit "mechanical guards only" head comment, running the ownership fixtures, the install rollback fixture, the structural lint over `AGENT_HANDOFF.md`, and a PyYAML-based check that `SKILL.md` frontmatter parses with `name` and `description` present.
- **Structural lint (P4)**: new `evals/lint-handoff.py` verifies required top-level headings, the three ownership subsections (`### agent-owned`, `### user-reserved`, `### frozen`), ISO 8601 timestamps in `## History`, and that `## Next agent starts from` is non-trivial.
- **Supported Platforms section (P2)**: `README.md` and `README_IT.md` now document the supported target as Bash on Linux and macOS (scripts rely on Bash features like `mapfile` and `[[ ... ]]`, not strictly POSIX `sh`); native Windows is unsupported and WSL is not part of the test matrix.
- **Version metadata (P5)**: `skills/cli-collaboration/SKILL.md` frontmatter now carries `version: "2.3.0"`. The same version is surfaced in `README.md`, `README_IT.md`, and this `CHANGELOG.md` so the source of truth is not solely the frontmatter (per Codex's cautela: if a downstream skill validator rejects the field, the user-visible version still lives in README + CHANGELOG).
- **Italian contributors record (P5)**: new `CONTRIBUTORS_IT.md` mirroring `CONTRIBUTORS.md` for symmetry with `README_IT.md`.
- **Python ownership parser (PR #4 review cycle)**: new `skills/cli-collaboration/scripts/parse-ownership.py`. See the matching entry under `### Changed` for the migration rationale.

### Changed

- **Doc-honest globs (P1)**: corrected the documented behavior of `*` in ownership patterns. `*` in a bash `case` pattern matches any sequence including `/`, so `scripts/*` matches both `scripts/foo.sh` and `scripts/sub/foo.sh`. The previously asserted "single directory level" behavior was factually wrong against the parser. Affected files: `skills/cli-collaboration/references/handoff-template.md`, `skills/cli-collaboration/references/codex-adapter.md`, `skills/cli-collaboration/SKILL.md > ## Ownership`, `README.md`, `README_IT.md`.
- **Ownership parser migration to Python (P2 follow-up, PR #4 review cycle)**: `check-ownership.sh` was reduced to a thin Bash wrapper (`exec python3 "$SCRIPT_DIR/parse-ownership.py" "$@"`) and the full parser + matcher + conflict logic moved to a new `scripts/parse-ownership.py`. Python 3 is now a runtime dependency of the ownership check (it was already a CI/eval dependency from P4). The migration was forced by GitHub Actions `fixtures (macos-latest)` failing on Bash 3.2.57 whenever a handoff ownership line contained multibyte UTF-8 bytes (en-dash, em-dash). Seven distinct Bash-side mitigations were attempted and ruled out before the migration: literal multibyte patterns, ANSI-C-quoted dash variables, `sed`-based normalization, first-token via `${rest%%[[:space:]]*}`, first-token via `${rest%% *}`, controlled word splitting via `set --`, and `awk` micro-delegation. All seven failed on the same two fixtures (`endash-owner`, `glob-crosses-slash`); the eighth approach (full Python delegation) is the one that lands. CLI contract (flags, env var, exit codes, conflict-message wording) is preserved verbatim. The new Python parser uses `fnmatch.fnmatchcase` for glob matching, preserving the P1 contract in which `*` crosses `/`. Affected files: `skills/cli-collaboration/scripts/check-ownership.sh` (rewritten as wrapper), `skills/cli-collaboration/scripts/parse-ownership.py` (new), `skills/cli-collaboration/references/codex-adapter.md` (implementation note + updated separator prose), `README.md` + `README_IT.md` (Python 3 runtime dependency documented under Supported Platforms).
- **Shell hardening (P3, selective)**: `install-skill.sh` and `sync-skill.sh` use `set -euo pipefail`. `check-ownership.sh` keeps `set -u` and `set -o pipefail` (no `-e`); this was originally to preserve the exit-code contract of the in-Bash parser's `matches_pattern` (`return 1` = no match, not an error). After the Plan C migration the wrapper is trivial enough that the distinction is moot, but the conservative flag set is kept.
- **`evals/evals.json` honesty (P4)**: top-level `status` field changed from `"tri-cli-complete"` to `"mechanical-guards-only"`, with a `status_note` explaining what CI actually verifies. Each scenario now carries a boolean `"mechanized"` field: scenario C is `true` (covered by the ownership parser fixtures, with `mechanized_by` naming the specific cases); A, B, D, E, F are `false` (intent-only — would require an LLM-judge harness which is out of scope).
- **`AGENT_HANDOFF.md` history (P5)**: per the project rule in `SKILL.md`, the `## History` section was compacted: the last three detailed entries are preserved verbatim and older entries are summarized to keep the file useful as it grows.

### Out of scope (deferred to v3, gated by `docs/future-architecture.md`)

- Custom segment-bounded glob parser (`**` token, single-directory `*`).
- POSIX `flock`-based concurrency, `.agent/state.json` sidecar, MCP transport.
- LLM-judge harness for behavioral evaluation of scenarios A, B, D, E, F.
- Native Windows support.
