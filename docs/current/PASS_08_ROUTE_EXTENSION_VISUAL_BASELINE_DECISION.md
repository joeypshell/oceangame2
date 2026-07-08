# Pass 08 Route Extension Visual Baseline Decision

Date: 2026-07-08

Issue: #188 `Review and accept Pass 08 route-extension visual impact`
Implementation issues: #180-#187

## Decision

Accept the current `production_slice_01` normal captures as the Pass 08 route-extension visual baseline.

The accepted differences are limited to the intentional Pass 08 route-scale change:

- the new tiny southwest return-pocket alcove near `southwest_return_pocket_extension`
- the new common salvage cue `salvage_southwest_return_cache`
- the normal overlay total changing from `0/6` to `0/7` because the new cue is authored salvage

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Debug captures refreshed for review only: `visual_captures/production_slice_01_debug/`
- Focused route-extension capture: `visual_captures/route_extension/production_slice_01_route_extension.png`
- Baseline comparison sheet: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Accepted baseline: `visual_baselines/production_slice_01_accepted/`

## Stable Areas

The review confirmed these areas remain stable:

- boat entry and extraction framing
- player sprite and default capture placement
- timed-salvage marker and `salvage_deep_right_cache`
- Pass 07 `hazard_right_branch` pressure marker
- unrelated salvage and hazard props
- camera test definitions and framing
- production slices 02-04
- broad terrain, water, and background treatment outside the selected route-extension area

## Scope Confirmation

This decision does not change or accept changes to:

- map source data
- collision generation
- gameplay behavior
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
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
```

`check-clean --all-slices` initially found pre-existing ignored `.import` sidecars in accepted baseline directories for slices 02-04. Running `clean-generated --all-slices` removed those sidecars, and the follow-up clean check passed.

## Follow-Up

Verify the public Web preview under #189 after the Pass 08 commits deploy.
