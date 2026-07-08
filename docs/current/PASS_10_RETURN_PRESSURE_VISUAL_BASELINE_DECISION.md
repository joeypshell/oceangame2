# Pass 10 Return Pressure Visual Baseline Decision

Date: 2026-07-08

Issue: #207 `Review Pass 10 visual impact and accept only intentional differences`
Implementation issues: #201-#206

## Decision

Accept the current `production_slice_01` normal captures as the Pass 10 return-pressure visual baseline.

The accepted difference is limited to the intentional Pass 10 source marker:

- `return_pressure_to_boat` now appears as the same subtle route/review marker style used by existing route annotations.

This marker supports the new `salvage_return_branch` cargo/banking pressure beat and does not change terrain topology, collision, spawn, extraction, salvage scoring, hazards, oxygen, or camera test definitions.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Debug captures refreshed for review only: `visual_captures/production_slice_01_debug/`
- Focused Pass 10 capture: `visual_captures/pass_10_return_pressure/production_slice_01_return_pressure.png`
- Baseline comparison sheet: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Accepted baseline: `visual_baselines/production_slice_01_accepted/`

## Stable Areas

The review confirmed these areas remain stable:

- terrain topology and collision-derived cave shape
- water, background silhouettes, and route camera framing
- boat entry/extraction visuals
- player sprite and movement pose
- existing salvage and hazard props
- timed deep-cache affordance
- Pass 08/09 southwest pocket payoff cue
- production slices 02-04

## Scope Confirmation

This decision does not accept changes to:

- source map topology
- runtime behavior beyond the already implemented Pass 10 feedback
- public Web preview deployment state
- production slices 02-04 baselines
- generated `.import` sidecars

The focused route-outcome, timed-salvage, and southwest-pocket review captures were run as verification but were not accepted as part of this baseline decision.

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
```

## Follow-Up

Verify the public Web preview under #208 after the Pass 10 commits deploy.
