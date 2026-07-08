# Greybox World Split Plan

Date: 2026-07-08

Issue: #248 `Plan greybox_world.gd no-behavior split boundaries`

## Decision

Split `scripts/world/greybox_world.gd` through small no-behavior helper extractions.

The file starts this lane at 1,377 lines. It should remain the world coordinator, JSON loader, public query API, and owner of high-level build order. Rendering, asset lookup, collision/parity, and geometry helper responsibilities should move into focused helper scripts under `scripts/world/`.

This lane must avoid Pass 13 gameplay/source work. Do not edit `docs/current/CONTROLLED_GAMEPLAY_PASS_13_PLAN.md`, Pass 13 source-rules docs, `tools/create_production_slice_map.py`, generated map JSON, visual captures, or accepted baselines unless a later issue explicitly coordinates that work.

## Current Responsibilities

`greybox_world.gd` currently owns:

- JSON map loading and public map state
- public query APIs for salvage, hazards, extraction, markers, paths, and parity
- source greybox TileMapLayer rendering
- cave terrain TileMapLayer and terrain TileSet generation
- collision body construction and parity data
- background silhouettes and landmarks
- zone and route/review marker rendering
- salvage and hazard prop rendering
- boat, spawn, base, and relay extraction visuals
- texture loading and fallback asset lookup
- shared geometry primitives and point builders

## Keep In greybox_world.gd

Keep these responsibilities in `greybox_world.gd`:

- `_ready`, `load_greybox`, `_load_map_data`
- map metadata fields and public labels
- public query APIs used by `scripts/main/main.gd`
- high-level build orchestration:
  - clear old children
  - create root nodes
  - call helper builders in stable order
  - store salvage/hazard/extraction/boat arrays
- source-of-truth state such as collected salvage and node lookup maps
- coordinate conversion wrappers if main/runtime code already calls them indirectly

Do not change public function names unless a later issue explicitly updates all callers.

## Proposed Helpers

Suggested helper files:

- `scripts/world/greybox_asset_lookup.gd`
  - texture path constants or resource lookup
  - packaged texture fallback
  - prop texture lookup
- `scripts/world/greybox_terrain_renderer.gd`
  - cave terrain TileSet creation
  - terrain solid-cell extraction
  - terrain atlas coordinate selection
  - tile-rect filling
- `scripts/world/greybox_debug_renderer.gd`
  - source grid TileMapLayer setup
  - route/review/debug marker overlays that are not entity props
  - debug labels and outlines where practical
- `scripts/world/greybox_collision_builder.gd`
  - collision rectangle construction
  - runtime collision rect/cell parity extraction
  - sorted cell array helpers if only parity uses them
- `scripts/world/greybox_background_renderer.gd`
  - background silhouettes
  - landmark/decorative background items
- `scripts/world/greybox_entity_renderer.gd`
  - salvage prop visuals
  - hazard prop visuals
  - valuable/timed salvage visual affordances
- `scripts/world/greybox_extraction_renderer.gd`
  - boat visuals
  - spawn/base relay visuals
  - extraction zone visuals
- `scripts/world/greybox_geometry.gd`
  - local polygon/line helpers
  - rectangle, diamond, circle, ellipse, and star point builders
  - item-to-rect and item-to-center helpers

If a planned helper would exceed 500 lines, split it before landing rather than creating a new oversized file.

## Recommended Issue Order

1. #248 Plan split boundaries.
2. #249 Extract texture and asset lookup.
3. #250 Extract terrain tile rendering.
4. #251 Extract source grid and debug overlay rendering.
5. #252 Extract collision and parity helpers.
6. #253 Extract background and landmark rendering.
7. #254 Extract salvage and hazard prop rendering.
8. #255 Extract extraction, spawn, and boat rendering.
9. #256 Extract route marker and review zone rendering.
10. #257 Close out the lane and update architecture docs.

This order moves low-level shared dependencies before larger renderers. It also leaves route-marker rendering late because Agent A may be working Pass 13 source/feedback decisions in parallel.

## Verification After Each Split

Run at minimum:

```powershell
python tools/check_file_lengths.py
git diff --check
```

For rendering or collision helpers, also run:

```powershell
python tools/check_map_parity.py maps/production_slice_01.greybox.json
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
```

When a split touches entity, hazard, extraction, route marker, or terrain rendering, prefer one targeted smoke or capture if available locally. Do not accept visual baselines in this lane unless a separate visual review issue asks for it.

## Parallel Safety

Agent B owns this greybox-world split lane. Agent A owns the Pass 13 gameplay lane.

Avoid overlap:

- Agent B should not edit Pass 13 docs/source/runtime files.
- Agent A should avoid `scripts/world/greybox_world.gd` and new `scripts/world/greybox_*` helpers unless the two lanes explicitly coordinate.
- If both lanes need route marker rendering, let Agent A finish source/runtime behavior first or rebase this lane before extracting route marker visuals.

## Exit Criteria

This lane is complete when:

- `greybox_world.gd` is materially smaller and still under active reduction
- new helper files are under 500 lines
- source/render/collision parity remains stable
- no gameplay, map topology, assets, captures, or accepted baselines changed unintentionally
- architecture docs list the new helper responsibilities
