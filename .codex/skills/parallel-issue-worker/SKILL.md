---
name: parallel-issue-worker
description: Work as one Codex agent in oceangame2's optional parallel GitHub issue workflow. Use when the user explicitly resumes parallel work and asks an agent to claim one non-overlapping issue. Reuse one dedicated worktree for that agent, create a fresh branch per issue, use PR/CI/merge discipline, and never create a future milestone merely to keep agents busy.
---

# Parallel Issue Worker

## Operating Rule

Claim one GitHub issue at a time, finish or block it, then refresh the queue before taking another issue. Do not permanently own a fixed batch. Do not run broad queue-draining skills while another agent needs independent work unless the user explicitly selects that mode and the queue-health check passes.

## Read First

Read these before claiming:

- `AGENTS.md`
- `docs/current/PROJECT_CONTEXT.md`
- `docs/current/PARALLEL_CODEX_WORKFLOW.md`
- the target issue body, comments, milestone, labels, and linked PRs
- any current pass plan or closeout doc named by the issue

## Queue-Health Check

Before claiming, inspect open issues, active milestones, open PRs, and recent issue comments.

- Prefer the active milestone selected by the user or latest current-state docs.
- Treat `#52` and `#53` as deferred slice-03 polish unless the user explicitly selects slice-03 presentation work.
- Count active unclaimed issues that can be worked independently.
- If active unclaimed issues are fewer than the number of active agents, let excess agents stop and report that the remaining work is serial.
- Do not seed the next milestone merely to prevent an agent from sitting idle.
- If only large risky or overlapping issues remain, report that instead of waiting silently.

Useful commands:

```powershell
gh issue list --state open --limit 100 --json number,title,milestone,labels,url
gh pr list --state open --json number,title,headRefName,url
gh issue view <issue> --comments --json number,title,body,comments,milestone,labels,url
git worktree list
git status --short --branch
```

## Claim Flow

1. Select one issue whose files do not overlap an active claim.
2. Create or reuse the clean dedicated worktree assigned to this agent.
3. Fetch `origin` and create `codex/<issue>-<short-slug>` from current `origin/main`.
4. Comment on the issue before editing.
5. Keep all work scoped to that issue.

Recommended worktree path:

```text
C:\Users\pirat\OneDrive\Documents\oceangame2-agent-<name>
```

Claim comment template:

```markdown
Claimed by <agent name>.

Branch: `codex/<issue>-<short-slug>`
Worktree: `C:\Users\pirat\OneDrive\Documents\oceangame2-agent-<name>`
Expected files:
- `<path>`

Scope: <one sentence>. No unrelated gameplay, map, asset, capture, baseline, or workflow changes.
```

## Overlap Rules

Avoid parallel edits to these files unless the user explicitly coordinates the overlap:

- `scripts/main/main.gd`
- `docs/current/PROJECT_CONTEXT.md`
- `tools/create_production_slice_map.py`
- generated map JSON
- visual baselines and generated captures
- GitHub workflow YAML

Prefer parallel-safe tasks such as planning docs, isolated validators, isolated helper scripts, one focused smoke, or one focused capture. If a task expands into shared files, leave a comment and pick a different issue or ask for coordination.

## Implementation Rules

- Do not push directly to `main`.
- Do not edit the root checkout if it has unrelated dirty files.
- Do not revert unrelated user or agent changes.
- Do not accept visual baselines while another agent is changing runtime, map data, or assets.
- Do not create broad future epics to pad the queue.
- Keep new files under the 500-line policy.
- Use source-of-truth data and generators for map or terrain changes.

## Finish Flow

For the claimed issue:

1. Run the issue's verification steps plus `git diff --check`.
2. Run `python tools/check_file_lengths.py` when available.
3. Self-review against the issue acceptance criteria.
4. Commit on the feature branch.
5. Push and open a PR with `Closes #<issue>`.
6. Wait for required checks when practical.
7. Merge only after the PR is ready.
8. Close or let GitHub close the issue through the PR.
9. Comment with the merge SHA and verification result.
10. Fetch/prune, detach the worktree at current `origin/main`, and delete only the merged issue branch.
11. Refresh the selected milestone and repeat only if the user asked this agent to continue.

Final response should report:

- claimed issue
- worktree path
- branch
- PR or commit
- files changed
- validation run
- next parallel-safe issue, if obvious

## Relation To Other Repo Skills

Use `repo-drift-evaluation` to audit direction or create a missing batch. Use `resolve-github-issues` only for a selected issue or intentionally solo queue drain. Use `drift-batch-resolve` only when the user wants one agent to audit, batch, and drain without parallel throughput concerns.
