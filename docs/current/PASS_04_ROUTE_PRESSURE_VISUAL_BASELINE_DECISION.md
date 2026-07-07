# Pass 04 Route Pressure Visual Baseline Decision

Date: 2026-07-07

Issue: #146 `Review and accept Pass 04 route-pressure visual baseline`
Implementation issues: #138-#145

## Decision

Accept the current `production_slice_01` normal captures as the Pass 04 route-pressure visual baseline.

The baseline comparison showed no pixel-level drift in the six normal production-slice captures after the Pass 04 runtime/UI changes. The route-outcome result panel is covered by the focused review capture from #145, not by replacing the normal six-view baseline with a completed-run state.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Debug captures refreshed for freshness only: `visual_captures/production_slice_01_debug/`
- Baseline comparison sheet: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Accepted baseline: `visual_baselines/production_slice_01_accepted/`
- Focused route-outcome review capture: `visual_captures/route_outcome/production_slice_01_route_outcome_result.png`

## Review Result

The normal baseline review accepted the current captures with no visible differences from the previous accepted normal baseline.

The intentional Pass 04 visible changes are reviewed through focused/runtime states:

- hazard warning and oxygen penalty feedback remain runtime overlay states, covered by smoke checks
- safe/deep oxygen pressure remains runtime route behavior, covered by smoke checks
- route outcome text appears in the focused result-panel capture as `Route: Deep route`

The following remained visually stable in the normal captures:

- cave terrain and tile seams
- water and background depth art
- player, boat, salvage, and hazard sprites
- camera framing
- source map topology and collision
- normal idle review overlay layout

## Scope Confirmation

This decision does not change or accept changes to:

- map source data
- collision generation
- camera test definitions
- production slices 02-04
- accepted baseline sidecars or generated `.import` files
- public Web preview deployment state

## Verification

Commands run:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
python tools/manage_production_slice_baseline.py --slice production_slice_01 compare
python tools/manage_production_slice_baseline.py --slice production_slice_01 accept
python tools/manage_production_slice_baseline.py clean-generated --all-slices
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py check-clean --all-slices
```

`python tools/check_production_slice_captures.py --fail-on-stale` initially reported stale slice-01 debug captures after normal capture regeneration. Refreshing `--capture-production-slice-debug-map` fixed the freshness check without changing accepted normal-baseline scope.

## Follow-Up

Verify the public Web preview under #147 after the Pass 04 commits deploy.
