# OceanGame Expansion 18 Visual Baseline Decision

Date: 2026-08-02

Issue: #1199 `Review and accept Expansion 18 visual differences`

Reviewed runtime: `7cd4054f43466d7156a9368cdbf64135a5994cbe`

## Decision

**Accept the named Transfer Hub visual differences.**

The existing `production_level_01` baseline now includes only the authored
lower-chamber bulkhead, exceptional-interior entrance marker, and paired return
entry. A new `transfer_hub_interior_01_accepted` baseline owns six desktop and
iPhone-landscape interior states.

No production-slice baseline changed. Focused exterior entrance, return, and
boat-result captures remain ignored local evidence rather than accepted
baseline files.

## Accepted Exterior Difference

Only these existing full-level views changed:

- overview at desktop and mobile sizes
- lower-left context at desktop and mobile sizes
- lower-right context at desktop and mobile sizes

Their difference panels contain the source-authored Expansion 18 records in
the existing lower chamber: `transfer_hub_exterior_bulkhead`,
`transfer_hub_exterior_entrance`, and `transfer_hub_exterior_return`.
Expansion 18 provenance records `terrain_changes: []`; terrain topology,
collision-facing edges, and prior camera definitions remain unchanged.

The boat-entry, opening-gameplay, upper-left, and return-to-boat desktop/mobile
views stayed pixel-identical after temporary build-label normalization. The
normal build metadata file was restored after comparison.

## Accepted Interior Baseline

The new baseline contains desktop `1280x720` and landscape-mobile `844x390`
pairs for:

- west-doorway interior arrival
- full-cargo navigation-core block
- recovered navigation core

The compact room has a distinct bulkhead backdrop, one central terrain mass,
one readable east-side Cutter cradle/core target, and one physical west return.
The mobile core framing keeps the diver and core left of ACT/USE controls while
retaining the existing right command rail. No map source is mutated by capture
setup.

The wider ignored focused set also confirms locked/ready exterior entry,
paired exterior return, and canonical-boat delivery feedback.

## Source And Collision Review

- `production_level_01`: 14,898 terrain cells and 376 runtime collision
  rectangles match source.
- `transfer_hub_interior_01`: 522 terrain cells and 11 runtime collision
  rectangles match source.
- Both maps pass source reachability from their authored entries.
- The Expansion 18 pair test proves player-footprint routes from the exterior
  boat to the entrance and from interior arrival to the core and return.
- The full-level traversal audit still reports all three regional round trips
  footprint-clear and within the review oxygen/daylight budget.

The committed source/render/collision sheets are:

- `references/greybox/production_level_01_source_render_collision_review.png`
- `references/greybox/transfer_hub_interior_01_source_render_collision_review.png`

## Stable Areas

No unexplained difference was accepted in player, boat, terrain, existing
props, prior routes, camera framing, cargo/gear/tool presentation, or slices
01-04. After acceptance, every configured difference panel is black.

The ready-entrance focused frame still has a dense status panel touching the
leading edge of the cargo strip. The route prompt, held count, gear icons, and
desktop/mobile controls remain readable, so this is not a baseline blocker.
Keep it as bounded HUD follow-up evidence rather than expanding Expansion 18
into a broad interface replacement.

Accepted baseline directories contain no `.import`, OS sidecar, or unexpected
files.

## Verification

```powershell
python tools/validate_greybox_map.py maps/production_level_01.greybox.json
python tools/validate_greybox_map.py maps/transfer_hub_interior_01.greybox.json
python tools/validate_full_level_traversal.py maps/production_level_01.greybox.json
python tools/test_production_level_01_expansion_18.py
python tools/check_map_parity.py maps/production_level_01.greybox.json maps/transfer_hub_interior_01.greybox.json
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-18-transfer-hub
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-09-full-level
python tools/check_camera_captures.py maps/production_level_01.greybox.json visual_captures/expansion_09_full_level --camera-id-prefix production_level_ --suffix 1280x720 --suffix mobile_844x390 --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact-SHA public Web verification remains scoped to #1200.
