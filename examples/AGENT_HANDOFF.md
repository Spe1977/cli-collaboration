# AGENT_HANDOFF.md

**Last updated:** 2026-04-22T16:45:00+02:00
**Last agent:** Claude Code
**Status:** in-progress

> This is an illustrative example, not a live handoff. It shows what a healthy multi-agent handoff looks like after three shifts on a hypothetical project. Copy `references/handoff-template.md` instead of this file when starting your own project.

## Current task
Phase 2 of the `auth-service` rebuild: introduce passkey support alongside the existing password flow. This shift wrote the protocol-level documentation and the failing integration test; the actual handler implementation is the next shift's job.

## Current state
- Project goal frozen on 2026-04-15: passkeys must coexist with passwords for at least one release. No "passkey-only" path in v2.
- WebAuthn library choice frozen: `@simplewebauthn/server` v9 (decided after benchmark, see `docs/decisions/2026-04-18-webauthn-library.md`).
- DB migration `0042_passkey_credentials.sql` is committed and reviewed; the schema is now considered a frozen contract for any code touching credential storage.
- Failing integration test added today is intentionally red: `tests/auth/passkey_register.test.ts::registers a new passkey and returns 200`. Do not delete it — it is the handoff artifact for the next shift.
- One pending decision: should the registration endpoint live under `/auth/passkey/register` or `/auth/webauthn/register`? Awaiting product owner reply (asked 2026-04-22, no response yet).

## File ownership
### agent-owned
- src/auth/passkey/*: Codex — handler implementation, depends on the failing test
- src/auth/passkey/handlers/*: Codex — endpoint wiring
- tests/auth/passkey/*: Claude — test specs and assertions
- docs/auth/passkey.md: Claude — protocol-level documentation
- migrations/0042_passkey_credentials.sql: Codex (frozen-after-review) — schema contract
- scripts/dev/seed-passkey-fixtures.sh: Gemini — dev fixture seeding

### user-reserved
- .env: user — secrets and local config
- docs/decisions/*: user — architectural decision records, append-only

### frozen
- migrations/0042_passkey_credentials.sql: frozen — schema reviewed and shipped to staging on 2026-04-20

## Files changed this shift
- docs/auth/passkey.md: rewrote the protocol overview, added the registration sequence diagram, documented the cross-device fallback.
- tests/auth/passkey/passkey_register.test.ts: added the intentionally-red integration test covering the registration happy path.
- AGENT_HANDOFF.md: end-of-shift update (this block).

## Tests
- Red: `tests/auth/passkey/passkey_register.test.ts::registers a new passkey and returns 200` — fails because `src/auth/passkey/handlers/register.ts` does not exist yet. Expected: handler that calls `@simplewebauthn/server`'s `generateRegistrationOptions` and returns 200 with the challenge JSON. Currently: 404.
- Green: full pre-existing suite (`npm test -- --testPathIgnorePatterns=passkey`) — 142 passing.

## Open concerns
- Endpoint path decision still pending (see `## Current state`). The failing test currently asserts `/auth/passkey/register`; if product picks `/auth/webauthn/register`, the test needs a one-line update before Codex starts.
- The `@simplewebauthn/server` v9 API differs from v8 in challenge encoding. Codex must verify the test's expected response shape matches v9, not v8 (the docs cache may still show v8 examples).
- Gemini's seed script (`scripts/dev/seed-passkey-fixtures.sh`) uses hard-coded user IDs that collide with the test fixture loader. Not blocking, but worth fixing in the next Gemini shift.

## Next agent starts from
**Next agent: Codex.**

Start at `src/auth/passkey/handlers/register.ts` (does not exist; create it). The failing test in `tests/auth/passkey/passkey_register.test.ts:18-47` describes the exact request and expected response. Implement until that single test passes; do NOT implement the authentication flow yet — that is a separate Phase 3 shift.

**Do not touch:**
- `tests/auth/passkey/*` (Claude-owned; if the test needs updating after the endpoint-path decision, ask first).
- `migrations/0042_passkey_credentials.sql` (frozen).
- `docs/auth/passkey.md` (Claude-owned).
- `scripts/dev/seed-passkey-fixtures.sh` (Gemini-owned).
- `.env` and `docs/decisions/*` (user-reserved).

## History
- 2026-04-22T16:45 - Claude Code: Wrote protocol documentation and the red integration test for passkey registration. Did not implement handlers. (in-progress)
- 2026-04-20T11:12 - Codex: Reviewed and merged migration `0042_passkey_credentials.sql`. Froze the schema. Did not touch handlers. (in-progress)
- 2026-04-18T09:30 - Gemini CLI: Bootstrapped the passkey subpackage scaffolding under `src/auth/passkey/`, added the dev fixture seed script, declared initial ownership. Marked all handler files as Codex-owned. (in-progress)
- 2026-04-15T14:00 - User: Approved project scope, froze the passkeys+passwords coexistence requirement, decided the WebAuthn library benchmark would precede implementation. (decision)
