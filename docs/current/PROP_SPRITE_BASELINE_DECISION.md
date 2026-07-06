# Prop Sprite Baseline Decision

Date: 2026-07-06

Issue: #71 `Decide #70 prop sprite baseline acceptance`
Follow-up: #75 `Reconcile production slice 01 accepted baseline`

## Decision

Accept the #70 sprite-prop pass as the current prototype prop-art baseline for the production-slice reference set, with one important scope split:

- Accept updated visual baselines for `production_slice_02`, `production_slice_03`, and `production_slice_04`.
- Do not replace the `production_slice_01` accepted baseline in this issue.

The prop sprites are now approved current-prototype assets. They are still allowed to evolve through future controlled visual revisions, but they are no longer merely planned or unreviewed draft assets.

## Rationale

The prop review sheet shows distinct, readable sprites for the currently authored salvage and hazard kinds:

- salvage: `crate`, `wreck_fragment`, `relic`
- hazards: `mine`, `jellyfish`

The accepted-baseline review sheets for slices 02, 03, and 04 showed differences concentrated around those prop sprites. Terrain shape, camera framing, relay/base visuals, collision source, and route context remained stable.

The slice 01 review sheet did not show a clean prop-only diff. It includes pre-existing broad baseline/current differences from the older accepted slice-01 baseline versus the current six-view capture set. Accepting slice 01 here would hide unrelated baseline drift inside a prop-art decision, so #75 handles that as a separate scoped baseline reconciliation.

## Accepted Artifacts

Updated accepted baselines:

```text
visual_baselines/production_slice_02_accepted/
visual_baselines/production_slice_03_accepted/
visual_baselines/production_slice_04_accepted/
```

Review artifacts:

```text
references/asset_reviews/prop_sprites_01_review.png
references/asset_reviews/production_slice_02_visual_baseline_review.png
references/asset_reviews/production_slice_03_visual_baseline_review.png
references/asset_reviews/production_slice_04_visual_baseline_review.png
```

Pending follow-up artifact:

```text
references/asset_reviews/production_slice_01_visual_baseline_review.png
```

## Verification

Completed for this decision:

```powershell
python tools\manage_production_slice_baseline.py --slice production_slice_02 accept
python tools\manage_production_slice_baseline.py --slice production_slice_03 accept
python tools\manage_production_slice_baseline.py --slice production_slice_04 accept
python tools\manage_production_slice_baseline.py compare-all
python tools\check_production_slice_captures.py
```

`production_slice_01` baseline acceptance was intentionally not run.
