# Codex Adapter

Use this reference when installing, syncing, or operating `cli-collaboration` from Codex.

## Triggering

Codex should load this skill when a repo contains `AGENT_HANDOFF.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, a dirty worktree from another session, or the user asks to resume shared work.

For single-agent continuation, treat `AGENT_HANDOFF.md` as persistent project memory across Codex sessions.

## Project Guidance

Add this to project `AGENTS.md` when the repo should enforce collaboration (see `examples/AGENTS.md`):

```markdown
When `AGENT_HANDOFF.md` exists, read it before editing. Declare the cli-collaboration start gate, respect `agent-owned`, `user-reserved`, and `frozen` sections, and update the handoff last.
```

## Pause And Resume

Preferred cross-CLI pause mechanisms:

- `.cli-collaboration-off` in the project root.
- `**Status:** paused` at the top of `AGENT_HANDOFF.md`.

Pause only disables procedural overhead. It never permits destructive cleanup or overwrite of existing work.

## Script ABI

All scripts expect to run from any cwd and resolve paths from their own location (`<SKILL_DIR>/scripts/`) unless a path flag is supplied.

- `scripts/check-ownership.sh [--handoff PATH] [--agent NAME] FILE...`
  - `0`: valid ownership and no conflict detected.
  - `1`: conflict with `agent-owned`, `user-reserved`, or `frozen`.
  - `2`: usage error, missing handoff, or malformed ownership section.
  - **Implementation note (v2.3.0+):** `check-ownership.sh` is a thin Bash wrapper delegating to `scripts/parse-ownership.py` (Python 3 runtime dependency). In v2.6.0, `parse-ownership.py` also strips `./` prefixes, relativizes absolute paths within the handoff directory, and normalizes agent aliases (`OpenAI Codex` -> `codex`, `Claude Code` -> `claude`, `Gemini CLI` -> `gemini`, `Grok Build` -> `grok`, `Antigravity IDE` / `agy` -> `antigravity`, keeping `antigravity` and `gemini` distinct).
- `scripts/install-skill.sh [--dry-run] [--source DIR] [--target DIR ...] [--codex] [--agents] [--grok] [--claude] [--antigravity] [--gemini] [--all]`
  - Dry-run prints planned copies.
  - Non-dry-run backs up divergent pre-existing targets to a sibling `../skills-backups/` directory (outside `skills/`) before copying, and rolls back automatically on failure (exit `3`).
  - Default targets (when no `--target` or preset flag is given): `${CODEX_HOME:-$HOME/.codex}/skills/cli-collaboration`, `${AGENTS_HOME:-$HOME/.agents}/skills/cli-collaboration`, and `${GROK_HOME:-$HOME/.grok}/skills/cli-collaboration`.
  - `--all` targets Codex, Agents, Grok, Claude, and Antigravity (`~/.gemini/skills` stays explicit opt-in via `--gemini` to avoid Gemini duplicate-skill conflicts with `~/.agents/skills`).
- `scripts/sync-skill.sh [--install] [--source DIR] [--target DIR ...] [preset flags...]`
  - Read-only by default; reports `in-sync`, `drift`, or `missing` for every target.
  - `--install` delegates updates to `install-skill.sh`.
- `scripts/lang.sh {get|set <lang> [--force] [--local] [--by NAME]|ensure-noninteractive}`
  - `get` checks global `${CLI_COLLAB_CONFIG_FILE:-${XDG_CONFIG_HOME:-$HOME/.config}/cli-collaboration/config.json}`, then project-local `${CLI_COLLAB_LOCAL_CONFIG:-.cli-collaboration.json}`, then `$CLI_COLLAB_LANG`, returning `3` if unset.
  - `set --local` writes project-local `.cli-collaboration.json`; `set` exits cleanly with `4` if the target config directory is read-only or sandboxed.
- `scripts/hook-guard.py --runtime <antigravity|claude|gemini> --event <session-start|pre-tool|stop> [--agent NAME] [--destructive-mode ask|deny]`
  - Stdlib-only deterministic guardrail script importing `parse-ownership.py` directly; emits runtime-native hook JSON on stdout.

## Ownership Format

`check-ownership.sh` parses this exact line shape under `## File ownership`:

```text
- <path-or-glob>: <agent-name> — <reason>
```

The `### agent-owned`, `### user-reserved`, and `### frozen` headings are all required, even when a section is empty. Empty sections may use prose such as `No frozen files currently declared.` under the heading.

The canonical separator is the em-dash (`—`). The parser ignores the separator (`—`, `–`, `--`, or ` - `) and extracts the owner phrase prior to it, stripping parenthetical notes and normalizing recognized aliases (`Claude (pending Phase 2)` -> `claude`, `Antigravity IDE` -> `antigravity`). Generated handoffs should still use the canonical em-dash for stylistic consistency.

Globs use bash `case`-pattern semantics: `*` matches any sequence of characters **including `/`**, so `scripts/*` covers nested paths such as `scripts/sub/foo.sh`. Use explicit path segments when you need to scope to a single directory level. `**` is not a recognized token.

Only one active writer should update `AGENT_HANDOFF.md` at a time. If a concurrent write is observed, record the incident in `AGENT_HANDOFF.md` history; `docs/future-architecture.md` defines when to promote the protocol to flock-based locking.

## Language Preference (documentary)

Binding behavior lives in `SKILL.md` → `## Language Preference`. Run `<SKILL_DIR>/scripts/lang.sh get`; if unset and writable, ask `Choose your language:` in English and run `scripts/lang.sh set "<answer>" --by CODEX` (or continue in the user's prompt language if sandboxed / exit `4`).
