---
name: stack-split
description: This skill should be used when a feature branch has grown too large for one PR and needs to be split into a stack of logically ordered PRs. Triggers on requests like "split this branch into stacked PRs", "break this PR up", "stack this feature", "this PR is too big, split it". Splits by logical layer (base changes at the bottom, follow-ups on top), not by line count. Uses Graphite (gt) when the repo is gt-initialized, plain git + gh otherwise.
---

# Stack Split

Split one oversized committed feature branch into a stack of meaningful, independently green PRs. The split is **logical, not arithmetic**: the bottom PR carries foundations (schema, migrations, shared types, config), each layer above builds on the one below, and the top of the stack reproduces the source branch exactly.

## Preconditions

1. All work must be committed. If the working tree is dirty, stop and ask the user to commit or stash first — do not commit for them.
2. Identify trunk (`main`/`master`/`staging` — check the repo's default branch) and compute `git merge-base trunk source-branch`.
3. The source branch is **never modified**. It is the backup and the verification oracle.

## Tool detection

Use Graphite only when both hold:

- `command -v gt` succeeds, AND
- the repo is gt-initialized: `test -f "$(git rev-parse --git-dir)/.graphite_repo_config"` (or `gt log` exits 0).

Otherwise use plain git. For PR submission in the plain-git path, use `gh pr create --base <parent-branch>` so each PR targets its parent (manual stack). If `gh` is also unavailable, stop after building local branches and print push/PR instructions.

## Phase 1 — Analyze and plan

1. Read the full diff: `git diff <merge-base>..source-branch --stat` then the diff itself (in chunks for large branches).
2. Draft a split plan. For each layer, record:
   - Branch name and PR title
   - Files (and, for files spanning layers, which hunks) assigned to it
   - One-line rationale: why this layer, why this position
3. Grouping principles:
   - Bottom layer = changes everything else depends on (DB migrations, shared types/packages, config).
   - Each layer must be green standalone: it may only reference code that exists at its level. Tests live in the layer that introduces the code they exercise (or above), never below.
   - Prefer 3–6 layers. A layer earns its place by being independently reviewable, not by hitting a line quota. Do not split just to shrink numbers; do not merge unrelated concerns to reduce count.
   - Flag every file needing an intra-file split (parts in different layers) explicitly in the plan — these are the error-prone spots.

## Phase 2 — Reviewer subagent

Dispatch a separate reviewer subagent with the plan, the diffstat, and the grouping principles above. Ask it to attack:

- Dependency order: does any layer reference symbols/files introduced in a later layer?
- Layer coherence: is each PR one reviewable idea?
- Green feasibility: can each layer plausibly pass typecheck/tests alone?
- Intra-file splits: are the flagged hunks actually separable?

Revise the plan with its findings.

## Phase 3 — User approval

Present the final plan (layers, titles, file assignments, intra-file splits, deviations from the first draft) and wait for explicit approval before creating any branch.

## Phase 4 — Build the stack

Discover the repo's check commands first (CLAUDE.md/AGENTS.md, package.json scripts — e.g. `check`, `typecheck`, `lint`, package-scoped tests).

For each layer, bottom-up:

1. Create the branch from its parent (trunk for layer 1, previous layer otherwise).
   - Graphite: stage changes, then `gt create <branch-name> -m "<title>"` — **always pass an explicit branch name**; gt auto-generated names (dates, underscores) break CI systems with strict slug rules.
   - Plain git: `git checkout -b <branch-name> <parent>`, stage, `git commit -m "<title>"`.
2. Materialize the layer's content **at final state** from the source branch:
   - Whole files: `git checkout source-branch -- <paths>`.
   - Split files: edit manually so only this layer's parts are present; the last layer touching the file checks out the full final version.
   - Deleted files: `git rm` them in the layer that owns the deletion.
3. Run the check commands (typecheck + lint at minimum; tests scoped to touched packages when feasible). The layer must be green before starting the next one.

**Naming and titles:**

- Branch: short lowercase kebab, letter-start, no underscores, < 64 chars, following the user's/repo's prefix convention (e.g. `sami/chat-attach-db`).
- Commit subject = PR title: conventional-commit style if the repo uses it, always ending with the stack marker: `feat(chat): attachment tables + types (1/5)`.

**Hidden coupling (self-heal policy):** when a layer can't go green without content planned for a later layer, move the minimal coupled hunks down (or merge two layers if inseparable), renumber every affected `(x/y)`, and continue. Record every deviation. Stop and re-ask the user only if the plan collapses structurally (e.g. 5 layers become 2).

## Phase 5 — Verify

1. `git diff source-branch <top-branch>` must be **empty**. If not, diagnose the drift and fix the owning layer (restack afterwards: `gt restack` / cascading rebases in plain git).
2. Confirm every layer passed its checks.
3. Renumber check: all `(x/y)` markers consistent with the final layer count.

## Phase 6 — Summary and submit offer

Show: layer table (branch, title, diffstat), deviations from the approved plan, verification results. Then **ask** whether to submit — never push without an explicit yes.

On yes:

- Graphite: `gt submit --stack --draft` (drafts by default), then apply the user's PR conventions (e.g. `gh pr edit <num> --add-assignee @me`).
- Plain git: push each branch, `gh pr create --draft --base <parent-branch>` per layer, bottom-up.
- PR bodies: 1–2 sentences on what the layer does, plus its stack position and the PRs directly below and above.
