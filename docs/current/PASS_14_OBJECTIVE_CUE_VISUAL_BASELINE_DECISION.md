# Pass 14 Objective Cue Visual Baseline Decision

Date: 2026-07-08

Issue: #284 `Review Pass 14 visual impact and baseline decision`
Implementation issues: #278-#283

## Decision

Do not accept any production-slice baseline changes for Pass 14.

The Pass 14 objective-cue work adds one compact overlay line at the boat/extraction start context, deterministic smoke coverage, and a focused review capture. The normal production-slice camera captures match the accepted baselines pixel-for-pixel across slices 01-04, so there are no terrain, player, prop, boat, camera, background, or normal overlay differences to accept.

The new review artifact is:

- `visual_captures/pass_14_objective_cue/production_slice_01_objective_cue.png`

That capture is a review artifact only. It is not an accepted visual baseline.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Focused Pass 14 capture: `visual_captures/pass_14_objective_cue/production_slice_01_objective_cue.png`
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
- boat entry/extraction visuals
- player sprite and movement pose
- salvage, timed-salvage, hazard, rest-pocket, route-cue, and objective-progress visuals outside the focused start cue
- accepted baseline captures for production slices 01-04

## Scope Confirmation

This decision does not accept changes to:

- source map topology
- runtime behavior beyond the already implemented Pass 14 objective cue
- public Web preview deployment state
- production-slice accepted baselines
- generated `.import` sidecars

## Verification

Commands run:

```powershell
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
python tools/check_file_lengths.py
git diff --check
```

Additional pixel comparison:

```text
production_slice_01: no differences
production_slice_02: no differences
production_slice_03: no differences
production_slice_04: no differences
```

## Follow-Up

Verify the public Web preview under #285 after the Pass 14 commits deploy.
