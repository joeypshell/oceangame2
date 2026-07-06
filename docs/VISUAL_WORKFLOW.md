# Visual Workflow

## Principle

The project should never ask for a whole scene to be regenerated to fix one visual issue. The workflow must keep map data, assets, rendering, and polish separated.

## Workflow Order

1. Lock camera, collision grid, art module sizes, and map size.
2. Build a greybox map.
3. Save a greybox baseline screenshot.
4. Create a small grid-aligned terrain tileset for seam-critical cave terrain.
5. Render greybox terrain through `TileMapLayer` tile selection.
6. Add large generated modules only as background or landmark decoration.
7. Add approved props.
8. Add player and UI.
9. Save a visual baseline screenshot.
10. Make one targeted visual revision.
11. Compare against the baseline.

## Baseline Screenshots

Save visual checkpoints under:

```text
visual_baselines/
```

Suggested names:

```text
001_greybox_map.png
002_first_tile_pass.png
003_props_pass.png
004_player_ui_pass.png
005_revision_test.png
```

## Accepted Production Slice Baseline

The first accepted production-slice baseline lives under:

```text
visual_baselines/production_slice_01_accepted/
```

Accept the current production-slice captures only after a reviewer agrees that the current visuals are the comparison target for future changes:

```bash
python tools/manage_production_slice_baseline.py accept
```

Render a baseline/current/difference review sheet with:

```bash
python tools/manage_production_slice_baseline.py compare
```

This writes:

```text
references/asset_reviews/production_slice_01_visual_baseline_review.png
```

Update the accepted baseline when the team intentionally approves a new visual state. If a targeted visual change has unexpected differences, keep the baseline fixed and create a follow-up issue describing the regression or disputed change.

`production_slice_02` is now accepted as a visual baseline under `visual_baselines/production_slice_02_accepted/`. See `docs/current/PRODUCTION_SLICE_02_VISUAL_BASELINE_DECISION.md`; the original deferral remains historical context, and the 2026-07-06 update records the accepted baseline.

## Revision Rule

Every visual change should state:

- target issue
- affected assets
- untouched assets
- expected screenshot difference

Example:

```text
Target issue: cave terrain top edges do not read clearly against the water.
Affected assets: terrain_floor_long_01.png and terrain_floor_short_01.png.
Untouched assets: player, sub, salvage crates, hazards, UI, map collision.
Expected difference: playable surfaces read more clearly while layout and props remain unchanged.
```

## Failure Condition

A revision fails if it improves the target issue but also damages unrelated visuals, changes the map layout, changes perspective, changes scale, or introduces incompatible detail.

## Terrain Placement Rule

In-engine terrain art should be placed from the machine-readable map data. Do not hand-tune collision, routes, or topology in Godot to make an asset fit. If art reveals a real layout problem, update `maps/cave_salvage_test_01.greybox.json`, regenerate previews/captures, and rerun the accessibility validator.

Core floors, walls, ceilings, and corners should use grid-aligned terrain tiles. Do not non-uniformly scale seam-critical terrain sprites to fit greybox rectangles. Large generated modules are for background silhouettes, landmarks, and non-collision decoration unless they are converted into tile-compatible pieces.
