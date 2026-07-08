# Parallel Codex Worktree Workflow

Date: 2026-07-08

Issue: #234 `Document parallel Codex worktree workflow`

## Purpose

Use separate Git worktrees and feature branches when multiple Codex agents work on `oceangame2` at the same time.

Do not run two agents in the same checkout. This repo has generated assets, Godot metadata, map JSON, visual baselines, and known local dirty files, so a shared working tree makes it too easy for one agent to stage or overwrite another agent's work.

## Coordinator Responsibilities

The primary/coordinator agent should:

- inspect `git status` in the main checkout before assigning work
- leave unrelated dirty files alone
- review open issues and milestones
- create or select one scoped GitHub issue per agent
- assign each agent a unique branch and worktree
- comment on the issue with the branch and worktree path
- avoid assigning overlapping files unless the dependency is explicit
- merge or rebase branches one at a time after `main` changes

## Worktree Setup

From the main checkout:

```powershell
git fetch origin
git worktree add ..\oceangame2-agent-pass13 -b codex/234-short-name origin/main
```

Use one sibling folder per active agent. Example:

```text
C:\Users\pirat\OneDrive\Documents\oceangame2
C:\Users\pirat\OneDrive\Documents\oceangame2-agent-pass13
C:\Users\pirat\OneDrive\Documents\oceangame2-agent-refactor
```

Each Codex session should open only its assigned worktree folder.

## Branch And Issue Pattern

Use branch names that include the issue number:

```text
codex/234-parallel-worktree-workflow
codex/235-pass13-plan
codex/236-main-gd-refactor
```

Each issue claim comment should include:

```text
Claimed by <agent role>.
Worktree: <absolute path>
Branch: <branch name>
Scope: <one-sentence scope>
```

## Parallel-Safe Work

Good parallel splits:

- one agent plans the next pass while another does no-behavior tooling
- one agent updates docs while another works on a narrow helper file
- one agent creates an issue batch while another validates existing map/capture state

Risky splits that need sequencing:

- two agents editing `scripts/main/main.gd`
- two agents editing `docs/current/PROJECT_CONTEXT.md`
- two agents editing `tools/create_production_slice_map.py`
- one agent changing map source while another accepts visual baselines
- one agent changing runtime visuals while another verifies public Web preview
- one agent regenerating map JSON while another manually edits generated map output

For map or terrain work, update the source/generator first, regenerate outputs, then verify. Do not use a parallel branch to hand-tune generated outputs.

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

GitHub Pages reflects the deployed `main` workflow, not an arbitrary feature branch. Public Web preview verification should normally happen after the relevant runtime/map branch lands on `main`.

## Current Recommended Parallel Tracks

As of Pass 12 closeout, the safest next parallel tracks are:

- Pass 13 planning/issue batch around one expedition objective or retry target
- no-behavior file-length refactor planning or helper extraction
- tooling/documentation work that avoids `PROJECT_CONTEXT.md` unless explicitly assigned

Keep #52 and #53 deferred unless slice-03 presentation becomes the selected goal.
