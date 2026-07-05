# Cave Tileset V1

This folder contains the first grid-aligned cave terrain tileset for Godot.

## Assets

- `cave_tileset_v1.png` - 256x160 atlas of 32x32 terrain tiles.
- `cave_tileset_v1_manifest.json` - tile names, atlas coordinates, and side-mask metadata.

Review sheet:

```text
references/asset_reviews/cave_tileset_v1_review.png
```

## Purpose

These tiles replace the stretched terrain-module approach for seam-critical gameplay terrain. Floors, walls, ceilings, exposed corners, inner-corner cases, pillars, and isolated islands should render from this atlas through `TileMapLayer` cell selection.

Large generated terrain modules in `assets/terrain/` remain useful for background silhouettes, landmarks, and non-collision decoration.

## Regeneration

Run:

```bash
python tools/generate_cave_tileset.py
```

Generate the organic stress-test map with:

```bash
python tools/generate_tileset_test_map.py
```

The first atlas is still a draft. It proves grid alignment, tile variants, and seam rules before final AI-assisted painted tile art is generated against exact tile masks.
