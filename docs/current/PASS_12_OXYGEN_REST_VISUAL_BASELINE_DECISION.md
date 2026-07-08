# Pass 12 Oxygen Rest Visual Baseline Decision

Date: 2026-07-08

Issue: #231 `Review and accept only intentional Pass 12 visual differences`
Implementation issues: #224-#230

## Decision

Accept the current `production_slice_01` normal captures as the Pass 12 oxygen-rest visual baseline.

The accepted difference is limited to the intentional Pass 12 source marker:

- `lower_loop_oxygen_rest_pocket` now appears in the same subtle route/review marker style as existing route annotations.

This marker supports the compact `Rest pocket +oxygen` feedback and limited oxygen recovery behavior. It does not change terrain topology, collision, spawn, extraction, salvage scoring, hazards, cargo capacity, camera tests, player art, props, or background art.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Debug captures refreshed for review only: `visual_captures/production_slice_01_debug/`
- Focused Pass 12 capture: `visual_captures/pass_12_oxygen_rest_pressure/production_slice_01_oxygen_rest_pressure.png`
- Baseline comparison sheet: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Accepted baseline: `visual_baselines/production_slice_01_accepted/`

## Accepted Differences

The normal and debug capture changes are expected only in the views where the rest-pocket marker is visible:

- `production_slice_overview`
- `production_slice_central_crossing`
- `production_slice_lower_loop`

The comparison sheet before acceptance showed marker-only differences in these views. After baseline acceptance, the comparison sheet was regenerated against the new accepted baseline.

## Stable Areas

The review confirmed these areas remain stable:

- terrain topology and collision-derived cave shape
- water, background silhouettes, and camera framing
- boat entry/extraction visuals
- player sprite and movement pose
- existing salvage, timed-salvage, hazard, return-pressure, and pre-pickup cue visuals
- production slices 02-04

## Scope Confirmation

This decision does not accept changes to:

- source map topology
- runtime behavior beyond the already implemented Pass 12 rest-pocket feedback
- public Web preview deployment state
- production slices 02-04 baselines
- generated `.import` sidecars

## Verification

Commands run:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
python tools/check_production_slice_captures.py --fail-on-stale
```

## Follow-Up

Verify the public Web preview under #232 after the Pass 12 commits deploy.
