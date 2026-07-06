# Production Slice 03 Visual Baseline Decision

Date: 2026-07-06

Issue: #55 `Decide visual baseline status for production slice 03`

## Decision

Accept the current `production_slice_03` normal captures as the visual baseline for the slice.

This baseline is a reference target for the compact connector/landmark room-cluster slice. It is not a claim that the slice is final production art, and it does not promote slice 03 to the default preview map.

## Rationale

- `docs/current/PRODUCTION_SLICE_03_EVALUATION.md` found the slice valid as a connector/landmark reference and judged the current relay readability, camera framing, and source-derived collision review good enough for this prototype pass.
- Normal captures are complete, nonblank, and show the five intended route beats: overview, relay entry, stacked rooms, connector, and return route.
- Debug captures are complete and confirm source grid, route rectangles, extraction, salvage, and hazard markers align with the rendered terrain.
- Open follow-ups #52 and #53 remain useful as future improvement tasks, but they are not blockers for preserving today's reviewed state as a regression target.

## Accepted Artifacts

- Baseline directory: `visual_baselines/production_slice_03_accepted/`
- Review sheet: `references/asset_reviews/production_slice_03_visual_baseline_review.png`
- Source captures: `visual_captures/production_slice_03/`
- Debug review captures: `visual_captures/production_slice_03_debug/`

If future camera framing, terrain source cleanup, or relay art changes intentionally alter these views, compare against this baseline first, then accept a replacement baseline only after that change is reviewed.

## Verification

Completed for this decision:

```powershell
python tools/check_camera_captures.py maps/production_slice_03.greybox.json visual_captures/production_slice_03
python tools/check_camera_captures.py maps/production_slice_03.greybox.json visual_captures/production_slice_03_debug
python tools/manage_production_slice_baseline.py --slice production_slice_03 accept
python tools/manage_production_slice_baseline.py --slice production_slice_03 compare
```
