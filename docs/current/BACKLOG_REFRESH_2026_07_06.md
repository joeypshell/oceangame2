# Backlog Refresh

Date: 2026-07-06

Issue: #74 `Refresh actionable backlog after prop sprite pass`

## Purpose

Restore a useful near-term GitHub issue queue after the #70 prop sprite pass, #71 baseline decision, #72 web verification, and #73 Controlled Visual Revision 02 plan.

This refresh keeps #52 and #53 intentionally deferred. They remain optional slice-03 polish issues and should not be pulled into active work unless the accepted slice-03 reference intentionally changes.

## Recommended Order

1. #82 `Prevent baseline accept from copying import sidecars`
2. #75 `Reconcile production slice 01 accepted baseline`
3. #76 `Add player-focused visual capture path`
4. #77 `Implement controlled player sprite pass`
5. #78 `Decide player sprite baseline acceptance`
6. #79 `Verify public web preview after player sprite pass`
7. #80 `Validate committed asset manifest paths`
8. #81 `Expose web build metadata for preview verification`
9. #83 `Add controlled visual revision checklist`
10. #84 `Plan controlled visual revision 03`

## Rationale

#82 should happen before more baseline acceptance work because #71 exposed that the baseline accept command can copy ignored `.import` sidecars locally.

#75 should happen before relying on `production_slice_01` for clean controlled visual-revision diffs. Its accepted baseline is broader and older than the current six-view capture set.

#76-#79 are the scoped Controlled Visual Revision 02 chain: establish a player-focused review capture, implement the player sprite, decide baseline acceptance, then verify the public web preview.

#80 and #81 harden the asset and Web preview workflow around gaps found during the prop pass. #83 captures the repeated process as a reusable checklist, and #84 starts the next planning cycle only after the player pass is reviewed or deliberately deferred.

## Deferred Issues

Keep these open but inactive:

- #52 `Tune production slice 03 camera framing`
- #53 `Clean production slice 03 topology artifacts in source generator`

Both are intentionally deferred unless future art direction chooses to alter the accepted slice-03 baseline.

## Verification

Completed for this refresh:

```powershell
gh issue list --state open --limit 100
git diff --check
```
