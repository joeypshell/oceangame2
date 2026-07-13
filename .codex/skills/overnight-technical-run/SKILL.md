---
name: overnight-technical-run
description: "Run unattended oceangame2 technical work for a bounded overnight window through repeated audit, frozen-batch, PR/CI/merge, and integration loops. Use when the user asks for an overnight run, night shift, long autonomous maintenance, regression hardening, validator work, or other technical progress that should continue without routine input. Default to an eight-hour ceiling while stopping at player-experience, visual-baseline, product, roadmap, map-design, art, or blocked-future-milestone decisions."
---

# Overnight Technical Run

## Purpose

Make meaningful unattended technical progress without using elapsed time as a reason to invent work. Run several bounded loops when justified, preserve GitHub and source-of-truth discipline, and leave human judgment gates open.

This skill composes the procedures in:

- `.codex/skills/repo-drift-evaluation/SKILL.md`
- `.codex/skills/resolve-github-issues/SKILL.md`
- `.codex/skills/drift-batch-resolve/SKILL.md`

Read those files, `AGENTS.md`, `docs/GITHUB_ISSUE_WORKFLOW.md`, and relevant current docs before selecting work.

## Invocation Contract

- Treat explicit invocation as authorization for autonomous **technical** closeout: branches, commits, pushes, PRs, CI fixes, merges, issue comments, and technical deployment verification.
- Use the user's requested duration up to eight hours. If no duration is supplied, use an eight-hour ceiling. A shorter user limit always wins.
- Record the start time, deadline, final-closeout reserve, current loop, and active issue set in the first progress update. Reconstruct state from GitHub and Git if context compacts.
- Treat eight hours as a ceiling, never a quota. Stop early when no meaningful eligible work remains.
- Honor an explicit issue list as the first loop. Otherwise inspect live state and select the current milestone's highest-impact technical blockers first.
- Do not ask routine implementation questions. Skip ambiguous work with evidence and continue only to independent eligible work.
- Never invoke this skill merely to keep a machine busy.

## Eligibility Filter

Prefer work with deterministic acceptance criteria:

- reproducible bugs and regressions in current committed behavior
- source-of-truth validators, parity, reachability, and progression integrity
- deterministic smoke, browser, CI, export, and deployment reliability
- current documentation or tooling drift that can be proven against live state
- bounded no-behavior-change refactors with clear ownership boundaries
- generated-output hygiene and review-fixture isolation
- existing technical blockers for the current player-review gate

Reject or defer work requiring human or product judgment:

- player GO/HOLD, fun, pacing, clarity, balance, or replay-value decisions
- visual baseline acceptance or subjective art review
- new roadmap direction, milestone selection, economy, progression, or game-loop design
- broad map topology, geography, asset replacement, or presentation redesign
- a future gameplay milestone blocked by the current closeout
- issues explicitly deferred by current docs, labels, or comments
- dependency upgrades or architectural rewrites without a current approved issue
- vague cleanup, speculative polish, or tickets created only to fill the window

Do not close a human gate or claim a technical run proved player experience. The invocation's autonomous authorization permits only a **technical GO** where repository policy allows it.

## Bootstrap

1. Inspect `git status --short --branch`, `git worktree list`, and current processes before editing.
2. Fetch `origin` with pruning and compare the working base with `origin/main`.
3. Never edit, switch, reset, clean, or overwrite a dirty or stale primary checkout.
4. Create or reuse one clean dedicated overnight resolver worktree based on current `origin/main`. Reuse it across all loops.
5. Confirm GitHub access, active claims, open issues, milestones, recent merges, CI, and deployment state.
6. Protect unrelated branches, worktrees, dirty files, generated output, editor sessions, and user processes.
7. Establish the deadline and reserve the final 45 minutes for integration, issue comments, process cleanup, and reporting.

If another worker owns overlapping files, skip that issue. Do not use parallel agents during this skill unless the user explicitly requests them.

## Bounded Loop

Run at most four loops and never exceed the deadline.

### 1. Refresh Evidence

- Refresh `origin/main`, GitHub issue/PR state, claims, CI, and the remaining time.
- Re-read only the current docs and code relevant to the technical lane.
- Prefer an existing coherent actionable issue set over creating more work.
- Use `$repo-drift-evaluation` in evaluation-only mode when a broader audit is needed, then apply this skill's stricter eligibility filter.

### 2. Freeze A Small Batch

- Freeze one to four ordered technical issues that can reasonably finish within the remaining window.
- Run duplicate checks before creating issues.
- Create a new issue only when the audit found a discrete, evidence-backed defect or validation gap with summary, acceptance criteria, ownership, dependencies, and verification.
- Keep created issues in the current approved technical lane or current milestone. Do not create or populate a future gameplay milestone.
- Exclude human closeout, deferred work, visual acceptance, and unrelated backlog items.
- Publish the explicit frozen issue numbers before implementation. Never refill that set mid-loop.

If no eligible issue exists, stop the overnight run successfully instead of manufacturing a batch.

### 3. Resolve Sequentially

- Run `$resolve-github-issues` against only the frozen issue numbers in dependency order.
- Use a fresh `codex/<issue>-<slug>` branch from current `origin/main` for each issue in the reusable worktree.
- Claim the issue with branch, worktree, and expected files.
- Implement the smallest complete change, validate proportionally, self-review, push, open a PR, wait for applicable CI, merge only when green, comment with the merge SHA, and clean only that branch.
- Skip a blocked issue only with evidence and an exact unblock condition. Continue only when later frozen issues are independent.
- Do not add newly discovered work to the active loop; record it as a follow-up candidate for the next checkpoint.

### 4. Integrate Once

- Use focused validation per issue.
- For a loop that changes runtime, maps, shared validation, or cross-owner contracts, run the full release-candidate suite at most once after the loop's merged integration state is ready.
- Skip the full suite for docs-only or narrowly isolated tooling loops when focused checks and CI are sufficient.
- Across multiple loops, rerun the full suite only when later merged runtime/map changes make the previous result stale.
- Verify exact deployed SHA only when the loop affects the public build or review path.
- Never accept a visual baseline. Regenerate and inspect only affected captures when technical verification requires them.

### 5. Checkpoint

After each loop:

1. Fetch current `origin/main` and confirm merged/closed state.
2. Record resolved, blocked, deferred, and newly discovered technical candidates.
3. Recalculate time remaining and preserve the 45-minute closeout reserve.
4. Stop if the next required action is a player, visual, product, roadmap, map-design, or art decision.
5. Start another loop only when at least one meaningful eligible issue exists and there is conservative time for implementation, CI, merge, and cleanup.

Do not start a new loop in the final 90 minutes. Do not start a new issue when fewer than 45 minutes remain or when its likely CI/deployment path cannot finish before closeout.

## Validation Discipline

- Documentation/planning: file-length audit when present and `git diff --check`.
- Schema/map/source: focused tests, generator repeatability, source validation, reachability/parity, and affected previews.
- Runtime: focused state or journey smoke plus regressions for touched owners.
- Integrated runtime/map loop: one release-candidate suite after the merged set.
- Web: exact build metadata, initialization, canvas/framing, and relevant browser behavior.
- Treat `SCRIPT ERROR`, `ERROR:`, nonzero exits, missing expected output, and hung processes as failures.
- Never weaken a test merely to make the batch green. Correct the fixture only when source ownership or the intended contract changed.
- Do not run dozens of unrelated tests after every issue.

## Timeouts And External Failures

- Give every long command an explicit timeout and wait for every required running session before moving on.
- Track processes started by the run. On timeout, inspect executable, start time, and command context; terminate only the process tree started by this run.
- Never kill the user's Godot editor, browser, server, or unrelated agent process.
- Diagnose CI failures on the same branch and rerun relevant focused checks before pushing a fix.
- When GitHub, CI, deployment, or another external service remains unavailable, comment with evidence, leave the issue open, and continue only to independent work.
- Never bypass checks, merge known failures, or mark work complete because the deadline is near.

## Deadline Safety

- Use the closeout reserve to finish the current issue, run required integration, stop processes, and report.
- Do not begin speculative work to consume unused time.
- If an issue cannot be completed safely, leave it open. Push a draft PR only when the branch is coherent, contains no secrets/generated junk, and clearly omits closing keywords.
- Never merge partial or unvalidated work.
- Do not discard user changes or destroy an incomplete branch merely to report a clean tree.
- End all tool sessions and background processes started by the run.

## Stop Conditions

Stop when any of these is true:

- the deadline or four-loop limit is reached
- no meaningful eligible technical issue remains
- the next dependency is a human/player/visual/product decision
- the current milestone has no remaining eligible technical blocker and is blocked only on player review
- only deferred or future-milestone work remains
- remaining time cannot safely cover implementation, CI, and cleanup
- a repeated external blocker prevents meaningful independent progress

Do not begin another milestone in the same overnight run.

## Final Report

Report:

- requested window, actual elapsed time, and loop count
- canonical starting and ending SHAs
- issues selected, created, resolved, skipped, blocked, or awaiting review
- PRs and merge SHAs
- focused, integration, CI, capture, and Web verification results
- commands not run and why
- processes started and cleanup confirmation
- resolver worktree, branch, and dirty-state status
- remaining human gates, deferred issues, and the single next recommended action

Leave the reusable overnight worktree clean and detached at current `origin/main` when all work merged. Preserve and report any unmerged draft branch explicitly.
