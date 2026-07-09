# Pass 20 Light Upgrade Visual Baseline Decision

Date: 2026-07-09

Issue: #407 `Review Pass 20 visual impact and baseline decision`
Implementation issues: #400-#406

## Decision

Do not accept any production-slice baseline changes for Pass 20.

Pass 20 adds one session light confidence upgrade, compact overlay/result feedback, deterministic smoke coverage, and a focused review capture. The normal production-slice camera captures remain clean against the accepted baselines across slices 01-04, so there are no terrain, player, prop, boat, camera, background, collision-shape, or normal capture differences to accept.

The new review artifact is:

- `visual_captures/pass_20_light_upgrade/production_slice_01_pass_20_light_upgrade.png`

That capture is a review artifact only. It is not an accepted visual baseline.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Focused Pass 20 capture: `visual_captures/pass_20_light_upgrade/production_slice_01_pass_20_light_upgrade.png`
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
- salvage, timed-salvage, hazard, oxygen-rest, route-cue, objective-cue, primary-completion, pry-salvage, and prior progression visuals outside the focused Pass 20 light upgrade capture
- accepted baseline captures for production slices 01-04

## Scope Confirmation

This decision does not accept changes to:

- source map topology
- runtime behavior beyond the already implemented Pass 20 light upgrade flow
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
production_slice_01: clean
production_slice_02: clean
production_slice_03: clean
production_slice_04: clean
```

## Follow-Up

Verify the public Web preview under #408 after the Pass 20 commits deploy.
