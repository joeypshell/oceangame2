# Milestone 07 Release-Readiness Audit

Date: 2026-07-09

Issue: #591
Milestone: Simple Diver Game 07 `Presentation And Game Feel`

## Decision

Milestone 07 should continue with one more focused presentation/game-feel pass before release-candidate preparation.

The next pass should target player movement and direction-change readability, especially the reported direction-change flash where the diver can briefly appear to face both directions. This is more release-relevant than adding another connector, objective, economy beat, or map-scale expansion.

## Current State

- Pass 26 completed the first Milestone 07 result-presentation improvement.
- The compact result panel now prioritizes objective/payoff text and shows `Final dive signal locked` when the final-dive payoff is completed.
- Smoke, focused capture, visual review, Web preview verification, and closeout exist for Pass 26.
- #52 and #53 remain deferred optional slice-03 polish.
- The active non-deferred backlog is below the target rolling queue after #590.

## Release-Readiness Gaps

1. Player-facing transition confidence.
   - The project has previous facing fixes and `--smoke-player-facing`, but the user has reported a remaining visual flash during direction changes.
   - This affects moment-to-moment feel in every dive and should be checked before broader polish.

2. Movement-feel review evidence.
   - Existing smoke coverage measures movement behavior, but Milestone 07 needs a focused visual/capture review path for reversal and direction-change readability.

3. Presentation polish boundary.
   - Result text is now clearer, so the next work should avoid growing UI scope unless it directly improves play clarity.

4. Release-candidate discipline.
   - The project should keep using small pass batches with plan, runtime, smoke, capture, visual decision, Web verification, and closeout.

## Drift Check

- Roadmap direction remains aligned with the finished small diver game target.
- Source-of-truth discipline remains intact; no map or terrain change is needed for the next pass.
- The deferred slice-03 issues should stay deferred unless slice-03 presentation becomes the selected goal.
- Do not expand into enemies, procedural generation, full inventory/loadout systems, save files, broad economy, broad art replacement, broad audio, or full-map productionization.

## Recommended Next Batch

Created Controlled Gameplay Pass 27 around player movement/facing feel:

1. #602 Plan Pass 27 around player movement and direction-change readability.
2. #603 Reproduce and document the direction-change flash.
3. #604 Fix direction-change rendering so the diver never appears double-facing.
4. #605 Evaluate movement reversal feel without changing route semantics.
5. #606 Add deterministic smoke coverage for facing transitions.
6. #607 Add a focused movement/facing review capture.
7. #608 Review Pass 27 visual impact without accepting unrelated baseline drift.
8. #609 Verify public Web preview after Pass 27.
9. #610 Add Pass 27 closeout and next-step evaluation.
10. #611 Refresh the release-readiness blocker list after Pass 27.

## Exit Criteria For The Next Pass

- Direction changes are visually stable in local review and Web preview.
- Existing movement, oxygen, cargo, salvage, hazard, objective, and result semantics are unchanged.
- Smoke and capture coverage make the regression easy for future agents to check.
- Any remaining game-feel or release-readiness work is captured as scoped follow-up issues.

## Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
