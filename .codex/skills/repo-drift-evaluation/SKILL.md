---
name: repo-drift-evaluation
description: Fully evaluate this repository for drift from project direction, stale or missing documentation, GitHub issue/backlog mismatch, validation gaps, source-of-truth discipline, and alignment with AGENTS.md. Use when asked to audit, evaluate, assess direction, find drift, review project state, identify documentation updates, plan the next issue batch, or check whether the repo still matches its agent operating guide.
---

# Repo Drift Evaluation

## Purpose

Run an evidence-based project audit. Default to evaluation-only: do not edit files, create issues, close issues, accept baselines, or change source maps unless the user explicitly asks.

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
   - Do not create issues unless the user asks for issue creation.

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
- Active next issues to create or work, intentionally deferred issues, and what not to do yet.

**Validation**
- Commands run and results; commands skipped and why.

**Next Recommended Action**
One specific next action, scoped enough for a GitHub issue.
```

## Guardrails

- Be explicit about uncertainty and distinguish evidence from inference.
- Do not treat old chat memory as source of truth when repo docs or GitHub state disagree.
- Do not silently fix drift during an evaluation unless the user requested edits.
- Do not pad recommendations with vague epics.
- If recommending follow-up issues, include acceptance criteria and verification steps.
