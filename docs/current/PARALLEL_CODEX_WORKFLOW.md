# Parallel Codex Worktree Workflow

Date: 2026-07-08

Use this workflow when multiple Codex agents work on `oceangame2` at the same time.

Parallel work is optional and is not the default resolver mode. Prefer the single-agent bounded milestone workflow unless the user explicitly resumes multiple agents and enough independent work already exists.

## Purpose

Use separate Git worktrees and feature branches for parallel work.

Do not run two agents in the same checkout. This repo has generated assets, Godot metadata, map JSON, visual baselines, and known local dirty files, so a shared working tree makes it too easy for one agent to stage or overwrite another agent's work.

## Core Rule

One active agent gets one dedicated Git worktree that it reuses across sequential issues. Each claimed issue gets a fresh feature branch. Agents should not permanently own a fixed issue batch.

## Queue-Health Guard

Before any agent claims work, count independent unclaimed issues in the selected committed milestone.

- Do not create the next milestone's batch merely to keep every agent busy.
- If independent work is fewer than active agents, let excess agents stop or report that the remaining dependency chain is serial.
- If only overlapping or high-risk issues remain, sequence them instead of forcing parallel work.
- Keep deferred issues deferred unless their topic becomes the selected goal.

Agent utilization is secondary to source ownership, merge safety, and milestone coherence.

## Coordinator Responsibilities

The primary or coordinator agent should:

- inspect `git status` in the main checkout before assigning work
- leave unrelated dirty files alone
- review open issues, comments, PRs, and milestones
- create or select one scoped GitHub issue per agent
- assign each agent one persistent worktree and one current issue branch
- comment on the issue with the branch, worktree path, expected files, and scope
- avoid assigning overlapping files unless the dependency is explicit
- merge or rebase branches one at a time after `main` changes

## Worktree Setup

Create one sibling worktree per active agent, based on current `origin/main`:

```powershell
git fetch origin --prune
git worktree add C:\Users\pirat\OneDrive\Documents\oceangame2-agent-a origin/main
```

Reuse that worktree for each issue assigned to that agent. Example:

```text
C:\Users\pirat\OneDrive\Documents\oceangame2
C:\Users\pirat\OneDrive\Documents\oceangame2-agent-a
C:\Users\pirat\OneDrive\Documents\oceangame2-agent-b
```

Each Codex session should open only its assigned worktree folder.

## Branch And Issue Pattern

Use branch names that include the issue number:

```text
codex/278-pass14-plan
codex/287-parallel-issue-worker-skill
```

Before starting each issue in the assigned clean worktree:

```powershell
git fetch origin --prune
git switch -c codex/<issue>-<short-slug> origin/main
```

Each issue claim comment should include:

```markdown
Claimed by <agent role>.

Branch: `codex/<issue>-<short-slug>`
Worktree: `C:\Users\pirat\OneDrive\Documents\oceangame2-agent-<name>`
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

The agent whose branch merged should return its worktree to a reusable clean state and delete only that merged branch:

```powershell
git fetch origin --prune
git switch --detach origin/main
git branch -d codex/<issue>-<short-slug>
```

Do not remove another agent's worktree or mass-clean historical worktrees as part of issue resolution.

## Public Preview Rule

GitHub Pages reflects the deployed `main` workflow, not an arbitrary feature branch. Public Web preview verification should normally happen after the relevant runtime or map branch lands on `main`.

## Skill

Use `$parallel-issue-worker` for this workflow. Use `$resolve-github-issues` only for a selected issue or an intentionally solo queue drain. Use `$drift-batch-resolve` when the user wants one agent to audit, create a batch, and drain it without parallel throughput concerns.
