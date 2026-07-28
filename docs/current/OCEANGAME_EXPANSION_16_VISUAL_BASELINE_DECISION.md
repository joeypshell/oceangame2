# OceanGame Expansion 16 Visual Baseline Decision

Date: 2026-07-28

Issue: #1131 `Review and accept intentional Expansion 16 visual differences`

Runtime source: `edc4f71abb9226d5d601a0f32573efb5a4936727`

## Decision

**Accepted** the current 14-image `production_level_01` baseline as one
coherent desktop/mobile set.

The accepted world difference is the source-authored far-west confined-wreck
destination added for Expansion 16. The focused warning, protected, cutter,
and scanner pairs remain ignored local evidence and were not promoted into
`visual_baselines/`.

No production-slice 01-04 baseline changed.

## Intentional Expansion 16 Differences

The overview and lower-left full-level contexts now include the far-west wreck
backdrop, landmark, recorder, and survey presentation. These additions occupy
existing open geography; terrain topology, collision-facing edges, and camera
definitions do not change.

The focused evidence shows:

- unprotected `Confined wreck air | Oxygen x8` warning
- protected `Rebreather active` feedback at the same threshold
- selected Cutter with 50% recorder progress
- held Scanner with 50% artifact progress and contextual card
- readable status, cargo/equipment, tool, and touch-control surfaces at
  1280x720 and the 844x390 landscape-mobile review size

The scanner card is framed clear of the fixed status panel. Mobile controls do
not cover status, cargo/equipment, active-tool, or scanner content.

## Prior HUD Reconciliation

The preceding full-level baseline predated two separately approved,
source-backed HUD changes:

- #1063 / PR #1064 moved active tools from the top `No tool` text panel to the
  bottom icon hotbar.
- #1074 / PR #1082 added the read-only `EQUIPPED` segment to the top cargo
  strip.

Both changes had focused desktop/mobile review and deterministic layout
coverage but explicitly deferred baseline acceptance. They are identified
here rather than being misattributed to Expansion 16. No unexplained HUD drift
was accepted.

## Stable Areas

Before acceptance, all four production-slice review sheets had black
difference columns. Full-level differences outside the attributed HUD surfaces
and far-west source presentation were black: player, boat, terrain,
collision-facing edges, camera framing, existing landmarks, and unrelated
props remained unchanged.

After acceptance, every configured full-level and production-slice difference
panel is black. Accepted baseline directories contain no `.import` sidecars or
unexpected generated files.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-16-deeper-wreck
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-09-full-level
python tools/check_camera_captures.py maps/production_level_01.greybox.json visual_captures/expansion_09_full_level --camera-id-prefix production_level_ --suffix 1280x720 --suffix mobile_844x390 --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_level_01 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact-SHA public Web verification remains scoped to #1132.
