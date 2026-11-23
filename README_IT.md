# cli-collaboration

[![CI](https://github.com/Spe1977/cli-collaboration/actions/workflows/ci.yml/badge.svg)](https://github.com/Spe1977/cli-collaboration/actions/workflows/ci.yml)

**Versione:** 2.6.0 | [English](README.md) | [Changelog](CHANGELOG.md) | [Contributori](CONTRIBUTORS_IT.md)

`cli-collaboration` e un protocollo leggero con guardrail deterministici per coordinare **Codex**, **Claude Code**, **Gemini CLI**, **Grok Build**, **Antigravity (IDE / App 2.0 / `agy` CLI)**, oppure un singolo agente attraverso piu sessioni nello stesso progetto.

La fonte di verita e `AGENT_HANDOFF.md`. Script e hook opzionali fungono da guardrail: prevengono scorciatoie distruttive, rilevano conflitti di ownership e validano la struttura dell'handoff senza sostituire il giudizio dell'agente.

## Cosa Risolve

- Preserva il lavoro dell'utente e degli agenti nei worktree sporchi.
- Supporta il caso single-agent: l'handoff diventa memoria di progetto persistente tra sessioni.
- Assegna agli agenti CLI e IDE ownership esplicita dei file, identita distinte (`Antigravity` vs `Gemini`) e stop condition chiare.
- Impedisce che la pulizia distruttiva (`reset --hard`, `clean`, `stash` non autorizzato, `restore`, `checkout --`) diventi la scorciatoia predefinita.
- Offre hook deterministici opzionali (`SessionStart`, `PreToolUse`/`BeforeTool`, `Stop`) in affiancamento al caricamento progressivo della skill.
- Rende la collaborazione auditabile: ogni agente legge prima `AGENT_HANDOFF.md` e lo aggiorna per ultimo.

## Sintesi Del Workflow

Il flusso raccomandato e handoff-first:

1. L'agente attivo legge `AGENT_HANDOFF.md` (oppure esegue il bootstrap conservativo se manca).
2. Dichiara lo **Start Gate**: handoff letto, task corrente, file espliciti da toccare, test rosso atteso, zone riservate confermate e stop condition.
3. Il lavoro rispetta le classi di ownership (`### agent-owned`, `### user-reserved`, `### frozen`) e l'aderenza al task.
4. Una sola sessione parent/coordinator aggiorna `AGENT_HANDOFF.md` per ultimo (subagent paralleli e swarm Antigravity riportano al coordinatore senza scrivere in concorrenza).
5. Ogni handoff registra file modificati, test rossi/verdi, open concerns concreti e il prossimo passo esatto.

Il caso single-LLM e di prima classe: anche quando opera un solo agente, `AGENT_HANDOFF.md` mantiene la continuità tra riavvii e sessioni.

## Attivazione E Pausa

Tutti i runtime supportati trattano la presenza di `AGENT_HANDOFF.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, un worktree sporco, `brainstorming.md` o una richiesta di resume come trigger:

- **Codex:** carica la skill tramite metadata `SKILL.md` e guidance `AGENTS.md`.
- **Claude Code:** carica tramite description matching di `SKILL.md`, `/cli-collaboration`, `CLAUDE.md` ed eventuali hook `SessionStart` / `PreToolUse`.
- **Gemini CLI:** scopre nativamente `SKILL.md` (preferire `~/.agents/skills/` rispetto a `~/.gemini/skills/` per evitare duplicati), attiva con `activate_skill`, `GEMINI.md` e hook opzionali `SessionStart` / `BeforeTool`.
- **Grok Build:** scopre `~/.grok/skills/` (o `.grok/skills/`), `/cli-collaboration` e `AGENTS.md` (vedi `references/grok-adapter.md`).
- **Antigravity (IDE / App 2.0 / `agy` CLI):** scopre `~/.gemini/config/skills/` e `.agents/skills/` nel workspace, carica automaticamente sia `AGENTS.md` che `GEMINI.md`, mantiene `AGENT_HANDOFF.md` nella root del repo tra Plan/Execute Mode e supporta `hooks.json` (`SessionStart`, `PreToolUse`, `Stop`) (vedi `references/antigravity-adapter.md`).

Il meccanismo portabile di pausa cross-CLI e basato sul filesystem:

- `.cli-collaboration-off` nella root del progetto.
- `**Status:** paused` in `AGENT_HANDOFF.md`.

La pausa riduce solo l'overhead procedurale (Start Gate / End-of-Shift). Non autorizza **mai** pulizia distruttiva, sovrascrittura del lavoro altrui o violazioni di `### user-reserved` e `### frozen`.

## Workflow Non-Code

Il caso d'uso primario resta la collaborazione su repository. Lo stesso protocollo coordina anche workflow non-code espliciti come brainstorming multi-LLM, sintesi di ricerca, dibattito strutturato, revisione editoriale o confronto tra modelli.

Per il brainstorming multi-LLM, crea una cartella topic con il solo `brainstorming.md`. Il primo agente legge il seed file, fa bootstrap di `AGENT_HANDOFF.md`, scrive il primo turno e aggiorna l'handoff per ultimo. Vedi `skills/cli-collaboration/references/alternate-workflows.md`.

## Come E Stato Sviluppato

Questo pacchetto e stato costruito applicando su se stesso il protocollo `cli-collaboration` attraverso cinque fasi (vedi [`CONTRIBUTORS_IT.md`](CONTRIBUTORS_IT.md)):

- **Fase 1 — Codex (OpenAI):** `SKILL.md` core, script di guardrail, suite di fixture, metadati OpenAI, adapter Codex, `README.md`/`README_IT.md` e hardening della portabilita `v2.5.0`.
- **Fase 2 — Claude Code (Anthropic):** reference semantiche, template, anti-pattern, scenari di validazione, esempi, `docs/future-architecture.md` e transizione CI/rollback/lint `v2.3.0`.
- **Fase 3 — Gemini CLI (Google):** guidance e adapter Gemini, QA cross-CLI e allineamento `v2.4.0`.
- **Fase 4 — Grok Build (xAI):** adapter Grok, metadati, ricerca su discovery e note runtime per host immutabili.
- **Fase 5 — Antigravity (Google DeepMind):** integrazione `v2.6.0` per Antigravity IDE / App 2.0 / `agy` CLI, separazione identita `Antigravity` vs `Gemini` nel parser, `lang.sh` sandbox-friendly, backup fuori dall'albero discovery (`skills-backups/`), hook deterministici (`hook-guard.py`), CI meccanica a 10 step e harness opt-in per eval live locali (`evals/run-live-evals.py`).

## Struttura Del Pacchetto

```text
cli-collaboration/
├── README.md
├── README_IT.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTORS.md
├── CONTRIBUTORS_IT.md
├── AGENT_HANDOFF.md
├── CLAUDE.md
├── GEMINI.md
├── .github/workflows/ci.yml
├── docs/
│   ├── future-architecture.md
│   └── superpowers/
├── evals/
│   ├── evals.json
│   ├── lint-handoff.py
│   ├── run-live-evals.py
│   ├── run-mechanical-checks.sh
│   └── test-lint-handoff.sh
├── examples/
│   ├── AGENT_HANDOFF.md
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   ├── GEMINI.md
│   └── hooks/
│       ├── antigravity.hooks.json
│       ├── claude.settings.json
│       └── gemini.settings.json
└── skills/
    └── cli-collaboration/
        ├── SKILL.md
        ├── agents/
        │   ├── antigravity.yaml
        │   ├── claude.yaml
        │   ├── grok.yaml
        │   └── openai.yaml
        ├── references/
        │   ├── alternate-workflows.md
        │   ├── antigravity-adapter.md
        │   ├── claude-adapter.md
        │   ├── codex-adapter.md
        │   ├── gemini-adapter.md
        │   ├── grok-adapter.md
        │   ├── handoff-anti-patterns.md
        │   ├── handoff-template.md
        │   └── validation-scenarios.md
        └── scripts/
            ├── check-ownership.sh
            ├── hook-guard.py
            ├── install-skill.sh
            ├── lang.sh
            ├── parse-ownership.py
            ├── sync-skill.sh
            └── test-fixtures/
                ├── grok-portability-tests.sh
                ├── hook-guard-tests.sh
                ├── install-rollback-test.sh
                ├── lang-tests.sh
                └── run-tests.sh
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

Le righe di ownership sotto `## File ownership` usano questa forma esatta:

```text
- <path-or-glob>: <agent-name> — <reason>
```

Sottosezioni obbligatorie (tutte e tre le intestazioni devono essere presenti anche se vuote):

- `### agent-owned`: file assegnati a `Codex`, `Claude`, `Gemini`, `Grok`, `Antigravity` o altro agente nominato.
- `### user-reserved`: file dell'utente; fermarsi prima di modificare.
- `### frozen`: file protetti; fermarsi prima di modificare.

Dalla v2.6.0+, `parse-ownership.py` mantiene strettamente distinti `Antigravity` (`antigravity`) e `Gemini` (`gemini`), normalizza gli alias riconosciuti (`Claude Code`, `Gemini CLI`, `OpenAI Codex`, `Grok Build`, `Antigravity IDE`, `agy`) e le note tra parentesi, rimuove i prefissi `./` e relativizza i path assoluti interni alla directory dell'handoff. I glob usano `fnmatch.fnmatchcase` dove `*` attraversa `/` (`scripts/*` copre `scripts/sub/foo.sh`); `**` non e riconosciuto.

## Piattaforme Supportate

Gli script Bash (`check-ownership.sh`, `install-skill.sh`, `sync-skill.sh`, `lang.sh`) e gli helper Python (`parse-ownership.py`, `hook-guard.py`) supportano **Bash (3.2+) e Python 3 su Linux e macOS** (compatibili anche con host immutabili come Bluefin/Silverblue). La CI esegue `shellcheck` su `ubuntu-latest` e la matrice a 10 step su `ubuntu-latest` e `macos-latest`. Windows nativo non e supportato.

## Installazione E Sync

Anteprima dei target predefiniti (`--codex`, `--agents`, `--grok`):

```bash
skills/cli-collaboration/scripts/install-skill.sh --dry-run
```

Installa tutti i runtime non in conflitto (**Codex**, **Agents** [scoperto anche da Gemini CLI], **Grok**, **Claude Code** e **Antigravity**):

```bash
skills/cli-collaboration/scripts/install-skill.sh --all
```

Oppure seleziona singoli runtime (`--codex`, `--agents`, `--grok`, `--claude`, `--antigravity`, `--gemini`, o `--target DIR`):

```bash
skills/cli-collaboration/scripts/install-skill.sh --antigravity
skills/cli-collaboration/scripts/install-skill.sh --claude
```

> **Nota:** `--all` omette intenzionalmente `~/.gemini/skills/cli-collaboration` perche Gemini CLI legge gia `~/.agents/skills/cli-collaboration` e la presenza di entrambi causa conflitti di duplicazione. Le copie divergenti preesistenti vengono salvate nella directory sorella `../skills-backups/` (fuori da `skills/`) e ripristinate automaticamente in caso di errore di copia.

Controlla il drift o sincronizza le installazioni:

```bash
skills/cli-collaboration/scripts/sync-skill.sh --all
skills/cli-collaboration/scripts/sync-skill.sh --all --install
```

## Check Ownership

Esegui il controllo prima di toccare file vicini ai confini di ownership:

```bash
skills/cli-collaboration/scripts/check-ownership.sh --agent Antigravity README.md
```

Exit code:

- `0`: struttura valida e nessun conflitto rilevato.
- `1`: conflitto con `agent-owned`, `user-reserved` o `frozen`.
- `2`: errore d'uso, handoff mancante o sezione ownership malformata.

## Hook Deterministici (Opzionali)

`skills/cli-collaboration/scripts/hook-guard.py` applica il protocollo a livello di runtime su Antigravity, Claude Code e Gemini CLI tramite i template in `examples/hooks/`:

- **Antigravity:** `examples/hooks/antigravity.hooks.json` -> `.agents/hooks.json` o `~/.gemini/config/hooks.json` (`SessionStart`, `PreToolUse`, `Stop`).
- **Claude Code:** `examples/hooks/claude.settings.json` -> `.claude/settings.json` o `~/.claude/settings.json` (`SessionStart`, `PreToolUse`).
- **Gemini CLI:** `examples/hooks/gemini.settings.json` -> `.gemini/settings.json` o `~/.gemini/settings.json` (`SessionStart`, `BeforeTool`).

Quando `AGENT_HANDOFF.md` esiste, l'hook inietta un riepilogo compatto di avvio, nega le modifiche su file di altri agenti / `user-reserved` / `frozen`, richiede conferma su comandi git distruttivi e verifica la validita dell'handoff modificato nello `Stop` di Antigravity.

## Preferenza Lingua Sandbox-Friendly

`scripts/lang.sh` controlla nell'ordine:

1. Configurazione globale `${CLI_COLLAB_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/cli-collaboration/config.json}`
2. Configurazione locale di progetto `${CLI_COLLAB_LOCAL_CONFIG:-.cli-collaboration.json}` (via `lang.sh set <lang> --local`)
3. Variabile d'ambiente `$CLI_COLLAB_LANG`

Se `lang.sh set` gira in un sandbox dove `$HOME/.config` non e scrivibile, esce pulitamente con codice `4` senza richiedere permessi fuori sandbox; gli agenti proseguono nella lingua del prompt utente.

## Validazione E Verifica Di Release

Sei scenari comportamentali (`A`–`F`) piu 14 trigger eval (`T1`–`T8`, `N1`–`N6`) sono definiti in `skills/cli-collaboration/references/validation-scenarios.md` ed `evals/evals.json`. I check meccanici girano tramite `bash evals/run-mechanical-checks.sh` in 10 step:

| Step | Gate | Target |
|---|---|---|
| 1/10 | Fixture parser ownership (33 casi) | `skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` |
| 2/10 | Rollback install, `skills-backups/`, dry-run & sync (8 check) | `skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh` |
| 3/10 | Preferenza lingua e fallback sandbox (34 asserzioni) | `skills/cli-collaboration/scripts/test-fixtures/lang-tests.sh` |
| 4/10 | Portabilita cross-CLI (Grok + Antigravity) | `skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh` |
| 5/10 | Fixture hook deterministici e template (11 blocchi) | `skills/cli-collaboration/scripts/test-fixtures/hook-guard-tests.sh` |
| 6/10 | Unit test `lint-handoff.py` (10 casi) + lint repo | `evals/test-lint-handoff.sh` e `evals/lint-handoff.py` |
| 7/10 | Self-test deterministico harness eval live | `python3 evals/run-live-evals.py --self-test` |
| 8/10 | Frontmatter stretto `SKILL.md` + asset YAML/JSON | Validatore Python inline (`PyYAML` + `json`) |
| 9/10 | Integrita link markdown relativi e permessi `+x` | Controllo Python inline su `SKILL.md`, `references/`, `scripts/` |
| 10/10 | Source-guard multibyte `check-ownership.sh` | Controllo byte Python inline |

### Valutazione Live Opt-In (Locale)

Per provare agenti CLI/IDE reali su sandbox git temporanee isolate per gli scenari `A`–`F` e i 14 `trigger_evals` (non eseguita in CI):

```bash
python3 evals/run-live-evals.py --cli agy --mode all --dry-run
python3 evals/run-live-evals.py --cli <claude|codex|gemini|agy|grok> --mode all --json-out /tmp/eval-report.json
```

## Aggiornamento E Manutenzione

L'eventuale infrastruttura sidecar v3 resta subordinata alle soglie empiriche di `docs/future-architecture.md` e utilizza `.cli-collaboration/` (non `.agent/`, riservata da Antigravity alle personalizzazioni di workspace).

## Licenza

Licenza MIT. Vedi `LICENSE`.
