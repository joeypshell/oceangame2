# Salvage/Oxygen Feedback Baseline Decision

Date: 2026-07-06

Issue: #107 `Review and accept feedback polish baselines`
Implementation issue: #106 `Implement salvage and oxygen feedback polish`

## Decision

Accept the salvage/oxygen feedback overlay polish as the current prototype visual baseline for normal production-slice captures.

The accepted change is limited to the top-left review overlay text/layout:

- `Salvage banked X/Y`
- `Held N`
- `Oxygen Ns` with `LOW` when applicable
- a prompt/state line such as `Return to extraction`

## Reviewed Artifacts

- Focused feedback capture: `visual_captures/feedback_overlay/production_slice_01_feedback_overlay.png`
- Slice 01 review sheet: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Slice 02 review sheet: `references/asset_reviews/production_slice_02_visual_baseline_review.png`
- Slice 03 review sheet: `references/asset_reviews/production_slice_03_visual_baseline_review.png`
- Slice 04 review sheet: `references/asset_reviews/production_slice_04_visual_baseline_review.png`

## Review Result

The pre-acceptance comparison sheets showed the expected differences only:

- the top-left review overlay became slightly taller
- banked salvage and held salvage are now separated
- oxygen and prompt/state text are clearer

The following remained visually stable:

- cave terrain
- water
- background depth art
- player, boat, and prop sprites
- salvage and hazard world positions
- camera framing
- map topology

## Accepted Baselines

The normal accepted-baseline directories were refreshed from current captures:

- `visual_baselines/production_slice_01_accepted/`
- `visual_baselines/production_slice_02_accepted/`
- `visual_baselines/production_slice_03_accepted/`
- `visual_baselines/production_slice_04_accepted/`

Debug captures and map source data were not intentionally changed for this decision.

## Scope Confirmation

This decision does not change or accept changes to:

- map source data
- terrain/collision generation
- route design
- player movement or collision
- salvage collection, banking, or reset semantics
- hazard behavior
- oxygen drain/refill/depletion behavior
- default preview selection

## Verification

Commands run before acceptance:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-03-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-04-map
python tools/manage_production_slice_baseline.py compare-all
```

Baseline acceptance commands:

```powershell
python tools/manage_production_slice_baseline.py --slice production_slice_01 accept
python tools/manage_production_slice_baseline.py --slice production_slice_02 accept
python tools/manage_production_slice_baseline.py --slice production_slice_03 accept
python tools/manage_production_slice_baseline.py --slice production_slice_04 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/check_production_slice_captures.py --fail-on-stale
```

Gameplay checks:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
```

## Follow-Up

Verify the public Web preview under #108 after this acceptance commit deploys. If the public preview reports stale build metadata, missing resources, or runtime errors, fix that as a Web preview issue rather than changing the accepted baseline here.
