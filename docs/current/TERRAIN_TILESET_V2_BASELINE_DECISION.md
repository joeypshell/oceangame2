# Terrain Tileset V2 Baseline Decision

Date: 2026-07-06

Issue: #96 `Decide terrain tileset v2 baseline acceptance`

Decision: accept the Controlled Visual Revision 05 terrain tileset v2 pass for the current prototype baseline.

## Accepted Scope

Accepted asset:

- `assets/terrain_tiles/cave_tileset_v2.png`

Supporting source and review files:

- `tools/generate_cave_tileset_v2.py`
- `assets/terrain_tiles/cave_tileset_v2_manifest.json`
- `references/asset_reviews/cave_tileset_v2_review.png`
- `references/asset_reviews/cave_tileset_v2_coverage_review.png`

Accepted visual baselines were refreshed for:

- `visual_baselines/production_slice_01_accepted/`
- `visual_baselines/production_slice_02_accepted/`
- `visual_baselines/production_slice_03_accepted/`
- `visual_baselines/production_slice_04_accepted/`

## Review Result

The comparison sheets showed expected terrain-only differences:

- cave interiors changed from the v1 square scratch pattern to the v2 layered rock texture
- exposed top/floor rims remained readable
- side, corner, inner-corner, and isolated terrain silhouettes stayed aligned to the same atlas coordinates
- water, background depth, player, props, boat, relay/base visuals, UI, salvage/hazard positions, and camera framing did not intentionally change

Known slice-03 topology/camera follow-ups remain separate. This decision does not resolve or alter #52 or #53.

## Source-Of-Truth Check

No map source, collision generation, route design, player movement, prop logic, boat/extraction logic, or default preview selection was changed for this decision. The accepted baseline update records the approved visual result from the already-implemented v2 terrain atlas pass.

## Verification

Commands run before acceptance:

```bash
python tools/manage_production_slice_baseline.py compare-all
python tools/check_map_parity.py
python tools/check_asset_manifest.py
python tools/check_production_slice_captures.py --fail-on-stale
```

Baseline acceptance commands:

```bash
python tools/manage_production_slice_baseline.py accept
python tools/manage_production_slice_baseline.py --slice production_slice_02 accept
python tools/manage_production_slice_baseline.py --slice production_slice_03 accept
python tools/manage_production_slice_baseline.py --slice production_slice_04 accept
python tools/manage_production_slice_baseline.py compare-all
```

After acceptance, `compare-all` regenerated comparison sheets against the accepted v2 captures.
