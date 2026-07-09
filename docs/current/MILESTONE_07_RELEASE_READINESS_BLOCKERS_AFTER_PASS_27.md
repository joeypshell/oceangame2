# Milestone 07 Release-Readiness Blockers After Pass 27

Date: 2026-07-09

Issue: #611 `Refresh release-readiness blocker list after Pass 27`

## Verdict

No remaining Milestone 07 player-facing blocker prevents starting Simple Diver Game 08 release-candidate hardening.

Pass 26 clarified completed-run result presentation. Pass 27 addressed the reported direction-change flash with sprite-frame clipping, repeated-reversal smoke, focused capture, visual review, and Web verification. The project should now move into a release-candidate hardening batch rather than adding another presentation feature by default.

## Release-Candidate Blockers

These are blockers before declaring a release candidate complete:

1. No single current validation matrix defines the release gates.
2. No one-command release-candidate validation runner exists yet.
3. The current beginning-to-end/default journey needs one release-focused smoke or composed smoke gate.
4. Capture/baseline inventory needs a release-candidate review index.
5. Fresh local run/import and public Web handoff need release-candidate verification notes.
6. README, milestones, and project context need final release-candidate handoff alignment after the hardening pass.

## Deferred Polish

These are not release-candidate entry blockers:

- #52 `Tune production slice 03 camera framing`
- #53 `Clean production slice 03 topology artifacts in source generator`
- Known file-length allowlist debt in `scripts/main/main.gd` and `scripts/world/greybox_world.gd`
- Broad audio systems, inventory/loadouts, save systems, enemy AI, procedural generation, broad economy, broad art replacement, and full-map productionization

## Next Issue Batch

Created the next scoped Simple Diver Game 08 release-candidate hardening batch:

1. #622 Plan Simple Diver Game 08 release-candidate hardening pass.
2. #623 Define release-candidate validation matrix and blocker gates.
3. #624 Add one-command release-candidate validation runner.
4. #625 Add complete default-journey release smoke coverage.
5. #626 Add release-candidate capture review index.
6. #627 Verify default local run and import quickstart for release candidate.
7. #628 Audit public Web export artifact and Pages handoff for release candidate.
8. #629 Audit accepted visual baselines and capture inventory for release candidate.
9. #630 Refresh README and project context for release-candidate handoff.
10. #631 Add Release Candidate Pass 28 closeout and go/no-go decision.

## Scope Guard

The next batch should harden and prove the current small game rather than expand it. Do not start new map-scale expansion, enemies, procedural generation, inventory/loadout systems, save files, broad economy work, broad art replacement, broad audio systems, or full-map productionization unless a new roadmap issue explicitly changes the selected goal.

## Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
