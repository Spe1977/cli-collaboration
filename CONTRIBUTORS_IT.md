# Contributori

Questo progetto e stato progettato e raffinato attraverso una collaborazione multi-agente. La vista contributori di GitHub accredita solo l'account umano che ha autorato i commit; questo file registra il contributo effettivo di ciascun partecipante.

## Umano

- **Leospe / Spe1977** — proprietario del progetto, direzione, review, decisioni, pubblicazione del repository.

## Agenti AI

- **Codex** (OpenAI) — implementazione Fase 1: `SKILL.md` core, script di guardrail (`install-skill.sh`, `sync-skill.sh`, `check-ownership.sh`), suite di fixture, metadati OpenAI, adapter Codex, `README.md`, `README_IT.md`, `.gitignore`, hardening del parser (sottosezioni obbligatorie, normalizzazione dei trattini), workflow Git, gate di release. Hardening finale della portabilita v2.5 e coverage di regressione per il contributo Grok.
- **Claude Code** (Anthropic) — implementazione Fase 2: reference semantiche (`handoff-template.md`, `handoff-anti-patterns.md`, `validation-scenarios.md`), adapter Claude, metadati Claude, esempi (`AGENT_HANDOFF.md`, `CLAUDE.md`), `docs/future-architecture.md`, item di review README R1-R12, rilevamento del drift dei target di installazione, audit di chiusura. Inoltre transizione v2.3: glob doc-honest (P1), CI GitHub Actions (P2), shell hardening + rollback (P3), mechanical eval checks (P4), housekeeping (P5).
- **Gemini CLI** (Google) — implementazione Fase 3: adapter Gemini, `examples/GEMINI.md`, verifica cross-agent, check finali di consistenza tri-CLI. Inoltre QA review cross-CLI sulla transizione v2.3 e allineamento CI/repo v2.4.0.
- **Grok Build** (xAI) — contributo iniziale di compatibilita Fase 4: adapter Grok e metadata documentali, ricerca su discovery/installazione e note runtime per Bluefin/Silverblue.
- **Antigravity** (Google DeepMind) — Fase 5 / ottimizzazione e allineamento release v2.6.0: aggiunto supporto di prima classe per Antigravity IDE / App 2.0 / `agy` CLI (`antigravity-adapter.md`, `antigravity.yaml`), separate le identita di ownership `Antigravity` vs `Gemini` e irrobustita la normalizzazione di path/alias in `parse-ownership.py`, reso `lang.sh` sandbox-friendly (`--local`, `$CLI_COLLAB_LANG`, exit `4`), spostati i backup di installazione fuori da `skills/` (`skills-backups/`) e aggiunti i flag preset (`--all`, `--antigravity`, `--claude`, `--codex`, `--agents`, `--grok`, `--gemini`), introdotti gli hook deterministici (`hook-guard.py` + template `examples/hooks/` per Antigravity, Claude Code e Gemini CLI), snellite le guidance d'esempio (`examples/{AGENTS,CLAUDE,GEMINI}.md`) e allineato il path sidecar `.cli-collaboration/`, estesi `lint-handoff.py` e i check meccanici CI a 10 step (`run-tests.sh` 33 casi, `install-rollback-test.sh` 8 check, `hook-guard-tests.sh` 11 blocchi, `test-lint-handoff.sh` 10 casi, integrita link Markdown e bit `+x`), aggiunto il runner opt-in di eval live locali (`evals/run-live-evals.py`) e aggiornati documentazione e metadati release GitHub v2.6.0.

## Authorship Git

I metadati di commit Git (`author` / `committer`) accreditano intenzionalmente solo l'account umano. Gli agenti AI non hanno identita GitHub; iniettare email o account inventati comprometterebbe l'integrita dell'audit. Questo file e il record autoritativo del contributo multi-agente ed e referenziato dall'ownership e dalla history di `AGENT_HANDOFF.md`.
