# Contributors

This project was designed and refined through a multi-agent collaboration. GitHub's contributors view credits the human account that authored the commits; this file records the actual contribution of each participant.

## Human

- **Leospe / Spe1977** — project owner, direction, review, decisions, repository publication.

## AI agents

- **Codex** (OpenAI) — Phase 1 implementation: core `SKILL.md`, guardrail scripts (`install-skill.sh`, `sync-skill.sh`, `check-ownership.sh`), fixture suite, OpenAI metadata, Codex adapter, `README.md`, `README_IT.md`, `.gitignore`, parser hardening (mandatory subsections, dash normalization), Git workflow, release gates.
- **Claude Code** (Anthropic) — Phase 2 implementation: semantic references (`handoff-template.md`, `handoff-anti-patterns.md`, `validation-scenarios.md`), Claude adapter, Claude metadata, examples (`AGENT_HANDOFF.md`, `CLAUDE.md`), `docs/future-architecture.md`, README review items R1-R12, install-target drift detection, closing audit.
- **Gemini CLI** (Google) — Phase 3 implementation: Gemini adapter, `examples/GEMINI.md`, cross-agent verification, final tri-CLI consistency checks.

## Git authorship

Git commit metadata (`author` / `committer`) intentionally credits only the human account. AI agents do not have GitHub identities; injecting fabricated emails or accounts would compromise audit integrity. This file is the authoritative record of multi-agent contribution and is referenced from `AGENT_HANDOFF.md` ownership and history.
