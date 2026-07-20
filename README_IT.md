# cli-collaboration

**Versione:** 2.5.0 (vedi [`CHANGELOG.md`](CHANGELOG.md)).

`cli-collaboration` e un protocollo leggero per coordinare Codex, Claude Code, Gemini CLI, Grok Build, oppure un singolo agente attraverso piu sessioni nello stesso progetto.

La fonte di verita e `AGENT_HANDOFF.md`. Gli script sono guardrail: segnalano drift, ownership malformata e probabili conflitti, ma non sostituiscono il giudizio dell'agente.

## Cosa Risolve

- Preserva il lavoro dell'utente e degli agenti nei worktree sporchi.
- Supporta il caso single-agent: l'handoff diventa memoria di progetto tra sessioni.
- Fornisce ownership esplicita dei file e stop condition per piu agenti CLI.
- Impedisce che la pulizia distruttiva diventi la risposta predefinita all'incertezza.
- Rende la collaborazione auditabile: ogni agente legge prima l'handoff e lo aggiorna per ultimo.

## Sintesi Del Workflow

Il workflow finale e stato definito dalla discussione in `workflow.md`.

La conclusione condivisa e l'opzione C: il primo agente va scelto in base all'aderenza al task, non in base a una regola rigida sul caricamento nativo della skill. Codex e il primo agente naturale per scaffolding, script, test, packaging e release gate. Claude e il primo agente naturale per lavoro semantico sul protocollo, policy, template e reference. Gemini puo fare bootstrap di scaffolding inerte o QA/red-team. Grok e adatto all'esecuzione Grok-native e al QA su host immutabili. Ogni agente deve creare o rispettare subito `AGENT_HANDOFF.md`.

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
- Grok scopre `SKILL.md` nelle proprie directory skill ed espone la skill installata come `/cli-collaboration`.
- Tutte le CLI devono trattare la presenza di `AGENT_HANDOFF.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, un worktree sporco o una richiesta di resume come trigger per applicare il protocollo.

L'attivazione di Gemini puo richiedere un prompt esplicito. Quando non scatta, copia il forced-activation prompt da `skills/cli-collaboration/references/gemini-adapter.md` nell'apertura della sessione.

Grok espone la skill come `/cli-collaboration`; il comportamento degli slash command varia tra runtime. Il meccanismo di pausa portabile cross-CLI e basato sul filesystem:

- `.cli-collaboration-off` nella root del progetto.
- `**Status:** paused` in `AGENT_HANDOFF.md`.

La pausa riduce solo l'overhead procedurale. Non autorizza mai pulizia distruttiva, sovrascrittura del lavoro altrui o ignorare ownership `user-reserved` e `frozen`.

## Workflow Non-Code

Il caso d'uso primario resta la collaborazione su repository. Lo stesso protocollo di handoff puo coordinare anche workflow non-code espliciti, come brainstorming multi-LLM, sintesi di ricerca, dibattito strutturato, revisione editoriale o confronto tra modelli.

Per il brainstorming multi-LLM, inizia con una cartella topic che contiene solo `brainstorming.md`. Il primo agente legge quel seed file, crea `AGENT_HANDOFF.md`, scrive il primo turno e aggiorna l'handoff. Vedi `skills/cli-collaboration/references/alternate-workflows.md`.

## Come E Stato Sviluppato

Il pacchetto e stato costruito intenzionalmente facendo dogfooding del protocollo che fornisce.

- Fase 1, Codex: implementati core skill, script, fixture, metadata OpenAI, adapter Codex, `README.md` e wiring tecnico degli eval.
- Fase 2, Claude: implementati reference semantici, template handoff, anti-pattern, scenari di validazione, adapter Claude, metadata Claude ed esempi.
- Fase 3, Gemini: implementati guidance Gemini e contenuti adapter, poi QA cross-CLI.
- Fase 4, Grok: contributo iniziale ad adapter Grok, metadata, ricerca sulla discovery e note di compatibilita specifiche per Bluefin.
- Verifica finale Codex: conversione del port Grok-specifico iniziale in un unico pacchetto portabile per quattro CLI, aggiunta della coverage di regressione e riesecuzione dei release gate.

La divisione ha seguito la decisione finale C-emendata:

- Codex possiede package/tooling e release gate finali.
- Claude possiede chiarezza semantica e policy dei reference.
- Gemini possiede guidance Gemini-specifica e review QA/red-team.
- Grok possiede guidance dell'adapter Grok, metadata e QA sul runtime Grok.

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
        │   ├── claude.yaml
        │   └── grok.yaml
        ├── references/
        │   ├── alternate-workflows.md
        │   ├── codex-adapter.md
        │   ├── claude-adapter.md
        │   ├── gemini-adapter.md
        │   ├── grok-adapter.md
        │   ├── handoff-template.md
        │   ├── handoff-anti-patterns.md
        │   └── validation-scenarios.md
        └── scripts/
            ├── install-skill.sh
            ├── sync-skill.sh
            ├── check-ownership.sh
            ├── parse-ownership.py
            └── test-fixtures/
                └── grok-portability-tests.sh
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

Gli script di guardrail (`check-ownership.sh`, `install-skill.sh`, `sync-skill.sh`) e le fixture di test sono pensati per Bash su Linux e macOS (gli script usano feature Bash come `mapfile` e `[[ ... ]]` e non sono strettamente POSIX `sh`). `check-ownership.sh` delega il parsing dell'ownership a un helper Python 3 (`parse-ownership.py`); Python 3 e quindi una dipendenza a runtime del controllo di ownership (era gia dipendenza di `evals/run-mechanical-checks.sh`). La CI esegue sia `ubuntu-latest` sia `macos-latest` tramite GitHub Actions (`.github/workflows/ci.yml`). Il target predefinito Grok resta nella home utente scrivibile, quindi e compatibile con host immutabili Bluefin/Silverblue. Windows nativo non e supportato; WSL non fa parte della matrice di test e non e garantito funzioni.

## Installazione

Anteprima dei target di installazione predefiniti:

```bash
skills/cli-collaboration/scripts/install-skill.sh --dry-run
```

Installazione nei target predefiniti Codex, Agents interoperabile e Grok:

```bash
skills/cli-collaboration/scripts/install-skill.sh
```

Gemini CLI scopre `~/.agents/skills/` come alias di `~/.gemini/skills/`, con
precedenza per l'alias Agents. L'installazione predefinita copre quindi Gemini
tramite il target Agents ed evita intenzionalmente di duplicare la skill nelle
due directory.

Installazione in un target esplicito:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.codex/skills/cli-collaboration"
```

Per Claude Code:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.claude/skills/cli-collaboration"
```

Per un'installazione solo Gemini che non deve usare il target Agents
interoperabile:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.gemini/skills/cli-collaboration"
```

Per installazioni Antigravity CLI che usano il layout dell'albero di
configurazione Gemini:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.gemini/config/skills/cli-collaboration"
```

Per Grok Build:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "${GROK_HOME:-$HOME/.grok}/skills/cli-collaboration"
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
- Grok possiede contenuti dell'adapter/metadata Grok e QA sul runtime Grok.

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
| Fixture ownership | `skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` | pass, 8/8 |
| Validita JSON | `python3 -m json.tool evals/evals.json` | pass |
| Validita YAML | parse PyYAML di `SKILL.md`, `openai.yaml`, `claude.yaml`, `grok.yaml` | pass |
| Portabilita Grok | `skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh` | pass |
| Discovery Grok | install temporanea con `GROK_HOME` e `grok inspect --json` | pass |
| Discovery Gemini | `gemini skills list --all` con alias Agents installato | pass, abilitata senza percorsi skill duplicati |
| Install dry-run | `install-skill.sh --dry-run` | pass |
| Target install esplicito | `tmp="$(mktemp -d)" && install-skill.sh --target "$tmp/cli-collaboration"` | pass |
| Target sync esplicito | `sync-skill.sh --target "$tmp/cli-collaboration"` | pass dopo install esplicito |
| Ownership guard | `check-ownership.sh --handoff AGENT_HANDOFF.md --agent Codex README.md evals/evals.json` | pass |

Git e stato inizializzato per questo workspace e la baseline v2.2 e committata su `main`.

Le directory skill installate predefinite possono andare in drift rispetto al pacchetto locale finche l'utente non esegue `install-skill.sh` o `sync-skill.sh --install`.

## Prontezza Di Release

La release `2.5.0` e verificata localmente. Per i futuri aggiornamenti di release:

1. Revisionare il diff di release ed eseguire tutti i gate di verifica.
2. Pushare il commit di release intenzionale sul remote GitHub configurato.
3. Eseguire `install-skill.sh --dry-run` prima di aggiornare le installazioni locali.
4. Aggiungere il file di guidance rilevante (`AGENTS.md`, `CLAUDE.md` o `GEMINI.md`) ai progetti che devono applicare collaborazione handoff-first tra Codex, Claude Code, Gemini CLI, Grok Build o Antigravity.

## Licenza

Licenza MIT. Vedi `LICENSE`.
