# Grok Multi-CLI Compatibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Release one validator-clean `cli-collaboration` 2.5.0 package that adds Grok Build without changing the identity or default behavior of Codex, Claude Code, or Gemini CLI.

**Architecture:** Keep the protocol and frontmatter runtime-neutral; place Grok paths, tools, and identity in a dedicated adapter. Extend the existing installer's default target set from three homes to four, preserve the historical ownership-parser default, and enforce the contract with a new portability fixture wired into the mechanical release gate.

**Tech Stack:** Markdown/YAML skill package, Bash guardrail scripts, Python 3 ownership parser and validation helpers, GitHub Actions on Linux/macOS, Grok Build `grok inspect`.

---

### Task 1: Lock the portable contract with failing tests

**Files:**
- Create: `skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh`
- Modify: `skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh`
- Modify: `evals/run-mechanical-checks.sh`

- [x] **Step 1: Add the portability fixture**

Create a Bash test that uses a temporary directory and asserts:

```bash
GROK_HOME="$WORK/grok" CODEX_HOME="$WORK/codex" \
AGENTS_HOME="$WORK/agents" GEMINI_HOME="$WORK/gemini" \
  "$INSTALL_SH"

for root in grok codex agents gemini; do
  test -f "$WORK/$root/skills/cli-collaboration/SKILL.md"
done
```

It must also parse `SKILL.md` and reject frontmatter outside `name`,
`description`, and `metadata`; verify the checker defaults to Codex; verify
`--agent Grok` accepts a Grok-owned fixture; and reject a Grok-specific heading
or hardcoded `Agent: Grok` in the shared core.

- [x] **Step 2: Run the new fixture and confirm RED**

Run:

```bash
bash skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh
```

Expected: FAIL against the current overlay because default installation only
creates the Grok target, the parser defaults to Grok, the core is Grok-native,
and the shared frontmatter contains Grok-only keys.

- [x] **Step 3: Repair the rollback fixture's precondition**

Add a minimal valid source manifest before invoking the installer:

```bash
printf '%s\n' '---' 'name: cli-collaboration' \
  'description: rollback fixture' '---' > "$SRC/SKILL.md"
```

This is a test correction, not the production fix: it makes the fixture reach
the forced copy failure and preserve its exit-3 rollback assertion.

- [x] **Step 4: Wire the portability fixture into the mechanical gate**

Require the new script in `evals/run-mechanical-checks.sh`, insert it after the
ownership fixtures, renumber the step labels, and keep the final success line.

- [x] **Step 5: Re-run the mechanical gate and confirm production assertions remain RED**

Run:

```bash
bash evals/run-mechanical-checks.sh
```

Expected: rollback passes; portability fails for the current Grok-specific
implementation.

### Task 2: Restore the runtime-neutral skill contract

**Files:**
- Modify: `skills/cli-collaboration/SKILL.md`
- Modify: `skills/cli-collaboration/scripts/parse-ownership.py`
- Modify: `examples/AGENTS.md`

- [x] **Step 1: Replace Grok-only frontmatter with the shared subset**

Use:

```yaml
---
name: cli-collaboration
description: "Use when multiple CLI agents or assistants alternate on the same repository or explicit shared handoff workflow — especially with AGENT_HANDOFF.md, side-by-side AGENTS.md/CLAUDE.md/GEMINI.md, dirty worktrees, ownership notes, red tests, resume/continue requests, or /cli-collaboration in Grok Build."
metadata:
  version: "2.5.0"
  short-description: "Safe multi-agent handoffs via AGENT_HANDOFF.md"
---
```

- [x] **Step 2: Restore the shared protocol body and add Grok only at neutral extension points**

Keep the v2.4 protocol, add `Grok` to agent examples and end-of-shift
placeholders, and route Grok-specific operations to
`references/grok-adapter.md`. Remove `$GROK_SKILL_HOME`, Grok tool tables,
Bluefin notes, and `Agent: Grok` from the shared body.

- [x] **Step 3: Restore historical parser behavior**

Set:

```python
agent = os.environ.get("CLI_COLLAB_AGENT", "Codex")
```

- [x] **Step 4: Make the AGENTS.md example runtime-neutral**

Use `--agent <CURRENT_AGENT_NAME>` and list Codex, Claude, Gemini, and Grok as
valid identities instead of forcing Grok.

- [x] **Step 5: Run the focused portability fixture**

Expected: frontmatter, neutrality, and identity assertions pass; installer
target assertions remain red until Task 3.

### Task 3: Make install and sync additive

**Files:**
- Modify: `skills/cli-collaboration/scripts/install-skill.sh`
- Modify: `skills/cli-collaboration/scripts/sync-skill.sh`
- Modify: `skills/cli-collaboration/references/codex-adapter.md`
- Modify: `skills/cli-collaboration/references/grok-adapter.md`
- Modify: `skills/cli-collaboration/agents/grok.yaml`

- [x] **Step 1: Restore the stable installer ABI with non-duplicating Codex, Agents, and Grok defaults**

With no `--target`, construct exactly:

```bash
targets+=("${CODEX_HOME:-$HOME/.codex}/skills/cli-collaboration")
targets+=("${AGENTS_HOME:-$HOME/.agents}/skills/cli-collaboration")
targets+=("${GEMINI_HOME:-$HOME/.gemini}/skills/cli-collaboration")
targets+=("${GROK_HOME:-$HOME/.grok}/skills/cli-collaboration")
```

Keep the source `SKILL.md` validation and rollback exit contract. Remove the
unpublished `--multi-cli` branch, extra Gemini config target, incomplete system
path denylist, and false copy-exclusion comment. Use the previously tested
portable `cp -R` behavior.

- [x] **Step 2: Mirror the same non-duplicating target policy in sync-skill.sh**

Preserve read-only drift reporting and pass computed targets explicitly when
delegating `--install`.

- [x] **Step 3: Align adapter documentation**

Document the Codex, Agents, and Grok defaults in the Codex adapter, including
the Gemini alias precedence rule. In the Grok adapter, describe the
shared package, official `.grok`, `.agents`, and Claude-compatible discovery,
explicit `--agent Grok`, Bluefin-safe user paths, and commands without
`--multi-cli`.

- [x] **Step 4: Keep Grok YAML explicitly documentary**

Ensure `agents/grok.yaml` does not claim to be a consumed loader surface.

- [x] **Step 5: Run portability and mechanical tests**

Expected: both exit `0`.

### Task 4: Synchronize release documentation and examples

**Files:**
- Modify: `README.md`
- Modify: `README_IT.md`
- Modify: `CHANGELOG.md`
- Modify: `CONTRIBUTORS.md`
- Modify: `CONTRIBUTORS_IT.md`
- Modify: `skills/cli-collaboration/references/handoff-template.md`
- Modify: `skills/cli-collaboration/references/alternate-workflows.md`
- Modify: `.gitignore`

- [x] **Step 1: Update version and support statements**

Set every current release reference to `2.5.0`, list Grok as the fourth
runtime, add `grok.yaml` and `grok-adapter.md` to package trees, and document
the non-duplicating default install/sync targets plus explicit Antigravity and
Claude targets in both READMEs.

- [x] **Step 2: Rewrite the 2.5.0 changelog entry as an additive release**

Credit Grok's initial port while recording the final portable frontmatter,
adapter, installer target, regression coverage, and Bluefin-safe path.

- [x] **Step 3: Update contributor and handoff placeholders**

Add Grok to contributor records and to `<Codex | Claude Code | Gemini CLI |
Grok | other>` placeholders without changing protocol semantics.

- [x] **Step 4: Ignore local Claude permission state**

Add `.claude/settings.local.json` to `.gitignore`. Do not delete or publish the
file, and do not touch `cli-collaboration.png`.

- [x] **Step 5: Run documentation consistency searches**

Search for stale `2.4.0`, `Grok-native`, forced `Agent: Grok`, old default
target descriptions, and `--multi-cli`; retain historical changelog references
only where they describe earlier releases.

### Task 5: Normalize file modes and validate both runtimes

**Files:**
- Normalize tracked file modes according to the Git index
- Modify last: `AGENT_HANDOFF.md`

- [x] **Step 1: Restore tracked non-script modes**

For every tracked index entry with mode `100644`, remove accidental executable
bits. Preserve `100755` only for executable scripts already marked executable
in the index and the new fixture script.

- [x] **Step 2: Run all local release gates**

Run:

```bash
bash skills/cli-collaboration/scripts/test-fixtures/run-tests.sh
bash skills/cli-collaboration/scripts/test-fixtures/install-rollback-test.sh
bash skills/cli-collaboration/scripts/test-fixtures/lang-tests.sh
bash skills/cli-collaboration/scripts/test-fixtures/grok-portability-tests.sh
bash evals/run-mechanical-checks.sh
python3 <skill-creator>/scripts/quick_validate.py skills/cli-collaboration
git diff --check
```

Also run Bash syntax, Python compilation without `.pyc` output, JSON/YAML
parsing, and ShellCheck when available.

- [x] **Step 3: Validate real Grok discovery from a temporary home**

Install to temporary Codex/Agents/Gemini/Grok roots, set `GROK_HOME` to the
temporary Grok root, run `grok inspect --json`, and assert
`cli-collaboration` is found at that temporary path with `userInvocable: true`.

- [x] **Step 4: Review the final diff and status**

Confirm only intentional content changes, the two approved design/plan files,
the new Grok files, and the new test remain. Confirm `.claude/settings.local.json`
is ignored and `cli-collaboration.png` remains untouched and untracked.

- [x] **Step 5: Update the handoff last**

Record user supersession for cross-owned documentation, exact files changed,
green/red tests, the unavailable-local-tool caveat if ShellCheck remains
missing, and the next step: review then commit/push to GitHub.
