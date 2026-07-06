# Player Sprite Baseline Decision

Date: 2026-07-06

Issue: #78 `Decide player sprite baseline acceptance`

## Decision

Accept the #77 player/diver sprite pass as the current prototype player-art baseline.

The `assets/player/player_diver_01.png` sprite is approved for the current prototype. It replaces the procedural player body/visor placeholder while preserving the existing player collision shape, movement controller, camera behavior, light cone, map data, and gameplay logic.

## Rationale

The player sprite review sheet shows a compact side-view diver with a readable silhouette, clear visor, and collision overlay smaller than the art. The focused player-readability capture shows the sprite clearly in the default production-slice boat-entry context.

The accepted-baseline review sheets for production slices 01, 02, 03, and 04 showed differences limited to the intended player visual where the player is visible. Terrain, props, water/background treatment, UI framing, camera definitions, route context, and map geometry remained stable.

## Accepted Artifacts

Approved player asset:

```text
assets/player/player_diver_01.png
```

Review artifacts:

```text
references/asset_reviews/player_sprite_01_review.png
visual_captures/player_readability/production_slice_01_player_start.png
references/asset_reviews/production_slice_01_visual_baseline_review.png
references/asset_reviews/production_slice_02_visual_baseline_review.png
references/asset_reviews/production_slice_03_visual_baseline_review.png
references/asset_reviews/production_slice_04_visual_baseline_review.png
```

Updated accepted baselines:

```text
visual_baselines/production_slice_01_accepted/
visual_baselines/production_slice_02_accepted/
visual_baselines/production_slice_03_accepted/
visual_baselines/production_slice_04_accepted/
```

## Follow-Up

#79 should verify the public web preview after this accepted player sprite pass. Keep further player animation, equipment variants, scale changes, or movement/collision changes out of this decision and track them as separate controlled visual or gameplay issues.

## Verification

Completed for this decision:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-03-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-04-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-player-readability
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_slice_01 accept
python tools/manage_production_slice_baseline.py --slice production_slice_02 accept
python tools/manage_production_slice_baseline.py --slice production_slice_03 accept
python tools/manage_production_slice_baseline.py --slice production_slice_04 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
git diff --check
```
