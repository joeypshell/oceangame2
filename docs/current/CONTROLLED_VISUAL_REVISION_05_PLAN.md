# Controlled Visual Revision 05 Plan

Date: 2026-07-06

Issue: #93 `Plan controlled visual revision 05 terrain tileset v2`
Follow-ups: #94, #95, #96, #97

## Selected Target

Controlled Visual Revision 05 should create a named terrain atlas variant, `assets/terrain_tiles/cave_tileset_v2.png`, while preserving the existing JSON maps, source-derived terrain/collision cells, route design, camera tests, accepted foreground/background assets, gameplay behavior, and default preview selection.

Supporting files:

- `assets/terrain_tiles/cave_tileset_v2.png`
- `assets/terrain_tiles/cave_tileset_v2_manifest.json`
- `tools/generate_cave_tileset_v2.py`
- `references/asset_reviews/cave_tileset_v2_review.png`
- terrain atlas coverage review artifact from #94

Do not overwrite `cave_tileset_v1.png` in this pass. Keep v1 committed as the rollback/comparison atlas until v2 is accepted or deliberately deferred.

## Why This Target

The current terrain atlas is readable enough for the prototype, but it is still the most visible structural placeholder. A v2 terrain pass is the next useful workflow proof because seam-critical terrain must improve without invalidating the source-of-truth rules already proven by the production slices.

This pass is higher risk than props, player, boat, or background depth because terrain touches every production-slice screenshot. It must stay focused on the atlas art and manifest only unless #94 proves a renderer/manifest mismatch that must be fixed first.

## Atlas Coverage Expectations

The v2 atlas must preserve:

- tile size: `32x32`
- atlas grid: `8` columns by `5` rows
- source maps: unchanged
- tile mask semantics: unchanged
- renderer mask selection behavior: unchanged unless #94 identifies a documented mismatch

Required atlas coordinates:

| Role | Coordinates |
|---|---|
| fill variants | `(0,0)`, `(0,2)`, `(5,2)`, `(6,2)`, `(7,2)` |
| top exposed variants | `(1,0)`, `(0,3)`, `(1,3)` |
| right exposed variants | `(2,0)`, `(6,3)`, `(7,3)` |
| bottom exposed variants | `(4,0)`, `(2,3)`, `(3,3)` |
| left exposed variants | `(0,1)`, `(4,3)`, `(5,3)` |
| outer corners | `(3,0)`, `(0,4)`, `(1,1)`, `(1,4)`, `(6,0)`, `(2,4)`, `(4,1)`, `(3,4)` |
| isolated/narrow terrain | `(7,1)`, `(4,4)`, `(5,4)` |
| inner corners | `(1,2)`, `(2,2)`, `(3,2)`, `(4,2)` |

The manifest should preserve mask ids `0` through `15`, existing variant roles, and the four named inner-corner roles:

- `inner_top_left`
- `inner_top_right`
- `inner_bottom_left`
- `inner_bottom_right`

## Expected Screenshot Differences

Expected differences:

- rock interiors read less like repeated square scratch tiles
- top/floor edges remain readable but less zipper-like
- exposed walls, ceilings, corners, and isolated terrain keep clear gameplay silhouettes
- differences appear wherever cave terrain tiles are visible across production slices 01-04

Unexpected differences:

- changed map topology, terrain cells, collision rectangles, route openings, or player spawn
- changed camera framing, authored `camera_tests`, route smoke behavior, or default preview map
- changed approved props, player, boat, relay/base, background depth, UI, salvage, hazards, or oxygen behavior
- atlas dimensions, tile size, mask ids, or coordinate semantics changing without an explicit renderer/tooling issue
- accepted baseline replacement during #95 implementation

## Rollback And Comparison

Keep v1 as the stable rollback target:

- `assets/terrain_tiles/cave_tileset_v1.png`
- `assets/terrain_tiles/cave_tileset_v1_manifest.json`
- `references/asset_reviews/cave_tileset_v1_review.png`

The v2 implementation should update the renderer to select the v2 atlas only after the v2 asset and manifest exist. If the v2 pass fails review, rollback should be a small renderer constant change back to v1 plus regenerating captures/comparison sheets.

Before accepting v2, compare against all accepted production-slice baselines:

```bash
python tools/manage_production_slice_baseline.py compare-all
```

Keep accepted baselines fixed until #96 explicitly accepts or defers the terrain v2 baseline.

## Validation Commands

Use the normal source/render checks to prove terrain art did not alter map semantics:

```bash
python tools/check_map_parity.py
python tools/check_asset_manifest.py
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

Run route and launch smokes appropriate to a terrain renderer change:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-02-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-03-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-04-route
```

## Follow-Up Issue Shape

Use the follow-up issues created from this plan:

- #94 add terrain atlas coverage review tooling
- #95 implement the controlled cave tileset v2 pass
- #96 decide whether to accept replacement baselines after review
- #97 verify the public Web preview after deployment

Do not combine #95 with map topology cleanup, background art, lighting systems, prop/player/boat changes, movement tuning, or whole-scene regeneration.
