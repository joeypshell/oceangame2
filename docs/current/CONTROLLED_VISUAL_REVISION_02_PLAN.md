# Controlled Visual Revision 02 Plan

Date: 2026-07-06

Issue: #73 `Plan controlled visual revision 02`
Follow-ups: #76, #77, #78, #79

## Selected Target

The second controlled visual revision should replace the procedural player placeholder with a named committed player/diver sprite asset, while preserving the existing player controller, collision shape, camera behavior, oxygen/hazard/salvage logic, and all map data.

Target asset:

- `assets/player/player_diver_01.png`

Supporting generator/review artifact:

- `tools/generate_player_sprite.py`
- `references/asset_reviews/player_sprite_01_review.png`

Implementation status: #77 adds the draft `player_diver_01.png` asset, generator, review sheet, and `Player.tscn` integration. Baseline acceptance remains separate under #78.

## Why This Target

The player is the most important remaining procedural foreground object. Improving it tests the same controlled-asset workflow as the prop pass, but on the object players focus on while moving through the map.

This target is intentionally narrower than terrain, lighting, background, or relay/base art:

- one named foreground asset
- one scene integration point: `scenes/player/Player.tscn`
- no map source changes
- no terrain tile changes
- no collision shape changes
- no movement tuning

## Affected Assets And Code

Expected affected paths for the implementation issue:

- `assets/player/player_diver_01.png`
- `tools/generate_player_sprite.py`
- `references/asset_reviews/player_sprite_01_review.png`
- `scenes/player/Player.tscn`
- `docs/ASSET_MANIFEST.md`
- production-slice captures and baseline review sheets after the renderer/assets change

The player sprite should be selected by the player scene, not by map JSON. The map source of truth remains unchanged.

## Untouched Areas

The implementation should not intentionally change:

- `maps/*.greybox.json`
- terrain tile source or tile selection
- terrain/collision generation
- player `CollisionShape2D` size or position
- player movement speed, acceleration, deceleration, or input mapping
- camera limits, smoothing, or capture camera definitions
- salvage, hazards, oxygen, extraction, reset, or route-smoke logic
- accepted baseline directories under `visual_baselines/` until a review issue accepts replacement baselines
- debug marker meanings or colors

## Expected Screenshot Differences

Expected differences:

- the player reads more like a compact side-view diver or small salvage swimmer
- the current orange polygon body and cyan visor placeholder are replaced by the named sprite
- the existing light cone can remain if it still supports readability

Unexpected differences:

- changed spawn position
- changed collision clearance or route-smoke behavior
- changed map framing, camera zoom, or capture definitions
- changed boat, relay/base, terrain, props, water, or UI art
- accepted baseline replacement without review

## Capture And Baseline Expectations

Before changing the player visual:

```bash
python tools/manage_production_slice_baseline.py compare-all
```

#76 adds the focused player-readability capture for this pass:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-player-readability
```

Expected output:

```text
visual_captures/player_readability/production_slice_01_player_start.png
```

Use this close spawn/player view alongside the normal production-slice captures before accepting any replacement baseline.

After changing the player visual:

```bash
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

Keep accepted baselines fixed until the player sprite pass is explicitly reviewed and accepted.

## Validation Commands

Use source/render and gameplay checks to prove the visual pass did not alter map semantics or movement:

```bash
python tools/check_map_parity.py
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

Run Godot smoke checks appropriate to the changed player scene:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-interaction
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-02-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-03-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-04-route
```

## Follow-Up Issue Shape

Create scoped follow-up issues for:

- #76 adding or confirming a player-focused visual capture/review artifact
- #77 implementing the player sprite asset and scene integration
- #78 deciding whether to accept replacement baselines after review
- #79 verifying the public web preview after the player sprite pass

Do not combine the player sprite pass with map cleanup, terrain art, relay/base art, enemy behavior, animation systems, or inventory/UI work.
