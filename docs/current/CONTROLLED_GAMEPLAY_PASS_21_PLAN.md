# Controlled Gameplay Pass 21 Plan

Date: 2026-07-09

Issue: #420 `Plan Controlled Gameplay Pass 21 around one world-slice connector`
Milestone: Simple Diver Game 05 `World Slice Expansion`

## Decision

Pass 21 should add the first narrow world-slice connector between existing validated slices:

```text
production_slice_01 boat hub -> lower-left relay connector -> production_slice_04 return-loop slice
```

This is not full-map productionization. It is one source-authored connector pair that proves the project can move from the default slice into a second authored area through data, validation, runtime transition, smoke, capture, visual review, and Web preview.

## Target Experience

- `production_slice_01` remains the default preview and first-area boat hub.
- The player can discover a compact connector cue on the selected route edge.
- Triggering the connector loads `production_slice_04` and places the player at its relay entry.
- The transition should feel like reaching a remembered lower-left route, not like a debug map selector.
- Session progression from Pass 18-20 persists across the transition.
- The first pass may treat the destination as a fresh local dive leg from the relay; continuous cross-slice cargo/oxygen persistence can wait unless the contract keeps it safe.

## Meaningful-Change Filter

Pass 21 is worth doing only if it creates connected-space progress:

- one existing reference slice becomes reachable through authored source data
- the connector is visible and readable without debug overlays
- deterministic smoke proves origin, destination, and placement
- the player can recognize `production_slice_04` as a connected lower-left loop role

If the work starts requiring full-map stitching, broad world state persistence, save files, a map screen, procedural travel, or a generalized fast-travel system, defer that to a later Milestone 05 or release-candidate pass.

## Connector Target

Use `production_slice_01` to `production_slice_04`.

Rationale:

- Slice 01 is the current default and has the clearest boat hub.
- Slice 04 is already documented as a lower-left connector/return-loop reference.
- Slice 04 has a relay entry/extraction model that can serve as the destination without inventing a surface boat.
- Slice 03 remains explicitly deferred under #52/#53 unless the project selects slice-03 presentation as the active goal.

Recommended connector id:

```text
lower_left_loop_connector
```

Recommended destination:

```text
production_slice_04
```

## Planned Issue Batch

Implementation order:

1. #420 Plan Controlled Gameplay Pass 21 around one world-slice connector.
2. #421 Document Pass 21 connector metadata contract and boundaries.
3. #422 Add connector zone schema to map spec and validator.
4. #423 Author one connector zone pair between `production_slice_01` and `production_slice_04`.
5. #424 Implement one runtime connector transition between production slices.
6. #425 Add deterministic Pass 21 connector transition smoke coverage.
7. #426 Add focused Pass 21 connector route review capture.
8. #427 Review Pass 21 visual impact and baseline decision.
9. #428 Verify public Web preview after Pass 21 connector pass.
10. #429 Add Pass 21 closeout and next-step evaluation.

## Source-Of-Truth Boundaries

Connector placement must be authored in map source/generator data first.

Allowed source work:

- marker-zone connector metadata
- origin map id and destination map id
- connector label
- destination entry/spawn reference if needed
- validation-only intent text

Do not source-author:

- runtime transition flags
- persisted player progress
- cargo or oxygen values
- score or wallet changes
- terrain changes by eye
- visual-only Godot scene edits

## Runtime And UI Boundaries

Runtime may:

- read connector metadata from the loaded map
- show compact connector prompt/status text
- load the destination map through the existing map-loading path
- place the player at the destination relay/spawn
- preserve session wallet and purchased upgrades

Runtime must not:

- add a map screen, inventory screen, store scene, or fast-travel menu
- add persistent save data
- merge the full sketch into one giant production map
- change player movement, collision, salvage values, objective rules, or upgrade costs
- change accepted visual baselines as part of runtime implementation

## Validation And Smoke Plan

Add one focused smoke:

```text
--smoke-pass-21-world-connector
```

The smoke should verify:

- origin map id
- connector id and label
- transition trigger
- destination map id
- destination placement near the authored relay/spawn
- session wallet and Pass 18-20 upgrades persist
- no stale origin overlay/result text leaks into the destination state

Existing production-slice route smokes and progression smokes should remain green.

## Capture And Visual Plan

Add one focused review capture:

```text
visual_captures/pass_21_world_connector/
```

The capture should show either the connector discovery prompt in slice 01 or the immediate destination-arrival state in slice 04, whichever better communicates the new route connection.

Normal production-slice baselines should be compared before accepting anything. Expected stable areas are terrain, camera framing, player body, boat/base visuals, salvage art, hazard art, objectives, prior progression prompts, and existing accepted slice captures.

## Deferred Work

Keep these out of Pass 21:

- #52/#53 slice-03 polish unless slice 03 becomes the selected target
- full-map productionization
- seamless multi-area world streaming
- persistent saves
- map screen or travel menu
- cross-slice objective chains beyond the one connector proof
- broad art replacement
- enemies, procedural generation, or complex inventory/loadout systems

## Exit Criteria

Pass 21 is done when:

- the connector contract is documented
- connector metadata is validated
- one connector pair is authored through source/generator data
- runtime can transition from slice 01 to slice 04 through the connector
- deterministic smoke covers the transition
- a focused capture exists for review
- visual impact is reviewed
- public Web preview is verified
- closeout records what changed, what stayed stable, and the next recommendation
