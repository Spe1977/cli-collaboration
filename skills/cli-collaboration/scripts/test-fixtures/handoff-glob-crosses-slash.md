# AGENT_HANDOFF.md

**Last updated:** 2026-05-20T11:00:00+02:00
**Last agent:** Codex
**Status:** in-progress

## Current task
Fixture proving that `*` in an ownership pattern matches `/`, so `scripts/*`
covers nested paths such as `scripts/sub/foo.sh`. This pins the parser's
bash `case`-pattern semantics as a tested contract.

## File ownership
### agent-owned
- scripts/*: Codex — tooling owner; pattern intentionally covers nested paths
### user-reserved
No user-reserved files currently declared.
### frozen
No frozen files currently declared.

## Next agent starts from
Run the ownership checker against `scripts/sub/foo.sh` with `--agent Codex`
and expect exit 0.
