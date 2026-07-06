# Production Slice 04 Decision

Date: 2026-07-06

Issue: #59 `Select production slice 04 candidate from full sketch`

Follow-up implementation issue: #61 `Author production slice 04 from lower-left loop`

## Selection

Use the lower-left loop from `maps/full_cave_sketch_01.greybox.json` as the fourth focused production-slice candidate.

Selected bounds:

```text
x: 0
y: 86
w: 88
h: 50
```

## Role

Primary role: connector / return loop.

Secondary role: curved-corridor cleanup test.

This slice should test a lower-left route that is meaningfully different from the first three slices:

- Slice 01: top-center first-area boat hub.
- Slice 02: lower-right later-game chamber route.
- Slice 03: upper-left connector / landmark room cluster.
- Slice 04: lower-left loop with longer curved-corridor movement and return-path readability.

## Rationale

The lower-left loop is the best next workflow proof because it covers a mostly untested quadrant of the full sketch while exercising a different topology problem.

Good fit:

- It is not another first-area surface entry.
- It is not another broad lower-right destination chamber.
- It is not another compact stacked-room cluster.
- It includes a longer loop-like route with curved sketch corridors that will expose source-generator cleanup costs.
- It can use a believable in-water relay near the east-side connector back toward the central cave.

Candidate regions not selected:

- Bottom terminal chamber: useful later, but it overlaps the slice-02 lower terminal context and is less urgent than proving the lower-left loop.
- Top-right side route: visually distinct, but it is closer to another side branch than a new topology stress test and has more ambiguous top-edge entry fiction.

## Spawn And Extraction Plan

Use `spawn + base`, not `boat_spawn`.

The slice has no natural top-water surface entry. Place an in-water relay/base near the east-side connector so the player enters from believable larger-map context, explores the lower-left loop, then returns to the relay.

Planning entry target:

```text
source/global entry: x=74, y=104
local entry within slice: x=74, y=18
```

This point was open in the full-sketch source under the selected bounds and reached all open cells in a pre-implementation edge-seal sanity check. Implementation must still validate reachability after generator cleanup and authored entities are added.

## Authored Gameplay Plan

Source sketch icons remain ignored. Gameplay objects should be reauthored in JSON.

Initial target density:

- 4 to 5 salvage entities spread across the loop and branch turns.
- 2 to 3 hazards at corridor bends, choke points, or return-pressure locations.
- Route markers for the relay connector, lower-left loop, branch/turnaround route, and return path.
- Camera tests for overview, relay entry, lower-left loop, curved corridor, and return route.

## Crop And Cleanup Risks

- The left edge is the full-map boundary, but any open pockets near that edge must still be intentional and reachable.
- The top edge overlaps the bottom fringe of slice 03; seal it unless the implementation intentionally preserves a connector cue.
- Curved sketch corridors may create stair-stepped one-tile bends; clean these in source generation if they hurt navigation or readability.
- The east-side relay must not be cropped so tightly that it feels arbitrary.
- If sealing the bottom edge hides the loop's payoff, adjust bounds before authoring gameplay objects.

## Required Verification For Implementation

The implementation issue should verify:

```powershell
python tools/create_production_slice_04_map.py
python tools/render_greybox_map.py maps/production_slice_04.greybox.json references/greybox/production_slice_04.svg
python tools/validate_greybox_map.py maps/production_slice_04.greybox.json
python tools/check_map_parity.py maps/production_slice_04.greybox.json
```

If the implementation adds capture routes, also verify:

```powershell
python tools/check_camera_captures.py maps/production_slice_04.greybox.json visual_captures/production_slice_04
python tools/check_camera_captures.py maps/production_slice_04.greybox.json visual_captures/production_slice_04_debug
```

Add a route smoke only after authored salvage/extraction is included. Create a source/render/collision review sheet before considering any slice-04 baseline decision.

## Next Action

Implement #61 as a separate scoped pass. Do not change the default preview map or accept a slice-04 visual baseline as part of the selection issue.

## Selection Verification

Completed for this decision:

- Reviewed `docs/current/PRODUCTION_SLICE_SELECTION_CRITERIA.md`.
- Reviewed lessons from `production_slice_01`, `production_slice_02`, and `production_slice_03`.
- Inspected the full-sketch conversion review and selected bounds against `maps/full_cave_sketch_01.greybox.json`.
- Ran a pre-implementation sanity check for the selected crop: after sealing crop edges, the local relay entry `(74, 18)` reached all 1500 open cells in the crop.
