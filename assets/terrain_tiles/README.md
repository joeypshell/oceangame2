# Cave Tileset V1

This folder contains the first grid-aligned cave terrain tileset for Godot.

## Assets

- `cave_tileset_v1.png` - 256x96 atlas of 32x32 terrain tiles.
- `cave_tileset_v1_manifest.json` - tile names, atlas coordinates, and side-mask metadata.

Review sheet:

```text
references/asset_reviews/cave_tileset_v1_review.png
```

## Purpose

These tiles replace the stretched terrain-module approach for seam-critical gameplay terrain. Floors, walls, ceilings, exposed corners, and basic inner-corner cases should render from this atlas through `TileMapLayer` cell selection.

Large generated terrain modules in `assets/terrain/` remain useful for background silhouettes, landmarks, and non-collision decoration.

## Regeneration

Run:

```bash
python tools/generate_cave_tileset.py
```

The first atlas is intentionally simple. It proves grid alignment and seam rules before final AI-assisted painted tile art is generated against exact tile masks.
