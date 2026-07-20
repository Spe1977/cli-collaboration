# AGENT_HANDOFF.md

**Last updated:** 2026-07-20T17:59:20+02:00
**Last agent:** Codex
**Status:** in-progress

## Current task
Completare la documentazione Grok/Gemini/Antigravity della release `2.5.0`, pubblicare il commit su `origin/main` e verificare GitHub Actions.

## Current state
- Il port Grok-specifico e stato corretto in una release portabile unica `2.5.0`: `SKILL.md` resta neutrale e compatibile con i validator condivisi; le istruzioni specifiche sono isolate nell'adapter Grok.
- Install e sync hanno tre target predefiniti non duplicati (Codex, Agents e Grok). Gemini CLI scopre l'alias interoperabile Agents; Gemini-only, Antigravity e Claude restano target espliciti. Il parser mantiene `Codex` come default storico e gli altri runtime passano `--agent` esplicitamente.
- Aggiunti adapter Grok, metadata documentali e fixture di portabilita. Grok 0.2.106 scopre correttamente la copia installata in una home temporanea come skill utente invocabile.
- Ripristinati i permessi corretti dei file e ignorato solo lo stato locale `.claude/settings.local.json`; `cli-collaboration.png` e i file user-reserved non sono stati toccati.
- Le copie realmente installate per Codex, `.agents`/Gemini, Gemini/Antigravity, Grok e Claude sono byte-identiche alla sorgente `2.5.0`; la copia Gemini duplicata e tutti i backup sono stati spostati fuori dalle directory di discovery.

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
- CHANGELOG.md: Codex — release tracking and version-gate documentation (reassigned under User Supersession for v2.5)
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
- skills/cli-collaboration/agents/grok.yaml: Grok — documentation-only Grok metadata
- skills/cli-collaboration/references/grok-adapter.md: Grok — Grok discovery, identity, tools, and Bluefin guidance
- docs/superpowers/specs/*: Codex — approved implementation design records
- docs/superpowers/plans/*: Codex — executable implementation plans
- brainplan.md: Codex — review plan for brainstorming workflow documentation integration

### user-reserved
- final-skill.md: user — approved source specification
- workflow.md: user — workflow decisions and voting record
- progetti-1-2.md: user — user-reserved source if reintroduced

### frozen
No frozen files currently declared.

## Files changed this shift
- `skills/cli-collaboration/SKILL.md`: frontmatter portabile, metadata `2.5.0`, core neutrale e routing verso l'adapter Grok.
- `skills/cli-collaboration/scripts/{install-skill.sh,sync-skill.sh}`: target Grok aggiuntivo, default non duplicati Codex/Agents/Grok, validazione sorgente e ABI/rollback preservati.
- `skills/cli-collaboration/scripts/test-fixtures/{grok-portability-tests.sh,install-rollback-test.sh,run-tests.sh}`: regressioni Grok/multi-CLI, divieto del doppio alias Gemini, precondizione rollback valida e output concorrente isolato in `/tmp`.
- `evals/run-mechanical-checks.sh`: fixture Grok aggiunta come sesto gate.
- `skills/cli-collaboration/{agents/grok.yaml,references/grok-adapter.md}`: integrazione Grok documentata senza contaminare il core condiviso.
- `skills/cli-collaboration/references/{codex-adapter.md,gemini-adapter.md,handoff-template.md,alternate-workflows.md}` e `examples/AGENTS.md`: discovery, target, identita e template allineati a Codex, Claude, Gemini, Grok e Antigravity.
- `CLAUDE.md`, `GEMINI.md`, `examples/CLAUDE.md`, `examples/GEMINI.md` e `brainplan.md`: riferimenti Grok aggiunti dove mancavano.
- `README.md`, `README_IT.md`, `CHANGELOG.md`, `CONTRIBUTORS.md`, `CONTRIBUTORS_IT.md`: release `2.5.0`, Grok Build, discovery Gemini, target Antigravity, verifica e crediti aggiornati.
- `.gitignore`: escluso solo `.claude/settings.local.json`; gli artefatti locali dell'utente restano preservati.
- `docs/superpowers/specs/2026-07-20-grok-multicli-compatibility-design.md` e `docs/superpowers/plans/2026-07-20-grok-multicli-compatibility.md`: design approvato e piano eseguito.
- Installazioni esterne sincronizzate: `~/.codex/skills`, `~/.agents/skills` (anche Gemini), `~/.gemini/config/skills` (Antigravity), `~/.grok/skills` e `~/.claude/skills`; copia ridondante `~/.gemini/skills` e backup spostati nei rispettivi `skills-backups`.
- `AGENT_HANDOFF.md`: chiusura del turno e User Supersession registrate per ultime.

## Tests
- Red:
  - `grok-portability-tests.sh`: frontmatter condiviso inizialmente incompatibile e core Grok-specifico.
  - Esecuzione parallela dei fixture: falso drift install/sync causato da `.out/.err` scritti dentro il payload sorgente.
  - `gemini skills list --all`: warning riproducibile per skill duplicata in `~/.agents/skills` e `~/.gemini/skills`; fixture aggiornata inizialmente rossa sul doppio target.
  - Audit documentazione Grok: fixture rossa per riferimenti mancanti in `CLAUDE.md` e guidance di esempio.
- Green:
  - `bash evals/run-mechanical-checks.sh` (6/6 gate verdi)
  - `bash skills/cli-collaboration/scripts/test-fixtures/lang-tests.sh` (24/24 verdi)
  - ownership, rollback e Grok portability fixture, anche in parallelo (tutti verdi)
  - `quick_validate.py skills/cli-collaboration` (`Skill is valid!`)
  - `bash -n` su tutti gli script, JSON e YAML parse (verdi)
  - install e sync predefiniti in home temporanee: Codex, Agents/Gemini e Grok tutti `in-sync`, senza copia Gemini duplicata
  - `GROK_HOME=<temp> grok inspect --json` con Grok 0.2.106: `cli-collaboration` scoperta dalla user path e `userInvocable: true`
  - `sync-skill.sh` con cinque target reali non duplicati: tutte le copie `in-sync` e tutte riportano metadata version `2.5.0`
  - `grok inspect --json` sulla home reale: una sola skill `cli-collaboration`, sorgente `~/.grok/skills`, `userInvocable: true`
  - `gemini skills list --all`: skill `cli-collaboration` abilitata e caricata da `~/.agents/skills`, senza warning di conflitto
  - ownership guard e `git diff --check` (verdi)

## Open concerns
- Il lavoro ha modificato `CONTRIBUTORS.md`, `CONTRIBUTORS_IT.md` e `references/handoff-template.md`, storicamente Claude-owned. L'utente ha autorizzato esplicitamente l'opzione di correzione completa sul `main` corrente: modifiche registrate come User Supersession; Claude puo revisionarle in seguito.
- `shellcheck` non e installato localmente sull'host Bluefin immutabile. La sintassi Bash e tutti i test sono verdi; il lint statico resta coperto dalla CI GitHub gia configurata e dovra essere osservato dopo il push.
- Il diff e pronto per il commit diretto su `main`, esplicitamente richiesto dall'utente. `origin/main` e ancora al commit di partenza `bbf2f7b`, quindi non esiste divergenza remota.
- Il token separato di `gh` risulta scaduto, ma `git push --dry-run origin main` e riuscito con le credenziali Git configurate; la pubblicazione diretta non dipende da `gh`.

## Next agent starts from
**Next agent: Codex — creare il commit di release `2.5.0` escludendo `cli-collaboration.png`, pushare `main`, osservare GitHub Actions e poi registrare commit/check finali nel handoff con un ultimo commit documentale.**

Do not touch: `final-skill.md`, `workflow.md`, or `progetti-1-2.md` (user-reserved). Do not touch `cli-collaboration.png`; it was already untracked before this shift and is unrelated.

## History
- 2026-07-20T17:59:20+02:00 - Codex: Completata la documentazione Grok richiesta dall'utente in README, guidance root, esempi, adapter, template, crediti e changelog. Le fonti ufficiali Gemini incluse nella CLI hanno confermato che `.agents/skills` e alias prioritario di `.gemini/skills`; riprodotto il warning di duplicazione, aggiunta regressione RED, rimossi i default duplicati e verificata la skill Gemini abilitata senza conflitti. Antigravity resta target esplicito; cinque installazioni reali non duplicate sincronizzate. Release pronta per commit/push diretto su `main`. (in-progress)
- 2026-07-20T17:44:03+02:00 - Codex: Su richiesta esplicita dell'utente, sincronizzate alla sorgente `2.5.0` le copie reali Codex, `.agents`, Gemini standard, Gemini/Antigravity, Grok e Claude. Verificate tutte con `sync-skill.sh`; Grok scopre una sola skill invocabile, Gemini la carica abilitata da `.agents` e segnala la copia identica `.gemini/skills` come override non bloccante. Backup preservati fuori dalle directory di discovery. (done)
- 2026-07-20T17:29:49+02:00 - Codex: Corretto il port Grok in una release condivisa `2.5.0` compatibile con Codex, Claude Code, Gemini CLI e Grok Build; aggiunti adapter/metadata/test Grok, preservati parser e ABI storici, normalizzati i permessi, risolta una race dei fixture, verificati validator, 6/6 gate meccanici, 24/24 test lingua, install/sync su quattro target temporanei e discovery reale con Grok 0.2.106. Nessun commit, push o sync delle installazioni reali. Modifiche cross-ownership autorizzate dall'utente sotto User Supersession. (done)
- 2026-05-24T23:48:00+02:00 - Gemini CLI: Risolto avvisi ShellCheck (SC2295 e SC1090) in lang.sh e lang-tests.sh, eseguito il push su main, sincronizzate tutte le installazioni locali (.codex, .agents, .gemini) rimuovendo il drift e spostando i backup per evitare conflitti. (done)
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
