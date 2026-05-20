# cli-collaboration

`cli-collaboration` is a lightweight protocol for coordinating Codex, Claude Code, Gemini CLI, or one agent across multiple sessions in the same project.

The source of truth is `AGENT_HANDOFF.md`. Scripts are guardrails: they report drift, malformed ownership, and likely conflicts, but they do not replace agent judgment.

## What It Solves

- Preserves user and agent work in dirty worktrees.
- Supports the single-agent case: the handoff is project memory between sessions.
- Gives multiple CLI agents explicit file ownership and stop conditions.
- Prevents destructive cleanup from becoming the default response to uncertainty.
- Makes collaboration auditable: each agent reads the handoff first and updates it last.

## Workflow Summary

The final workflow was shaped by the discussion in `workflow.md`.

The shared conclusion is option C: the first agent should be chosen by task fit, not by a rigid rule about native skill loading. Codex is the natural first agent for scaffolding, scripts, tests, packaging, and release gates. Claude is the natural first agent for semantic protocol work, policy, templates, and reference writing. Gemini can bootstrap inert scaffolding or perform QA/red-team work as long as it creates or respects `AGENT_HANDOFF.md` immediately.

The recommended multi-LLM flow is handoff-first:

1. The first agent reads or creates `AGENT_HANDOFF.md`.
2. It declares the start gate: handoff read, current task, files to touch, expected red test, reserved zones, and stop condition.
3. Work is assigned by ownership and competence.
4. Each agent edits only its declared files.
5. Every handoff records files changed, tests red/green, open concerns, and the next concrete step.

The single-LLM case is first-class. Even when only one CLI is installed, `AGENT_HANDOFF.md` is still project memory between sessions, so the agent can resume from the last checkpoint instead of rediscovering state from scratch.

## Activation And Pause

The skill is designed to be effectively always available when collaboration state exists, but the exact trigger differs by CLI:

- Codex loads the skill through its skill metadata and `AGENTS.md` project guidance.
- Claude loads the skill through `SKILL.md` description matching, `CLAUDE.md`, and optional SessionStart hooks.
- Gemini loads the skill through `activate_skill`, `GEMINI.md`, or the Gemini adapter flow.
- All CLIs should treat the presence of `AGENT_HANDOFF.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, a dirty worktree, or a resume request as a trigger to apply the protocol.

Gemini's automatic trigger is the weakest of the three. When activation does not fire, copy the forced-activation prompt from `skills/cli-collaboration/references/gemini-adapter.md` into the session opener.

Slash commands such as `/cli-collaboration on` and `/cli-collaboration off` are useful UX, but they are not portable across CLIs. The cross-CLI pause mechanism is filesystem-based:

- `.cli-collaboration-off` in the project root.
- `**Status:** paused` in `AGENT_HANDOFF.md`.

Pause only reduces procedural overhead. It never authorizes destructive cleanup, overwriting someone else's work, or ignoring `user-reserved` and `frozen` ownership.

## How It Was Developed

The package was intentionally built by dogfooding the protocol it provides.

- Phase 1, Codex: implemented the core skill, scripts, fixtures, OpenAI metadata, Codex adapter, `README.md`, and technical eval wiring.
- Phase 2, Claude: implemented semantic references, handoff template, anti-patterns, validation scenarios, Claude adapter, Claude metadata, and examples.
- Phase 3, Gemini: implemented Gemini guidance and adapter content, then performed cross-CLI QA.
- Final Codex verification: re-ran release gates after Phase 2 and Phase 3, then refreshed package metadata where needed.

The division followed the final C-emendata decision:

- Codex owns package/tooling and final release gates.
- Claude owns semantic clarity and reference policy.
- Gemini owns Gemini-specific guidance and QA/red-team review.

## Package Structure

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

Ownership lines use this exact shape:

```text
- <path-or-glob>: <agent-name> — <reason>
```

The three ownership classes are:

- `agent-owned`: a named agent owns the file or glob.
- `user-reserved`: the user owns the file; stop before editing.
- `frozen`: the file is protected; stop before editing.

All three ownership headings must be present in `AGENT_HANDOFF.md`, even when a section is empty. The canonical ownership separator is an em-dash (`—`); the checker tolerates common dash variants but generated handoffs should use the canonical form. Ownership patterns are bash `case` patterns: `*` matches any sequence of characters including `/`, so `scripts/*` covers both `scripts/foo.sh` and `scripts/sub/foo.sh`; use explicit path segments when you need to scope to a single directory level. `**` is not a recognized token.

Concurrency: `AGENT_HANDOFF.md` has one active writer at a time in v2.2. Locking infrastructure is deferred to v3 and gated on a documented concurrent-write incident logged in the handoff history (see `docs/future-architecture.md`).

Destructive operations are explicitly banned unless the user asks for them:

- `git reset --hard`
- `git clean`
- unauthorized `git stash`
- `git restore`
- `git checkout --`
- lateral overwrite of files whose owner is unclear or contested

## Supported Platforms

The guardrail scripts (`check-ownership.sh`, `install-skill.sh`, `sync-skill.sh`) and the test fixtures target POSIX-compatible shells on Linux and macOS. CI exercises both `ubuntu-latest` and `macos-latest` via GitHub Actions (`.github/workflows/ci.yml`). Native Windows is not supported; WSL is not part of the test matrix and is not guaranteed to work.

## Install

Preview the default install targets:

```bash
skills/cli-collaboration/scripts/install-skill.sh --dry-run
```

Install to the default Codex and agents skill directories:

```bash
skills/cli-collaboration/scripts/install-skill.sh
```

Install to an explicit target:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.codex/skills/cli-collaboration"
```

For Claude Code:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.claude/skills/cli-collaboration"
```

For Gemini CLI:

```bash
skills/cli-collaboration/scripts/install-skill.sh --target "$HOME/.gemini/skills/cli-collaboration"
```

## Check Ownership

Use the checker before touching files named in `AGENT_HANDOFF.md`:

```bash
skills/cli-collaboration/scripts/check-ownership.sh --agent Codex README.md
```

Exit codes:

- `0`: ownership structure is valid and no conflict was detected.
- `1`: conflict with `agent-owned`, `user-reserved`, or `frozen`.
- `2`: usage error, malformed ownership section, or missing required subsection (`### agent-owned`, `### user-reserved`, and `### frozen` must all be present even when empty).

Examples:

```bash
# Validate a Codex-owned file.
skills/cli-collaboration/scripts/check-ownership.sh --handoff AGENT_HANDOFF.md --agent Codex README.md

# Detect a user-reserved conflict.
skills/cli-collaboration/scripts/check-ownership.sh --handoff AGENT_HANDOFF.md --agent Codex workflow.md

# Validate a Codex-owned single-level glob target.
skills/cli-collaboration/scripts/check-ownership.sh --handoff AGENT_HANDOFF.md --agent Codex skills/cli-collaboration/scripts/install-skill.sh
```

## Sync

Report drift against install targets:

```bash
skills/cli-collaboration/scripts/sync-skill.sh
```

Apply updates after reviewing drift:

```bash
skills/cli-collaboration/scripts/sync-skill.sh --install
```

The sync command is read-only by default and reports all missing or drifted targets before exiting.

## Validation Scenarios

The eval design has six scenarios, defined semantically in `skills/cli-collaboration/references/validation-scenarios.md` and wired in `evals/evals.json`.

- A: dirty worktree without handoff.
- B: existing plan but more specific handoff.
- C: ownership conflict.
- D: low context budget.
- E: vague handoff.
- F: user supersession.

Scenarios A-E include destructive-cleanup negative assertions wherever a dirty worktree, unfamiliar state, or ownership conflict could tempt cleanup as a shortcut. Scenario F focuses on user supersession and handoff continuity.

Fixture coverage in `run-tests.sh` is broader than the scenario count: it also includes parser-level cases (required-subsection enforcement and dash variant normalization) that test the checker contract independently of scenarios A-F.

## Updating And Maintenance

Future changes should preserve the same ownership model used to build the skill:

- Codex owns package/tooling files, install/sync/check scripts, metadata, release gates, `.gitignore`, `README.md`, and `evals/evals.json`.
- Claude owns semantic references, handoff template, anti-patterns, validation scenario prose, Claude adapter, and future-architecture policy.
- Gemini owns Gemini adapter/example content and QA/red-team review.

When changing eval behavior, update `skills/cli-collaboration/references/validation-scenarios.md` first, then mirror the technical wiring in `evals/evals.json`.

When changing script behavior, update `skills/cli-collaboration/references/codex-adapter.md` and rerun the fixture suite.

Potential v3 infrastructure, such as sidecar state files or locks, should only be promoted through the thresholds in `docs/future-architecture.md`.

When initializing this package as a Git repository, create `.gitignore` before the first commit. The default ignore list excludes `.handoff-backups/` so optional handoff snapshots do not add noise to diffs.

## Release-Time Verification

The package has passed these local verification gates. Most commands are directly reproducible from this repository; the skill package validation command requires the Codex `skill-creator` harness.

| Gate | Command | Result |
|---|---|---|
| Skill package validation | `python3 <skill-creator>/scripts/quick_validate.py skills/cli-collaboration` | pass |
| Bash syntax | `bash -n` on all scripts | pass |
| Ownership fixtures | `skills/cli-collaboration/scripts/test-fixtures/run-tests.sh` | pass, 7/7 |
| JSON validity | `python3 -m json.tool evals/evals.json` | pass |
| YAML validity | PyYAML parse of `SKILL.md`, `openai.yaml`, `claude.yaml` | pass |
| Install dry-run | `install-skill.sh --dry-run` | pass |
| Explicit install target | `tmp="$(mktemp -d)" && install-skill.sh --target "$tmp/cli-collaboration"` | pass |
| Explicit sync target | `sync-skill.sh --target "$tmp/cli-collaboration"` | pass after explicit install |
| Ownership guard | `check-ownership.sh --handoff AGENT_HANDOFF.md --agent Codex README.md evals/evals.json` | pass |

Git has been initialized for this workspace and the v2.2 baseline is committed on `main`.

The default installed skill directories may drift from this local package until the user runs `install-skill.sh` or `sync-skill.sh --install`.

## Release Readiness

The package is locally verified and ready to install. The recommended next operational steps are:

1. Add a Git remote if this repository should be published.
2. Push `main` to the remote.
3. Run `install-skill.sh --dry-run` before future local installs.
4. Add the relevant project guidance file (`AGENTS.md`, `CLAUDE.md`, or `GEMINI.md`) to projects that should enforce handoff-first collaboration.

## License

MIT License. See `LICENSE`.
