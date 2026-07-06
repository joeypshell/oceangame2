# Production Slice 01 Visual Baseline Reconciliation

Date: 2026-07-06

Issue: #75 `Reconcile production slice 01 accepted baseline`

## Decision

Accept the current six-view `production_slice_01` capture set as the default slice's named visual baseline.

This reconciles the accepted baseline with the current authored camera-test set:

- `production_slice_overview`
- `production_slice_entry_shaft`
- `production_slice_first_route_choice`
- `production_slice_central_crossing`
- `production_slice_lower_loop`
- `production_slice_return_to_boat`

## Rationale

The pre-reconciliation review sheet showed broad differences between the old accepted baseline and the current captures. Those differences were not a clean prop-only diff from the controlled prop sprite pass. They came from the older four-view baseline target being out of sync with the current six-view default-slice capture set and its current framing/context.

No terrain, map topology, gameplay, prop art, camera definitions, collision, or route behavior changed as part of this decision. This pass only updates the accepted comparison target so future controlled visual revisions can produce clean slice-01 review diffs.

## Accepted Artifacts

Updated accepted baseline:

```text
visual_baselines/production_slice_01_accepted/
```

Updated review artifact:

```text
references/asset_reviews/production_slice_01_visual_baseline_review.png
```

## Caveat

This baseline is a current-prototype default-slice reference, not final production art. Future intentional changes to player art, terrain, water/background treatment, boat/base visuals, or props should compare against this baseline first and replace it only through a separate review/acceptance issue.

## Verification

Completed for this decision:

```powershell
python tools/check_camera_captures.py maps/production_slice_01.greybox.json visual_captures/production_slice_01
python tools/check_camera_captures.py maps/production_slice_01.greybox.json visual_captures/production_slice_01_debug
python tools/manage_production_slice_baseline.py --slice production_slice_01 compare
python tools/manage_production_slice_baseline.py --slice production_slice_01 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
git diff --check
```
