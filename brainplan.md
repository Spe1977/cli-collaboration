# Brainstorming Workflow Integration Plan

## Purpose

Document `cli-collaboration` as a reusable handoff protocol for sequential multi-LLM brainstorming without changing its technical guardrails or repository-collaboration behavior.

The integration should make one concrete workflow first-class in the documentation:

1. The user creates a dedicated topic folder.
2. The folder initially contains only `brainstorming.md`.
3. The user opens a terminal in that folder, starts an LLM CLI, and invokes `cli-collaboration`.
4. Because `AGENT_HANDOFF.md` is missing, the agent reads the seed file `brainstorming.md` before creating a generic handoff.
5. The agent follows the bootstrap instructions embedded in `brainstorming.md`, creates `AGENT_HANDOFF.md`, self-registers, writes the first turn, and updates the handoff last.

## Scope

This is a documentation-only change. It should not alter:

- ownership parser behavior
- `check-ownership.sh`
- `parse-ownership.py`
- install or sync scripts
- fixture behavior
- CI/eval mechanics
- the canonical repository-collaboration protocol

## Proposed File Changes

### `skills/cli-collaboration/SKILL.md`

Make a small, controlled update so the skill recognizes explicit shared handoff workflows beyond repository work.

Proposed changes:

- Extend the frontmatter `description` from repository-only language to repository or explicit shared handoff workflow language.
- Add a short bootstrap routing rule:

  ```markdown
  If `AGENT_HANDOFF.md` is missing but a known workflow seed file such as
  `brainstorming.md` exists, read that seed file before creating a generic
  handoff. Follow its bootstrap instructions to create the initial
  `AGENT_HANDOFF.md`.
  ```

- Add a short reference pointer:

  ```markdown
  For non-code workflows such as multi-LLM brainstorming, load
  `references/alternate-workflows.md` only when the user explicitly asks for
  that workflow or the handoff/seed file declares it.
  ```

Keep this section short so normal repository work does not load unnecessary brainstorming detail.

### `skills/cli-collaboration/references/alternate-workflows.md`

Add a new reference file for non-code applications of the same handoff protocol.

Required content:

- Core principle: these are applications of the existing protocol, not new execution logic.
- Activation rule: use only when requested by the user, declared in `AGENT_HANDOFF.md`, or seeded by a known file such as `brainstorming.md`.
- Field mapping for non-code workflows:

  ```markdown
  | Code field | Non-code equivalent |
  |---|---|
  | Files I will touch | Artifact files or sections I will edit |
  | Expected red test | Validation method, or `no test: non-code workflow` |
  | Tests green | Checks/review completed |
  | Ownership | File, section, or contribution ownership |
  | Stop condition | Turn complete, blocker, context budget, or user decision needed |
  ```

- Multi-LLM brainstorming workflow with the one-file seed model:

  ```text
  topic-folder/
  └── brainstorming.md
  ```

  After first invocation:

  ```text
  topic-folder/
  ├── brainstorming.md
  └── AGENT_HANDOFF.md
  ```

- Complete reusable `brainstorming.md` seed template, including:
  - mode and rules
  - participants/self-registration
  - self-identification table
  - user intervention section
  - topic section
  - append-only turns section
  - embedded bootstrap template for the first `AGENT_HANDOFF.md`

- Safety rules:
  - append turns only
  - do not edit previous turns
  - do not edit other participant names except when explicitly asked by the user
  - do not run tests, edit code, create extra files, or commit
  - update `AGENT_HANDOFF.md` last
  - stop on ambiguous format, conflicting instructions, or missing bootstrap data

### `README.md`

Add a concise section after the core workflow or activation section:

```markdown
## Non-Code Workflows

The primary use case remains repository collaboration. The same handoff
protocol can also coordinate explicit non-code workflows, such as multi-LLM
brainstorming, research synthesis, structured debate, editorial review, or
model comparison.

For multi-LLM brainstorming, start a topic folder with only `brainstorming.md`.
The first agent reads that seed file, creates `AGENT_HANDOFF.md`, writes the
first turn, and updates the handoff. See
`skills/cli-collaboration/references/alternate-workflows.md`.
```

Keep the README focused; do not paste the full template there.

### `README_IT.md`

Add the Italian mirror of the README section.

Suggested title:

```markdown
## Workflow Non-Code
```

The content should preserve the same constraints:

- repository collaboration remains primary
- brainstorming is an explicit documented application
- full template lives in `references/alternate-workflows.md`

### `skills/cli-collaboration/references/handoff-template.md`

Optional small note only. Do not rewrite the canonical template.

Suggested note:

```markdown
For non-code workflows, keep the same handoff discipline. Test fields may be
replaced with explicit validation notes or `no test: non-code workflow`, but
file/section scope, reserved areas, and stop condition remain mandatory.
```

### `CHANGELOG.md`

Add a documentation-only entry.

Suggested entry:

```markdown
### Added
- Documented multi-LLM brainstorming as a supported non-code handoff workflow.
- Added `references/alternate-workflows.md` with a complete `brainstorming.md`
  seed template and bootstrap behavior for creating `AGENT_HANDOFF.md`.

### Changed
- Clarified that repository collaboration remains the primary use case, while
  explicit handoff workflows can reuse the same protocol for non-code
  turn-taking.
```

## Review Questions For Gemini And Claude

1. Is the `SKILL.md` trigger expansion narrow enough, or could it cause unwanted activation outside repository collaboration?
2. Should the seed filename be limited to `brainstorming.md`, or should the documentation leave room for future seed files?
3. Should `alternate-workflows.md` include only brainstorming for now, or briefly list other patterns without templates?
4. Is the embedded `AGENT_HANDOFF.md` bootstrap template enough to make a one-file seed folder reliable across Codex, Claude, Gemini, and Antigravity?
5. Should `handoff-template.md` mention non-code workflows, or should that remain isolated in `alternate-workflows.md`?

## Acceptance Criteria

- The core repository collaboration behavior remains unchanged.
- `SKILL.md` contains only the minimal routing rule and reference pointer.
- `alternate-workflows.md` contains the full brainstorming seed template.
- README files mention brainstorming as a concrete documented application without bloating the quick-start path.
- Changelog clearly marks the change as documentation-only.
- No technical scripts or fixtures are modified.

## Recommended Implementation Order

1. Add `alternate-workflows.md` with the full brainstorming template.
2. Make the minimal `SKILL.md` description and bootstrap-rule update.
3. Add short README/README_IT sections.
4. Add the optional `handoff-template.md` note only if reviewers agree it improves clarity.
5. Add the CHANGELOG entry.
6. Run documentation/metadata checks only; no script behavior tests should be necessary unless `SKILL.md` frontmatter validation requires it.
