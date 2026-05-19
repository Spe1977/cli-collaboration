# Future Architecture: v3 Thresholds and Sidecar Policy

The v2.2 protocol is intentionally minimal: `AGENT_HANDOFF.md` is a human-readable markdown document, scripts are best-effort guardrails, and no machine-state lives inside the handoff. This is a deliberate trade-off, not an oversight. Earlier proposals (the Gemini v3.0 Enterprise direction) considered embedded YAML state objects, POSIX locks, and MCP readiness probes inside the handoff; the consortium voted these *out* of the v1 default because they would pay a permanent complexity cost for problems that have not yet been observed in practice.

This document records the empirical thresholds that would justify promoting v3 features, and the design those features would take if the thresholds trip.

## Principle

`AGENT_HANDOFF.md` remains the narrative contract. Any machine-state that future agents need is a **cache**, not a source of truth: it must be reconstructible from the handoff and the repository state at any time. The handoff is authoritative; sidecar files are derivative.

This principle survives any v3 promotion. Even with a sidecar, deleting the sidecar must never destroy information that cannot be recovered from the handoff plus `git`.

## Thresholds for v3 Promotion

Promote a v3 feature only when at least one of the following thresholds trips in observed use, not in speculation:

### Threshold 1 — Race-condition evidence

At least **one documented concurrent-write incident** on `AGENT_HANDOFF.md`, recorded in `AGENT_HANDOFF.md` history, is enough to promote a small opt-in flock-based guardrail for that project. At least **two write conflicts** within **50 multi-agent turns** is enough to promote the lock design below as the default v3 behavior. A "write conflict" is any of:

- two agents producing diverging end-of-shift blocks for the same shift,
- one agent overwriting another's pending edits without merge,
- a `git` merge conflict on the handoff that required manual resolution.

Single isolated incidents should first promote the minimum opt-in guardrail, not the whole v3 lock suite. Recurring incidents prove the problem is structural and justify making locking the default.

**If tripped:** introduce `.agent/lock` (described below). Do not introduce in-handoff state objects.

## Concurrency

The v2.2 rule is procedural: exactly one active writer updates `AGENT_HANDOFF.md` at a time, and parallel agents report back to that writer instead of mutating the handoff directly.

Promote to flock-based locking when at least one concurrent-write incident is documented in `AGENT_HANDOFF.md` history. The first implementation should be opt-in and scoped to write coordination only; it must not introduce machine state inside `AGENT_HANDOFF.md`.

### Threshold 2 — Handoff bloat

`AGENT_HANDOFF.md` exceeds **4,000 tokens** in normal use, *despite* the "last 3 detailed blocks + one-line summaries for older shifts" rule being followed. Token count is measured with the canonical tokenizer of the targeted CLI (cl100k for Claude/OpenAI as of 2026); approximate counts above this threshold count.

**If tripped:** introduce a separate `docs/handoff-archive.md` for shifts older than the last 30 days, leaving `AGENT_HANDOFF.md` lean. Do not split the handoff into machine and human halves; keep one narrative file plus an archive.

### Threshold 3 — Structured tooling adoption

At least **two CLI targets** consume `AGENT_HANDOFF.md` through structured channels (MCP resources, programmatic file readers in tooling, dashboards) and would benefit from a parsed representation rather than the raw markdown.

**If tripped:** generate a `.agent/state.json` sidecar (described below) on every end-of-shift, derived from the markdown. The markdown remains authoritative; the JSON is regenerated from it.

### Threshold 4 — Recurring eval failure

Scenarios C (ownership conflict) or F (user supersession) — from `references/validation-scenarios.md` — fail repeatedly in eval runs **after** the core protocol has been hardened (clarified anti-patterns, tightened start-gate wording, improved adapter notes). "Repeatedly" means three consecutive failures across separate eval runs on the same scenario.

**If tripped:** the failure mode is structural, not semantic. Introduce machine-checkable constraints: a stricter parser for `## File ownership`, automated supersession-note linting, or a CI check that rejects handoffs missing required fields.

## Sidecar Design

If any threshold trips, the v3 evolution lives in a `.agent/` directory at the repository root. It is git-ignored by default; downstream projects may opt into committing it.

```text
.agent/
├── state.json          # parsed handoff state, regenerated on every end-of-shift
└── lock                # advisory lock, only present when an agent is mid-shift
```

### `.agent/state.json`

A derived representation of the current `AGENT_HANDOFF.md`. Schema sketch:

```jsonc
{
  "schema_version": "1.0",
  "generated_at": "2026-05-19T11:18:50+02:00",
  "generated_from": "AGENT_HANDOFF.md",
  "generated_from_sha256": "<hash of AGENT_HANDOFF.md at generation time>",
  "last_updated": "2026-05-19T11:18:50+02:00",
  "last_agent": "Codex",
  "status": "in-progress",
  "ownership": {
    "agent_owned": [
      { "pattern": "scripts/*", "agent": "Codex", "reason": "tooling lead" }
    ],
    "user_reserved": [
      { "pattern": ".env", "reason": "secrets" }
    ],
    "frozen": []
  },
  "next_agent": "Claude",
  "next_action_file": "skills/cli-collaboration/references/handoff-template.md"
}
```

**Hard rule:** every consumer must verify `generated_from_sha256` against the current hash of `AGENT_HANDOFF.md` before trusting the cache. If they diverge, the cache is stale and the consumer must re-parse the markdown directly.

`state.json` is never edited by hand. The script that generates it from the markdown is the only writer. If a future agent finds themselves editing `state.json` to change behavior, the protocol is being violated.

### `.agent/lock`

An advisory POSIX lock file, created with `mkdir .agent/lock` (atomic on POSIX filesystems) when an agent starts a shift and removed at end-of-shift. Schema for the lock contents (one file: `.agent/lock/owner`):

```text
agent: Codex
pid: 42813
hostname: dev-box
started_at: 2026-05-19T11:00:00+02:00
heartbeat_at: 2026-05-19T11:15:00+02:00
```

**Stale-lock recovery is mandatory.** A lock whose `heartbeat_at` is older than **15 minutes** is considered stale and may be force-removed by the next agent. The forcing agent records the removal in `AGENT_HANDOFF.md` under `## Open concerns` with the previous owner's identity, so the displaced agent can detect on return that its shift was interrupted.

The lock is **advisory**, not enforcing. Agents that ignore it can still write to `AGENT_HANDOFF.md` directly; the lock exists to detect collisions, not prevent them at the filesystem level. This matches the principle: the handoff is authoritative, the lock is signal.

## What v3 Does NOT Add

To prevent scope creep when one threshold trips and an agent considers expanding beyond it:

- **No Zone A inside `AGENT_HANDOFF.md`.** The Gemini v3.0 proposal embedded machine-state inside the handoff itself. The v2.2 consortium rejected this: it makes the file unreadable as a narrative document and trains agents to treat parts of it as parseable structure when other parts are not.
- **No mandatory MCP integration.** MCP support is a feature of specific CLIs, not a requirement of the protocol. The skill must remain usable from any CLI that can read markdown and run bash.
- **No automatic conflict resolution.** Even with locks and state caches, ownership conflicts (scenario C) remain the user's decision. The protocol surfaces conflicts; it does not resolve them.
- **No removal of the markdown narrative.** Whatever v3 adds, `AGENT_HANDOFF.md` stays as a human-readable document. If a future change makes the markdown obsolete, that is a v4 conversation, not a v3 one.

## Promotion Procedure

When a threshold trips:

1. **Document the trip.** Add an entry to `docs/eval-history/` (or equivalent) naming the threshold, the evidence, and the date. Do not implement v3 features speculatively.
2. **Propose the minimum v3 increment.** One threshold trips one feature, not the entire v3 suite. Threshold 1 → lock only. Threshold 3 → state.json only.
3. **Get cross-CLI ratification.** Per the original consortium agreement, structural changes require Codex + Claude + Gemini review. Use `AGENT_HANDOFF.md` itself as the coordination channel (dogfood the protocol on its own evolution).
4. **Implement behind a feature flag** for at least one minor version cycle. Existing v2.2 projects must keep working without the new feature; the v3 feature must be opt-in.
5. **Update this document** with the threshold trip, the implementation date, and any thresholds that did not yet trip (so the boundary between v2.2 and v3 remains visible).

## Current Status

As of the v2.2 release, **no threshold has tripped**. No v3 feature is implemented. This document exists to ensure that when a threshold does trip, the response is proportionate, well-scoped, and consistent with the principles that made v2.2 the chosen design.
