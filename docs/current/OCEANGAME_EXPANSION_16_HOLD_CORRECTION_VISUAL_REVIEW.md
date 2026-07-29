# Expansion 16 Owner-HOLD Correction Visual Review

Date: 2026-07-28

Issue: #1145

Runtime source: `4902b8e1218b1a50d107154548664a6d833bc28b`

Status: Focused visual review and integrated release validation PASS.

## Decision

Accepted the corrected 14-image `production_level_01` baseline as one
coherent desktop/mobile set. The accepted differences are limited to the
source-authored far-west route/threshold guidance from #1143 and the bounded
passive-gear presentation from #1144.

No production-slice 01-04 baseline changed. Focused Expansion 16 captures
remain review evidence and were not promoted into `visual_baselines/`.

## Intentional Differences

- Four cyan relay beacons and one amber oxygen-pressure threshold make the
  existing far-west wreck route readable without changing terrain.
- The status surface names the broad destination and, at the threshold, shows
  either `Confined wreck air | Oxygen x8` or `Rebreather active`.
- Desktop replaces the fixed `EQUIPPED` row with a fixed five-cell `GEAR`
  surface. Contextually active gear moves first and additional owned gear uses
  one `+N` overflow cell.
- The closed-circuit rebreather has a named icon and visible active treatment
  while it normalizes the confined-wreck oxygen zone.
- Landscape mobile uses one compact active-gear summary instead of squeezing
  the desktop row into the top band.

Scanner, Cutter, and Shock Prod remain in the bottom active-tool hotbar. Cargo
counts, capacity, and banking presentation do not change.

## Focused Evidence

`visual_captures/expansion_16_deeper_wreck/` shows route guidance,
pre-rebreather warning, protected rebreather state, recorder cutting, and
recorder scanning at 1280x720 and 844x390. The compact mobile summary remains
above the play field and clear of the bottom hotbar and touch controls.

The focused PNGs remain ignored review output. No `.import` sidecars or
generated cache files were accepted.

## Stable Areas

Before acceptance, full-level differences were confined to the attributed
guidance and HUD regions. Terrain, collision-facing edges, camera framing,
player, boat, active-tool hotbar, existing landmarks, and unrelated props
remained stable.

All four production-slice review sheets were black before acceptance. After
accepting `production_level_01`, all five configured review sheets have black
difference panels. `check-clean --all-slices` confirms every accepted
directory contains only expected baseline files.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-16-deeper-wreck
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-09-full-level
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_level_01 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/run_release_candidate_validation.py --require-godot
python tools/check_file_lengths.py
git diff --check
```

The release-candidate suite passed source/schema validation, progression
audit, map parity, baseline hygiene, Godot import/startup, core runtime smokes,
and every integrated journey through Expansion 16.

## Next Gate

#1146 must verify the exact merged correction SHA in the public Web preview.
#1133 and milestone #42 remain open for owner GO/HOLD. This visual PASS does
not select Expansion 17; #52/#53 remain deferred optional slice-03 polish.
