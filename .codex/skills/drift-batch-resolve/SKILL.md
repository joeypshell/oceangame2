---
name: drift-batch-resolve
description: "Audit this repository for drift, ensure a scoped GitHub issue batch exists, and then resolve the active non-deferred issue queue. Use when the user asks Codex to evaluate direction/backlog and keep moving: run repo drift evaluation, create a 10-issue batch if none was created or the actionable backlog is below target, then run the GitHub issue resolver."
---

# Drift Batch Resolve

## Purpose

Run the full project-maintenance loop:

1. Evaluate repo drift and direction.
2. Ensure a concrete GitHub issue batch exists.
3. Resolve the active non-deferred issues one by one.

This skill composes the project-local skills:

- `.codex/skills/repo-drift-evaluation/SKILL.md`
- `.codex/skills/resolve-github-issues/SKILL.md`

## Workflow

1. **Read required instructions.**
   - Read `AGENTS.md`.
   - Read `.codex/skills/repo-drift-evaluation/SKILL.md`.
   - Read `.codex/skills/resolve-github-issues/SKILL.md`.
   - Read `docs/GITHUB_ISSUE_WORKFLOW.md` when present.

2. **Run repo drift evaluation first.**
   - Follow `$repo-drift-evaluation` completely.
   - Allow it to create its recommended scoped issue batch unless the user explicitly asked for report-only/no issue creation.
   - Capture any created issue numbers, dependency order, and deferred issues.

3. **If no issue batch was created, ensure one exists.**
   - Refresh open issues with `gh issue list --state open --limit 100`.
   - Exclude intentionally deferred issues such as #52/#53 unless the selected goal explicitly returns to that topic.
   - If there are fewer than about 10 active actionable issues, evaluate the next small project direction from current docs and create a 10-issue batch.
   - Run duplicate checks against open and recently closed issues before creating anything.
   - Each created issue must include summary, acceptance criteria, relevant docs/code areas, dependencies/blockers, implementation notes, and verification steps.
   - Order the batch by dependency: current-state correction/planning, source rules, source authoring, runtime, smoke, capture, visual review, Web verification, closeout.
   - Return the created issue numbers and URLs.

4. **Resolve active issues.**
   - Run `$resolve-github-issues` after the active batch exists.
   - Resolve only active non-deferred issues in dependency order unless the user selected a different scope.
   - Preserve unrelated dirty files and do not revert user changes.
   - Commit, push, comment, and close each resolved issue according to the resolver skill.
   - Leave deferred issues open with their deferral rationale.

## Guardrails

- Do not create vague epics just to reach the issue target.
- Do not resolve intentionally deferred slice-polish issues unless the user explicitly selects that goal.
- Do not broaden a gameplay pass into economy, upgrades, enemies, inventory, procedural generation, broad art replacement, or full-map productionization unless current docs select that direction.
- For map/terrain work, update source/generator data first, regenerate previews, validate reachability/parity, and use screenshots only for rendering confirmation.
- If GitHub access is unavailable, report the blocker and provide exact issue drafts instead of pretending issues were created.
- If the user explicitly says evaluation-only, report-only, do not create issues, or do not resolve issues, obey that narrower scope.

## Final Report

Report:

- drift verdict and key findings
- whether a batch already existed or was created
- created issue numbers and URLs, if any
- resolved/skipped/blocked issue numbers
- commits pushed
- validation commands and results
- remaining open issues and which are deferred
