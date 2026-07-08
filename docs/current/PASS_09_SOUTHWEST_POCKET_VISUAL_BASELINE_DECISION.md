# Pass 09 Southwest Pocket Visual Baseline Decision

Date: 2026-07-08

Issue: #197 `Review and accept Pass 09 southwest pocket visual impact`
Implementation issues: #191-#196

## Decision

Accept the current `production_slice_01` normal captures as the Pass 09 southwest pocket visual baseline.

The accepted difference is limited to the intentional Pass 09 route-decision payoff:

- `salvage_southwest_return_cache` now renders as `valuable` salvage with the existing small gold cue.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Debug captures refreshed for review only: `visual_captures/production_slice_01_debug/`
- Focused Pass 08 route-extension capture: `visual_captures/route_extension/production_slice_01_route_extension.png`
- Focused Pass 09 decision capture: `visual_captures/southwest_pocket_decision/production_slice_01_southwest_pocket_decision.png`
- Baseline comparison sheet: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Accepted baseline: `visual_baselines/production_slice_01_accepted/`

## Stable Areas

The review confirmed these areas remain stable:

- terrain topology, collision, water, and background framing
- boat entry/extraction visuals
- player sprite and camera test framing
- existing safe/deep route salvage cues
- `hazard_right_branch` pressure marker
- timed salvage marker and progress target
- production slices 02-04

## Scope Confirmation

This decision does not change or accept changes to:

- map source data
- runtime behavior
- camera test definitions
- production slices 02-04 baselines
- public Web preview deployment state
- generated `.import` sidecars

## Verification

Commands run:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
```

## Follow-Up

Verify the public Web preview under #198 after the Pass 09 commits deploy.
