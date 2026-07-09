# Controlled Gameplay Pass 25 Plan

Date: 2026-07-09

Milestone: Simple Diver Game 06 `Objective And Run Structure`

Issues: #562-#571

## Decision

Pass 25 will add one tiny source-authored final-dive objective seed that follows from the Pass 24 relay confirmation.

The selected shape is:

```text
Deep cache objective complete -> lower-left relay investigated -> final-dive signal discovered
```

This is a capstone seed, not a full final mission. It should make the prototype feel like it is pointing toward a finishable small-game arc while staying inside the existing source-map, objective, salvage, oxygen, connector, overlay, smoke, capture, visual-review, and Web-preview workflow.

## Target Experience

- The player completes the existing default-slice objective chain.
- The Pass 23/24 lower-left relay follow-through remains the bridge into the next objective.
- One authored source marker or target presents a compact final-dive/capstone cue.
- The cue should be visible at the right moment, not as a permanent quest log.
- Result text should confirm the seed when the player completes the planned action.
- Failure, reset, and maps without the metadata should not show stale capstone text.

## Meaningful-Change Filter

The pass should create at least one of these player-facing values:

- a clearer reason to attempt another dive
- a stronger sense that the route/objective chain has a destination
- a compact payoff for remembering the lower-left relay
- a decision point for whether Milestone 06 is complete

If the planned behavior cannot satisfy one of those, the pass should close Milestone 06 and move to Milestone 07 presentation/game feel instead of adding another label.

## Planned Issue Batch

1. #562 Plan Controlled Gameplay Pass 25 around final-dive objective seed.
2. #563 Document Pass 25 final-dive objective source contract.
3. #564 Add Pass 25 final-dive objective validation.
4. #565 Author one Pass 25 final-dive objective seed in source.
5. #566 Implement compact Pass 25 final-dive objective runtime feedback.
6. #567 Add deterministic Pass 25 final-dive objective smoke coverage.
7. #568 Add focused Pass 25 final-dive objective review capture.
8. #569 Review Pass 25 visual impact and baseline decision.
9. #570 Verify public Web preview after Pass 25 final-dive objective.
10. #571 Add Pass 25 closeout and Milestone 06 decision.

## Source-Of-Truth Boundaries

- Add metadata through the established map source or generator path.
- Do not hand-tune Godot scene geometry or collision.
- Do not change terrain topology unless a later source-authoring issue explicitly justifies it.
- Keep `production_slice_01` as the default preview map.
- Use `production_slice_04` only if the contract needs the existing lower-left relay follow-through as the capstone seed's source.
- Maps without Pass 25 metadata must preserve current behavior.

## Runtime And UI Boundaries

- Reuse compact overlay/result text patterns.
- Prefer focused helper code over growing `scripts/main/main.gd`.
- Preserve existing salvage, cargo, oxygen, hazard, progression, connector, primary-objective, next-dive, and relay follow-through behavior.
- The final-dive seed is session/prototype state only; it is not a save-heavy mission tracker.

## Validation And Smoke Plan

Validation should catch broken metadata before runtime work:

- missing or duplicate capstone objective ids
- references to unknown route, marker, connector, salvage, or objective ids
- unsupported display labels or objective kinds
- unreachable authored targets where reachability applies
- accidental requirement on maps that do not opt in

Smoke should verify:

- metadata loads for the selected map
- capstone feedback is hidden before the planned trigger
- feedback/result text appears after the planned trigger
- reset and failure do not leave stale text
- maps without Pass 25 metadata keep prior objective behavior

## Visual And Capture Plan

- Add one focused review capture for the capstone cue or result state.
- Do not accept baselines in the capture issue.
- In the visual-review issue, compare accepted production-slice baselines before accepting anything.
- Prefer no baseline change if the capstone cue can be reviewed through the focused capture only.

## Non-Goals

- No quest log.
- No persistent save system.
- No complex mission chain.
- No inventory or loadout screen.
- No enemy AI or combat.
- No procedural generation.
- No broad economy or broad upgrade work.
- No broad audio, music, ambience, or options work.
- No broad art replacement.
- No full-map productionization.

## Exit Criteria

- One source-authored final-dive/capstone objective seed exists or the pass explicitly decides not to add one.
- Runtime feedback and result text are compact, deterministic, and reset-safe.
- Validator, smoke, focused capture, visual review, and Web preview verification cover the seed.
- The closeout states whether Milestone 06 is complete or needs one more small objective/run-structure batch.
