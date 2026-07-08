# Asset Generation

Regenerate the cave tileset and organic stress-test map:

```bash
python tools/generate_cave_tileset.py
python tools/generate_tileset_test_map.py
python tools/generate_organic_salvage_map.py
```

Render the terrain atlas coverage review sheet:

```bash
python tools/render_terrain_atlas_coverage.py
python tools/render_terrain_atlas_coverage.py --manifest assets/terrain_tiles/cave_tileset_v2_manifest.json --output references/asset_reviews/cave_tileset_v2_coverage_review.png
```

This writes `references/asset_reviews/cave_tileset_v1_coverage_review.png`, labels manifest tile names, atlas coordinates, mask/open-side roles, renderer selection roles, and fails if any coordinate used by `scripts/world/greybox_world.gd` is missing from the terrain manifest. Use it before reviewing terrain tileset changes so the art pass preserves exact mask coverage.

Regenerate the first-pass salvage and hazard prop sprites:

```bash
python tools/generate_prop_sprites.py
```

This writes the draft 32x32 prop sprites under `assets/props/` and the review sheet at `references/asset_reviews/prop_sprites_01_review.png`. Runtime prop selection still comes from JSON entity `kind` values, and the renderer keeps procedural fallback art if a sprite asset cannot be loaded.

Regenerate the draft player diver sprite:

```bash
python tools/generate_player_sprite.py
```

This writes `assets/player/player_diver_01.png` and the review sheet at `references/asset_reviews/player_sprite_01_review.png`. The player scene uses this sprite while preserving the existing collision shape, movement script, camera, and light cone.

Process locally generated raw chroma-key terrain assets into exact-size transparent draft PNGs:

```bash
python tools/process_terrain_kit.py
```

This expects local raw generations under `tmp/imagegen/terrain_raw/`, writes final modules to `assets/terrain/`, and writes the review sheet to `references/asset_reviews/terrain_kit_01.png`.

## Generated Files

Do not commit:

- `.godot/`
- `.import/`
- `*.import`
- `builds/`
- `exports/`
- local editor state
