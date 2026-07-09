# Controlled Gameplay Pass 22 Plan

Date: 2026-07-09

Issue: #502 `Plan Controlled Gameplay Pass 22 around a slice-04 destination payoff`
Milestone: Simple Diver Game 05 `World Slice Expansion`

## Decision

Pass 22 should add one constrained destination-side payoff for the existing Pass 21 connector from `production_slice_01` into `production_slice_04`.

The selected player value is:

```text
Use the lower-left connector, arrive in production_slice_04, find one authored destination cache, and get a compact payoff cue that makes the new slice feel worth revisiting.
```

This is not another connector pass and not full-map productionization. It is one small source-authored reason for the connected destination to matter.

## Target Experience

- `production_slice_01` remains the default preview and boat-hub slice.
- The Pass 21 connector still moves the player to `production_slice_04` at the authored relay entry.
- `production_slice_04` gets one selected payoff target near a route that makes sense from the relay entry and return-side connector.
- The payoff should be readable as a destination cache, not as random extra salvage.
- Existing salvage, oxygen, cargo, upgrades, banking, reset, connector, and result rules stay stable unless a later issue proves a tiny explicit change is needed.

Recommended source id:

```text
slice_04_destination_cache
```

Recommended route/payoff tag:

```text
slice_04_destination_payoff
```

## Meaningful-Change Filter

Pass 22 is worth doing only if it creates connected-space value:

- the destination slice gains a remembered target
- the connector has a reason beyond proving map loading
- the payoff is source-authored and reachable from the destination entry
- smoke and capture make the behavior reviewable

Defer the work if it starts requiring broad world state, a map screen, persistent saves, full inventory/loadouts, enemies, procedural generation, full-map stitching, or another connector.

## Planned Issue Batch

Implementation order:

1. #502 Plan Controlled Gameplay Pass 22 around a slice-04 destination payoff.
2. #503 Document Pass 22 destination payoff source contract.
3. #504 Add destination payoff validation for connected slice metadata.
4. #505 Author one slice-04 destination payoff target through source generator.
5. #506 Implement compact destination payoff runtime feedback.
6. #507 Add deterministic smoke coverage for Pass 22 destination payoff.
7. #508 Add focused Pass 22 destination payoff review capture.
8. #509 Review Pass 22 destination payoff visual impact.
9. #510 Verify public Web preview after Pass 22 destination payoff.
10. #511 Add Pass 22 closeout and next-step evaluation.

## Source-Of-Truth Boundaries

Allowed source work:

- one `production_slice_04` payoff target or marker authored through the generator path
- compact route/payoff metadata, such as a `route_id` or dedicated `destination_payoff_id`
- source validation for supported values and reachability
- regenerated greybox JSON/SVG from the source path

Do not source-author:

- terrain changes by eye
- Godot scene-only geometry
- hidden runtime flags
- broad cross-slice inventory or cargo continuity
- save data, map screens, or fast-travel state

## Runtime And UI Boundaries

Runtime may:

- read the selected payoff metadata from the loaded map
- show compact overlay feedback when the destination payoff is discovered or collected
- keep existing route/result wording if it already covers the state safely
- reuse existing salvage, objective, connector, and feedback helpers

Runtime must not:

- add a new inventory/loadout screen
- add another connector or general world-travel system
- change player movement, collision, oxygen timings, upgrade costs, or salvage values
- change accepted visual baselines as part of runtime implementation

## Validation And Smoke Plan

Validation should prove:

- the payoff id/tag is supported
- metadata appears only on an allowed entity or marker
- the target is in bounds, non-solid, and reachable from the `production_slice_04` relay entry
- the return/extraction path remains valid

Add one focused smoke:

```text
--smoke-pass-22-destination-payoff
```

The smoke should report the origin map, destination map, connector id, payoff id, collected or discovered state, held cargo, banked score, oxygen, and any compact feedback text it verifies.

Existing connector, production-slice route, cargo, oxygen, progression, and feedback smokes should remain green if touched.

## Capture And Visual Plan

Add one focused review artifact:

```text
visual_captures/pass_22_destination_payoff/
```

The preferred capture frames the player in `production_slice_04` near the selected payoff with the compact payoff feedback visible. It is a review artifact, not baseline acceptance.

Before accepting any visual baseline change, compare the normal production-slice captures. Expected stable areas are terrain, camera framing, player body, boat/base visuals, existing salvage and hazard art, connector visuals, objective text, and prior progression/audio feedback.

## Deferred Work

Keep these out of Pass 22:

- #52/#53 slice-03 polish unless slice 03 becomes the selected target
- another connector or full-map productionization
- seamless cross-slice cargo/oxygen/objective continuity
- persistent save data
- map screen or travel menu
- enemies, procedural generation, broad economy, broad audio, or complex inventory/loadout systems
- accepted baseline changes unrelated to the selected destination payoff

## Exit Criteria

Pass 22 is done when:

- the destination payoff contract is documented
- validation protects the selected source metadata
- one payoff is authored through the `production_slice_04` source/generator path
- runtime feedback makes the payoff readable
- deterministic smoke covers the connected destination payoff
- a focused review capture or artifact exists
- visual impact is reviewed
- the public Web preview is verified
- closeout records what changed, what stayed stable, and the next recommendation
