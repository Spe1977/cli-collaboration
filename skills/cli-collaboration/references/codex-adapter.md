# Codex Adapter

Use this reference when installing, syncing, or operating `cli-collaboration` from Codex.

## Triggering

Codex should load this skill when a repo contains `AGENT_HANDOFF.md`, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, a dirty worktree from another session, or the user asks to resume shared work.

For single-agent continuation, treat `AGENT_HANDOFF.md` as persistent project memory across Codex sessions.

## Project Guidance

Add this to project `AGENTS.md` when the repo should enforce collaboration:

```markdown
When `AGENT_HANDOFF.md` exists, read it before editing. Declare the cli-collaboration start gate, respect `agent-owned`, `user-reserved`, and `frozen` sections, and update the handoff last.
```

## Pause And Resume

Preferred cross-CLI pause mechanisms:

- `.cli-collaboration-off` in the project root.
- `**Status:** paused` at the top of `AGENT_HANDOFF.md`.

Pause only disables procedural overhead. It never permits destructive cleanup or overwrite of existing work.

## Script ABI

All scripts expect to run from any cwd and resolve paths from their own location unless a path flag is supplied.

- `scripts/check-ownership.sh [--handoff PATH] [--agent NAME] FILE...`
  - `0`: valid ownership and no conflict detected.
  - `1`: conflict with `agent-owned`, `user-reserved`, or `frozen`.
  - `2`: usage error, missing handoff, or malformed ownership section.
  - **Implementation note (v2.3.0)**: `check-ownership.sh` is a thin Bash wrapper that delegates to `scripts/parse-ownership.py`. Python 3 is therefore a runtime dependency of the ownership check. The CLI contract above (flags, env var, exit codes, conflict-message wording) is unchanged; only the implementation moved out of Bash, because macOS Bash 3.2.57 proved unreliable on multibyte UTF-8 input (en-dash, em-dash) across seven distinct Bash-side mitigations.
- `scripts/install-skill.sh [--dry-run] [--source DIR] [--target DIR ...]`
  - Dry-run prints planned copies.
  - Non-dry-run backs up divergent targets before copying.
- `scripts/sync-skill.sh [--install] [--source DIR] [--target DIR ...]`
  - Read-only by default.
  - Reports all missing or drifted targets before exiting.
  - `--install` delegates updates to `install-skill.sh`.

Default install targets are `${CODEX_HOME:-$HOME/.codex}/skills/cli-collaboration` and `${AGENTS_HOME:-$HOME/.agents}/skills/cli-collaboration`.

## Ownership Format

`check-ownership.sh` parses this exact line shape under `## File ownership`:

```text
- <path-or-glob>: <agent-name> — <reason>
```

The `### agent-owned`, `### user-reserved`, and `### frozen` headings are all required, even when a section is empty. Empty sections may use prose such as `No frozen files currently declared.` under the heading.

The canonical separator is the em-dash (`—`). The parser (v2.3.0+, Python) extracts the owner as the first whitespace-delimited token after the colon and ignores the separator entirely, so en-dash (`–`), em-dash (`—`), ASCII hyphen (`-`), and double-hyphen (`--`) all work interchangeably. Generated handoffs should still use the canonical em-dash for stylistic consistency.

Globs use bash `case`-pattern semantics: `*` matches any sequence of characters **including `/`**, so `scripts/*` covers nested paths such as `scripts/sub/foo.sh`. Use explicit path segments when you want to scope to a single directory level. `**` is not a recognized token. Agent names may include parenthetical annotations; the parser strips them for comparison, so `Claude (pending Phase 2)` compares as `Claude`.

Only one active writer should update `AGENT_HANDOFF.md` at a time. If a concurrent write is observed, record the incident in `AGENT_HANDOFF.md` history; `docs/future-architecture.md` defines when to promote the protocol to flock-based locking.
