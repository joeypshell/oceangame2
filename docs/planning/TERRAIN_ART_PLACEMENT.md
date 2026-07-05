# Terrain Art Placement Pass 01

Issue: #3

## Purpose

This pass proves that generated modular terrain art can be layered over the runtime greybox without changing map topology, collision, or reachability.

The source of truth remains:

```text
maps/cave_salvage_test_01.greybox.json
```

## Runtime Rule

`scripts/world/greybox_world.gd` builds three separate concepts from the same JSON:

- `SourceTileMapLayer`: faint greybox topology reference.
- `Collision`: `StaticBody2D` rectangles generated only from `terrain` items.
- `TerrainArt`: draft sprites scaled over those same terrain rectangles.

Art sprites are not collision, and they do not define gameplay space.

## Current Mapping

| Map IDs | Art Asset |
|---|---|
| `bottom_floor`, `base_floor`, shelves | `terrain_floor_long_01.png` or `terrain_floor_short_01.png` |
| `left_wall`, `central_arch_left_column` | `terrain_wall_left_01.png` |
| `right_wall`, `central_arch_right_column` | `terrain_wall_right_01.png` |
| `ceiling_*`, `central_arch_top` | `terrain_ceiling_01.png` |
| `stalactite_*` | Wall modules used as temporary hanging rock columns |
| `central_arch_*` group | Additional translucent `terrain_arch_01.png` overlay |
| `background` rectangles | `background_rocks_01.png` |

## Known Visual Mismatches

Follow-up: #7

- The modules are scaled to fit coarse collision rectangles, so some rock texture stretches on very wide or narrow blocks.
- Stalactites are using wall modules as placeholders; they need dedicated hanging-rock art later.
- The central arch overlay proves the idea but is not yet a clean custom-fit module.
- The greybox source layer remains faintly visible on purpose so screenshots can confirm art did not hide the authored topology.
- Props, salvage crates, hazards, vegetation, and final player art are still separate future passes.

## Verification

Run:

```bash
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
```

Then capture named Godot views and compare against the previous greybox baseline. Any topology problem should be fixed in the JSON map or converter, not by nudging art in the scene.
