# Pass 06 Timed-Salvage Visual Baseline Decision

Date: 2026-07-08

Issue: #167 `Review and accept Pass 06 timed-salvage visual impact`
Implementation issues: #160-#166

## Decision

Accept the current `production_slice_01` lower-loop normal capture as the Pass 06 timed-salvage visual baseline.

The only accepted normal-capture difference is the small in-world timed-salvage affordance at `salvage_deep_right_cache`, visible in the lower-loop/deep-cache view. This is intentional Pass 06 feedback for the existing timed target.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Debug captures refreshed for freshness: `visual_captures/production_slice_01_debug/`
- Accepted baseline: `visual_baselines/production_slice_01_accepted/`
- Baseline comparison sheet: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Focused timed-salvage review capture: `visual_captures/timed_salvage/production_slice_01_timed_salvage.png`

## Review Result

Accepted differences:

- `production_slice_lower_loop.png` now includes the cyan timed-salvage affordance marker around the deep cache.
- The focused timed-salvage capture shows the marker, player, oxygen/cargo overlay, and compact progress bar.

Stable unchanged areas:

- terrain topology and collision presentation
- camera framing and camera test definitions
- boat, player, hazards, instant salvage, props, water, and background depth
- production slices 02-04
- route-outcome result capture

## Scope Confirmation

This decision does not change or accept changes to:

- map JSON source data
- gameplay behavior
- collision generation
- new asset families
- generated `.import` sidecars
- public Web preview deployment state

## Verification

Commands run:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
python tools/manage_production_slice_baseline.py --slice production_slice_01 compare
python tools/manage_production_slice_baseline.py --slice production_slice_01 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
python tools/check_production_slice_captures.py --fail-on-stale
```

`python tools/check_production_slice_captures.py --fail-on-stale` initially reported stale slice-01 debug captures after the normal capture refresh. Refreshing `--capture-production-slice-debug-map` fixed freshness without changing accepted-baseline scope.

## Follow-Up

Verify the public Web preview under #168 after the Pass 06 visual commits deploy.
