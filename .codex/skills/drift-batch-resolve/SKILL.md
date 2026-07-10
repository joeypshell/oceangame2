---
name: drift-batch-resolve
description: "Run one bounded repository-maintenance cycle: audit current origin/main for drift, select or create one meaningful milestone issue batch, and resolve only that frozen issue set through feature branches, pull requests, applicable CI, and cleanup in one clean resolver worktree. Use when the user asks Codex to evaluate direction/backlog and keep moving through a complete scoped milestone. Stop at the player-experience gate unless the user explicitly requests an autonomous technical closeout, and never begin the next milestone in the same run."
---

# Drift Batch Resolve

## Purpose

Run one bounded project-maintenance cycle:

1. Establish a current, clean repository view.
2. Audit direction and select exactly one milestone or explicit issue set.
3. Create a meaningful batch only when needed.
4. Resolve only the frozen batch through PRs and CI.
5. Stop at the player-experience gate or close the selected milestone.

This skill composes:

- `.codex/skills/repo-drift-evaluation/SKILL.md`
- `.codex/skills/resolve-github-issues/SKILL.md`

Invoking this skill without a narrower instruction means the full cycle. Honor `audit-only`, `batch-only`, `resolve-only`, explicit issue numbers, or `autonomous technical closeout` when the user supplies them.

## Workflow

### 1. Bootstrap Before Reading Current Direction

- Inspect `git status --short --branch` and `git worktree list` before reading current-state docs.
- Fetch `origin` with pruning, then compare `HEAD` with `origin/main`.
- Never edit, switch, clean, or reset a dirty primary checkout.
- If the primary checkout is dirty or stale, create or reuse one clean dedicated resolver worktree based on `origin/main`. Reuse that worktree for the entire sequential batch; do not create one worktree per issue.
- A reused resolver worktree must be clean and unclaimed. If it is not, choose another clean run worktree without disturbing it.
- Record unrelated dirty files as protected evidence and leave them untouched.

### 2. Audit And Select One Scope

- Read `AGENTS.md`, both composed skills, and `docs/GITHUB_ISSUE_WORKFLOW.md` from the current clean base.
- Run `$repo-drift-evaluation` completely.
- Let the drift skill own issue-batch creation. Do not run a second independent batch-creation pass.
- Capture its explicit outputs:
  - selected milestone or planning gate
  - selected issue numbers
  - newly created issue numbers
  - dependency order
  - deferred issues
- If there is no evidence-backed actionable scope, stop with the audit result. Do not manufacture work to reach a count.
- If the next direction is not already named with a goal, boundaries, and exit criteria, create or recommend only the planning decision needed to unblock it and stop before implementation.

### 3. Freeze The Batch

- Freeze the returned issue-number set before implementation.
- Prefer 6-10 meaningful issues for one milestone. Fewer are valid when they fully cover the work; never pad to exactly ten.
- Assign the selected GitHub milestone when one exists.
- Exclude issues marked deferred by labels, issue comments, or current roadmap docs unless the user explicitly selects that topic.
- Never add unrelated open issues, future-milestone issues, or issues created by another active worker to the frozen set.

### 4. Resolve The Frozen Set

- Run `$resolve-github-issues` with the explicit issue numbers and dependency order.
- Use the one clean resolver worktree and a fresh `codex/<issue>-<slug>` branch from current `origin/main` for each issue.
- Require an issue claim comment, scoped implementation, relevant local validation, self-review, commit, push, PR, applicable CI, merge, merge-SHA comment, and current-branch cleanup.
- Never push directly to `main` and never close an implementation issue merely because a branch was pushed.
- Refresh GitHub state after each merge, but continue only through the still-open members of the frozen issue set.
- Do not refill the queue during resolution.

### 5. Use Proportional Validation

- Documentation/planning: file-length audit when present and `git diff --check`.
- Schema/map/source: focused validator tests, generator repeatability, reachability, parity, and only affected previews.
- Runtime: focused state or journey smoke plus regressions for touched owners.
- Integrated milestone: run the full release-candidate suite once after the integrated runtime/smoke/capture surface is ready, not after every small issue.
- Visual/Web: regenerate only affected captures, compare before acceptance, keep generated sidecars out of commits, and verify exact deployed build metadata.
- Treat `SCRIPT ERROR` and `ERROR:` as failures even when Godot exits zero.

### 6. Player-Experience Gate

For a milestone that changes gameplay, route pressure, progression, controls, or presentation:

- Resolve technical implementation, smoke, capture, visual review, and Web verification first.
- Before resolving the milestone closeout, give the user a short local playtest path and checklist tied to the milestone exit question.
- Stop with the closeout issue open until the user reports GO, HOLD, or explicitly requests `autonomous technical closeout`.
- An autonomous override may record a **technical GO** only; do not claim that automation proved fun, pacing, or player motivation.
- Pure documentation, tooling, and internal refactor batches do not require this gate unless the user asks for one.

### 7. Close And Clean Up

- Close the selected milestone only after every frozen issue is merged and its closeout criteria are satisfied.
- Do not create the next milestone's batch in the same run.
- After each merge, prune remote refs and delete only the local branch created for that issue after confirming the PR merged.
- At final closeout, leave the reusable resolver worktree clean and detached at current `origin/main`, or remove only that run's worktree after verifying it is clean and inside the intended workspace.
- Never mass-delete or rewrite pre-existing branches/worktrees as incidental cleanup.

## Guardrails

- Preserve map/source-of-truth and controlled visual workflow rules from `AGENTS.md`.
- Do not accept visual baselines without an explicit issue, rendered comparison, and intentional-difference decision.
- Do not broaden a milestone into economy, inventory, procedural geography, broad art replacement, or map-scale expansion unless current roadmap docs explicitly select it.
- If GitHub, CI, deployment, or required user review is unavailable, leave the affected issue open with evidence and continue only where dependencies permit.
- If the user requests evaluation-only, no issue creation, or no resolution, obey that narrower scope.

## Final Report

Report:

- drift verdict and selected milestone/scope
- created and frozen issue numbers
- resolved, skipped, blocked, or awaiting-player-review issues
- PRs and merge commits
- validation and CI results
- worktree and current-run branch cleanup
- remaining open/deferred issues
- the one next recommended action, without starting it
