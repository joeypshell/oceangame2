# Pass 19 Cargo Upgrade Visual Baseline Decision

Date: 2026-07-09

Issue: #387 `Review Pass 19 visual impact and baseline decision`
Implementation issues: #380-#386

## Decision

Do not accept any production-slice baseline changes for Pass 19.

Pass 19 adds one session cargo capacity upgrade, compact overlay/result feedback, deterministic smoke coverage, and a focused review capture. The normal production-slice camera captures remain clean against the accepted baselines across slices 01-04, so there are no terrain, player, prop, boat, camera, background, collision-shape, or normal capture differences to accept.

The new review artifact is:

- `visual_captures/pass_19_cargo_upgrade/production_slice_01_pass_19_cargo_upgrade.png`

That capture is a review artifact only. It is not an accepted visual baseline.

## Reviewed Artifacts

- Normal captures: `visual_captures/production_slice_01/`
- Focused Pass 19 capture: `visual_captures/pass_19_cargo_upgrade/production_slice_01_pass_19_cargo_upgrade.png`
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
- salvage, timed-salvage, hazard, oxygen-rest, route-cue, objective-cue, primary-completion, pry-salvage, and progression visuals outside the focused Pass 19 cargo upgrade capture
- accepted baseline captures for production slices 01-04

## Scope Confirmation

This decision does not accept changes to:

- source map topology
- runtime behavior beyond the already implemented Pass 19 cargo upgrade flow
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

Verify the public Web preview under #388 after the Pass 19 commits deploy.
