# Route Payoff Visual Baseline Decision

Date: 2026-07-06

Issue: #118 `Review and accept route-payoff visual baselines`
Implementation issues: #115 `Render high-value salvage with distinct prototype marker`, #116 `Author one risk-reward salvage placement in production slice 01`

## Decision

Accept the route-payoff visual change in `production_slice_01` as the current prototype baseline.

The accepted visual change is limited to the small valuable-salvage cue rendered over `salvage_lower_loop`, the authored lower-loop route-choice payoff target.

## Reviewed Artifacts

- Slice 01 normal captures: `visual_captures/production_slice_01/`
- Slice 01 debug captures: `visual_captures/production_slice_01_debug/`
- Slice 01 review sheet: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Accepted baseline: `visual_baselines/production_slice_01_accepted/`

## Review Result

The pre-acceptance comparison showed the expected differences only:

- a tiny gold valuable-salvage cue in the overview context
- the same valuable-salvage cue in the lower-loop capture

The following remained visually stable:

- cave terrain
- water
- background depth art
- player and boat sprites
- common salvage and hazard props
- camera framing
- map topology and collision
- review overlay layout

## Accepted Baseline

The accepted `production_slice_01` baseline was refreshed from the current six-view normal capture set:

```text
visual_baselines/production_slice_01_accepted/
```

Debug captures were regenerated to keep capture freshness checks clean, but debug captures are not the named accepted visual baseline.

## Scope Confirmation

This decision does not accept changes to:

- terrain topology
- collision
- player movement
- oxygen timing
- extraction semantics
- production slices 02-04
- public Web preview deployment state

## Verification

Commands run for this decision:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
python tools/check_camera_captures.py maps/production_slice_01.greybox.json visual_captures/production_slice_01
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py --slice production_slice_01 compare
python tools/manage_production_slice_baseline.py --slice production_slice_01 accept
python tools/manage_production_slice_baseline.py --slice production_slice_01 compare
```

Gameplay/source checks from #116 and #117 already confirmed:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
```

## Follow-Up

Verify the public Web preview under #119 after this accepted baseline commit deploys.
