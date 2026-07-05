# Terrain Kit 01

This folder contains the first draft modular cave terrain kit for the side-view visual proof-of-concept.

## Assets

- `terrain_floor_short_01.png` - 256x128 short playable cave floor
- `terrain_floor_long_01.png` - 512x256 long playable cave floor
- `terrain_wall_left_01.png` - 128x256 left cave wall
- `terrain_wall_right_01.png` - 128x256 right cave wall
- `terrain_ceiling_01.png` - 512x128 cave ceiling
- `terrain_arch_01.png` - 256x256 cave arch
- `background_rocks_01.png` - 512x256 non-collision background silhouette

All files are transparent PNGs processed from AI-generated chroma-key sources. Their manifest status is `draft`, not approved or locked.

## Review

Gameplay-scale review sheet:

```text
references/asset_reviews/terrain_kit_01.png
```

## Generation Notes

The raw generations used a flat `#ff00ff` chroma-key background and followed the approved modular cave direction:

```text
references/visual/visual_direction_b_modular_cave.png
docs/ART_BIBLE.md
docs/REFERENCE_STANDARD.md
```

The source prompts requested clean stylized side-view underwater cave modules with:

- dark blue-gray rock
- pale sandy playable floor edges where relevant
- broad readable planes
- low-noise texture
- no pixel art
- no retro/SNES cave style
- no props, text, labels, coins, ladders, or characters

Final processing command:

```bash
python tools/process_terrain_kit.py
```

That command expects local raw chroma-key generations under `tmp/imagegen/terrain_raw/` and writes exact-size transparent PNGs into this folder.
