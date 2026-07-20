# Grok Build Adapter

Use this reference when installing, activating, or operating
`cli-collaboration` from Grok Build.

## Discovery And Activation

Grok discovers skills from project `.grok/skills/` directories walked up to
the repository root, the user directory `${GROK_HOME:-$HOME/.grok}/skills/`,
enabled plugins, and configured extra skill paths. It also reads compatible
Claude and `.agents` skill directories.

This skill activates when:

1. The user runs `/cli-collaboration` with optional context after the name.
2. The shared `SKILL.md` description matches a handoff or continuation task.
3. Project `AGENTS.md` tells Grok to apply the protocol.

For single-agent continuation, treat `AGENT_HANDOFF.md` as project memory
across Grok sessions.

## User Installation

The Grok user target is:

```text
${GROK_HOME:-$HOME/.grok}/skills/cli-collaboration
```

From the repository root, install only the Grok copy with:

```bash
skills/cli-collaboration/scripts/install-skill.sh \
  --target "${GROK_HOME:-$HOME/.grok}/skills/cli-collaboration"
```

With no `--target`, the installer updates the Codex, interoperable Agents, and
Grok user homes. Gemini CLI discovers the Agents alias, so no duplicate Gemini
copy is created. The sync script uses the same defaults.

On Bluefin, Fedora Silverblue, and other immutable hosts, keep the skill under
the mutable user home (commonly `/var/home/<user>`). Do not layer it into the
ostree or assume `/usr` is writable.

## Project Guidance

Add this to `AGENTS.md` when the repository should enforce collaboration:

```markdown
When `AGENT_HANDOFF.md` exists, read it before editing. Apply the
`cli-collaboration` skill: declare the start gate, respect `agent-owned`,
`user-reserved`, and `frozen` sections, run ownership checks with
`--agent Grok`, and update the handoff last.
```

## Agent Identity

Use these values consistently:

| Context | Value |
| --- | --- |
| Handoff `Agent:` field | `Grok` |
| `check-ownership.sh --agent` | `Grok` |
| `lang.sh set ... --by` | `Grok` |
| Environment override | `CLI_COLLAB_AGENT=Grok` |

Prefer the bare owner name `Grok`; model-version suffixes are unnecessary.

## Tool Mapping

| Protocol step | Grok tool |
| --- | --- |
| Read handoff | `read_file` |
| Git status and tests | `run_terminal_command` |
| Edit existing files | `search_replace` |
| Create a required file | `write` |
| Parallel research | subagents, with the parent as sole handoff writer |

Scripts resolve paths from their own location and can run from any working
directory. When the skill is installed, use an absolute skill-home path:

```bash
GROK_SKILL_HOME="${GROK_HOME:-$HOME/.grok}/skills/cli-collaboration"
"$GROK_SKILL_HOME/scripts/check-ownership.sh" --agent Grok \
  --handoff AGENT_HANDOFF.md <files...>
"$GROK_SKILL_HOME/scripts/lang.sh" get
```

## Pause, Safety, And Subagents

The portable pause mechanisms are `.cli-collaboration-off` and
`**Status:** paused` in the handoff. Pausing procedural overhead never permits
destructive cleanup.

Combine the protocol with Grok's action safety:

- Do not run `git reset --hard`, `git clean`, `git stash`, blind restore, or
  force-push without explicit user approval.
- Confirm external side effects such as pushes and PR comments.
- The parent session alone updates `AGENT_HANDOFF.md`; subagents report their
  files and test results to it.

## Verification

After installation:

```bash
test -f "${GROK_HOME:-$HOME/.grok}/skills/cli-collaboration/SKILL.md"
grok inspect --json
```

The inspection output should list `cli-collaboration` from the Grok user path
with `userInvocable` set to `true`.
