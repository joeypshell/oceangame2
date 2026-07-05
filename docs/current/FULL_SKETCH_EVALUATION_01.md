# Full Sketch Evaluation 01

Date: 2026-07-05

Issue: #21 `Evaluate full sketch topology and choose first production slice`

## Inputs

- Source sketch: `references/source_maps/full_cave_sketch_01.png`
- Converted JSON: `maps/full_cave_sketch_01.greybox.json`
- Generated SVG preview: `references/greybox/full_cave_sketch_01.svg`
- Godot captures: `visual_captures/full_cave_sketch/`

## Current Conversion Read

The conversion is good enough as a topology draft. The large room relationships, long connecting corridors, vertical shafts, and broad chamber shapes are present in the Godot preview. It is not production-ready as a whole-map source yet.

Strengths:

- The macro layout survived conversion: upper-left cluster, top-center shaft, central crossing, lower-right chamber, and bottom terminal chamber are recognizable.
- The full converted map is one reachable open-water component.
- Godot terrain and collision parity matches the authored JSON.
- The draft is now useful as a planning source for selecting smaller production slices.

Limits:

- The full map is too large for the next production pass.
- Icons are intentionally ignored, so salvage, hazards, landmarks, and doors must be reauthored in JSON.
- The current spawn is temporary validation data, not the real boat/top-water spawn.
- Some curved sketch corridors become stair-stepped tile corridors; this is acceptable for a draft but should be cleaned in source data or converter output for any production slice.
- The current terrain art makes the full map readable, but repeated tile identity is obvious at overview scale.

## Candidate Slices

### Candidate A: Top-Center Entry Hub

Approximate bounds:

```text
x: 58
y: 0
w: 72
h: 84
```

Why it works:

- It includes the strongest natural top-water entry shaft for the future boat spawn.
- It connects into the central crossing and supports multiple route choices.
- It has enough room for early salvage, one or two hazards, and a return-to-extraction test.
- It exercises vertical descent, lateral branches, and curved/choked connectors without requiring the entire full map.

Risks:

- It needs the boat/top-water spawn model before it becomes the true default production map.
- The slice boundary must be chosen carefully so route edges do not feel like arbitrary cutoffs.

### Candidate B: Upper-Left Room Cluster

Approximate bounds:

```text
x: 0
y: 8
w: 64
h: 82
```

Why it works:

- It is compact and room-heavy.
- It includes a readable progression from left rooms into a larger route.
- It would be easier to hand-clean than the top-center hub.

Risks:

- It does not naturally solve the boat/top-water spawn goal.
- It is less representative of the larger map's central-route structure.

### Candidate C: Lower-Right Chamber Route

Approximate bounds:

```text
x: 88
y: 78
w: 66
h: 72
```

Why it works:

- It has a large chamber and an obvious terminal/landmark area.
- It may be good later as a deeper expedition slice.

Risks:

- It feels like a later-game destination, not the first production slice.
- It depends on upstream entry/spawn/extraction decisions.

## Decision

Use Candidate A, the top-center entry hub, as the first production slice target.

Recommended order:

1. Implement #22 boat and top-water spawn/extraction model.
2. Implement #23 first production slice JSON from the top-center entry hub.
3. Implement #24 production slice preview shortcut and capture route.

Rationale:

The top-center entry hub is the best bridge between the user's full-map sketch and the current playable prototype. It lets the next map source test the real intended spawn model, a short salvage run, route branching, collision clearance, and terrain readability without forcing the whole full sketch into production at once.

## Verification

Completed for this evaluation:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-full-sketch-map
python tools/validate_greybox_map.py maps/full_cave_sketch_01.greybox.json
python tools/check_map_parity.py maps/full_cave_sketch_01.greybox.json
```

Results:

- Full-sketch captures regenerated successfully.
- `full_cave_sketch_01` passed reachability validation from temporary spawn `(91, 0)`.
- `full_cave_sketch_01` passed Godot terrain/collision parity with 14908 terrain cells and 364 collision rectangles.
