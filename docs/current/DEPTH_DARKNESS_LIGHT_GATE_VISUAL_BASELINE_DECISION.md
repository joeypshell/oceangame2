# Depth Darkness Light Gate Visual Baseline Decision

Date: 2026-07-09

Issue: #468 `Review darkness-light visual impact and baseline decision`
Implementation issues: #462-#467

## Decision

Do not accept any production-slice baseline changes for the first darkness/light gate pass.

The pass adds one source-authored visual-only darkness zone, a `dive_light_1` readability improvement, deterministic smoke coverage, and a focused before/after review capture pair. The normal production-slice camera captures remain clean against the accepted baselines across slices 01-04, so there are no terrain, player, prop, boat, hazard, salvage, camera, UI, or map-framing differences to accept.

The intentional visual review artifacts are:

- `visual_captures/darkness_light_gate/production_slice_01_darkness_light_before_light.png`
- `visual_captures/darkness_light_gate/production_slice_01_darkness_light_after_light.png`

Those captures are review artifacts only. They are not accepted visual baselines.

## Reviewed Artifacts

- Focused darkness/light captures:
  - `visual_captures/darkness_light_gate/production_slice_01_darkness_light_before_light.png`
  - `visual_captures/darkness_light_gate/production_slice_01_darkness_light_after_light.png`
- Baseline comparison sheets:
  - `references/asset_reviews/production_slice_01_visual_baseline_review.png`
  - `references/asset_reviews/production_slice_02_visual_baseline_review.png`
  - `references/asset_reviews/production_slice_03_visual_baseline_review.png`
  - `references/asset_reviews/production_slice_04_visual_baseline_review.png`
- Accepted baselines: `visual_baselines/production_slice_*_accepted/`

## Stable Areas

The review confirmed these areas remain stable:

- production-slice terrain topology and collision-derived cave shape
- water, background silhouettes, and camera framing
- boat entry/extraction and relay/base visuals
- player sprite pose, direction, and light-cone ownership
- salvage, timed-salvage, pry-salvage, upgrade-chest, hazard, moving-hazard, current-gate, oxygen-rest, objective, connector, and progression visuals outside the focused darkness/light captures
- accepted baseline captures for production slices 01-04

## Scope Confirmation

This decision does not accept changes to:

- source map topology
- runtime behavior beyond the already implemented visual-only darkness/readability state
- public Web preview deployment state
- production-slice accepted baselines
- generated `.import` sidecars

## Verification

Commands run:

```powershell
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Additional review:

```text
production_slice_01: clean
production_slice_02: clean
production_slice_03: clean
production_slice_04: clean
```

The focused before/after capture pair was reviewed visually: the before shot shows `Light base` in `deep_cache_dark_pocket`, and the after shot shows the reduced darkness overlay with `Light +range upgraded`.

## Follow-Up

Verify the public Web preview under #469 after this decision doc lands.
