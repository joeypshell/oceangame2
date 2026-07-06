# Controlled Visual Revision 04 Plan

Date: 2026-07-06

Issue: #88 `Plan controlled visual revision 04 background depth pass`
Follow-ups: #89, #90, #91, #92

## Selected Target

Controlled Visual Revision 04 should improve the non-collision background/depth layer used by authored `background` data while preserving the current production-slice maps, terrain tiles, collision, gameplay behavior, camera framing, and approved foreground sprites.

Target asset:

- `assets/terrain/background_rocks_02.png`

Supporting generator/review artifacts:

- `tools/generate_background_depth_sprite.py`
- `references/asset_reviews/background_rocks_02_review.png`
- `visual_captures/background_depth/production_slice_01_background_depth.png`

The existing `assets/terrain/background_rocks_01.png` remains a draft v1 comparison asset until the replacement is reviewed. The implementation issue should add a named variant instead of silently replacing unrelated terrain modules.

Implementation status: #90 added `background_rocks_02.png`, `tools/generate_background_depth_sprite.py`, `references/asset_reviews/background_rocks_02_review.png`, and renderer integration that prefers v2 while preserving v1 fallback. Source maps, collision, terrain tiles, gameplay behavior, camera tests, approved foreground sprites, and accepted baselines remain unchanged until #91 decides whether to accept replacement baselines.

## Why This Target

Background depth is the next useful visual test because it is visible in normal production-slice screenshots, but it should never define collision, routes, extraction, or map topology. It gives the project a controlled way to make the scene feel less flat without touching seam-critical terrain art yet.

This target is intentionally narrower than terrain-tile replacement:

- one named non-collision background asset
- one renderer integration path: the existing authored `background` rectangles in `scripts/world/greybox_world.gd`
- no JSON map source changes
- no terrain atlas changes
- no collision, movement, or gameplay changes
- no default-preview change

## Affected Assets And Code

Expected affected paths for #90:

- `assets/terrain/background_rocks_02.png`
- `tools/generate_background_depth_sprite.py`
- `references/asset_reviews/background_rocks_02_review.png`
- `scripts/world/greybox_world.gd`
- `docs/ASSET_MANIFEST.md`
- focused background-depth capture output from #89
- production-slice captures and baseline review sheets after the renderer/assets change

The renderer should continue to place the visual from existing `background` source rectangles. The map source of truth remains unchanged.

## Untouched Areas

The implementation should not intentionally change:

- `maps/*.greybox.json`
- terrain tile source, terrain atlas coordinates, or terrain tile selection
- terrain/collision generation
- player spawn position, collision shape, movement, camera, or light cone
- salvage, hazards, oxygen, extraction, reset, or route-smoke logic
- approved prop, player, boat, and relay/base visuals
- authored production-slice `camera_tests`
- accepted baseline directories under `visual_baselines/` until #91 accepts replacement baselines
- default preview map selection
- debug marker meanings or colors

## Expected Screenshot Differences

Expected differences:

- distant rock silhouettes read as cleaner underwater cave depth
- background shapes feel less placeholder-flat while staying lower contrast than gameplay terrain
- background art remains visibly behind terrain, player, props, boat, and relay/base extraction visuals
- source-authored background rectangle placement remains consistent with the current maps

Unexpected differences:

- changed map topology, terrain shape, collision, route openings, or player spawn
- changed terrain atlas art, tile-grid seams, or terrain mask behavior
- changed salvage, hazard, player, boat, relay/base, UI, or oxygen visuals
- changed camera framing or default preview map
- accepted baseline replacement during implementation
- background art becoming so high contrast that it competes with collision terrain

## Capture And Baseline Expectations

#89 should add a focused capture so this pass can be reviewed without relying only on the broad production-slice overview:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-background-depth
```

Expected output:

```text
visual_captures/background_depth/production_slice_01_background_depth.png
```

Before changing visuals:

```bash
python tools/manage_production_slice_baseline.py compare-all
```

After changing the background visual and regenerating captures:

```bash
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

Expected baseline differences should be limited to views where authored `background` rectangles are visible. Keep accepted baselines fixed until #91 explicitly reviews and accepts or rejects the replacement baseline.

## Validation Commands

Use source/render and asset checks to prove the visual pass did not alter map semantics:

```bash
python tools/check_map_parity.py
python tools/check_asset_manifest.py
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

Run a minimal Godot smoke check for the renderer path:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
```

## Follow-Up Issue Shape

Use the follow-up issues created from this plan:

- #89 add a background-depth focused review capture
- #90 implement the controlled background depth art pass
- #91 decide whether to accept replacement baselines after review
- #92 verify the public Web preview after deployment

Do not combine #90 with terrain tile replacement, slice-03 polish, map topology cleanup, lighting systems, HUD changes, movement tuning, or whole-scene regeneration.
