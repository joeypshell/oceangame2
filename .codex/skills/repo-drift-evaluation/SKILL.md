---
name: repo-drift-evaluation
description: "Audit the current repository for drift from project direction, stale documentation, backlog mismatch, validation gaps, source-of-truth violations, and AGENTS.md misalignment, then create or select one scoped milestone batch when the actionable queue is below target unless the user requests evaluation-only. Use for direction audits, backlog planning, documentation freshness checks, or as the planning stage of drift-batch-resolve. Return an explicit frozen issue-number set and never implement or close issues during the audit."
---

# Repo Drift Evaluation

## Purpose

Run an evidence-based audit from a current clean repository view. Select one bounded milestone and create its actionable issue batch when justified. Do not edit project files, implement fixes, accept baselines, change maps, or close issues during the audit.

If the user requests evaluation-only, report-only, no issue creation, or similar, recommend the batch without creating it.

## Bootstrap Before Reading Current Docs

1. Inspect `git status --short --branch` and `git worktree list`.
2. Fetch `origin` with pruning when available.
3. Compare `HEAD` with `origin/main` and report ahead/behind state.
4. Never clean, reset, switch, or edit a dirty primary checkout.
5. When the primary checkout is dirty or stale, read and audit from one clean dedicated worktree based on `origin/main`.
6. If remote freshness cannot be checked, state that limitation before using local docs as current truth.

This ordering is mandatory: stale checkout docs must not drive new GitHub issues.

## Required Reading

Read from the current clean base when present:

- `AGENTS.md`
- `README.md`
- `docs/MILESTONES.md`
- `docs/current/PROJECT_CONTEXT.md`
- `docs/current/ARCHITECTURE.md`
- the latest relevant plan, closeout, visual decision, and Web verification
- `docs/current/TOOLING.md` or the split tooling docs
- `docs/GITHUB_ISSUE_WORKFLOW.md`

Then inspect live state:

- recent commits on `origin/main`
- open issues with numbers, titles, labels, milestones, and URLs
- relevant recently closed issues and PRs
- open/closed milestones
- recent Actions runs when smoke or deployment status matters

## Audit Workflow

### 1. Establish Evidence

- Identify the canonical commit, protected dirty files, active worktree, recent merged work, open actionable issues, deferred issues, and milestone state.
- Treat GitHub plus current `origin/main` docs as authoritative over old chat memory or a stale checkout.
- Distinguish facts from inference and name unavailable evidence.

### 2. Check AGENTS.md Alignment

- Confirm meaningful work is represented by independently actionable issues.
- Verify feature-branch/PR/CI/merge discipline and that no issue is considered resolved merely because a branch was pushed.
- Verify map/terrain changes use source or renderer first, then generation, validation, and final screenshots.
- Verify visual changes are scoped, compared before baseline acceptance, and free of generated cache files.
- Verify work stays inside the selected roadmap boundary and the north-star filter: curiosity, pressure, payoff, remembered-place progress, meaningful route choice, or another-expedition motivation.

### 3. Find Documentation Drift

- Compare README, MILESTONES, PROJECT_CONTEXT, ARCHITECTURE, roadmap, closeouts, tooling, and live GitHub state.
- Flag stale current issue ranges, wrong next direction, missing closeout/Web/visual evidence, obsolete commands, and oversized docs.
- Prefer concise current-state corrections; split/archive rather than growing an already oversized document.

### 4. Evaluate Direction

- Select at most one milestone for actionable work.
- A full batch requires a documented goal, boundaries/non-goals, ownership/source expectations, and an exit question or criteria.
- If those are missing, create or recommend only the planning decision issue and return `planning_gate: true`; do not invent implementation details.
- Keep future named milestones directional until the selected milestone closes.

### 5. Check Validation Coverage

Prefer fast read-only checks:

- `python tools/check_file_lengths.py` when present
- `git diff --check`
- targeted validators/parity only when that source surface is under audit
- GitHub Actions status for smoke/Web state

Do not run long Godot capture or release suites unless the audit depends on them. Report skipped commands and why.

### 6. Assess Backlog Health

- Count active actionable issues separately from deferred, blocked, meta, and future-milestone issues.
- Reuse an existing coherent milestone batch before creating more work.
- Treat 6-10 meaningful issues as the normal batch range, not a quota. Fewer are valid when they fully cover the milestone.
- Never pad with vague planning, duplicate validation, or ceremonial closeout work.
- Do not immediately refill a batch that another resolver is actively draining.

### 7. Create One Batch When Needed

- Run duplicate checks against open issues and relevant recent closures.
- Create issues only for the selected milestone or planning gate.
- Assign the selected milestone when one exists.
- Each issue must include summary, acceptance criteria, relevant docs/code areas, dependencies/blockers, implementation notes, and verification.
- Prefer dependency order: plan/contract, source/schema, authoring, focused runtime, integration, smoke, capture/visual review, Web verification, player review, closeout. Include only stages the milestone actually needs.
- Do not hardcode deferred issue numbers as the general mechanism; use labels, issue comments, and current docs. Existing documented exceptions may still be named in the report.

## Required Handoff

Return these fields clearly enough for a resolver to freeze scope:

- `selected_milestone`: number/title or `none`
- `planning_gate`: `true` or `false`
- `selected_issue_ids`: ordered explicit numbers
- `created_issue_ids`: ordered explicit numbers
- `dependency_order`: concise ordered list
- `deferred_issue_ids`: explicit numbers and rationale
- `player_review_required`: `true` for gameplay/experience milestones, otherwise `false`

The audit must not resolve, close, or implement any returned issue.

## Output Format

Report:

1. **Verdict** - aligned, drifting, or blocked.
2. **Canonical State** - commit/worktree freshness and protected dirty files.
3. **Key Findings** - ordered by impact with file/issue evidence.
4. **Direction And Backlog** - selected milestone, meaningful-change rationale, and what remains directional.
5. **Created Or Selected Batch** - the required handoff fields and issue URLs.
6. **Validation** - commands and results, plus intentional omissions.
7. **Next Action** - one specific action without implementing it.

## Guardrails

- Do not silently fix drift during an audit.
- Do not create a second batch when one coherent selected batch already exists.
- Do not create implementation issues from an undocumented direction.
- Do not use old chat memory as current truth when GitHub or `origin/main` disagrees.
- If GitHub writes are unavailable, return complete issue drafts and mark them uncreated.
