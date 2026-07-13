# OceanGame Expansion 09 Source Contract

Date: 2026-07-13

Issue: #857

Milestone: OceanGame Expansion 09 `Contiguous Full-Level Foundation`

Status: Locked for the frozen #857-#865 implementation batch.

## Decision

Expansion 09 promotes the complete full-cave sketch into one separately generated
production candidate. It does not stitch production slices together and does not
use a connector, teleport, map menu, or stabilizer gate to cross former crop edges.

The candidate remains:

```text
maps/production_level_01.greybox.json
```

`production_slice_01` remains the default and slices 01-04 remain regression and
provenance fixtures until the player approves promotion at #864.

## Canonical Pipeline

The topology pipeline is one-way:

```text
references/source_maps/full_cave_sketch_01.png
  -> tools/convert_full_cave_sketch_map.py
  -> maps/full_cave_sketch_01.greybox.json
  -> tools/create_production_level_01_map.py
  -> maps/production_level_01.greybox.json
```

- The PNG is the human topology reference.
- The converter owns reproducible image interpretation and writes the full-sketch
  draft. It does not own production cleanup or gameplay.
- The full-sketch JSON is generated topology input, not a runtime production map
  to edit by hand.
- The production-level generator owns candidate assembly, named boundary and
  clearance cleanup, gameplay transformation, and candidate metadata.
- The generated candidate is runtime input. Godot scenes and collision are not
  topology authorities.
- Production slice JSON is never an input to the candidate generator.

Slice-01 gameplay definitions must be extracted as human-authored Python data and
consumed by both generators. #858 must prove that this extraction leaves the
existing generated slice byte-for-byte unchanged.

## Coordinate Spaces

The full-sketch and `production_level_01` use global full-map tile coordinates.
The slice-01 authored gameplay currently uses local coordinates inside this crop:

```text
slice source bounds: x=58, y=0, w=72, h=84
local-to-global offset: (+58, +0)
```

The full-level generator must apply this transform once, through schema-aware
helpers. It must not infer coordinates from generated slice JSON or blindly shift
every dictionary key named `x` or `y`.

### Transform Rules

- A local point `(x, y)` becomes `(x + 58, y)`.
- A local rectangle shifts `x` by 58 and keeps `y`, `w`, and `h` unchanged.
- Every point in a path, patrol, territory, lane, candidate list, or other nested
  gameplay geometry receives the same point transform.
- Camera `center_x` increases by 58. `center_y` and `zoom` remain unchanged.
- Direction vectors, current directions, durations, radii, strengths, costs,
  counts, labels, tags, requirements, and other non-position values do not shift.
- Stable ids and id references do not change.
- Provenance may retain both original slice-local and resulting global values,
  but provenance values must not be transformed a second time.
- Terrain is not transformed from slice 01. Candidate terrain comes from the
  complete full-sketch draft plus named production cleanup.

### Record Treatment

Apply the transform to all reused coordinate-bearing records in:

- zones and route/cue markers
- progression containers
- moving hazards, including every patrol/path point
- hostile encounters, including home, territory, and evade geometry
- biological resource sources
- survey targets
- material-pool candidate positions
- background rectangles
- gameplay entities and tool targets
- camera tests reused from slice 01

Reuse coordinate-free records without modification when all referenced ids remain
present. This includes daily-condition links, route objectives,
`primary_route_objective_id`, next-dive prompts, and material project definitions,
except for the explicit exclusions below.

## Stable Id Classification

### Reused

Keep the existing id and gameplay values for slice-01 content that represents the
same thing in the full level. This includes the safe/deep route, salvage, hazards,
timed salvage, standard east-current pocket, propulsion-fins gate, surveys,
materials, projects, eel encounter, biological sources, objectives, and condition
content not named as excluded.

`surface_boat_entry` remains the stable canonical boat/extraction id. The candidate
uses the full-sketch record at global `(91, 0)`, width 8. The transformed slice
record resolves to the same location and must not create a duplicate owner.

### Transformed

The reused coordinate-bearing records listed above retain their ids and receive
the locked `(+58, +0)` transform. Cross-record references continue to point to the
same ids. The standard `upper_right_current_pocket_gate` and
`propulsion_fins_project` remain part of the candidate and normal movement remains
their traversal model.

### Candidate-Only

The candidate generator owns these new records:

- map id `production_level_01`
- full-map bounds and candidate provenance
- named production cleanup records in global source coordinates
- full-map overview and sector camera tests
- representative traversal anchors:
  - `full_level_upper_left_anchor` at `(38, 49)`
  - `full_level_lower_left_anchor` at `(44, 112)`
  - `full_level_lower_right_anchor` at `(121, 115)`

The anchors are validation and review markers, not pickups, gates, teleports, or
new gameplay rewards. #860 may move an anchor only when actual-player clearance
proves its locked cell unusable; such a correction must stay in the same named
sector and be recorded with evidence.

### Excluded

Do not place these slice-only or superseded records in the candidate:

- zone `production_slice_bounds`
- crop-edge seals, filled crop pockets, and other slice cleanup metadata
- `lower_left_loop_connector` and all connector labels, destinations, prompts, or
  transition metadata associated with it
- `lower_left_loop_current`
- `current_stabilizer_project` as an Expansion 09 entry route
- relay extraction stand-ins or entry markers from slices 02-04
- any connector, teleport, map-menu, pressure, or candidate-entry behavior

Existing runtime support and slice regression behavior for connectors and the
optional stabilizer may remain untouched. They are excluded from the full-level
candidate, not deleted from project history.

## Boundary And Cleanup Ownership

The only intentional outer-boundary opening is the authored top-water boat opening
at `y=0`, `x=91..98`, aligned with `surface_boat_entry`.

The production-level generator must seal every other open cell on the left, right,
bottom, or unrelated top boundary. Each changed cell must be represented by a
named deterministic source-coordinate list with a short rationale and emitted in
candidate source/cleanup metadata. Clearance corrections use the same ownership
rule.

Do not modify the PNG or converter merely to hide a production boundary problem.
Do not edit generated JSON, SVG, Godot terrain, or collision by hand. Preserve the
supplied cave silhouette unless a minimal source-owned cleanup is required for
boundary safety or the real player footprint.

## Reference Preservation

- `production_slice_01` through `production_slice_04` remain unchanged fixtures.
- Their crop bounds, sealed edges, stand-in extraction points, and connector
  context remain valid only inside those fixtures.
- Existing slice validators, parity checks, smokes, captures, and baselines remain
  regression evidence.
- #52/#53 remain deferred optional slice-03 presentation polish.
- #849 remains independent repository-health work.

## Validation Handoff

Implementation must prove, in dependency order:

1. #858 extracts shared source definitions with zero slice-01 output drift.
2. #859 generates deterministic full topology, preserves the canonical boat
   opening, seals other boundaries, and adds the contracted anchors.
3. #860 validates the actual `26 x 18 px` player footprint, direct return, and
   route budgets rather than relying on tile-cell connectivity alone.
4. #861 transforms the gameplay overlay exactly once and validates every reused
   record and reference.
5. #862-#863 prove candidate selection, framing, runtime practicality, and a
   collision-active no-connector journey.
6. #864 presents candidate-only evidence and waits for player GO or HOLD.
7. #865 may promote the default only after explicit GO.

## Non-Goals

This contract adds no map output, runtime behavior, visual asset, baseline,
connector, pressure system, stabilizer route, regional content, or new progression
chain. It defines ownership so later implementation cannot drift back toward
stitched slices or teleport-based expansion.
