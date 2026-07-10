# GitHub Issue Workflow

Use GitHub Issues as the durable work queue for this project. Chat planning is useful, but actionable work should be captured in issues so future Codex sessions can continue without reconstructing context.

## When To Create Issues

Create or update issues when:

- a planning discussion produces concrete implementation steps
- a task is large enough to split across future sessions
- a visual or map decision needs validation later
- a bug or workflow gap is found while working
- a follow-up is useful but outside the current task

Do not create issues for vague epics, duplicate work, intentionally deferred ideas, or notes that belong in docs instead.

## Issue Shape

Each issue should include:

- summary or user story
- acceptance criteria
- relevant docs and code areas
- dependencies or blockers
- implementation notes
- verification steps

Keep issues small enough for one focused agent pass.

## Repository And Scope Safety

- Inspect `git status`, fetch `origin`, and compare the checkout with `origin/main` before reading current-direction docs or editing.
- Never clean, reset, switch, or overwrite a dirty primary checkout. Use one clean dedicated resolver worktree based on `origin/main` when the primary checkout is dirty or stale.
- Reuse that resolver worktree across sequential issues. Do not create one worktree per issue.
- Freeze a resolver run to explicit issue numbers or one committed milestone. Do not absorb unrelated open issues or immediately create the next milestone after closeout.
- Treat 6-10 as a useful range for a complete milestone batch, not a quota. Fewer meaningful issues are better than padded process tickets.

## Per-Issue Branch And PR Flow

For each selected issue:

1. Start a fresh `codex/<issue>-<slug>` branch from current `origin/main` in the clean resolver worktree.
2. Comment on the issue with the branch, worktree, agent identity, and expected files before editing.
3. Implement and validate only the issue scope.
4. Commit and push the feature branch; never push directly to `main`.
5. Open a PR with `Closes #<issue>` and the validation summary.
6. Wait for applicable required checks. A docs-only PR with no configured checks may merge after local validation and a clean mergeability check.
7. Merge, verify the issue closed, and comment with the PR, merge commit, and verification evidence.
8. Fetch/prune, return the resolver worktree to current `origin/main`, and delete only the merged branch created for this issue.

Do not mass-delete old branches or worktrees while resolving an unrelated issue. Legacy cleanup requires its own reviewed scope.

## Planning-To-Issue Rule

When the project identifies a sequence like:

1. build Godot greybox
2. validate map accessibility
3. generate terrain tiles
4. render terrain art from the greybox
5. capture visual baselines

create separate issues for the meaningful work items. Link the issue to the relevant docs, source maps, reference images, and validation tools.

## Map And Visual Issues

Map issues must mention:

- source map path
- preview path
- accessibility validator command
- expected reachable gameplay areas
- whether any unreachable areas are intentionally decorative/background-only

Visual issues must mention:

- art bible path
- reference standard path
- target assets
- untouched assets
- visual baseline expectations
- whether the change is a concept, production asset, or in-engine placement task

## Close-Out

Before closing an issue:

- confirm the acceptance criteria were met
- run the relevant verification steps
- merge the PR after applicable checks pass
- comment with the PR, merge commit, and verification result
- leave follow-up work as separate issues instead of expanding the closed issue

For gameplay milestones, automated smoke, capture, visual, and Web evidence establishes technical readiness. Before the final closeout, give the user a short local playtest checklist tied to the milestone exit question and wait for GO/HOLD. An explicit `autonomous technical closeout` may skip that pause, but the result must be described as technical rather than proof of fun or pacing.

After closing a milestone, stop. Do not create or begin the next milestone's batch in the same resolver run.
