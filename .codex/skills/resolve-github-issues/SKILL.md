---
name: resolve-github-issues
description: "Resolve an explicit GitHub issue set or one documented active milestone, one issue at a time, using a clean reusable worktree and a fresh feature branch per issue. Implement, validate, self-review, push, open a PR, wait for applicable CI, merge, comment with the merge SHA, and clean only the current branch before continuing. Use when the user asks Codex to drain or complete selected issues. Never push directly to main, sweep unrelated open issues, or close an issue merely because code was pushed."
---

# Resolve GitHub Issues

## Overview

Resolve one frozen issue-number set as distinct units of understanding, implementation, validation, PR review, merge, and cleanup. Respect the user's explicit issue list first; otherwise use only one documented active milestone. Never turn the general open queue into implicit scope.

## Initial Setup

1. Read `AGENTS.md`, `docs/GITHUB_ISSUE_WORKFLOW.md`, and relevant current docs from a clean current base.
2. Inspect `git status --short --branch`, `git worktree list`, and `HEAD` versus `origin/main` before editing.
3. Fetch `origin` with pruning. Never modify a dirty or stale primary checkout.
4. Create or reuse one clean dedicated resolver worktree based on `origin/main`; reuse it across the sequential issue set instead of creating one worktree per issue.
5. Confirm GitHub access and read the full selected issue set, comments, labels, milestones, dependencies, linked PRs, and current state.
6. Freeze the ordered issue numbers. Exclude unrelated, deferred, future-milestone, meta, duplicate, or already-resolved issues.
7. Record whether a gameplay closeout requires user review and whether the user supplied an `autonomous technical closeout` override.

If no explicit or clearly documented scope exists, stop and run the drift/planning workflow instead of guessing from issue-list order.

## Per-Issue Loop

For each still-open issue in the frozen set:

### 1. Refresh And Claim

- Fetch `origin/main` and verify the resolver worktree is clean.
- Create `codex/<issue-number>-<short-slug>` from current `origin/main`. Never implement on `main`.
- Check issue comments for another active claim.
- Add a claim comment with agent identity, branch, worktree, and expected files. If another claim overlaps, skip it and report the conflict rather than editing the same surface.

### 2. Understand And Implement

- Read the full issue, comments, linked docs, nearby code, and relevant source-of-truth files.
- Restate expected behavior, current gap, ownership boundaries, acceptance criteria, and verification before editing.
- Implement the smallest complete change. Do not absorb follow-up work into the issue.
- Preserve unrelated dirty/generated files and commit matching Godot `.uid` source sidecars only when they belong to newly added or moved source.

### 3. Validate Proportionally

- Documentation/planning: file-length audit when present and `git diff --check`.
- Schema/map/source: targeted validator tests, generator repeatability, reachability/parity, and affected previews.
- Runtime: focused state/journey smoke plus regressions for touched owners.
- Integrated milestone: full release-candidate suite once at the integration boundary or when the issue explicitly requires it.
- Visual/Web: regenerate only affected captures, inspect both target viewports, compare before acceptance, clean generated sidecars, and verify exact deployed SHA.
- Treat `SCRIPT ERROR` and `ERROR:` as failures even when the process exits zero.
- Record commands not run and why.

### 4. Self-Review

- Re-read every acceptance criterion and issue comment.
- Inspect the full diff and staged set.
- Confirm ownership/source boundaries, scope, tests, generated-file hygiene, and file-length policy.
- Remove debug output and unintended artifacts.
- Do not accept a visual baseline without explicit issue authorization and reviewed comparisons.

### 5. Publish Through A PR

- Stage only intended files and commit a coherent change referencing the issue.
- Push the feature branch; never push directly to `main`.
- Open a PR targeting `main` with `Closes #<issue>` and a validation summary.
- Wait for all applicable required checks. A docs-only path with no configured checks may merge after local validation and a clean mergeability check.
- If CI fails, inspect logs, fix the same branch, rerun relevant local checks, and wait for green CI. Do not bypass or close the issue.
- Merge only after the PR is mergeable and required checks pass.

### 6. Close And Clean The Current Issue

- Verify the PR merged and the issue closed. Close manually only when GitHub did not honor the closing keyword and all criteria are met.
- Comment on the issue with PR, merge SHA, verification, and any intentionally deferred follow-up.
- Fetch with pruning, move the resolver worktree to current `origin/main` in a detached clean state, and delete only the local branch created for this issue after confirming merge.
- Confirm the remote branch was deleted or pruned.
- Never mass-delete pre-existing branches or worktrees as incidental cleanup.

After cleanup, refresh only the remaining frozen issue numbers and continue in dependency order. Do not add newly discovered or unrelated open issues to the run.

## Player-Experience Gate

Before resolving a gameplay milestone's closeout issue:

- Confirm implementation, integrated smoke, visual review, and Web verification issues are merged.
- Provide the user a short local run path and checklist tied to the milestone exit question.
- Leave the closeout issue open until the user reports GO/HOLD.
- If the user explicitly requests `autonomous technical closeout`, continue but call the result a **technical GO** and do not claim automation proved fun, pacing, clarity to a human, or replay motivation.

Pure tooling, documentation, and internal refactor issue sets skip this gate unless requested.

## Skipping Or Blocking

Skip a frozen issue only when it is invalid, duplicate, already fixed, intentionally deferred, actively claimed with overlapping files, or blocked by missing information/external state.

- Leave it open unless repository policy supports closing it as duplicate/invalid/already fixed.
- Add a comment with evidence and the exact unblock condition.
- Continue only when later frozen issues do not depend on it.
- Do not silently reinterpret a blocked milestone into different work.

## Close-Out

Stop when the frozen scope is merged, deferred, blocked, or awaiting player review. Do not create or begin the next batch.

Report:

- frozen issue set and milestone
- issues resolved, skipped, blocked, or awaiting review
- PRs and merge SHAs
- local and CI validation
- resolver worktree state and current-run cleanup
- remaining open/deferred issues
