# Expedition Loop Visual Baseline Decision

Date: 2026-07-06

## Decision

Accept the regenerated `production_slice_01` normal visual captures as the current expedition-loop baseline.

The accepted differences are limited to the Controlled Gameplay Pass 03 surface:

- review overlay text now includes score, held cargo, and oxygen state
- `salvage_deep_right_cache` appears as the new lower-right valuable salvage cue in the lower-loop view
- accepted baseline sidecar cleanup removed generated `.import` files from production-slice accepted baseline folders

Terrain shape, collision source, camera framing, background art, boat/player/prop assets, and unrelated production slices remain unchanged for this acceptance pass.

## Review Artifact

Reviewed comparison sheet:

```text
references/asset_reviews/production_slice_01_visual_baseline_review.png
```

Accepted baseline:

```text
visual_baselines/production_slice_01_accepted/
```

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
python tools/manage_production_slice_baseline.py --slice production_slice_01 compare
python tools/manage_production_slice_baseline.py --slice production_slice_01 accept
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py check-clean --all-slices
```
