# Pass 13 Route Commitment Visual Baseline Decision

Date: 2026-07-08

Issue: #243 `Review and accept only intentional Pass 13 visual differences`
Implementation issues: #236-#242

## Decision

Do not accept any production-slice baseline changes for Pass 13.

The Pass 13 route-commitment work adds source/runtime objective metadata, compact overlay/result text, deterministic smoke coverage, and a focused review capture. The normal production-slice camera captures match the accepted baselines pixel-for-pixel across slices 01-04, so there are no terrain, player, prop, boat, camera, or background differences to accept.

The new review artifact is:

- `visual_captures/pass_13_route_commitment/production_slice_01_route_commitment.png`

That capture is a review artifact only. It is not an accepted visual baseline.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Focused Pass 13 capture: `visual_captures/pass_13_route_commitment/production_slice_01_route_commitment.png`
- Baseline comparison sheets:
  - `references/asset_reviews/production_slice_01_visual_baseline_review.png`
  - `references/asset_reviews/production_slice_02_visual_baseline_review.png`
  - `references/asset_reviews/production_slice_03_visual_baseline_review.png`
  - `references/asset_reviews/production_slice_04_visual_baseline_review.png`
- Accepted baselines: `visual_baselines/production_slice_*_accepted/`

## Stable Areas

The review confirmed these areas remain stable:

- terrain topology and collision-derived cave shape
- water, background silhouettes, and camera framing
- boat entry/extraction visuals
- player sprite and movement pose
- salvage, timed-salvage, hazard, rest-pocket, and route-cue visuals
- production slices 01-04 accepted baseline captures

## Scope Confirmation

This decision does not accept changes to:

- source map topology
- runtime behavior beyond the already implemented Pass 13 route objective
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

Verify the public Web preview under #244 after the Pass 13 commits deploy.
