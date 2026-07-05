# Current Architecture

## Purpose

The current project is a minimal Godot 4.7 greybox for testing the side-view underwater cave map before creating production art.

## Source Of Truth

The current default preview map source is:

```text
maps/cave_salvage_organic_01.greybox.json
```

The Godot scene reads this JSON at runtime. Do not hand-tune in-engine terrain topology without updating the source map.

Additional current map sources:

- `maps/cave_salvage_test_01.greybox.json`
  - Original rectangular salvage test map.
  - Preserved for comparison with the current organic default.
  - Load locally with `.\tools\open_godot_project.ps1 -Run -OriginalMap`.
- `maps/cave_tileset_test_01.greybox.json`
  - Organic stress-test map for TileSet terrain rendering.
  - Used to exercise jagged edges, winding tunnels, pillars, isolated cells, and pockets.
- `maps/full_cave_sketch_01.greybox.json`
  - Draft 0 topology-only conversion from `references/source_maps/full_cave_sketch_01.png`.
  - Used to test whether a supplied full-map sketch can move through image conversion, JSON source, validation, SVG preview, and Godot preview.
  - Not the default preview map.

## Scene Structure

- `scenes/main/Main.tscn`
  - Root scene.
  - Instantiates the greybox world and player.
  - Places the player at the JSON spawn position.

- `scenes/world/GreyboxWorld.tscn`
  - Runtime renderer for the greybox map.
  - Creates a `TileMapLayer` visual from the source JSON.
  - Creates a visible cave `TileMapLayer` from grid-aligned terrain tiles.
  - Creates `StaticBody2D` collision rectangles from the same terrain data.
  - Draws background silhouettes, route markers, extraction zone, salvage, hazards, and spawn markers.

- `scenes/player/Player.tscn`
  - Basic placeholder diver/sub-style player.
  - Uses `CharacterBody2D` with free-swim movement.
  - Contains the active `Camera2D`.

## Scripts

- `scripts/main/main.gd`
  - Loads world and player scenes.
  - Applies camera bounds from the world map size.
  - Supports visual capture flags for the baseline screenshot and named camera-test captures.
  - Supports `--map-path=<res://...>` for loading alternate JSON map sources.

- `scripts/world/greybox_world.gd`
  - Loads JSON.
  - Builds the runtime source TileMapLayer, cave terrain TileMapLayer, background art, and collision.
  - Keeps visuals tied to source topology.
  - Exposes `camera_tests` from the source map for repeatable visual captures.

- `scripts/player/player_controller.gd`
  - Basic side-view swimming controller.
  - Supports arrow keys and WASD.

## Visual Layering

The world intentionally separates authored topology from art:

- `SourceTileMapLayer` is the faint runtime reference for the JSON grid.
- `CaveTerrainTileMapLayer` contains 32x32 terrain tiles selected from neighboring solid cells.
- `BackgroundArt` may use larger non-collision modules for silhouettes and landmarks.
- `Collision` is generated only from the JSON terrain data.

Art placement must not create, remove, or move collision.

## Current Limits

- Terrain tile art is a first-pass structural placeholder, not final production art.
- Collision is rectangular per terrain block.
- No gameplay scoring yet.
- Salvage and hazards are visual markers only.
- First screenshot baseline is committed at `visual_baselines/001_greybox_in_engine.png`.
