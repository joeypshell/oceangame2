# Current Architecture

## Purpose

The current project is a minimal Godot 4.7 greybox for testing the side-view underwater cave map before creating production art.

## Source Of Truth

The authored map source is:

```text
maps/cave_salvage_test_01.greybox.json
```

The Godot scene reads this JSON at runtime. Do not hand-tune in-engine terrain topology without updating the source map.

## Scene Structure

- `scenes/main/Main.tscn`
  - Root scene.
  - Instantiates the greybox world and player.
  - Places the player at the JSON spawn position.

- `scenes/world/GreyboxWorld.tscn`
  - Runtime renderer for the greybox map.
  - Creates a `TileMapLayer` visual from the source JSON.
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

- `scripts/world/greybox_world.gd`
  - Loads JSON.
  - Builds the runtime TileMapLayer and collision.
  - Keeps visuals tied to source topology.

- `scripts/player/player_controller.gd`
  - Basic side-view swimming controller.
  - Supports arrow keys and WASD.

## Current Limits

- Terrain art is still greybox only.
- Collision is rectangular per terrain block.
- No gameplay scoring yet.
- Salvage and hazards are visual markers only.
- No screenshot baseline is committed yet.
