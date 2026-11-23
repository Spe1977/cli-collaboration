# cli-collaboration

[![CI](https://github.com/Spe1977/cli-collaboration/actions/workflows/ci.yml/badge.svg)](https://github.com/Spe1977/cli-collaboration/actions/workflows/ci.yml)

**Version:** 2.6.0 | [Italiano](README_IT.md) | [Changelog](CHANGELOG.md) | [Contributors](CONTRIBUTORS.md)

`cli-collaboration` is a lightweight protocol and deterministic guardrail toolkit for coordinating **Codex**, **Claude Code**, **Gemini CLI**, **Grok Build**, **Antigravity (IDE / App 2.0 / `agy` CLI)**, or a single agent across multiple sessions in the same project.

The source of truth is `AGENT_HANDOFF.md`. Scripts and optional lifecycle hooks are guardrails: they prevent destructive shortcuts, detect ownership conflicts, and validate handoff structure without replacing agent judgment.

## What It Solves

- Preserves user and agent work in dirty worktrees.
- Supports the single-agent case: the handoff is persistent project memory across sessions.
- Gives multiple CLI and IDE agents explicit file ownership, distinct identities (`Antigravity` vs `Gemini`), and clear stop conditions.
- Prevents destructive git cleanup (`reset --hard`, `clean`, unauthorized `stash`, `restore`, `checkout --`) from becoming a default shortcut.
- Offers optional deterministic lifecycle hooks (`SessionStart`, `PreToolUse`/`BeforeTool`, `Stop`) alongside prompt-driven progressive disclosure.
- Makes collaboration auditable: each agent reads `AGENT_HANDOFF.md` first and updates it last.

## Workflow Summary

The recommended workflow is handoff-first:

1. The active agent reads `AGENT_HANDOFF.md` (or bootstraps it conservatively if missing).
2. It declares the **Start Gate**: handoff read, current task, explicit files to touch, expected red test, reserved zones confirmed, and stop condition.
3. Work is scoped by ownership (`### agent-owned`, `### user-reserved`, `### frozen`) and task fit.
4. Only one parent/coordinator session updates `AGENT_HANDOFF.md` last (parallel subagents and Antigravity swarms report back instead of mutating it concurrently).
5. Every handoff records files changed, tests red/green, concrete open concerns, and the next concrete step.

The single-LLM case is first-class: even when only one agent works in a repository, `AGENT_HANDOFF.md` preserves context across restarts.

## Activation And Pause

All supported runtimes treat the presence of `AGENT_HANDOFF.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, a dirty worktree, `brainstorming.md`, or a resume request as a trigger:

- **Codex:** loads the skill via `SKILL.md` frontmatter and `AGENTS.md`.
- **Claude Code:** loads via `SKILL.md` description matching, `/cli-collaboration`, `CLAUDE.md`, and optional `SessionStart` / `PreToolUse` hooks.
- **Gemini CLI:** discovers `SKILL.md` natively (prefer `~/.agents/skills/` over `~/.gemini/skills/` to avoid duplicate warnings), activates via `activate_skill`, `GEMINI.md`, and optional `SessionStart` / `BeforeTool` hooks.
- **Grok Build:** discovers `~/.grok/skills/` (or `.grok/skills/`), `/cli-collaboration`, and `AGENTS.md` (see `references/grok-adapter.md`).
- **Antigravity (IDE / App 2.0 / `agy` CLI):** discovers `~/.gemini/config/skills/` and workspace `.agents/skills/`, loads both `AGENTS.md` and `GEMINI.md` automatically, keeps `AGENT_HANDOFF.md` at the repo root across Plan/Execute turns, and supports `hooks.json` (`SessionStart`, `PreToolUse`, `Stop`) (see `references/antigravity-adapter.md`).

The portable cross-CLI pause mechanism is filesystem-based:

- `.cli-collaboration-off` in the project root.
- `**Status:** paused` in `AGENT_HANDOFF.md`.

Pause only reduces procedural overhead (Start Gate / End-of-Shift verbosity). It **never** authorizes destructive cleanup, overwriting someone else's work, or bypassing `### user-reserved` and `### frozen` ownership.

## Non-Code Workflows

The primary use case remains repository collaboration. The same handoff protocol also coordinates explicit non-code workflows such as multi-LLM brainstorming, research synthesis, structured debate, editorial review, or model comparison.

For multi-LLM brainstorming, start a topic folder with `brainstorming.md`. The first agent reads that seed file, bootstraps `AGENT_HANDOFF.md`, writes the first turn, and updates the handoff last. See `skills/cli-collaboration/references/alternate-workflows.md`.

## How It Was Developed

This package was built by dogfooding the `cli-collaboration` protocol itself across five phases (see [`CONTRIBUTORS.md`](CONTRIBUTORS.md)):

- **Phase 1 — Codex (OpenAI):** core `SKILL.md`, guardrail scripts, fixture suite, OpenAI metadata, Codex adapter, `README.md`/`README_IT.md`, and `v2.5.0` portability hardening.
- **Phase 2 — Claude Code (Anthropic):** semantic references, templates, anti-patterns, validation scenarios, examples, `docs/future-architecture.md`, and `v2.3.0` CI/rollback/lint transition.
- **Phase 3 — Gemini CLI (Google):** Gemini guidance and adapter, cross-CLI QA verification, and `v2.4.0` alignment.
- **Phase 4 — Grok Build (xAI):** Grok adapter, metadata, discovery research, and immutable-host runtime notes.
- **Phase 5 — Antigravity (Google DeepMind):** `v2.6.0` Antigravity IDE / App 2.0 / `agy` CLI integration, `Antigravity` vs `Gemini` parser hardening, sandbox-friendly `lang.sh`, out-of-tree backups (`skills-backups/`), deterministic lifecycle hooks (`hook-guard.py`), 10-step mechanical CI, and opt-in local live eval harness (`evals/run-live-evals.py`).

## Package Structure

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

## Core Protocol

Every agent must treat `AGENT_HANDOFF.md` as the source of truth.

Before editing, the agent declares:

```text
Handoff read: <path, last-updated timestamp>
Current task: <one line>
Files I will touch: <explicit file list>
Expected red test: <test name, or no test with reason>
Reserved zones confirmed: <user-reserved/frozen areas>
Stop condition: <task-complete | context-budget | blocker>
```

Ownership lines use this exact shape under `## File ownership`:

```text
- <path-or-glob>: <agent-name> — <reason>
```

Required ownership subsections (all three headings must exist even when empty):

- `### agent-owned`: files assigned to `Codex`, `Claude`, `Gemini`, `Grok`, `Antigravity`, or another named agent.
- `### user-reserved`: user-owned files; stop before editing.
- `### frozen`: protected files; stop before editing.

In v2.6.0+, `parse-ownership.py` keeps `Antigravity` (`antigravity`) and `Gemini` (`gemini`) strictly distinct, normalizes common aliases (`Claude Code`, `Gemini CLI`, `OpenAI Codex`, `Grok Build`, `Antigravity IDE`, `agy`) and parenthetical notes (`Claude (pending Phase 2)`), strips `./` prefixes, and relativizes absolute paths inside the handoff directory. Glob matching uses `fnmatch.fnmatchcase` where `*` crosses `/` (`scripts/*` matches `scripts/sub/foo.sh`); `**` is not recognized.

## Supported Platforms

Guardrail scripts (`check-ownership.sh`, `install-skill.sh`, `sync-skill.sh`, `lang.sh`) and Python helpers (`parse-ownership.py`, `hook-guard.py`) target **Bash (3.2+) and Python 3 on Linux and macOS** (also compatible with immutable Linux user-home hosts like Bluefin/Silverblue). CI runs `shellcheck` on `ubuntu-latest` and the 10-step verification matrix on `ubuntu-latest` and `macos-latest`. Native Windows is not supported.

## Install And Sync

Preview default install targets (`--codex`, `--agents`, `--grok`):

```bash
skills/cli-collaboration/scripts/install-skill.sh --dry-run
```

Install all non-colliding runtimes (**Codex**, **Agents** [also discovered by Gemini CLI], **Grok**, **Claude Code**, and **Antigravity**):

```bash
skills/cli-collaboration/scripts/install-skill.sh --all
```

Or target specific runtimes individually (`--codex`, `--agents`, `--grok`, `--claude`, `--antigravity`, `--gemini`, or `--target DIR`):

```bash
skills/cli-collaboration/scripts/install-skill.sh --antigravity
skills/cli-collaboration/scripts/install-skill.sh --claude
```

> **Note:** `--all` intentionally omits `~/.gemini/skills/cli-collaboration` because Gemini CLI already discovers `~/.agents/skills/cli-collaboration`, and having both causes duplicate-skill errors. Divergent pre-existing installations are backed up into a sibling `../skills-backups/` folder (outside `skills/`) and automatically rolled back if copying fails.

Check drift or synchronize installed copies:

```bash
skills/cli-collaboration/scripts/sync-skill.sh --all
skills/cli-collaboration/scripts/sync-skill.sh --all --install
```

## Check Ownership

Run before touching files near ownership boundaries:

```bash
skills/cli-collaboration/scripts/check-ownership.sh --agent Antigravity README.md
```

Exit codes:

- `0`: ownership structure valid and no conflict detected.
- `1`: conflict with `agent-owned`, `user-reserved`, or `frozen`.
- `2`: usage error, missing handoff, or malformed ownership section.

## Deterministic Hooks (Optional)

`skills/cli-collaboration/scripts/hook-guard.py` enforces the protocol programmatically across Antigravity, Claude Code, and Gemini CLI using ready-to-copy templates under `examples/hooks/`:

- **Antigravity:** `examples/hooks/antigravity.hooks.json` -> `.agents/hooks.json` or `~/.gemini/config/hooks.json` (`SessionStart`, `PreToolUse`, `Stop`).
- **Claude Code:** `examples/hooks/claude.settings.json` -> `.claude/settings.json` or `~/.claude/settings.json` (`SessionStart`, `PreToolUse`).
- **Gemini CLI:** `examples/hooks/gemini.settings.json` -> `.gemini/settings.json` or `~/.gemini/settings.json` (`SessionStart`, `BeforeTool`).

When `AGENT_HANDOFF.md` exists, the hook injects a compact session summary, denies edits to files owned by other agents / `user-reserved` / `frozen`, prompts before destructive git commands (`reset --hard`, `clean`, `checkout --`, non-staged `restore`, mutating `stash`), and validates modified handoffs on Antigravity `Stop`.

## Sandbox-Friendly Language Preference

`scripts/lang.sh` checks, in order:

1. Global config `${CLI_COLLAB_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/cli-collaboration/config.json}`
2. Project-local config `${CLI_COLLAB_LOCAL_CONFIG:-.cli-collaboration.json}` (via `lang.sh set <lang> --local`)
3. Environment variable `$CLI_COLLAB_LANG`

If `lang.sh set` runs inside a sandbox where `$HOME/.config` is read-only, it exits cleanly with code `4` instead of forcing elevated permissions; agents continue in the user's prompt language.

## Validation And Release Verification

Six behavioral scenarios (`A`–`F`) plus 14 trigger eval cases (`T1`–`T8`, `N1`–`N6`) are documented in `skills/cli-collaboration/references/validation-scenarios.md` and `evals/evals.json`. Mechanical checks run as a 10-step driver (`bash evals/run-mechanical-checks.sh`):

| Step | Gate | Target |
|---|---|---|
| 1/10 | Ownership parser fixtures (33 cases) | `skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` |
| 2/10 | Install rollback, `skills-backups/`, dry-run & sync (8 checks) | `skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh` |
| 3/10 | Language preference & sandbox fallback (34 assertions) | `skills/cli-collaboration/scripts/test-fixtures/lang-tests.sh` |
| 4/10 | Cross-CLI portability (Grok + Antigravity) | `skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh` |
| 5/10 | Deterministic hook guard & template fixtures (11 blocks) | `skills/cli-collaboration/scripts/test-fixtures/hook-guard-tests.sh` |
| 6/10 | `lint-handoff.py` unit tests (10 cases) + repo handoff lint | `evals/test-lint-handoff.sh` & `evals/lint-handoff.py` |
| 7/10 | Opt-in live eval harness deterministic self-test | `python3 evals/run-live-evals.py --self-test` |
| 8/10 | Strict `SKILL.md` frontmatter + YAML/JSON assets | Inline Python validator (`PyYAML` + `json`) |
| 9/10 | Markdown relative links & script `+x` integrity | Inline Python check across `SKILL.md`, `references/`, `scripts/` |
| 10/10 | `check-ownership.sh` multibyte source-guard | Inline Python byte check |

### Opt-In Live Agent Evaluation (Local)

To test real installed CLI/IDE agents against isolated temporary git sandboxes for Scenarios `A`–`F` and the 14 `trigger_evals` (not run in CI):

```bash
python3 evals/run-live-evals.py --cli agy --mode all --dry-run
python3 evals/run-live-evals.py --cli <claude|codex|gemini|agy|grok> --mode all --json-out /tmp/eval-report.json
```

## Updating And Maintenance

Future v3 sidecar infrastructure (advisory locks and derived state cache) remains deferred behind empirical thresholds in `docs/future-architecture.md` and uses `.cli-collaboration/` (not `.agent/`, which Antigravity reserves for workspace customizations).

## License

MIT License. See `LICENSE`.
