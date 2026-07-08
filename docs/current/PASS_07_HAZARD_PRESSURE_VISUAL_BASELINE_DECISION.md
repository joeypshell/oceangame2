# Pass 07 Hazard Pressure Visual Baseline Decision

Date: 2026-07-08

Issue: #177 `Review and accept Pass 07 hazard/navigation visual impact`

## Decision

Accept the `production_slice_01` visual baseline update for the Pass 07 hazard/navigation pressure marker.

The accepted difference is limited to the source-authored `lower_loop_to_deep_cache_pressure` marker becoming visible in the affected `production_slice_01` review captures. This supports the selected `hazard_right_branch` route-pressure review context.

## Accepted Differences

- `visual_captures/production_slice_01/production_slice_overview.png`
- `visual_captures/production_slice_01/production_slice_lower_loop.png`
- matching accepted baseline files under `visual_baselines/production_slice_01_accepted/`
- matching debug captures under `visual_captures/production_slice_01_debug/`

The comparison sheet rendered before acceptance was:

```text
references/asset_reviews/production_slice_01_visual_baseline_review.png
```

It showed the intentional marker-area difference in the overview/lower-loop views. No terrain, player, boat, timed-salvage marker, prop, camera framing, or unrelated sprite drift was accepted.

## Stable Areas

- `production_slice_02`
- `production_slice_03`
- `production_slice_04`
- `production_slice_01` terrain topology and collision
- player, boat, salvage, hazard, background, and terrain art
- timed-salvage affordance and route-outcome capture behavior
- public baseline directories after generated sidecar cleanup

## Commands Run

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py accept
python tools/manage_production_slice_baseline.py clean-generated --all-slices
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
```

## Notes

- No gameplay, map source, or runtime behavior changed in this issue.
- No `.import` sidecars are part of the accepted change.
- The new focused hazard-pressure review capture from #176 remains a review artifact, not an accepted baseline target.
