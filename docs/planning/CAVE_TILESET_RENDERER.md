# Cave Tileset Renderer Pass 01

Issue: #8

## Purpose

This pass replaces stretched terrain sprites with a grid-aligned `TileMapLayer` renderer for core collision terrain.

The source map remains:

```text
maps/cave_salvage_test_01.greybox.json
```

The dedicated organic tileset stress-test map is:

```text
maps/cave_tileset_test_01.greybox.json
```

## Runtime Rule

`scripts/world/greybox_world.gd` now builds core terrain in this order:

- `BackgroundArt`: large non-collision silhouettes and background modules.
- `SourceTileMapLayer`: faint greybox/source reference.
- `CaveTerrainTileMapLayer`: visible 32x32 terrain tiles selected from solid-cell neighbors.
- `Collision`: rectangles generated only from JSON terrain data.
- `Markers`: extraction, route annotations, salvage, hazards, and spawn markers.

The terrain art layer is visual only. Collision and reachability still come from the source map.

## Tile Selection

The renderer converts every solid terrain rectangle into solid cells, then selects an atlas tile for each cell.

Exposed-side mask bits:

| Bit | Side |
|---:|---|
| `1` | top open |
| `2` | right open |
| `4` | bottom open |
| `8` | left open |

The 0-15 mask range covers fill, single edges, outer corners, and thin/isolated cells. If a cell has no cardinal open side but has an open diagonal, the renderer uses one of the inner-corner tiles.

The atlas is:

```text
assets/terrain_tiles/cave_tileset_v1.png
```

Review sheet:

```text
references/asset_reviews/cave_tileset_v1_review.png
```

## Asset Rule

Do not non-uniformly scale seam-critical terrain art.

Use grid-aligned tiles for:

- playable floors
- solid walls
- ceilings
- corners
- narrow pillars or stalactites that participate in collision

Use large generated modules for:

- distant background silhouettes
- non-collision landmarks
- decorative overlays
- future large ruins or cave set dressing

## Known Limits

Follow-up: #9

- The current tile art is a structural placeholder, not final production art.
- The atlas now includes multiple fill, edge, corner, and isolated-tile variants, but still needs a final AI-assisted production-art pass.
- The organic stress-test map exercises jagged cave edges, diagonal stair steps, pillars, isolated islands, pockets, and a carved winding tunnel.
- Stalactites are represented as grid terrain, not dedicated hanging-rock decoration yet.
- The source `TileMapLayer` remains faintly visible for visual debugging.

## Verification

Run:

```bash
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
python tools/validate_greybox_map.py maps/cave_tileset_test_01.greybox.json
```

Then regenerate the named Godot captures:

```bash
Godot_v4.7-stable_win64_console.exe --path . --quit-after 10 --capture-camera-tests
Godot_v4.7-stable_win64_console.exe --path . --quit-after 10 --capture-tileset-test
```
