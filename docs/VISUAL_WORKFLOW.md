# Visual Workflow

## Principle

The project should never ask for a whole scene to be regenerated to fix one visual issue. The workflow must keep map data, assets, rendering, and polish separated.

## Workflow Order

1. Lock camera, collision grid, art module sizes, and map size.
2. Build a greybox map.
3. Save a greybox baseline screenshot.
4. Create a small approved terrain-module kit.
5. Cover greybox terrain with large generated modules.
6. Add approved props.
7. Add player and UI.
8. Save a visual baseline screenshot.
9. Make one targeted visual revision.
10. Compare against the baseline.

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
