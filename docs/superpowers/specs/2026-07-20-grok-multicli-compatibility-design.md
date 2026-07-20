# Grok Multi-CLI Compatibility Design

## Decision

Release `cli-collaboration` 2.5.0 as one portable package for Codex, Claude
Code, Gemini CLI, Grok Build, and single-agent continuation. Grok support is
additive: the shared protocol stays runtime-neutral, while runtime-specific
paths, tools, and activation details live in adapters.

## Goals

- Preserve the v2.4 handoff, ownership, pause, language, and script contracts.
- Make Grok Build discover the skill from `~/.grok/skills/` and expose
  `/cli-collaboration` without making other installed copies identify as Grok.
- Keep one `SKILL.md` valid for both the Codex package validator and Grok Build.
- Restore a clean, reviewable Git diff with correct file modes and synchronized
  English and Italian documentation.
- Add deterministic regression coverage for Grok installation and agent
  identity before changing implementation behavior.

## Non-Goals

- No Grok-only fork or duplicated Grok wrapper skill.
- No changes to the ownership file format, pause sentinels, language config, or
  behavioral scenarios A-F.
- No push, tag, release, or modification of the user-reserved source files.
- No automatic overwrite of installed CLI copies outside the repository.

## Architecture

### Shared core

`skills/cli-collaboration/SKILL.md` remains the canonical protocol. Its
frontmatter uses the cross-runtime subset: `name`, a trigger-focused
`description`, and string-valued `metadata` containing version and display
information. Grok-only optional keys are unnecessary because Grok defaults
skills to user-invocable and can derive automatic invocation from the shared
description.

The body uses placeholders for the active agent identity and lists all four
runtime adapters. It never hardcodes Grok paths or Grok tools in steps that are
also installed for Codex, Claude, or Gemini.

### Grok adapter

`references/grok-adapter.md` owns Grok-specific discovery paths, tool names,
`GROK_HOME`, Bluefin/Silverblue guidance, slash-command behavior, and the
explicit `--agent Grok` convention. `agents/grok.yaml` remains
documentation-only metadata and says so plainly.

### Installer and synchronization

With no explicit `--target`, `install-skill.sh` and `sync-skill.sh` operate on
three non-duplicating user homes: Codex, Agents, and Grok. Current Gemini CLI
releases discover `~/.agents/skills` as an alias of `~/.gemini/skills`, with
the Agents alias taking precedence, so a second default Gemini copy would emit
a duplicate-skill warning. Explicit targets retain their existing behavior;
Gemini-only, Antigravity, and Claude installations remain explicit.

The installer retains source validation and rollback semantics. The rollback
fixture supplies a valid minimal `SKILL.md`, so it reaches and tests the copy
failure it claims to cover. The ownership parser keeps `Codex` as its historical
default; every other runtime passes its identity explicitly.

## Test Design

Tests are written before production edits and must first fail against the Grok
overlay currently in the working tree.

1. Extend the rollback fixture so a valid source reaches the forced copy
   failure; verify exit `3`, restoration, and no stale backup.
2. Add a portability fixture covering:
   - default install and sync across Codex, Agents (including Gemini discovery),
     and Grok homes without duplicate aliases;
   - default ownership identity remains Codex;
   - explicit `--agent Grok` accepts Grok-owned files and rejects other owners;
   - shared frontmatter contains only validator-compatible keys.
3. Wire the portability fixture into `evals/run-mechanical-checks.sh` and CI's
   existing all-shell-script lint discovery.
4. Validate the finished package with the Codex `quick_validate.py` harness and
   a temporary `GROK_HOME` followed by `grok inspect --json`.
5. Run ownership, language, mechanical, syntax, structured-data, whitespace,
   and file-mode checks.

## Documentation and Release State

- Use version `2.5.0` consistently in `SKILL.md`, both READMEs, and CHANGELOG.
- Describe Grok as the fourth supported runtime and document its explicit
  adapter and install target.
- Keep examples agent-neutral and update placeholders to include Grok.
- Credit the Grok compatibility contribution without describing the package as
  Grok-native.
- Ignore `.claude/settings.local.json`; leave `cli-collaboration.png` untouched.
- Update `AGENT_HANDOFF.md` last with exact files, tests, limitations, and the
  next GitHub step.

## Success Criteria

- Codex package validation exits `0`.
- Grok 0.2.106 discovers the temporary installed package as user-invocable.
- The complete mechanical suite and all standalone fixtures exit `0`.
- `git diff --check` is clean, non-script files retain mode `100644`, and only
  intentional content changes remain.
- README, README_IT, CHANGELOG, adapters, examples, and script behavior agree.
