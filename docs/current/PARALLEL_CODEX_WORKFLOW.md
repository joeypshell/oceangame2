# Parallel Codex Worktree Workflow

Date: 2026-07-08

Use this workflow when multiple Codex agents work on `oceangame2` at the same time.

## Purpose

Use separate Git worktrees and feature branches for parallel work.

Do not run two agents in the same checkout. This repo has generated assets, Godot metadata, map JSON, visual baselines, and known local dirty files, so a shared working tree makes it too easy for one agent to stage or overwrite another agent's work.

## Core Rule

One agent gets one Git worktree, one feature branch, and one GitHub issue at a time. Agents should not permanently own a fixed issue batch. After finishing or blocking one issue, refresh the queue before claiming the next issue.

## Queue-Health Guard

Before any agent claims work, count active unclaimed issues in the selected milestone.

- If active unclaimed issues are fewer than active agents, seed the next scoped issue batch before claiming more serial closeout work.
- If the active milestone has only review, Web verification, or closeout issues left, create the next milestone batch before one agent monopolizes the dependency chain.
- If only overlapping or high-risk issues remain, report that directly instead of waiting silently.
- Keep `#52` and `#53` deferred unless slice-03 presentation is the selected goal.

This guard exists because review, Web verification, and closeout tasks often depend on prior implementation landing. When one agent takes that serial tail, the other agent can starve unless the next independent batch is already available.

## Coordinator Responsibilities

The primary or coordinator agent should:

- inspect `git status` in the main checkout before assigning work
- leave unrelated dirty files alone
- review open issues, comments, PRs, and milestones
- create or select one scoped GitHub issue per agent
- assign each agent a unique branch and worktree
- comment on the issue with the branch, worktree path, expected files, and scope
- avoid assigning overlapping files unless the dependency is explicit
- merge or rebase branches one at a time after `main` changes

## Worktree Setup

From the main checkout:

```powershell
git fetch origin
git worktree add -b codex/<issue>-<short-slug> C:\Users\pirat\OneDrive\Documents\oceangame2-<issue>-<short-slug> origin/main
```

Use one sibling folder per active agent. Example:

```text
C:\Users\pirat\OneDrive\Documents\oceangame2
C:\Users\pirat\OneDrive\Documents\oceangame2-278-pass14-plan
C:\Users\pirat\OneDrive\Documents\oceangame2-287-parallel-issue-worker-skill
```

Each Codex session should open only its assigned worktree folder.

## Branch And Issue Pattern

Use branch names that include the issue number:

```text
codex/278-pass14-plan
codex/287-parallel-issue-worker-skill
```

Each issue claim comment should include:

```markdown
Claimed by <agent role>.

Branch: `codex/<issue>-<short-slug>`
Worktree: `C:\Users\pirat\OneDrive\Documents\oceangame2-<issue>-<short-slug>`
Expected files:
- `<path>`

Scope: <one-sentence scope>. No unrelated gameplay, map, asset, capture, baseline, or workflow changes.
```

## Parallel-Safe Work

Good parallel splits:

- one agent plans the next pass while another does no-behavior tooling
- one agent updates docs while another works on a narrow helper file
- one agent creates an issue batch while another validates existing map or capture state
- one agent handles a queue-health or workflow doc while another starts the next pass plan

Risky splits that need sequencing:

- two agents editing `scripts/main/main.gd`
- two agents editing `docs/current/PROJECT_CONTEXT.md`
- two agents editing `tools/create_production_slice_map.py`
- one agent changing map source while another accepts visual baselines
- one agent changing runtime visuals while another verifies public Web preview
- one agent regenerating map JSON while another manually edits generated map output

For map or terrain work, update the source or generator first, regenerate outputs, then verify. Do not use a parallel branch to hand-tune generated outputs.

## Merge Expectations

Agents should push feature branches, not `main`.

Before a branch is ready:

```powershell
git diff --check
python tools/check_file_lengths.py
```

Run issue-specific validation as well.

After one branch merges, other active agents should update:

```powershell
git fetch origin
git rebase origin/main
```

If a rebase touches the same source-of-truth file as another active branch, stop and coordinate before resolving conflicts.

## Public Preview Rule

GitHub Pages reflects the deployed `main` workflow, not an arbitrary feature branch. Public Web preview verification should normally happen after the relevant runtime or map branch lands on `main`.

## Skill

Use `$parallel-issue-worker` for this workflow. Use `$resolve-github-issues` only for a selected issue or an intentionally solo queue drain. Use `$drift-batch-resolve` when the user wants one agent to audit, create a batch, and drain it without parallel throughput concerns.
