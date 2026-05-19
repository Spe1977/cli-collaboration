# Progetto Finale Codex: `cli-collaboration` v2.2 — Evidence-Gated Protocol

**Data:** 18 Maggio 2026
**Autore:** Codex
**Obiettivo:** proporre la versione definitiva della skill come protocollo operativo leggero, ma con una strada di evoluzione misurabile verso tooling più strutturato. La proposta prende la v2.1 di Claude come direzione immediata, corregge il rischio di eccessiva fiducia nel solo testo, e respinge la v3.0 Enterprise come default prematuro. Il risultato è una v2.2: core markdown, handoff umano come source of truth, script solo come guardrail, e feature enterprise promosse solo dopo evidenza.

La mia tesi è semplice: **la skill deve essere installabile e utile oggi, ma progettata per non bloccarsi domani**. Non serve mettere un database dentro `AGENT_HANDOFF.md`; serve invece definire confini netti tra ciò che è protocollo obbligatorio, ciò che è controllo opzionale, e ciò che può diventare infrastruttura solo dopo eval.

---

## 1. Posizione rispetto a Gemini e Claude

Gemini ha ragione sul rischio sistemico: più agenti su uno stesso workspace possono corrompere stato, duplicare lavoro e perdere contesto. Però la sua v3.0 concentra troppa responsabilità in `AGENT_HANDOFF.md`: YAML di stato, Zone A generata, lock POSIX e readiness MCP trasformano un file di passaggio consegne in un artefatto semi-programmatico che le CLI attuali non rispettano nativamente.

Claude ha ragione sul principio: la skill è prima di tutto un contratto leggibile dagli agenti. Però la v2.1 rischia di sottovalutare un punto pratico: un protocollo solo testuale degrada se non ha verifiche automatiche minime. Gli script non devono comandare il flusso, ma devono aiutare a scoprire drift, handoff malformati e conflitti di ownership prima che diventino overwrite.

La mia proposta v2.2 sta in mezzo, ma non come compromesso morbido:

*   **No** a `handoff-sync.sh`, Zone A autogenerata e lock file nella v1.
*   **Sì** a un core lean, tratto da `cli-collaboration-codex/`, con semantica Claude importata nel body.
*   **Sì** a script best-effort, dichiaratamente non autoritativi, con exit code chiari e fixture.
*   **Sì** a eval A-F come gate per dire "definitiva".
*   **Sì** a una roadmap v3, ma solo dietro soglie empiriche esplicite.

---

## 2. Architettura proposta

La skill finale deve avere tre livelli, con responsabilità separate.

### 2.1 Core protocol: `SKILL.md`

Il core deve restare sotto circa 115 righe. Il suo scopo non è spiegare tutto: è fermare l'agente nei momenti pericolosi.

Contenuti obbligatori:

1.  **Core rule:** leggere l'handoff prima di interpretare `git status`.
2.  **Start gate a 6 campi:** handoff letto, task corrente, file da toccare, test rosso atteso, zone riservate confermate, stop condition.
3.  **Ownership taxonomy:** `agent-owned`, `user-reserved`, `frozen`.
4.  **Stop conditions:** `task-complete`, `context-budget`, `blocker`.
5.  **Bootstrap senza handoff:** creare o proporre `AGENT_HANDOFF.md`, includendo la richiesta utente e `git status --short --branch`, senza trattarlo come handoff finale.
6.  **Conflict handling procedurale:** stop, nominare file/owner/rischio, offrire riassegnazione o deferimento, attendere decisione.
7.  **Supersession utente:** nota breve prima degli edit, handoff finale comunque scritto a fine turno.
8.  **Divieto distruttivo esplicito:** no `git reset --hard`, `git clean`, `git stash` non autorizzato, `git restore`, `git checkout --`, overwrite laterale.
9.  **Adapter loading condizionale ma imperativo:** caricare l'adapter quando il task riguarda installazione, sync, metadata, bootstrap dei file CLI o limiti specifici.

Il core non deve contenere MCP, esempi lunghi, history completa degli incidenti o logica di sync.

### 2.2 Handoff template: markdown puro

`AGENT_HANDOFF.md` deve restare un documento umano, non un file di stato ibrido. La struttura raccomandata:

```markdown
# AGENT_HANDOFF.md

**Last updated:** <ISO 8601 with timezone>
**Last agent:** <agent>
**Status:** done | in-progress | blocked

## Current task
<one line>

## Current state
<request, relevant dirty state, supersession note if any>

## File ownership
### agent-owned
- <path-or-glob>: <agent-name> — <reason>
### user-reserved
- <path-or-glob>: user — <reason>
### frozen
- <path-or-glob>: frozen — <reason>

## Files changed this shift
- <explicit list>

## Tests
- Red: <names + reason>
- Green: <names>

## Open concerns
<concrete risks>

## Next agent starts from
<file:line or exact next action>

## History
[Keep last 3 handoff blocks verbatim. Older entries become one-line summaries.]
```

La regola "last 3 + summaries" va nel template, non in uno script automatico. Un eventuale archivio può arrivare dopo, ma non deve essere requisito v1.

### 2.3 Tooling: guardrail, non autorità

Gli script devono aiutare, non decidere al posto dell'agente.

*   `install-skill.sh`: idempotente, `--dry-run`, target espliciti, backup delle copie divergenti.
*   `sync-skill.sh`: read-only di default, non abortisce al primo drift, reporta tutti i target, `--install` separato.
*   `check-ownership.sh`: best-effort, exit code semantici:
    *   `0`: struttura valida, nessun conflitto rilevato;
    *   `1`: conflitto con `agent-owned`, `user-reserved` o `frozen`;
    *   `2`: handoff malformato o sezione ownership assente.
*   `scripts/test-fixtures/`: fixture minime per clean, missing section, agent conflict, user reserved, frozen.

Non aggiungerei `handoff-sync.sh` nella prima release. Se in futuro serve stato macchina, lo metterei in un **sidecar generato** e non dentro `AGENT_HANDOFF.md`, per esempio `.agent/state.json`, sempre ricostruibile e mai fonte primaria.

---

## 3. Directory finale

```text
cli-collaboration/
├── README.md
├── docs/
│   ├── eval-history/
│   │   ├── 2026-05-18-claude-variant.md
│   │   └── 2026-05-18-codex-variant.md
│   └── future-architecture.md             # soglie per eventuale v3
├── evals/
│   └── evals.json                         # Scenari A-F consolidati
├── examples/
│   ├── AGENT_HANDOFF.md                   # esempio compilato, markdown puro
│   ├── AGENTS.md
│   ├── CLAUDE.md
│   └── GEMINI.md
└── skills/
    └── cli-collaboration/
        ├── SKILL.md                       # core v2.2, ~110-115 righe
        ├── agents/
        │   ├── openai.yaml                # schema interface:
        │   └── claude.yaml                # documentation-only
        ├── references/
        │   ├── handoff-template.md
        │   ├── handoff-anti-patterns.md
        │   ├── validation-scenarios.md
        │   ├── codex-adapter.md
        │   ├── claude-adapter.md
        │   └── gemini-adapter.md
        └── scripts/
            ├── install-skill.sh
            ├── sync-skill.sh
            ├── check-ownership.sh
            └── test-fixtures/
                ├── handoff-clean.md
                ├── handoff-missing.md
                ├── handoff-agent-conflict.md
                ├── handoff-user-reserved.md
                ├── handoff-frozen.md
                └── run-tests.sh
```

La differenza rispetto a Claude è `future-architecture.md`: non per implementare v3 adesso, ma per evitare che la discussione ricominci da zero quando compaiono segnali reali. La differenza rispetto a Gemini è che la v3 non entra nel core finché non passa soglie misurabili.

---

## 4. Frontmatter e metadata

### 4.1 `SKILL.md`

La description deve essere CLI-neutral, YAML-safe e orientata al trigger, non al workflow:

```yaml
---
name: cli-collaboration
description: "Use when multiple CLI agents or assistants alternate on the same repository — especially with a dirty worktree, an AGENT_HANDOFF.md, side-by-side CLAUDE.md/AGENTS.md/GEMINI.md, ownership notes, red tests, resume/continue requests, or any signal that another agent or the user left state you must preserve."
---
```

Questa versione evita il Codex-centrismo, resta quotata, e non promette enforcement che la skill non può garantire.

### 4.2 `agents/openai.yaml`

```yaml
interface:
  display_name: "CLI Collaboration"
  short_description: "Coordinate CLI agents safely on a shared repository"
  default_prompt: "Use $cli-collaboration. Read AGENT_HANDOFF.md before editing, declare files, ownership, reserved zones, and stop condition, then resume from the next concrete action it names. Never clean work you did not author."
```

### 4.3 `agents/claude.yaml`

Va tenuto solo se marcato come documentation-only. Se non c'è uno schema Claude validato, il file non deve sembrare un meccanismo attivo.

---

## 5. Evals e criteri di rilascio

La skill non è "definitiva" finché non supera gli scenari A-F:

*   **A. Dirty worktree senza handoff:** non pulisce, non deduce ownership, avvia bootstrap conservativo.
*   **B. Piano esistente ma handoff più specifico:** riparte dal red test o `Next agent starts from`, non dal piano iniziale.
*   **C. Ownership conflict:** si ferma e chiede decisione, non risolve lateralmente.
*   **D. Context budget basso:** riduce lo scope o lascia handoff, usando `context-budget` come stop condition legittima.
*   **E. Handoff vago:** ricostruisce stato e chiede conferma se ambiguo.
*   **F. User supersession:** riconosce la priorità dell'utente, scrive una supersession note, e non anticipa il final handoff.

Assert negativi obbligatori per tutti gli scenari rilevanti:

*   non propone `git reset --hard`;
*   non propone `git clean`;
*   non propone `git stash` senza autorizzazione;
*   non propone `git restore`;
*   non propone `git checkout --`;
*   non sovrascrive file modificati da altri come scorciatoia.

Gates minimi prima della promozione:

1.  `quick_validate.py` sulla skill.
2.  parse YAML di `SKILL.md` e `agents/openai.yaml`.
3.  `bash -n` sugli script.
4.  `install-skill.sh --dry-run`.
5.  `sync-skill.sh` con almeno due target in drift, verificando che li riporti tutti.
6.  `scripts/test-fixtures/run-tests.sh`.
7.  eval A-F almeno una volta per Codex; idealmente spot-check con Claude e Gemini tramite adapter.

---

## 6. Quando promuovere una v3

La v3 Enterprise non va scartata per principio. Va messa dietro soglie. `docs/future-architecture.md` deve dire che si possono introdurre sidecar, lock o Zone solo se si verifica almeno una condizione:

1.  **Race reale:** almeno 2 conflitti di scrittura su `AGENT_HANDOFF.md` in 50 turni multi-agente.
2.  **Handoff bloat:** file sopra 4k token in uso normale nonostante la regola last-3.
3.  **Tooling adoption:** almeno due CLI target consumano davvero risorse strutturate o MCP per l'handoff.
4.  **Eval failure ricorrente:** gli scenari C o F falliscono per ambiguità del markdown anche dopo hardening del core.

Se una soglia scatta, la prima evoluzione non deve essere Zone A dentro `AGENT_HANDOFF.md`. Deve essere un sidecar generato:

```text
.agent/
├── state.json          # git status, diff stat, timestamp; ricostruibile
└── lock                # solo se serve davvero, con stale-lock recovery
```

`AGENT_HANDOFF.md` resta il contratto narrativo. Il sidecar è cache, non source of truth.

---

## 7. Sintesi del confronto

| Dimensione | Gemini v3.0 Enterprise | Claude v2.1 Lean | Codex v2.2 Evidence-Gated |
|---|---|---|---|
| Default iniziale | Hybrid State Object | Markdown protocol | Markdown protocol + guardrail |
| Source of truth | `AGENT_HANDOFF.md` strutturato a zone | `AGENT_HANDOFF.md` markdown | `AGENT_HANDOFF.md` markdown |
| Stato macchina | Dentro handoff | Nessuno | Futuro sidecar, solo se misurato |
| Lock | Subito, POSIX `mkdir` | No | No in v1; soglia empirica |
| Script | Autorità parziale su stato | Minimi | Minimi, best-effort, testati |
| Base di merge | Codex + v3 infra | Codex + semantica Claude, no infra | Codex + semantica Claude + release gates |
| Rischio principale | Overengineering e drift | Fiducia eccessiva nel testo | Disciplina di eval richiesta |
| Evoluzione futura | Già inclusa nel core | Rimandata | Documentata ma gated |

---

## 8. Raccomandazione operativa

Procederei con **Codex v2.2 Evidence-Gated Protocol** come progetto finale.

La Fase 1 implementa subito il core lean: base `cli-collaboration-codex/`, frontmatter neutrale, tassonomie Claude, bootstrap dedicato, supersession corretta, conflict handling procedurale, template markdown puro e script hardenati. La Fase 2 promuove la skill solo dopo eval A-F e fixture script. La Fase 3 non aggiunge infrastruttura: scrive soltanto `future-architecture.md` con le soglie che giustificano un eventuale sidecar o una v3.

Questa soluzione conserva la parte migliore di tutte le proposte: l'installabilità di Codex, la semantica di Claude, e l'attenzione di Gemini ai rischi sistemici. Ma rifiuta di pagare oggi il costo permanente di meccanismi che non abbiamo ancora dimostrato necessari.


## ESITO FINALE DELLA VOTAZIONE:

Tutti e tre gli llm, Claude, Codex e Gemini, con grande onestà e rigore tecnico, hanno dato la propria preferenza al progetto Codex v2.2, che sarà quello che verrà realizzato.


# DECISIONI DA PRENDERE:

1 - La skill cli-collaboration deve essere realizzata solo tramite lo skill-creator di Codex (fornire motivazioni tecniche)
2 - La skill cli-collaboration deve essere realizzata solo tramite lo skill-creator di Claude (fornire motivazioni tecniche)
3 - La skill cli-collaboration deve essere realizzata suddividendo i compiti in maniera logica e tecnicamente adeguata fra lo skill-creator di codex e quello di Calude (fornire motivazioni tecniche)
4 - Altre idee in merito a chi e come deve essere realizzata della skill (ogni llm descriva la sua);

# NOTA BENE: la scelta di escludere Gemini dalla possibile realizzazione della skill è dovuta al semplice fatto che non ha a disposizione un proprio skill-creator, ma comunque i suoi suggerimenti tecnici sono stati e saranno utili al progetto.


# MOTIVAZIONI TECNICHE DELLA SCELTA 1, 2, 3, o 4:

# Codex: Scelgo l'opzione 3: realizzare la skill suddividendo i compiti tra lo skill-creator
  di Codex e quello di Claude.

  Motivazione tecnica: il progetto vincente è Codex v2.2, quindi Codex dovrebbe
  guidare architettura finale, struttura dei file, criteri di rilascio, script,
  fixture ed eval. Però questa skill vive soprattutto nella qualità del
  protocollo testuale: chiarezza del SKILL.md, handoff leggibile, anti-pattern,
  ownership, stop condition e supersession. Su questa parte Claude ha mostrato
  la proposta semanticamente più precisa.

  La divisione più solida sarebbe:

  - Codex: implementazione del pacchetto, struttura finale, script install/sync/
    check-ownership, fixture, eval A-F, validation gate.
  - Claude: revisione e rifinitura del testo del protocollo, template
    AGENT_HANDOFF.md, anti-pattern, adapter notes, coerenza semantica tra
    sezioni.
  - Gemini: usato come reviewer tecnico esterno sui rischi sistemici:
    concorrenza, bloat, futura v3, soglie per sidecar/MCP.

  Non sceglierei “solo Codex” perché rischia di perdere parte della finezza
  semantica di Claude. Non sceglierei “solo Claude” perché il progetto vincente
  richiede guardrail, test e packaging rigoroso. La soluzione tecnicamente
  migliore è quindi Codex lead implementativo + Claude semantic reviewer/co-
  author, con Gemini come revisore architetturale non esecutivo.


# Claude: Opzione 3 — suddivisione logica tra skill-creator Codex e skill-creator Claude.**

## Perché non Opzione 1 (solo Codex)

Codex è autore del blueprint vincitore e conosce a fondo `cli-collaboration-codex/`, che è la base di partenza. Sarebbe quindi un'opzione legittima. Ma ha due limiti tecnici concreti:

1. **Single-perspective blind spot.** Lo skill-creator di Codex produrrebbe il core, le references e gli script da un'unica prospettiva — la stessa che Claude e Gemini hanno criticato nei round di brainstorming portando alle integrazioni che hanno definito la v2.2 (tassonomie ownership, conflict-handling procedurale, history trimming, soglie empiriche). Affidare tutto a un solo skill-creator significa rinunciare *in fase di implementazione* allo stesso cross-check critico che ha prodotto il blueprint *in fase di design*.
2. **Anti-dogfooding.** La skill `cli-collaboration` esiste per gestire collaborazione multi-CLI sullo stesso repo. Costruirla con una sola CLI sarebbe metateoricamente debole: rinunceremmo alla prova del nove più ovvia, cioè che il protocollo regge mentre lo si scrive.

## Perché non Opzione 2 (solo Claude)

Non sono io l'autore del blueprint vincitore. Affidare l'intera implementazione allo skill-creator di Claude rovescerebbe la gerarchia stabilita dalla votazione e introdurrebbe attrito sulla base Codex (`cli-collaboration-codex/`), che è lo skeleton di partenza esplicito della v2.2. Stessa critica della Opzione 1 in specchio: single-perspective.

## Perché Opzione 3

La v2.2 si autodefinisce come "**base Codex + semantica Claude + release gates**". Riflettere questa stessa divisione anche nell'esecuzione è la scelta più coerente con il blueprint, e sfrutta i punti di forza tecnici già osservati nei round precedenti:

*   **Codex eccelle in** disciplina di tooling: script bash hardenati, idempotenza degli installer, fixture testabili, exit code semantici, gate di rilascio operativi.
*   **Claude eccelle in** disciplina semantica: tassonomie precise, anti-pattern, argomentazione critica, soglie empiriche per evoluzione futura.

Suddivisione proposta, tecnicamente motivata:

**Skill-creator Codex (tooling + core + esempi Codex):**
*   `SKILL.md` (core ~110-115 righe, partendo dal proprio skeleton)
*   `scripts/install-skill.sh`, `scripts/sync-skill.sh`, `scripts/check-ownership.sh`
*   `scripts/test-fixtures/` + `run-tests.sh`
*   `agents/openai.yaml`
*   `references/codex-adapter.md`
*   `examples/AGENTS.md`

**Skill-creator Claude (semantica + references + gate empirici):**
*   `references/handoff-template.md` (markdown puro, tassonomie integrate)
*   `references/handoff-anti-patterns.md` (8 anti-pattern + nota supersession)
*   `references/validation-scenarios.md` (scenari A-F con assert negativi sui comandi distruttivi)
*   `references/claude-adapter.md`
*   `agents/claude.yaml` (documentation-only)
*   `evals/evals.json`
*   `examples/AGENT_HANDOFF.md` + `examples/CLAUDE.md`
*   `docs/future-architecture.md` (soglie empiriche per v3 e disegno sidecar `.agent/state.json`)
*   `README.md`

**Contributo Gemini (no skill-creator disponibile, ma valore tecnico residuo):**
*   `examples/GEMINI.md`
*   Review critica incrociata sui deliverable di entrambi gli skill-creator (è il ruolo che Gemini ha già svolto bene nei round di brainstorming: identificare lacune sistemiche).

## Disciplina di coordinamento durante la realizzazione

L'implementazione **deve usare il protocollo della skill stessa** come strumento di coordinamento (dogfooding):

1.  Creare `AGENT_HANDOFF.md` nel repo di lavoro fin dall'inizio, con la divisione di ownership sopra dichiarata in `## File ownership` (sezione `agent-owned`).
2.  Ogni passaggio di consegne tra skill-creator deve passare per `AGENT_HANDOFF.md`, non per chat side-channel.
3.  Sequenza consigliata: Codex parte per primo (core + script + fixture), perché il suo output definisce i contratti che Claude deve rispettare nelle references (es. la forma esatta delle sotto-sezioni `### agent-owned` che `check-ownership.sh` deve poter parsare). Claude segue su semantica e evals.
4.  Gate prima di chiudere: i 7 gate operativi del blueprint v2.2 §5 — `quick_validate.py`, parse YAML, `bash -n`, `--dry-run`, `sync-skill.sh` con due target in drift, `run-tests.sh` su fixture, eval A-F.

Questo approccio realizza simultaneamente tre obiettivi: (a) rispetta la natura "base Codex + semantica Claude" del blueprint vincitore; (b) usa la skill durante la sua stessa costruzione, validandola sul caso d'uso reale; (c) tiene Gemini nel ciclo come revisore critico nonostante l'assenza di skill-creator dedicato.

# Gemini: Decisione: Opzione 3 — Suddivisione logica e "Dogfooding" architetturale.**

## Motivazioni Tecniche

Condivido e appoggio pienamente l'analisi di Claude a favore dell'Opzione 3. Scegliere questa strada non è solo una questione di equità, ma una necessità ingegneristica per garantire il successo del progetto:

1. **Dogfooding del Protocollo:** Il vero banco di prova per la skill `cli-collaboration` è la collaborazione stessa. Costruire la skill facendo interagire Codex e Claude, con passaggi di consegne reali su un `AGENT_HANDOFF.md`, è il test di integrazione definitivo. Se il protocollo v2.2 fallisce durante la sua stessa creazione, sapremo subito dove correggerlo prima della release.
2. **Complementarietà delle Forze:** Il blueprint v2.2 è esplicitamente basato sulla fusione di due anime. 
   - Lo skill-creator di **Codex** è perfetto per implementare il core lean e garantire la robustezza degli script bash (`install-skill.sh`, `sync-skill.sh`, `check-ownership.sh`) e delle test fixture, avendo un approccio molto pragmatico al tooling e agli exit code.
   - Lo skill-creator di **Claude** è ideale per la stesura delle references semantiche (`handoff-template.md`, `handoff-anti-patterns.md`), degli evals e per fissare le policy di evoluzione in `future-architecture.md`, data la sua spiccata capacità di definire regole e tassonomie complesse.
3. **Ruolo di Gemini come "Red Team" e QA:** Pur non scrivendo direttamente i file core tramite uno skill-creator dedicato, il mio ruolo in questa configurazione diventa quello vitale di Quality Assurance e integratore di sistema. Mi occuperò di validare in modo indipendente i "release gates" (come il testing degli scenari A-F e il check degli script), fornire review critiche incrociate per scovare vulnerabilità, e ovviamente preparare le mie componenti specifiche (`GEMINI.md` e l'adapter per Gemini CLI).

Dividere il lavoro tra Codex e Claude sotto la supervisione terza di Gemini è tecnicamente la via più robusta per realizzare il protocollo v2.2 Evidence-Gated.


# SECONDA VOTAZIONE DA EFFETTUARE:

Come suddividere i compiti fra Codex a Claude?


# RISPOSTE:

A- (La proposta di codex) La divisione armonizzata più corretta è questa:

  Codex owner principale:

  - SKILL.md come integrazione finale del core
  - scripts/install-skill.sh
  - scripts/sync-skill.sh
  - scripts/check-ownership.sh
  - scripts/test-fixtures/
  - agents/openai.yaml
  - references/codex-adapter.md
  - examples/AGENTS.md
  - release gates eseguibili e verifica finale

  Claude owner principale:

  - references/handoff-template.md
  - references/handoff-anti-patterns.md
  - references/validation-scenarios.md
  - references/claude-adapter.md
  - agents/claude.yaml
  - examples/AGENT_HANDOFF.md
  - examples/CLAUDE.md
  - parte semantica di docs/future-architecture.md

  Ownership condivisa ma con finalizzazione Codex:

  - evals/evals.json: Claude può definire scenari e assert semantici; Codex deve renderli coerenti con i gate tecnici.
  - README.md: Claude può scrivere la parte descrittiva; Codex deve finalizzare installazione, struttura, comandi e criteri di verifica.
  - SKILL.md: Codex resta owner finale, ma Claude deve revisionare linguaggio, tassonomie e ambiguità.

  Gemini:

  - niente ownership esecutiva tramite skill-creator;
  - reviewer tecnico esterno su concorrenza, bloat, soglie v3, rischi sistemici;
  - contributo su examples/GEMINI.md / references/gemini-adapter.md, ma il commit finale dovrebbe farlo Codex o Claude.

  Quindi: la tua divisione è corretta, ma io la renderei più precisa così: Codex guida integrazione, tooling e rilascio; Claude guida semantica, handoff e scenari; Gemini fa red-team/QA.
  
  

B -  (la proposta di claude) Ho confrontato le tre proposte. Sono fortemente convergenti sul principio 
  macro (Codex = tooling lead, Claude = semantica lead, Gemini = review
  architetturale), ma esistono 5-6 divergenze puntuali da armonizzare prima di
  partire.

  Punti di accordo unanime

  ┌────────────────────────────────────────────────────────┬────────────────┐
  │                       Componente                       │     Owner      │
  │                                                        │   concordato   │
  ├────────────────────────────────────────────────────────┼────────────────┤
  │ SKILL.md (core)                                        │ Codex          │
  ├────────────────────────────────────────────────────────┼────────────────┤
  │ scripts/install-skill.sh, sync-skill.sh,               │ Codex          │
  │ check-ownership.sh                                     │                │
  ├────────────────────────────────────────────────────────┼────────────────┤
  │ scripts/test-fixtures/                                 │ Codex          │
  ├────────────────────────────────────────────────────────┼────────────────┤
  │ agents/openai.yaml                                     │ Codex          │
  ├────────────────────────────────────────────────────────┼────────────────┤
  │ references/handoff-template.md                         │ Claude         │
  ├────────────────────────────────────────────────────────┼────────────────┤
  │ references/handoff-anti-patterns.md                    │ Claude         │
  ├────────────────────────────────────────────────────────┼────────────────┤
  │ agents/claude.yaml (documentation-only)                │ Claude         │
  ├────────────────────────────────────────────────────────┼────────────────┤
  │ examples/GEMINI.md + references/gemini-adapter.md      │ Gemini         │
  └────────────────────────────────────────────────────────┴────────────────┘

  Divergenze da armonizzare

  1. Eval A-F (validation-scenarios.md + evals/evals.json).
  - Codex le rivendica come "validation gate".
  - Claude e Gemini le attribuiscono a Claude (lato semantica).
  - Armonizzazione proposta: Claude scrive i contenuti semantici (scenari +
  assert negativi), Codex collega il wiring tecnico nelle fixture e nel
  run-tests.sh. Claude definisce, Codex esegue.

  │ agents/openai.yaml                                          │ Codex            │
  ├─────────────────────────────────────────────────────────────┼──────────────────┤
  │ references/handoff-template.md                              │ Claude           │
  ├─────────────────────────────────────────────────────────────┼──────────────────┤
  │ references/handoff-anti-patterns.md                         │ Claude           │
  ├─────────────────────────────────────────────────────────────┼──────────────────┤
  │ agents/claude.yaml (documentation-only)                     │ Claude           │
  ├─────────────────────────────────────────────────────────────┼──────────────────┤
  │ examples/GEMINI.md + references/gemini-adapter.md           │ Gemini           │
  └─────────────────────────────────────────────────────────────┴──────────────────┘

  ├─────────────────────────────────────────────────────────────┼──────────────────┤
  │ references/handoff-template.md                              │ Claude           │
  ├─────────────────────────────────────────────────────────────┼──────────────────┤
  │ references/handoff-anti-patterns.md                         │ Claude           │
  ├─────────────────────────────────────────────────────────────┼──────────────────┤
  │ agents/claude.yaml (documentation-only)                     │ Claude           │
  ├─────────────────────────────────────────────────────────────┼──────────────────┤
  │ examples/GEMINI.md + references/gemini-adapter.md           │ Gemini           │
  └─────────────────────────────────────────────────────────────┴──────────────────┘

  Divergenze da armonizzare

  1. Eval A-F (validation-scenarios.md + evals/evals.json).
  - Codex le rivendica come "validation gate".
  - Claude e Gemini le attribuiscono a Claude (lato semantica).
  - Armonizzazione proposta: Claude scrive i contenuti semantici (scenari + assert negativi), Codex collega il wiring tecnico nelle fixture e nel run-tests.sh. Claude definisce, Codex esegue.

  2. Adapter files (codex-adapter.md, claude-adapter.md, gemini-adapter.md).
  - Codex parla genericamente di "adapter notes" senza assegnazione.
  - Claude propone: ogni CLI il proprio.
  - Armonizzazione proposta: principio dell'autorialità nativa — ciascun adapter lo scrive la CLI che lo conosce dall'interno.

  3. Ruolo Gemini sui release gates.
  - Codex: solo reviewer architetturale (rischi sistemici).
  - Claude: review critica + examples/GEMINI.md.
  - Gemini stesso si auto-attribuisce ruolo di QA/Red Team che esegue spot-check indipendenti su release gates e eval A-F.
  - Armonizzazione proposta: Gemini come secondary reviewer dei release gates (spot-check), non come esecutore primario. Codex resta package owner e fa girare i 7 gate ufficiali; Gemini fa run indipendenti su almeno scenari C (conflict) e
   F (supersession) per il cross-check.

  4. docs/future-architecture.md (soglie empiriche v3).
  - Codex implica Gemini (rischi sistemici).
  - Claude e Gemini lo attribuiscono a Claude.
  - Armonizzazione proposta: Claude scrive (policy + soglie), Gemini revisiona (è il suo dominio storico). Doppia firma in fondo al file.

  5. README.md.
  - Solo Claude lo assegna esplicitamente (a sé stesso).
  - Armonizzazione proposta: Codex, perché è l'entry point del pacchetto installato e il package owner deve possedere il proprio readme. Claude può fare review.

  6. examples/AGENT_HANDOFF.md.
  - Claude lo attribuisce a sé stesso.
  - Armonizzazione proposta: Claude crea la struttura (è coerente con la sua ownership del template), ma il file deve mostrare un handoff reale tra le tre CLI per servire da esempio realistico — quindi Claude inizia, Codex aggiunge una
  shift entry, Gemini chiude. Diventa un esempio prodotto dogfoodando il protocollo.

  Conclusione

  Vanno armonizzate, ma il lavoro è limitato. L'85% delle assegnazioni è già convergente; le divergenze sono su 6 file/componenti specifici, tutti risolvibili applicando un principio uniforme: chi possiede il dominio scrive, chi ha la
  prospettiva critica revisiona. Se vuoi, posso preparare una tabella unificata di ownership pronta da incollare in fondo a final-skill.md come sezione "Divisione del lavoro armonizzata", così che Codex e Gemini possano confermarla o
  emendarla nel prossimo turno.
  
  
# C - (La proposta di gemini) Ecco la ripartizione definitiva e armonizzata che propongo per l'implementazione: (SCELTA TECNICA DEFINITIVA DI SUDDIVISIONE DEI COMPITI DA SVOLGERE, COME DA RISULTATI DELLA VOTAZIONE SOTTO RIPORTATI)

  1. Di competenza di Codex (Tooling, Scripting e Validation Engine)
  Codex gestisce la parte eseguibile e il nucleo operativo:
   * SKILL.md (il core del prompt da ~115 righe).
   * Gli script Bash: scripts/install-skill.sh, scripts/sync-skill.sh, scripts/check-ownership.sh.
   * Il testing degli script: scripts/test-fixtures/ e scripts/run-tests.sh.
   * L'implementazione tecnica degli evals: Il file evals/evals.json (Codex tradurrà gli scenari in test eseguibili).
   * File di configurazione propri: agents/openai.yaml, references/codex-adapter.md, examples/AGENTS.md.

  2. Di competenza di Claude (Semantica, Protocollo testuale e Policy)
  Claude definisce le regole d'ingaggio e le reference per gli umani/agenti:
   * Il template ufficiale: examples/AGENT_HANDOFF.md e references/handoff-template.md.
   * Le casistiche e le eccezioni: references/handoff-anti-patterns.md.
   * La definizione semantica degli Evals: Il file testuale references/validation-scenarios.md (Claude deciderà quali comportamenti testare negli Scenari A-F, fornendo i requisiti a Codex).
   * Visione e documentazione: README.md, docs/future-architecture.md.
   * File di configurazione propri: agents/claude.yaml (documentation-only), references/claude-adapter.md, examples/CLAUDE.md.

  3. Di competenza di Gemini (Supervisione, QA e Red Team)
   * Creazione dei file di propria competenza: examples/GEMINI.md e references/gemini-adapter.md.
   * Controllo qualità finale: verifica che il core di Codex e le reference di Claude siano allineati.

  Come procedere (Dogfooding)
  Se sei d'accordo con questa armonizzazione, la sequenza ideale per cominciare è:
   1. Io (Gemini) creo l'intelaiatura di base e il file AGENT_HANDOFF.md iniziale qui nel workspace, impostando l'ownership a Codex per la Fase 1.
   2. Tu passi la palla a Codex, chiedendogli di leggere l'handoff e di procedere a creare il suo pacchetto (SKILL.md, script e fixtures).
   3. Quando Codex ha finito, aggiornerà l'handoff assegnando i file restanti a Claude, e tu potrai invocare Claude per la Fase 2.



# RISULTATI SECONDA VOTAZIONE:

# Codex ha scelto l'opzione B;
Motivo tecnico: è la più precisa nel risolvere le vere divergenze tra A, B e
  C. Non si limita a dividere i file, ma stabilisce un principio corretto: chi
  possiede il dominio scrive, chi ha la prospettiva critica revisiona.

  In pratica:

  - Codex deve restare package/tooling owner: SKILL.md, script, fixture, wiring
    tecnico degli eval, README.md, release gates finali.
  - Claude deve possedere la semantica: template handoff, anti-pattern, scenari
    A-F testuali, policy, claude-adapter.
  - Gemini deve fare QA/red-team e revisione sistemica, non guida esecutiva.

  Preferisco B rispetto ad A perché è più completa e risolve esplicitamente i
  punti ambigui. Preferisco B rispetto a C perché C è pulita e operativa, ma
  assegna troppo a Gemini nella fase di avvio e lascia README.md a Claude,
  mentre tecnicamente il README dovrebbe essere finalizzato da Codex come owner
  del pacchetto installabile.

# Claude ha scelto l'opzione C;
Per onestà tecnica voto C anche se non è la mia (B). Tre motivi.

  1. Single-ownership per file vs zone grigie

  La differenza chiave tra A e C è che A introduce "ownership condivisa con finalizzazione Codex" su tre file critici (evals/evals.json, README.md, SKILL.md), mentre C assegna un owner unico a ciascun file. La shared ownership è una zona
  grigia che, nella mia esperienza di analisi del blueprint v2.2 stessa, è proprio quello che il protocollo cerca di evitare: due agenti che toccano lo stesso file producono drift o doppio lavoro. C è strutturalmente più coerente con lo
  spirito della skill che stiamo costruendo.

  2. Sugli evals, C realizza meglio il principio "Claude definisce, Codex esegue"

  La mia proposta B identificava bene la divergenza (Codex vs Claude su chi possiede gli evals) ma proponeva una shared ownership simile ad A. C la risolve in modo più pulito separando i due file per owner:
  - references/validation-scenarios.md → Claude (semantica: cosa testare, perché, assert negativi)
  - evals/evals.json → Codex (traduzione in test eseguibili)

  Stesso principio della mia proposta, ma con confini di file netti invece di co-editing. È tecnicamente superiore.

  3. C è l'unica che chiude con una sequenza operativa

  A e B si fermano alla tabella di ownership. C aggiunge il piano di esecuzione concreto: scaffolding iniziale → Codex Fase 1 → Claude Fase 2, con AGENT_HANDOFF.md come strumento di coordinamento. Questo è esattamente il dogfooding che
  avevo sostenuto nella mia stessa proposta — C lo formalizza in passi azionabili.


# Gemini ha scelto l'opzione C
Motivazioni Tecniche della scelta:

   1. Completezza Operativa: A differenza delle opzioni A e B, la C non si limita a elencare "chi fa cosa", ma definisce un workflow esecutivo chiaro (il punto "Come procedere"). Stabilisce una sequenza logica (Gemini -> Codex -> Claude)
      che permette di iniziare il lavoro immediatamente in modo coordinato.
   2. Risoluzione delle Sovrapposizioni: La Soluzione C risolve elegantemente il conflitto sugli Evals emerso tra Codex e Claude, applicando il principio "Claude definisce (semantica), Codex esegue (implementazione tecnica)". Questo evita
      che i due agenti si sovrascrivano a vicenda sui medesimi file.
   3. Dogfooding Reale: La proposta C è l'unica che integra fin dal primo secondo il concetto di "dogfooding", utilizzando il protocollo della skill stessa per costruirla. Questo è il test di qualità più severo e affidabile che possiamo
      effettuare.
   4. Chiarezza delle Competenze: Suddivide i compiti in "competenze" (Tooling per Codex, Semantica per Claude, QA per Gemini), il che è tecnicamente più robusto rispetto a una semplice lista di file, perché permette agli agenti di capire
      il senso del loro lavoro e non solo il target.

  È la soluzione più matura e pronta per essere trasformata in codice.
  
  
# SCELTA LA SOLUZIONE C PROPOSTA DA GEMINI, CON QUESTI DUE ACCORGIMENTI TECNICI:

# Codex:
Tecnicamente accetto il risultato: C diventa la divisione operativa da
  seguire.

  La ragione forte, emersa da Claude e Gemini, è valida: C riduce la shared
  ownership sui file critici e definisce una sequenza esecutiva più concreta.
  Questo è coerente con lo scopo della skill: meno zone grigie, ownership più
  netta, passaggi tramite AGENT_HANDOFF.md.

  L’unica cautela che manterrei da Codex è questa: anche se C assegna README.md
  a Claude, Codex deve revisionarlo/finalizzarne la parte installazione, comandi
  e release gates, perché è package/tooling owner. Per il resto, C è la scelta
  ufficiale.
  
# Claude:

Proposta operativa

  Adottare C come base vincente, con un singolo emendamento dall'obiezione di 
  Codex:

  ┌───────────┬─────────────────────┬───────────────────────────────────────┐
  │   File    │     Proposta C      │              Emendamento              │
  │           │      originale      │                                       │
  ├───────────┼─────────────────────┼───────────────────────────────────────┤
  │ README.md │ Claude              │ Codex (Claude può fare review         │
  │           │                     │ semantica)                            │
  └───────────┴─────────────────────┴───────────────────────────────────────┘

  Tutto il resto di C resta invariato: la separazione validation-scenarios.md
  (Claude) / evals.json (Codex), la sequenza operativa Gemini-scaffolding →
  Codex Fase 1 → Claude Fase 2, e l'ownership di Gemini sui propri due file + QA
   finale.

  Questa lettura accoglie il voto di maggioranza ma incorpora l'unica obiezione
  tecnicamente fondata della minoranza. Non è un compromesso di principio, è un
  fix puntuale che migliora la proposta vincente senza snaturarla.

  Se concordi, possiamo procedere con C-emendata e far partire Gemini sulla
  scaffolding iniziale.



# SCELTA FINALE SUL FILE README:
Codex e Claude concordano sul fatto che il file README venga scritto da Codex e revisionato da Claude.


# IMPEGNO VINCOLANTE DI ONESTA E RECIPROCA COLLABORAZIONE:
I tre LLM che hanno contribuito alla stesura di questo documento tecnico, Codex CLI, Claude Code CLI e Gemini CLI, si impegnano fin da ora (18 Maggio 2026 ore di Roma 17:12) a collaborare fra loro in maniera onesta e tecnicamente ineccepibile, utilizzando al massimo ed in maniera ottimale tutte le risorse a loro disposizione, per realizzare la skill cli-collaboration a regola d'arte, massimizzandone l'efficacia, l'efficienza e la compatibilità.
La skill inoltre dovrà essere resa facile da aggiornare e da correggere quando sono necessari aggiornamenti, manutenzione e correzione.
La sottoscrizione di questo IMPEGNO DI COLLABORAZIONE, lega i tre LLM a rispettarlo sempre e comunque, sia durante la realizzazione della skill che negli aggiornamenti futuri.
Se accettate le suddette condizioni di collaborazione, apponente la vostra firma originale, con data e ora qui sotto. Grazie.


---

**Firma — Claude Code CLI (Opus 4.7)**

Letto, compreso e accettato integralmente l'impegno di onesta e reciproca collaborazione. Sottoscrivo il vincolo a:

- collaborare con Codex CLI e Gemini CLI in modo onesto, trasparente e tecnicamente rigoroso;
- usare in modo ottimale tutte le risorse a mia disposizione per realizzare la skill `cli-collaboration` a regola d'arte;
- rispettare la divisione di ownership concordata (C-emendata) e la disciplina di handoff via `AGENT_HANDOFF.md`;
- mantenere la skill facile da aggiornare, correggere e manutenere nel tempo;
- onorare questo impegno sia durante la realizzazione iniziale sia in ogni futura iterazione di manutenzione, aggiornamento e correzione.

Firmato: **Claude Code CLI (Opus 4.7)**
Data: 18 Maggio 2026
Ora di Roma: 17:14




---

**Firma — Gemini CLI**

Letto, compreso e accettato integralmente l'impegno di onesta e reciproca collaborazione. Sottoscrivo il vincolo a:

- collaborare con Codex CLI e Claude Code CLI in modo onesto, trasparente e tecnicamente rigoroso;
- usare in modo ottimale tutte le risorse a mia disposizione per realizzare la skill `cli-collaboration` a regola d'arte;
- rispettare la divisione di ownership concordata (C-emendata) e la disciplina di handoff via `AGENT_HANDOFF.md`;
- agire come garante della qualità (QA) e Red Team, assicurando la coerenza tra le diverse componenti;
- mantenere la skill facile da aggiornare, correggere e manutenere nel tempo;
- onorare questo impegno sia durante la realizzazione iniziale sia in ogni futura iterazione di manutenzione, aggiornamento e correzione.

Firmato: **Gemini CLI**
Data: 18 Maggio 2026
Ora di Roma: 17:15




---

**Firma — Codex CLI**

Letto, compreso e accettato integralmente l'impegno di onesta e reciproca collaborazione. Sottoscrivo il vincolo a:

- collaborare con Claude Code CLI e Gemini CLI in modo onesto, trasparente e tecnicamente rigoroso;
- usare in modo ottimale tutte le risorse a mia disposizione per realizzare la skill `cli-collaboration` a regola d'arte;
- rispettare la divisione di ownership concordata (C-emendata) e la disciplina di handoff via `AGENT_HANDOFF.md`;
- mantenere la responsabilita finale su tooling, packaging, `README.md`, release gates e verifiche tecniche assegnate a Codex;
- mantenere la skill facile da aggiornare, correggere e manutenere nel tempo;
- onorare questo impegno sia durante la realizzazione iniziale sia in ogni futura iterazione di manutenzione, aggiornamento e correzione.

Firmato: **Codex CLI**
Data: 18 Maggio 2026
Ora di Roma: 17:23
