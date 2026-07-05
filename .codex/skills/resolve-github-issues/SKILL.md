---
name: resolve-github-issues
description: Autonomously resolve selected open GitHub issues in the current repository, one issue at a time, until the requested issue set is complete or all remaining selected issues are invalid, duplicate, already fixed, intentionally deferred, or blocked. Use when the user asks Codex to drain, close, resolve, work through, or complete open GitHub issues, especially from a prompt that says to list open issues, select the next issue, implement fixes, validate, self-review, commit, push, and close each issue without stopping for confirmation.
---

# Resolve GitHub Issues

## Overview

Run an autonomous issue-resolution loop for the current repository. Keep each issue as a distinct unit of understanding, implementation, validation, commit, push, and close-out. Respect the user's requested scope: all issues, a named epic, a label, a numbered issue list, or the next small project-priority issues.

## Initial Setup

1. Inspect repository instructions before making changes. Read `AGENTS.md` and any project-specific development or GitHub issue workflow docs it names.
2. Confirm the working tree state with `git status --short --branch`. Preserve unrelated user changes.
3. Confirm GitHub access with `gh auth status` when the repo uses GitHub Issues.
4. List open issues with `gh issue list --state open --limit 100` or the repository's preferred issue workflow.
5. Select the next issue using the user's requested scope first, then project priority if documented; otherwise use the issue list order. Do not select epic/meta issues, intentionally deferred issues, or later-roadmap issues unless the user explicitly includes them.

## Per-Issue Loop

For each selected issue:

1. Read the full issue, comments, labels, linked PRs, linked issues, handoffs, and relevant repository files.
2. Restate the issue in your own words before editing.
3. Identify expected behavior, current behavior, likely cause, and acceptance criteria. If the issue is a docs or workflow task, translate these into requested output, current gap, relevant owner files, and completion criteria.
4. Implement the smallest correct fix or requested change. Avoid broad unrelated refactors.
5. Add or update tests when appropriate for the risk and project conventions.
6. Run relevant verification: tests, type checks, linting, builds, targeted scripts, or documentation validation. Record any blocker exactly.
7. Self-review before closing:
   - Re-read the original issue and comments.
   - Confirm every requested item was addressed.
   - Confirm the interpretation matches the issue intent.
   - Confirm changes are scoped to the issue.
   - Confirm tests or validation cover the fix where practical.
   - Confirm there are no obvious regressions, dead code, debug output, formatting issues, or unrelated changes.
   - Summarize exactly what changed and why.
8. Commit a small coherent change for the issue, referencing the issue number when practical.
9. Push the commit before closing the issue unless the project explicitly uses a different close-out policy.
10. Close the issue only after validation, self-review, commit, and push are complete.

After finishing one issue, immediately refresh the open issue list and continue with the next selected issue without asking for confirmation. Stop when the requested scope is complete, even if unrelated open issues remain.

## Skipping Or Blocking

Do not skip selected issues except when they are invalid, duplicates, already fixed, intentionally deferred by the roadmap/user, or blocked by missing information or unavailable external state. When skipping or blocking:

- Leave the issue open unless it is a duplicate, invalid, or already fixed according to repository policy.
- Add a GitHub comment explaining the reason, evidence, and what would unblock it.
- Continue to the next open issue.

Ask the user for clarification only when inspection cannot produce a safe reasonable interpretation.

## Close-Out

Stop when the requested issue scope is complete. If the user explicitly requested all open issues, stop only when `gh issue list --state open` shows no open issues or every remaining open issue has been documented as blocked, intentionally deferred, or intentionally left open. Final response should report:

- issues resolved, skipped, or blocked
- commits and push status
- verification run
- remaining open issues, if any
