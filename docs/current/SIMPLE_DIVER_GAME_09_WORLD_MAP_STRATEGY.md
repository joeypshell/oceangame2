# Simple Diver Game 09 Connected-World And Map Strategy

Date: 2026-07-09

Issue: #647
Milestone: Simple Diver Game 09 `2D Subnautica Expansion Planning`

## Decision

Build the first expansion as an explicit three-area connector graph using existing validated production slices:

```text
production_slice_01 (surface boat hub)
        <-> production_slice_04 (lower-left relay and final-dive signal)
        <-> production_slice_02 (lower-right anomaly destination)
```

Do not make a seamless full-sketch runtime map and do not author new terrain for the first expansion slice. The first implementation should add source-authored bidirectional travel between adjacent slice-04 and slice-02 regions, then author the anomaly survey content inside slice 02 through its generator.

This shape turns the existing final-dive signal into a destination, gives the player a remembered route through slice 04, and reuses a proven later-game chamber without moving the default boat hub.

## Why Slice 02

- Its full-sketch bounds begin at `x=88`, directly beside slice 04's right edge at `x=88`; their vertical bounds overlap.
- It is already validated as a later-game chamber/relay destination with a broad main room and lower terminal.
- Entry, extraction, route smoke, capture completeness, parity, and accepted baseline are already present.
- It has no open presentation blockers.
- Its role differs from the compact slice-03 landmark cluster and the slice-04 return loop.

Selection does not promote slice 02 to the default preview. It becomes the bounded anomaly destination reached through runtime travel from the existing journey.

## Source Roles

### Full Sketch

`maps/full_cave_sketch_01.greybox.json` remains a topology/planning atlas and global-coordinate reference. It is not loaded as the production world for this expansion.

Use it to confirm adjacency, derive bounded slices, and avoid contradictory geography. Do not hand-edit it to place expansion gameplay and do not infer supplied screenshot icons as entities.

### Production Slice 01

- Role: surface boat hub, first dive, preparation, and return context.
- Status: default Godot/public preview remains unchanged.
- Existing connector: `lower_left_loop_connector` to slice 04.
- Expansion rule: no new topology; preserve the release-candidate journey and its smoke.

### Production Slice 04

- Role: remembered lower-left route, relay, and source of `lower_left_final_dive_signal`.
- Existing return: `return_to_boat_hub_connector` to slice 01.
- Planned source change: one forward connector near the east/central-cave context to slice 02, authored in `tools/create_production_slice_04_map.py`.
- Expansion rule: the final-dive signal gates or explains the new lead; travel metadata must not encode save state, score, oxygen, or objective completion.

### Production Slice 02

- Role: first anomaly-survey destination and return endpoint.
- Existing entry: `relay_sub_entry` with in-water relay extraction.
- Planned source changes: one return connector to slice 04 plus one bounded anomaly objective/interaction area, authored in `tools/create_production_slice_02_map.py` after its source contract lands.
- Expansion rule: reuse existing terrain and camera context unless the authored objective cannot be placed reachably without a separately reviewed topology issue.

### Production Slice 03

- Role: future compact landmark/connector-room candidate.
- Status: reference slice only; not selected for the first expansion graph.
- #52/#53 remain deferred optional camera/topology polish.

## Identity And Connector Contract

Keep existing map identities and committed paths stable:

- `production_slice_01` -> `res://maps/production_slice_01.greybox.json`
- `production_slice_04` -> `res://maps/production_slice_04.greybox.json`
- `production_slice_02` -> `res://maps/production_slice_02.greybox.json`

Use the existing source-authored `zones[].world_connector` contract. Every connector must provide a unique lower_snake_case ID, display label, destination map ID/path, existing destination entry ID, and direction.

The first expansion should use two explicit records rather than assuming reciprocal travel:

- slice 04 forward connector -> slice 02 `relay_sub_entry`
- slice 02 return connector -> slice 04 `relay_sub_entry`

The exact connector IDs, source rectangles, labels, and gating rule belong in a focused source contract and validator issue. Marker rectangles must be in-bounds, non-solid, and reachable from the source entry and intended objective/return route.

Do not add a generic world graph database, map screen, fast travel system, seamless coordinate streaming, or scene-authored portal nodes for this first link.

## Destination And State Boundaries

- World travel loads one committed map at one authored entry; only one slice is active at a time.
- Destination-local salvage, hazard, objective, and oxygen state follows existing transition/reset behavior until #648 defines persistence.
- Existing session wallet and upgrades keep their current connector behavior.
- The new anomaly discovery may persist only through the owner and lifetime selected by #648; connector metadata must not store it.
- Failure must return/restore state according to the selected expedition contract, not strand the player in an invalid destination.
- The boat in slice 01 remains the canonical surface preparation and complete-expedition return context.

## Source And Runtime Ownership

| Concern | Owner |
| --- | --- |
| Slice topology and entities | Slice-specific Python generator |
| Generated map artifact | `maps/production_slice_0X.greybox.json` |
| Connector/anomaly schema rules | `docs/MAP_SPEC.md` and `tools/validate_greybox_map.py` |
| Terrain/collision rendering | Existing Godot world render/collision helpers |
| Connector lookup and map load | Existing world/main connector controllers, behind focused extensions |
| Expansion discovery lifetime | State owner selected by #648, never map marker metadata |
| Route integration checks | New connector/anomaly smoke helper plus existing route/release smokes |
| Visual review | Existing named captures, focused expansion capture, baseline comparison |

Godot scenes remain consumers. They must not contain alternate connector rectangles, topology, collision, or anomaly placement that is absent from generated source JSON.

## Implementation And Regeneration Order

For the later implementation batch:

1. Document exact connector/anomaly source fields and state boundaries.
2. Extend validation with negative cases or existing validator-test patterns.
3. Update `create_production_slice_04_map.py` and `create_production_slice_02_map.py`.
4. Regenerate only slice 04 and slice 02 JSON.
5. Regenerate only their SVG previews and source/render/collision review artifacts when visually relevant.
6. Validate both maps and check runtime terrain/collision parity.
7. Run existing slice-02/slice-04 route smokes plus a focused bidirectional connector/anomaly smoke.
8. Regenerate only affected focused/current captures.
9. Compare accepted baselines before deciding whether any intentional difference should be accepted.
10. Verify the public Web preview and deployed commit metadata.

Representative source checks:

```powershell
python tools/create_production_slice_04_map.py
python tools/create_production_slice_02_map.py
python tools/render_greybox_map.py maps/production_slice_04.greybox.json references/greybox/production_slice_04.svg
python tools/render_greybox_map.py maps/production_slice_02.greybox.json references/greybox/production_slice_02.svg
python tools/validate_greybox_map.py maps/production_slice_04.greybox.json
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
python tools/check_map_parity.py maps/production_slice_04.greybox.json
python tools/check_map_parity.py maps/production_slice_02.greybox.json
```

## Acceptance Gates For Future Map Work

- Connector source and destination IDs/paths/entries resolve exactly.
- Source connector water is reachable and non-solid on both maps.
- An open-water route exists from slice-02 entry to the anomaly and back to return/extraction.
- Generated terrain and collision remain parity-clean.
- Existing slice route smokes and the complete release journey remain green.
- Current-vs-accepted capture comparisons show no unrelated terrain, camera, player, boat/relay, prop, or UI drift.
- Web preview initializes at both tested viewports with matching build metadata and no failed requests or Godot errors.

## Explicitly Deferred

- production-slice-03 integration and #52/#53 polish
- new terrain topology solely to make the connector more dramatic
- seamless full-map runtime, streaming, minimap, or fast travel
- additional destinations beyond slice 02
- broad biome production or full-sketch productionization

## Planning Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
