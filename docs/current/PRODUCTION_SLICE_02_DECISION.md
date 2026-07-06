# Production Slice 02 Decision

Date: 2026-07-05

Issue: #40 `Select and author second production slice from full sketch`

## Selection

Use Candidate C from `docs/current/FULL_SKETCH_EVALUATION_01.md`: the lower-right chamber route.

Bounds in `maps/full_cave_sketch_01.greybox.json`:

```text
x: 88
y: 78
w: 66
h: 72
```

Generated source:

```text
maps/production_slice_02.greybox.json
```

## Rationale

This slice tests a different part of the supplied full sketch than `production_slice_01`.

- `production_slice_01` is the top-center first-area entry hub with a top-water boat.
- `production_slice_02` is a later-game destination/connector candidate with a broad chamber, a return route, and a lower terminal passage.
- It is useful precisely because it does not solve the same top-water entry problem again.

## Spawn And Extraction Plan

This region does not have a natural top-water opening, so it should not force a `boat_spawn`.

`production_slice_02` uses:

- `spawn`: `relay_sub_entry` at local tile `(8, 34)`
- `base` zone: `relay_extraction_zone` at local rect `(4, 32, 9, 5)`

The intended fiction is an in-water relay or sub drop-off reached from upstream routes in a larger map. It is not an alternate first area.

## Authored Gameplay Objects

Source sketch icons are ignored. Gameplay objects are reauthored as JSON entities:

- 5 salvage entities spread across the approach, main chamber, and lower terminal passage
- 4 hazard entities at choke or pressure points
- 5 camera tests for overview, relay entry, main chamber, lower terminal, and return route review

## Verification

Completed:

```powershell
python tools/create_production_slice_02_map.py
python tools/render_greybox_map.py maps/production_slice_02.greybox.json references/greybox/production_slice_02.svg
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
python tools/check_map_parity.py maps/production_slice_02.greybox.json
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-02-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-debug-map
```
