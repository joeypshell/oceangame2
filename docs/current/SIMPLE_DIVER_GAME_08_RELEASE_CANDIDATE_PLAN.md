# Simple Diver Game 08 Release-Candidate Plan

Date: 2026-07-09

Issues: #622-#631
Milestone: Simple Diver Game 08 `Release Candidate`

## Decision

Start release-candidate hardening for the current small diver game.

This batch should prove, document, and lock the current experience. It should not add a new connector, map-scale expansion, enemy system, inventory/loadout system, save system, broad economy, broad audio system, broad art replacement, or full-map productionization.

## Goal

Make it clear whether the current game can be treated as a release candidate by answering:

- Can a fresh agent or local user run the default production slice?
- Are the current map, smoke, capture, baseline, and Web checks enough to detect release-blocking drift?
- Is the beginning-to-end default journey covered by a deterministic gate?
- Are release blockers separated from deferred polish?

## Release Gates

Required gates for release-candidate status:

- File-length audit passes with only known allowlisted debt.
- Source map validation and parity checks pass for the production slices used by the release path.
- Asset manifest and committed capture inventory checks pass.
- Existing core smokes pass for salvage, cargo, oxygen, hazards, route/objective/result, progression, and player-facing behavior.
- A release-focused default-journey smoke or composed runner proves the selected beginning-to-end path.
- Baseline comparison/check-clean tooling shows no unintended accepted/current drift.
- Public Web preview build metadata matches the expected deployed runtime/export commit and browser initialization is clean.
- README/current docs explain how to run, verify, and continue the project.

## Planned Issue Batch

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

## Source-Of-Truth Boundaries

- Do not change terrain topology, generated map JSON, or Godot scene geometry in this batch unless a validation blocker proves the source data is wrong.
- Do not accept visual baselines in a validation issue; create a separate issue if intentional visual drift needs acceptance.
- Keep #52 and #53 deferred optional slice-03 polish unless slice-03 presentation becomes the selected release path.

## Validation Plan

Prefer composing existing checks before adding new behavior:

- Use existing Python validators and capture inventory tools.
- Use existing Godot smokes and add only the smallest release-focused smoke wrapper if needed.
- Keep any new runner under 500 lines and make its output easy for future Codex sessions to act on.

## Capture And Web Plan

- Treat release-candidate captures as review evidence, not automatic baseline acceptance.
- Use `compare-all` and `check-clean --all-slices` before any visual decision.
- Verify the public Pages build against the deployed runtime/export SHA; docs-only commits may not trigger a Web export.

## Deferred Work

- #52 and #53 remain optional slice-03 polish.
- Known file-length debt in `scripts/main/main.gd` and `scripts/world/greybox_world.gd` remains tracked as refactor debt, not release-candidate entry work.
- Broad expansion systems stay out of scope until after the simple diver game release-candidate decision.

## Exit Criteria

- The validation matrix exists and names release blockers clearly.
- A future agent can run one command or one documented sequence to verify release-candidate health.
- The default journey, visual review inventory, local run flow, and public Web preview have current verification notes.
- #631 records a go/no-go decision and the exact remaining blockers or deferred polish.

## Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
