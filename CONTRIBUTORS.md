# Contributors

This project was designed and refined through a multi-agent collaboration. GitHub's contributors view credits the human account that authored the commits; this file records the actual contribution of each participant.

## Human

- **Leospe / Spe1977** — project owner, direction, review, decisions, repository publication.

## AI agents

- **Codex** (OpenAI) — Phase 1 implementation: core `SKILL.md`, guardrail scripts (`install-skill.sh`, `sync-skill.sh`, `check-ownership.sh`), fixture suite, OpenAI metadata, Codex adapter, `README.md`, `README_IT.md`, `.gitignore`, parser hardening (mandatory subsections, dash normalization), Git workflow, release gates. Final v2.5 portability hardening and regression coverage for the Grok contribution.
- **Claude Code** (Anthropic) — Phase 2 implementation: semantic references (`handoff-template.md`, `handoff-anti-patterns.md`, `validation-scenarios.md`), Claude adapter, Claude metadata, examples (`AGENT_HANDOFF.md`, `CLAUDE.md`), `docs/future-architecture.md`, README review items R1-R12, install-target drift detection, closing audit. Also v2.3 transition: doc-honest globs (P1), GitHub Actions CI (P2), shell hardening + rollback (P3), mechanical eval checks (P4), housekeeping (P5).
- **Gemini CLI** (Google) — Phase 3 implementation: Gemini adapter, `examples/GEMINI.md`, cross-agent verification, final tri-CLI consistency checks. Also v2.3 cross-CLI QA review and v2.4.0 CI/repo alignment.
- **Grok Build** (xAI) — Phase 4 initial compatibility contribution: Grok adapter and documentation-only metadata, discovery/install research, and Bluefin/Silverblue runtime notes.
- **Antigravity** (Google DeepMind) — Phase 5 / v2.6.0 optimization & release alignment: added first-class Antigravity IDE / App 2.0 / `agy` CLI support (`antigravity-adapter.md`, `antigravity.yaml`), separated `Antigravity` vs `Gemini` ownership identities and hardened path/alias normalization in `parse-ownership.py`, made `lang.sh` sandbox-friendly (`--local`, `$CLI_COLLAB_LANG`, exit `4`), moved install backups out of `skills/` (`skills-backups/`) and added preset flags (`--all`, `--antigravity`, `--claude`, `--codex`, `--agents`, `--grok`, `--gemini`), built deterministic lifecycle hooks (`hook-guard.py` + `examples/hooks/` templates for Antigravity, Claude Code, and Gemini CLI), slimmed example guidance (`examples/{AGENTS,CLAUDE,GEMINI}.md`) and aligned `.cli-collaboration/` sidecar path, expanded `lint-handoff.py` and 10-step mechanical CI checks (`run-tests.sh` 33 cases, `install-rollback-test.sh` 8 checks, `hook-guard-tests.sh` 11 blocks, `test-lint-handoff.sh` 10 cases, Markdown relative link & `+x` integrity), added the opt-in local live eval harness (`evals/run-live-evals.py`), and aligned v2.6.0 documentation and GitHub release metadata.

## Git authorship

Git commit metadata (`author` / `committer`) intentionally credits only the human account. AI agents do not have GitHub identities; injecting fabricated emails or accounts would compromise audit integrity. This file is the authoritative record of multi-agent contribution and is referenced from `AGENT_HANDOFF.md` ownership and history.
