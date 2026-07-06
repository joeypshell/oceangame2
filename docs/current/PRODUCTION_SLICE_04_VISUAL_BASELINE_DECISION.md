# Production Slice 04 Visual Baseline Decision

Date: 2026-07-06

Issue: #63 `Decide visual baseline status for production slice 04`

## Decision

Accept the current `production_slice_04` normal captures as the visual baseline for the slice.

This baseline is a reference target for the lower-left connector / return-loop slice. It is not a claim that the slice is final production art, and it does not promote slice 04 to the default preview map.

## Rationale

- `docs/current/PRODUCTION_SLICE_04_EVALUATION.md` found the slice valid as a lower-left connector/return-loop reference.
- Source/collision parity, reachability validation, route smoke, and capture completeness all pass.
- Normal captures are complete, nonblank, and show the five intended route beats: overview, relay entry, lower-left loop, curved corridor, and return route.
- Debug captures confirm source grid, route rectangles, relay/extraction, salvage, and hazard markers align with terrain.
- Curved corridor stair steps remain visible, but they are an intentional part of what slice 04 is testing and are not a baseline blocker.

## Accepted Artifacts

- Baseline directory: `visual_baselines/production_slice_04_accepted/`
- Review sheet: `references/asset_reviews/production_slice_04_visual_baseline_review.png`
- Source captures: `visual_captures/production_slice_04/`
- Debug review captures: `visual_captures/production_slice_04_debug/`

If future camera framing, terrain source cleanup, or relay art changes intentionally alter these views, compare against this baseline first, then accept a replacement baseline only after that change is reviewed.

## Verification

Completed for this decision:

```powershell
python tools/manage_production_slice_baseline.py --list-slices
python tools/manage_production_slice_baseline.py --slice production_slice_04 accept
python tools/manage_production_slice_baseline.py --slice production_slice_04 compare
```

The rendered comparison sheet shows accepted baseline, current capture, and difference columns for all five configured slice-04 views.
