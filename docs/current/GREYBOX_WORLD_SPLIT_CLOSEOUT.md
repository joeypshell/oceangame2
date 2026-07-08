# Greybox World Split Closeout

Date: 2026-07-08

Issues: #248-#257

## Status

The first repo-health split lane for `scripts/world/greybox_world.gd` is complete.

This lane was intentionally no-behavior-change maintenance. It moved rendering and support responsibilities into focused helpers while keeping the JSON map, terrain/collision source of truth, gameplay runtime, maps, captures, assets, and accepted visual baselines unchanged.

## Helper Responsibility Map

- `scripts/world/greybox_asset_lookup.gd`
  - Texture paths, texture loading, and shared fallback lookup for world renderers.
- `scripts/world/greybox_terrain_renderer.gd`
  - Cave terrain `TileMapLayer`, terrain `TileSet`, solid-cell extraction, and neighbor mask tile selection.
- `scripts/world/greybox_debug_renderer.gd`
  - Runtime source layer, grid/debug outlines, debug labels, and basic shape helpers used by world review overlays.
- `scripts/world/greybox_collision_builder.gd`
  - Collision rectangles, runtime collision parity cells, and stable sorted-cell arrays for parity checks.
- `scripts/world/greybox_background_renderer.gd`
  - Non-collision background silhouettes, decorative landmark art, and background fallback shapes.
- `scripts/world/greybox_prop_renderer.gd`
  - Salvage and hazard prop visuals, including valuable and timed-salvage affordance markers.
- `scripts/world/greybox_extraction_renderer.gd`
  - Boat, base, relay spawn, extraction-zone, and spawn-cue visuals.
- `scripts/world/greybox_route_marker_renderer.gd`
  - Source-authored route/review marker rectangles plus compact debug outline/label rendering.
- `scripts/world/greybox_world.gd`
  - JSON loading, map state, source bookkeeping, entity/zone setup, helper orchestration, runtime query APIs, camera-test exposure, and salvage/extraction/hazard position APIs used by `scripts/main/main.gd`.

## Line-Count Outcome

The split plan recorded `greybox_world.gd` at 1,377 lines when issue #248 started. After issue #256, it is 734 lines.

All new world helper scripts are under the 500-line policy target. `greybox_world.gd` remains temporary file-length debt and should stay allowlisted until follow-up splits reduce it below 500 lines.

## Verification

The lane preserved source/render/collision behavior with repeated checks after the helper extractions, including:

```powershell
python tools/check_file_lengths.py
python tools/check_map_parity.py maps/production_slice_01.greybox.json
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
git diff --check
```

Targeted smokes used during the lane included salvage, cargo capacity, timed salvage, hazard pressure, production-slice route, Pass 08 route extension, Pass 10 return pressure, and Pass 12 oxygen-rest pressure checks.

No visual baselines were accepted in this lane.

## Remaining Debt

Recommended follow-up splits should stay no-behavior-change and focus only on responsibilities still owned by `greybox_world.gd`:

- runtime query/path/reachability helpers
- entity and zone bookkeeping helpers
- map-loading/source-state helpers if they can be moved without changing public APIs

Separate file-length debt remains in `scripts/main/main.gd` and oversized current docs such as `docs/current/PROJECT_CONTEXT.md`; those are outside this greybox-world closeout.
