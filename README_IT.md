# cli-collaboration

**Versione:** 2.3.0 (vedi [`CHANGELOG.md`](CHANGELOG.md)).

`cli-collaboration` e un protocollo leggero per coordinare Codex, Claude Code, Gemini CLI, oppure un singolo agente attraverso piu sessioni nello stesso progetto.

La fonte di verita e `AGENT_HANDOFF.md`. Gli script sono guardrail: segnalano drift, ownership malformata e probabili conflitti, ma non sostituiscono il giudizio dell'agente.

## Cosa Risolve

- Preserva il lavoro dell'utente e degli agenti nei worktree sporchi.
- Supporta il caso single-agent: l'handoff diventa memoria di progetto tra sessioni.
- Fornisce ownership esplicita dei file e stop condition per piu agenti CLI.
- Impedisce che la pulizia distruttiva diventi la risposta predefinita all'incertezza.
- Rende la collaborazione auditabile: ogni agente legge prima l'handoff e lo aggiorna per ultimo.

## Sintesi Del Workflow

Il workflow finale e stato definito dalla discussione in `workflow.md`.

La conclusione condivisa e l'opzione C: il primo agente va scelto in base all'aderenza al task, non in base a una regola rigida sul caricamento nativo della skill. Codex e il primo agente naturale per scaffolding, script, test, packaging e release gate. Claude e il primo agente naturale per lavoro semantico sul protocollo, policy, template e reference. Gemini puo fare bootstrap di scaffolding inerte o QA/red-team, purche crei o rispetti subito `AGENT_HANDOFF.md`.

Il flusso multi-LLM raccomandato e handoff-first:

1. Il primo agente legge o crea `AGENT_HANDOFF.md`.
2. Dichiara lo start gate: handoff letto, task corrente, file da toccare, test rosso atteso, zone riservate e stop condition.
3. Il lavoro viene assegnato per ownership e competenza.
4. Ogni agente modifica solo i file dichiarati.
5. Ogni handoff registra file modificati, test rossi/verdi, open concerns e prossimo passo concreto.

Il caso single-LLM e di prima classe. Anche quando e installata una sola CLI, `AGENT_HANDOFF.md` resta memoria di progetto tra sessioni, cosi l'agente puo riprendere dall'ultimo checkpoint invece di ricostruire il contesto da zero.

## Attivazione E Pausa

La skill e progettata per essere di fatto sempre disponibile quando esiste stato collaborativo, ma il trigger esatto varia per CLI:

- Codex carica la skill tramite metadata della skill e guidance `AGENTS.md`.
- Claude carica la skill tramite description matching di `SKILL.md`, `CLAUDE.md` e hook SessionStart opzionali.
- Gemini carica la skill tramite `activate_skill`, `GEMINI.md` o il flusso dell'adapter Gemini.
- Tutte le CLI devono trattare la presenza di `AGENT_HANDOFF.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, un worktree sporco o una richiesta di resume come trigger per applicare il protocollo.

Il trigger automatico di Gemini e il piu debole dei tre. Quando l'attivazione non scatta, copia il forced-activation prompt da `skills/cli-collaboration/references/gemini-adapter.md` nell'apertura della sessione.

Slash command come `/cli-collaboration on` e `/cli-collaboration off` sono utili come UX, ma non sono portabili tra CLI. Il meccanismo di pausa cross-CLI e basato sul filesystem:

- `.cli-collaboration-off` nella root del progetto.
- `**Status:** paused` in `AGENT_HANDOFF.md`.

La pausa riduce solo l'overhead procedurale. Non autorizza mai pulizia distruttiva, sovrascrittura del lavoro altrui o ignorare ownership `user-reserved` e `frozen`.

## Come E Stato Sviluppato

Il pacchetto e stato costruito intenzionalmente facendo dogfooding del protocollo che fornisce.

- Fase 1, Codex: implementati core skill, script, fixture, metadata OpenAI, adapter Codex, `README.md` e wiring tecnico degli eval.
- Fase 2, Claude: implementati reference semantici, template handoff, anti-pattern, scenari di validazione, adapter Claude, metadata Claude ed esempi.
- Fase 3, Gemini: implementati guidance Gemini e contenuti adapter, poi QA cross-CLI.
- Verifica finale Codex: rieseguiti i release gate dopo Fase 2 e Fase 3, poi aggiornati i metadata del pacchetto dove necessario.

La divisione ha seguito la decisione finale C-emendata:

- Codex possiede package/tooling e release gate finali.
- Claude possiede chiarezza semantica e policy dei reference.
- Gemini possiede guidance Gemini-specifica e review QA/red-team.

## Struttura Del Pacchetto

```text
cli-collaboration/
├── README.md
├── README_IT.md
├── LICENSE
├── AGENT_HANDOFF.md
├── docs/
│   └── future-architecture.md
├── evals/
│   └── evals.json
├── examples/
│   ├── AGENT_HANDOFF.md
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   └── GEMINI.md
└── skills/
    └── cli-collaboration/
        ├── SKILL.md
        ├── agents/
        │   ├── openai.yaml
        │   └── claude.yaml
        ├── references/
        │   ├── codex-adapter.md
        │   ├── claude-adapter.md
        │   ├── gemini-adapter.md
        │   ├── handoff-template.md
        │   ├── handoff-anti-patterns.md
        │   └── validation-scenarios.md
        └── scripts/
            ├── install-skill.sh
            ├── sync-skill.sh
            ├── check-ownership.sh
            └── test-fixtures/
```

## Protocollo Core

Ogni agente deve trattare `AGENT_HANDOFF.md` come fonte di verita.

Prima di modificare file, l'agente dichiara:

```text
Handoff read: <path, last-updated timestamp>
Current task: <one line>
Files I will touch: <explicit file list>
Expected red test: <test name, or no test with reason>
Reserved zones confirmed: <user-reserved/frozen areas>
Stop condition: <task-complete | context-budget | blocker>
```

Le righe di ownership usano questa forma esatta:

```text
- <path-or-glob>: <agent-name> — <reason>
```

Le tre classi di ownership sono:

- `agent-owned`: un agente nominato possiede il file o glob.
- `user-reserved`: l'utente possiede il file; fermarsi prima di modificarlo.
- `frozen`: il file e protetto; fermarsi prima di modificarlo.

Tutte e tre le intestazioni di ownership devono essere presenti in `AGENT_HANDOFF.md`, anche quando una sezione e vuota. Il separatore canonico di ownership e l'em-dash (`—`); il checker tollera varianti comuni di dash, ma gli handoff generati devono usare la forma canonica. I pattern di ownership sono pattern bash `case`: `*` matcha qualsiasi sequenza di caratteri **incluso `/`**, quindi `scripts/*` copre sia `scripts/foo.sh` sia `scripts/sub/foo.sh`; usa segmenti di path espliciti quando devi limitare il match a un singolo livello di directory. `**` non e un token riconosciuto.

Concorrenza: `AGENT_HANDOFF.md` ha un solo writer attivo alla volta in v2.2. L'infrastruttura di locking e rimandata alla v3 ed e vincolata a un incidente documentato di scrittura concorrente registrato nella history dell'handoff (vedi `docs/future-architecture.md`).

Le operazioni distruttive sono esplicitamente vietate a meno che l'utente le richieda:

- `git reset --hard`
- `git clean`
- `git stash` non autorizzato
- `git restore`
- `git checkout --`
- sovrascrittura laterale di file il cui owner e poco chiaro o contestato

## Piattaforme Supportate

Gli script di guardrail (`check-ownership.sh`, `install-skill.sh`, `sync-skill.sh`) e le fixture di test sono pensati per Bash su Linux e macOS (gli script usano feature Bash come `mapfile` e `[[ ... ]]` e non sono strettamente POSIX `sh`). La CI esegue sia `ubuntu-latest` sia `macos-latest` tramite GitHub Actions (`.github/workflows/ci.yml`). Windows nativo non e supportato; WSL non fa parte della matrice di test e non e garantito funzioni.

## Installazione

Anteprima dei target di installazione predefiniti:

```bash
skills/cli-collaboration/scripts/install-skill.sh --dry-run
```

Installazione nei target predefiniti Codex e agents:

```bash
skills/cli-collaboration/scripts/install-skill.sh
```

Installazione in un target esplicito:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.codex/skills/cli-collaboration"
```

Per Claude Code:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.claude/skills/cli-collaboration"
```

Per Gemini CLI:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.gemini/skills/cli-collaboration"
```

## Check Ownership

Usa il checker prima di toccare file nominati in `AGENT_HANDOFF.md`:

```bash
skills/cli-collaboration/scripts/check-ownership.sh --agent Codex README.md
```

Exit code:

- `0`: struttura ownership valida e nessun conflitto rilevato.
- `1`: conflitto con `agent-owned`, `user-reserved` o `frozen`.
- `2`: errore di uso, sezione ownership malformata o sottosezione obbligatoria mancante (`### agent-owned`, `### user-reserved` e `### frozen` devono essere tutte presenti anche quando vuote).

Esempi:

```bash
# Validare un file Codex-owned.
skills/cli-collaboration/scripts/check-ownership.sh --handoff AGENT_HANDOFF.md --agent Codex README.md

# Rilevare un conflitto user-reserved.
skills/cli-collaboration/scripts/check-ownership.sh --handoff AGENT_HANDOFF.md --agent Codex workflow.md

# Validare un target di glob single-level Codex-owned.
skills/cli-collaboration/scripts/check-ownership.sh --handoff AGENT_HANDOFF.md --agent Codex skills/cli-collaboration/scripts/install-skill.sh
```

## Sync

Segnala drift rispetto agli install target:

```bash
skills/cli-collaboration/scripts/sync-skill.sh
```

Applica gli aggiornamenti dopo aver revisionato il drift:

```bash
skills/cli-collaboration/scripts/sync-skill.sh --install
```

Il comando sync e read-only per impostazione predefinita e segnala tutti i target mancanti o drifted prima di uscire.

## Scenari Di Validazione

Il design degli eval ha sei scenari, definiti semanticamente in `skills/cli-collaboration/references/validation-scenarios.md` e collegati tecnicamente in `evals/evals.json`.

- A: dirty worktree senza handoff.
- B: piano esistente ma handoff piu specifico.
- C: conflitto di ownership.
- D: budget di contesto basso.
- E: handoff vago.
- F: supersession dell'utente.

Gli scenari A-E includono negative assertion contro pulizia distruttiva ovunque un worktree sporco, stato sconosciuto o conflitto di ownership possano incentivare scorciatoie. Lo scenario F si concentra su supersession dell'utente e continuita dell'handoff.

La coverage fixture in `run-tests.sh` e piu ampia del numero di scenari: include anche casi parser-level (enforcement delle sottosezioni obbligatorie e normalizzazione delle varianti di dash) che testano il contratto del checker indipendentemente dagli scenari A-F.

## Aggiornamento E Manutenzione

Le modifiche future devono preservare lo stesso modello di ownership usato per costruire la skill:

- Codex possiede file package/tooling, script install/sync/check, metadata, release gate, `.gitignore`, `README.md` ed `evals/evals.json`.
- Claude possiede reference semantici, template handoff, anti-pattern, prose degli scenari di validazione, adapter Claude e policy future-architecture.
- Gemini possiede adapter/example Gemini e review QA/red-team.

Quando si cambia il comportamento degli eval, aggiornare prima `skills/cli-collaboration/references/validation-scenarios.md`, poi riflettere il wiring tecnico in `evals/evals.json`.

Quando si cambia il comportamento degli script, aggiornare `skills/cli-collaboration/references/codex-adapter.md` e rieseguire la fixture suite.

Eventuale infrastruttura v3, come sidecar state files o lock, deve essere promossa solo tramite le soglie in `docs/future-architecture.md`.

Quando si inizializza questo pacchetto come repository Git, creare `.gitignore` prima del primo commit. L'ignore list predefinita esclude `.handoff-backups/` cosi snapshot handoff opzionali non aggiungono rumore ai diff.

## Verifica Di Release

Il pacchetto ha superato questi gate di verifica locali. La maggior parte dei comandi e direttamente riproducibile da questo repository; il comando di validazione del pacchetto skill richiede l'harness Codex `skill-creator`.

| Gate | Command | Result |
|---|---|---|
| Validazione pacchetto skill | `python3 <skill-creator>/scripts/quick_validate.py skills/cli-collaboration` | pass |
| Sintassi Bash | `bash -n` su tutti gli script | pass |
| Fixture ownership | `skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` | pass, 7/7 |
| Validita JSON | `python3 -m json.tool evals/evals.json` | pass |
| Validita YAML | parse PyYAML di `SKILL.md`, `openai.yaml`, `claude.yaml` | pass |
| Install dry-run | `install-skill.sh --dry-run` | pass |
| Target install esplicito | `tmp="$(mktemp -d)" && install-skill.sh --target "$tmp/cli-collaboration"` | pass |
| Target sync esplicito | `sync-skill.sh --target "$tmp/cli-collaboration"` | pass dopo install esplicito |
| Ownership guard | `check-ownership.sh --handoff AGENT_HANDOFF.md --agent Codex README.md evals/evals.json` | pass |

Git e stato inizializzato per questo workspace e la baseline v2.2 e committata su `main`.

Le directory skill installate predefinite possono andare in drift rispetto al pacchetto locale finche l'utente non esegue `install-skill.sh` o `sync-skill.sh --install`.

## Prontezza Di Release

Il pacchetto e verificato localmente e pronto per l'installazione. I prossimi step operativi raccomandati sono:

1. Aggiungere un remote Git se questo repository deve essere pubblicato.
2. Pushare `main` sul remote.
3. Eseguire `install-skill.sh --dry-run` prima delle future installazioni locali.
4. Aggiungere il file di guidance di progetto rilevante (`AGENTS.md`, `CLAUDE.md` o `GEMINI.md`) ai progetti che devono applicare collaborazione handoff-first.

## Licenza

Licenza MIT. Vedi `LICENSE`.
