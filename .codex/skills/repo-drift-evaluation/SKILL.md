---
name: repo-drift-evaluation
description: Fully evaluate this repository for drift from project direction, stale or missing documentation, GitHub issue/backlog mismatch, validation gaps, source-of-truth discipline, and alignment with AGENTS.md, then create the recommended scoped GitHub issue batch when the backlog is below target unless the user asks for evaluation-only. Use when asked to audit, evaluate, assess direction, find drift, review project state, identify documentation updates, plan or create the next issue batch, or check whether the repo still matches its agent operating guide.
---

# Repo Drift Evaluation

## Purpose

Run an evidence-based project audit, then create a scoped GitHub issue batch when the audit shows the active actionable backlog is below the repo target or current docs point to untracked concrete work.

Still default to no code/data changes: do not edit files, close issues, accept baselines, or change source maps unless the user explicitly asks. If the user says evaluation-only, no issue creation, report-only, or similar, do not create issues; only recommend the batch.

## Required Reading

Read these first when present:

- `AGENTS.md`
- `docs/current/PROJECT_CONTEXT.md`
- `README.md`
- `docs/MILESTONES.md`
- `docs/current/ARCHITECTURE.md`
- latest relevant pass plan, closeout, visual baseline decision, and Web verification docs under `docs/current/`
- `docs/current/TOOLING.md` or split docs under `docs/current/tooling/`
- `docs/GITHUB_ISSUE_WORKFLOW.md`

Then inspect live repo state:

- `git status --short --branch`
- `git log --oneline -10`
- `gh issue list --state open --limit 100 --json number,title,labels,url`
- recent closed issues if the current docs mention issue ranges
- recent GitHub Actions runs when Web preview, smoke coverage, or deployment status matters

## Audit Workflow

1. **Establish current state.**
   - Identify branch, local dirty files, untracked files, recent commits, open issues, and recently closed work.
   - Separate user/unrelated dirty changes from audit evidence.

2. **Check AGENTS.md alignment.**
   - Verify GitHub issue workflow health, including whether actionable work is represented as issues and whether intentionally deferred issues are clearly marked in docs.
   - Check source-of-truth discipline for map/terrain work: source data or renderer first, generated previews second, screenshots only for confirmation.
   - Check visual workflow discipline: no broad scene regeneration to fix one issue, baselines accepted only after comparison, no generated `.import` or cache files committed.
   - Check scope discipline: small implementation passes, no broad economy/upgrades/enemies/procedural/full-map expansion unless current docs select that goal.

3. **Find documentation drift.**
   - Compare README, MILESTONES, PROJECT_CONTEXT, ARCHITECTURE, closeouts, tooling docs, and issue state.
   - Flag stale "current next issue," stale active issue ranges, missing closeout/Web/baseline docs, old commands, and docs that exceed the file-length policy.
   - Prefer concise update recommendations; if a doc is already oversized, recommend split/archive rather than expansion.

4. **Evaluate roadmap direction.**
   - Apply the project north-star filter from `AGENTS.md`: curiosity, pressure, payoff, remembered-place progress, meaningful route choice, or reason to try another expedition.
   - Identify whether the next documented direction advances the goal or drifts into tooling-only churn, map-scale expansion, broad art replacement, or vague epics.
   - Keep `#52/#53` style deferred items deferred unless the selected goal explicitly returns to that topic.

5. **Check validation coverage.**
   - Prefer safe, fast checks:
     - `python tools/check_file_lengths.py` when present
     - `git diff --check`
     - map validators or parity checks only when map/source drift is under review
     - `gh run list` for CI/Web deployment status
   - Do not run long Godot capture/smoke suites unless the user asks or the audit depends on them.
   - Report commands not run and why.

6. **Assess issue/backlog health.**
   - Count open actionable issues.
   - Distinguish active next work from deferred optional work.
   - Recommend a small issue batch only when the queue is below the project target or the docs point to untracked concrete work.
   - Create the recommended issue batch during the run unless the user explicitly requested evaluation-only/no issue creation or GitHub access is unavailable.
   - Keep intentionally deferred issues such as #52/#53 out of the active batch unless the current selected goal explicitly returns to that topic.

7. **Create the issue batch when needed.**
   - Run a duplicate check against open and recently closed issues before creating anything.
   - Prefer about 10 open actionable issues when the queue is well below target.
   - Use small independently actionable issues; do not pad with vague epics.
   - Each issue body must include: summary, acceptance criteria, relevant docs/code areas, dependencies/blockers, implementation notes, and verification steps.
   - Order issues by dependency. Planning/source-rule issues should precede source/runtime/smoke/capture/visual/Web/closeout issues.
   - Create issues with `gh issue create` or the repo's preferred GitHub workflow.
   - Return created issue numbers and URLs, dependency order, and any recommended issue intentionally not created with the reason.

## Output Format

Return a concise but complete report:

```markdown
**Verdict**
One paragraph on whether the repo is aligned, drifting, or blocked.

**Evidence Read**
Key files, issue ranges, commits, and commands inspected.

**AGENTS.md Alignment**
- Rule/status/evidence/fix for the important project rules.

**Drift Findings**
- Ordered by impact. Include file paths, issue numbers, or command evidence.

**Documentation Updates Needed**
- Concrete docs to update, split, archive, or leave alone.

**Issue And Backlog Recommendations**
- Active next issues created or, in evaluation-only mode, issues to create; intentionally deferred issues; and what not to do yet.

**Created Issues**
- Issue numbers, titles, URLs, dependency order, and any issue intentionally not created.

**Validation**
- Commands run and results; commands skipped and why.

**Next Recommended Action**
One specific next action, scoped enough for a GitHub issue.
```

## Guardrails

- Be explicit about uncertainty and distinguish evidence from inference.
- Do not treat old chat memory as source of truth when repo docs or GitHub state disagree.
- Do not silently fix drift during an evaluation unless the user requested edits.
- Do not skip issue creation when the backlog is below target unless the user requested evaluation-only, GitHub access is unavailable, or every candidate would be duplicate/vague/deferred.
- Do not pad recommendations with vague epics.
- If recommending follow-up issues, include acceptance criteria and verification steps.
