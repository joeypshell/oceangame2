# Production Slice 03 Decision

Date: 2026-07-05

Issue: #49 `Select candidate for production slice 03`

## Selection

Use the upper-left room cluster from `docs/current/FULL_SKETCH_EVALUATION_01.md` as the third focused production-slice candidate.

Starting bounds in `maps/full_cave_sketch_01.greybox.json`:

```text
x: 0
y: 8
w: 76
h: 82
```

This is a slight widening of the original Candidate B sketch bounds (`x=0, y=8, w=64, h=82`) so implementation can preserve the east-side connector context instead of cropping the room cluster too tightly.

## Role

Primary role: connector.

Secondary role: landmark room cluster.

This slice should test compact room-to-room navigation and a memorable upper-left cluster, not another first-area boat route and not another later-game lower chamber.

## Rationale

Slice 01 already proved the top-center first-area entry hub with `boat_spawn`.

Slice 02 already proved a later-game lower-right destination/connector using `spawn + base`.

Slice 03 should therefore test a different problem:

- compact stacked rooms instead of one broad chamber
- upper-left room progression into a larger route
- cleanup cost for tight stair-stepped conversion shapes
- crop-edge handling along the full-map left side
- route readability through a denser room cluster

This keeps the project moving across different topology types without trying to productionize the whole full sketch at once.

## Spawn And Extraction Plan

Use `spawn + base`, not `boat_spawn`.

The upper-left cluster has no honest top-water surface opening for a boat. Implementation should place an in-water relay/base near the east-side connector back toward the central hub so the player enters from believable larger-map context, explores the upper-left rooms, then returns to the same relay.

If implementation cannot place a reachable relay without inventing topology, defer the slice rather than forcing a fake boat or hand-tuned scene entry.

## Authored Gameplay Plan

Source sketch icons remain ignored. Gameplay objects should be reauthored in JSON.

Initial target density:

- 4 to 5 salvage entities spread across the stacked rooms and connector path
- 2 to 3 hazards at chokepoints or return-pressure locations
- route markers for the room cluster, east connector, and any lower return path
- camera tests for overview, relay entry, stacked rooms, connector, and return route

## Crop And Cleanup Risks

- Left map edge may feel natural because it is also the full-sketch boundary, but any open pockets along that side must still be intentional and reachable.
- East connector should not be cropped so tightly that the relay fiction feels arbitrary.
- The room cluster has more small shapes than slices 01 and 02, so stair-stepped conversion artifacts may require source-generator cleanup.
- If sealed crop edges hide the reason the route is interesting, adjust bounds before authoring gameplay objects.

## Required Verification For Implementation

The implementation issue should verify:

```powershell
python tools/create_production_slice_03_map.py
python tools/render_greybox_map.py maps/production_slice_03.greybox.json references/greybox/production_slice_03.svg
python tools/validate_greybox_map.py maps/production_slice_03.greybox.json
python tools/check_map_parity.py maps/production_slice_03.greybox.json
python tools/check_camera_captures.py maps/production_slice_03.greybox.json visual_captures/production_slice_03
python tools/check_camera_captures.py maps/production_slice_03.greybox.json visual_captures/production_slice_03_debug
```

Also add a route smoke if authored salvage/extraction is included, regenerate normal/debug captures, and create a source/render/collision review sheet before considering a baseline.

## Next Action

Create a follow-up implementation issue for authoring `production_slice_03` from these bounds. Keep that implementation scoped to source generation, validation, captures, and documentation; do not add new gameplay systems as part of the slice selection work.
