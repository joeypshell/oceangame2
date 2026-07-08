# Pass 11 Pre-Pickup Route Cue Visual Baseline Decision

Date: 2026-07-08

Issue: #220 `Review and accept only intentional Pass 11 visual differences`
Implementation issues: #214-#219

## Decision

Accept the current `production_slice_01` normal captures as the Pass 11 pre-pickup route-cue visual baseline.

The accepted difference is limited to the intentional Pass 11 source marker:

- `southwest_pocket_pre_pickup_cue` now appears in the same subtle route/review marker style as existing route annotations.

This marker supports the pre-pickup `Optional pocket ahead` feedback for `salvage_southwest_return_cache`. It does not change terrain topology, collision, spawn, extraction, salvage scoring, hazards, oxygen, cargo capacity, camera tests, player art, props, or background art.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Debug captures refreshed for review only: `visual_captures/production_slice_01_debug/`
- Focused Pass 11 capture: `visual_captures/pass_11_pre_pickup_route_cue/production_slice_01_pre_pickup_route_cue.png`
- Baseline comparison sheet: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Accepted baseline: `visual_baselines/production_slice_01_accepted/`

## Stable Areas

The review confirmed these areas remain stable:

- terrain topology and collision-derived cave shape
- water, background silhouettes, and camera framing
- boat entry/extraction visuals
- player sprite and movement pose
- existing salvage, hazard, and timed-salvage props
- Pass 09 southwest pocket payoff feedback
- Pass 10 return-pressure marker and feedback
- production slices 02-04

## Scope Confirmation

This decision does not accept changes to:

- source map topology
- runtime behavior beyond the already implemented Pass 11 cue
- public Web preview deployment state
- production slices 02-04 baselines
- generated `.import` sidecars

## Verification

Commands run:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
```

## Follow-Up

Verify the public Web preview under #221 after the Pass 11 commits deploy.
