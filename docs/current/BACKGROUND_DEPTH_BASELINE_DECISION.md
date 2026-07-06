# Background Depth Baseline Decision

Date: 2026-07-06

Issue: #91 `Decide background depth baseline acceptance`
Implementation issue: #90 `Implement controlled background depth art pass`

## Decision

Accept `assets/terrain/background_rocks_02.png` as the current prototype background-depth visual and refresh the accepted production-slice baselines for slices 01-04.

The accepted change is limited to non-collision background/depth silhouettes rendered from authored `background` rectangles. It does not change map topology, terrain tiles, collision generation, route design, camera tests, player movement, salvage, hazards, oxygen, boat entry, relay/base extraction behavior, or default preview selection.

## Reviewed Artifacts

- Focused capture: `visual_captures/background_depth/production_slice_01_background_depth.png`
- Asset review: `references/asset_reviews/background_rocks_02_review.png`
- Slice 01 review: `references/asset_reviews/production_slice_01_visual_baseline_review.png`
- Slice 02 review: `references/asset_reviews/production_slice_02_visual_baseline_review.png`
- Slice 03 review: `references/asset_reviews/production_slice_03_visual_baseline_review.png`
- Slice 04 review: `references/asset_reviews/production_slice_04_visual_baseline_review.png`

## Rationale

The comparison sheets showed the expected differences: the distant background silhouettes changed from the v1 placeholder to the v2 cave-depth variant, while foreground terrain, approved props, player, boat, relay/base visuals, UI, camera framing, and authored map placement remained stable.

The v2 asset is still intentionally low contrast so it supports underwater depth without competing with collision terrain.

## Accepted Baselines

The following accepted-baseline directories were refreshed from the current captures:

- `visual_baselines/production_slice_01_accepted/`
- `visual_baselines/production_slice_02_accepted/`
- `visual_baselines/production_slice_03_accepted/`
- `visual_baselines/production_slice_04_accepted/`

## Verification

Completed for this decision:

```bash
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_slice_01 accept
python tools/manage_production_slice_baseline.py --slice production_slice_02 accept
python tools/manage_production_slice_baseline.py --slice production_slice_03 accept
python tools/manage_production_slice_baseline.py --slice production_slice_04 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/check_production_slice_captures.py --fail-on-stale
python tools/check_asset_manifest.py
git diff --check
```

## Follow-Up

Verify the public Web preview under #92 after this acceptance commit deploys. If the browser preview reports missing texture/resource warnings or stale build metadata, fix that as a web-preview issue rather than changing the accepted baseline here.
