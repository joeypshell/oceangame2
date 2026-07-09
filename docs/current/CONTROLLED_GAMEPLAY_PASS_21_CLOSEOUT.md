# Controlled Gameplay Pass 21 Closeout

Date: 2026-07-09

Issues: #420-#429
Milestone: Simple Diver Game 05 `World Slice Expansion`

## Decision

Pass 21 is complete.

The project now has its first source-authored world-slice connector from the default boat-hub slice into an existing reference slice:

```text
production_slice_01 lower_left_loop_connector -> production_slice_04 relay_sub_entry
```

This is intentionally a narrow connected-slice proof, not full-map productionization, seamless streaming, a map screen, fast travel, persistent save data, or a broad world system.

## Implemented Behavior

- `production_slice_01` remains the default Godot and public Web preview map.
- `production_slice_01` authors `lower_left_loop_connector` as a reachable marker zone with connector metadata.
- `production_slice_04` authors `return_to_boat_hub_connector` as the return-side marker zone.
- Runtime shows a compact prompted connector line while the player is in the connector zone.
- Pressing the interact key at the origin connector loads `production_slice_04` and places the player at `relay_sub_entry`.
- Session wallet and purchased oxygen, cargo, and light upgrades persist across the transition.
- Local expedition state resets for the destination map: held cargo, local banked score, route/result text, oxygen amount, interaction progress, and local salvage availability are rederived from the destination leg.

## Source And Runtime Decisions

- Connector metadata lives in source map/generator data, not hand-placed Godot scene geometry.
- Connector schema and cross-map validation are documented in `docs/MAP_SPEC.md` and enforced through `tools/validate_world_connectors.py`.
- Runtime support is isolated through `scripts/main/world_connector_controller.gd` plus small integration points in `scripts/main/main.gd` and `scripts/world/greybox_world.gd`.
- Pass 21 keeps cross-slice cargo, oxygen continuity, multi-area objectives, and persistent world-state changes deferred.

## Verification

Implemented during the pass:

- Connector schema and validation: #422
- Source-authored connector pair: #423
- Runtime connector transition: #424
- Deterministic smoke: `--smoke-pass-21-world-connector` under #425
- Focused capture: `visual_captures/pass_21_world_connector/production_slice_04_world_connector_arrival.png` under #426
- Visual decision: `docs/current/PASS_21_WORLD_CONNECTOR_VISUAL_BASELINE_DECISION.md` under #427
- Public Web verification: `docs/current/PASS_21_WORLD_CONNECTOR_WEB_PREVIEW_VERIFICATION.md` under #428

Closeout verification:

```powershell
python tools/check_file_lengths.py
git diff --check
```

## Visual Baseline Decision

No production-slice accepted baseline changes were needed for Pass 21.

Normal production-slice captures still match accepted baselines for slices 01-04. The Pass 21 connector capture is a focused review artifact only.

## Stable Areas

Pass 21 intentionally kept these stable:

- terrain topology and collision-derived cave shapes
- default preview map selection
- player movement, collision, and sprite behavior
- salvage values, cargo capacity rules, oxygen drain/refill rules, objective rules, and upgrade costs
- accepted production-slice baselines
- public Web preview initialization and asset packaging

## Remaining Gaps

- The connector proves slice-to-slice travel, but it does not yet create a continuous multi-area expedition with preserved cargo/oxygen/objective state.
- `production_slice_04` is reachable, but it is still a reference slice rather than a fully authored second act.
- Return-side connector behavior is source-authored and visible, but a richer back-and-forth route structure should wait for a specific player-facing reason.
- #52 and #53 remain deferred optional slice-03 polish unless slice-03 presentation becomes the selected goal.

## Next Recommendation

Do not immediately add another connector just because the first one works.

The next batch should stay within Milestone 05 only if it adds player-facing value to the connected-space proof: a small destination-side payoff, a return-loop reason, or a constrained objective that makes the new slice feel remembered and useful. If that cannot be scoped tightly, choose a small Milestone 06 objective/run-structure pass instead.

Avoid enemies, procedural generation, full inventory/loadouts, save files, broad economy, broad art replacement, and full-map productionization.
