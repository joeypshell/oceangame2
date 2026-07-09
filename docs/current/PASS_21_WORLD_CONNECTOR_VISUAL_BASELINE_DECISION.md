# Pass 21 World Connector Visual Baseline Decision

Date: 2026-07-09

Issue: #427 `Review Pass 21 visual impact and baseline decision`
Implementation issues: #420-#426

## Decision

Do not accept any production-slice baseline changes for Pass 21.

Pass 21 adds one source-authored connector pair, a prompted runtime transition from `production_slice_01` to `production_slice_04`, deterministic smoke coverage, and a focused connector review capture. The normal production-slice camera captures still match the accepted baselines across slices 01-04, so there are no terrain, player, boat, prop, camera, background, collision-shape, or normal capture differences to accept.

The new review artifact is:

- `visual_captures/pass_21_world_connector/production_slice_04_world_connector_arrival.png`

That capture is a review artifact only. It is not an accepted visual baseline.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/` through `visual_captures/production_slice_04/`
- Focused Pass 21 capture: `visual_captures/pass_21_world_connector/production_slice_04_world_connector_arrival.png`
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
- player sprite base pose and normal review captures
- salvage, timed-salvage, hazards, oxygen rest, route cues, objective cues, pry salvage, progression, cargo, and light-upgrade visuals outside the focused Pass 21 connector capture
- accepted baseline captures for production slices 01-04

## Scope Confirmation

This decision does not accept changes to:

- source map topology beyond the already implemented connector metadata
- runtime behavior beyond the already implemented Pass 21 connector flow
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

Baseline status:

```text
production_slice_01: current captures match accepted baselines
production_slice_02: current captures match accepted baselines
production_slice_03: current captures match accepted baselines
production_slice_04: current captures match accepted baselines
```

## Follow-Up

Verify the public Web preview under #428 after the Pass 21 commits deploy.
