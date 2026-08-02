# OceanGame Expansion 17 Visual Baseline Decision

Date: 2026-08-02

Issue: #1184 `Verify Expansion 17 owner-HOLD clarity corrections`

Reviewed runtime: `075a450d8751fae73ba796a6fdb001a9ce4e5281`

## Decision

**Retain the accepted production baselines without replacement.**

The regenerated 14-image `production_level_01` set is pixel-identical to the
accepted baseline. Production slices 01-04 also remain unchanged and clean.
No baseline acceptance command was run.

The corrected 16-image focused Expansion 17 set remains ignored local review
evidence. It replaces the obsolete separate analysis-readiness frames with one
automatic night-result state.

## Corrected Focused States

Desktop and iPhone-landscape review confirmed:

- the far-west recorder explains that transfer-hub coordinates were split
  across two wreck transponders
- the Western Coordinate Transponder uses a current-scoured elongated
  silhouette and stores the west coordinate half
- the Abyssal Coordinate Transponder uses a pressure-crushed reinforced
  silhouette and stores the east coordinate half
- both artifacts show held `Space/USE` scanner acquisition and 50% progress
- one-fragment night feedback reports `Coordinate half secured 1/2` and names
  the remaining transponder
- returning both halves produces `Transfer hub coordinates recovered` and the
  destination promise automatically at night
- no `Q`, `Space`, or mobile `USE` triangulation command remains

The local capture metadata was refreshed to `Build 075a450` before final
inspection. Focused captures are not accepted baselines.

## Stable Areas

No difference was found in terrain, collision-facing edges, camera framing,
player, boat, routes, normal cargo/gear/tool HUD, or retained slice fixtures.
Accepted baseline directories contain no generated sidecars or unexpected
files.

## Verification

```powershell
python tools/write_build_info.py --sha 075a450d8751fae73ba796a6fdb001a9ce4e5281 --ref main
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 900 --capture-expansion-17-wreck-network
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 1200 --capture-expansion-09-full-level
python tools/check_camera_captures.py maps/production_level_01.greybox.json visual_captures/expansion_09_full_level --camera-id-prefix production_level_ --suffix 1280x720 --suffix mobile_844x390 --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
```
