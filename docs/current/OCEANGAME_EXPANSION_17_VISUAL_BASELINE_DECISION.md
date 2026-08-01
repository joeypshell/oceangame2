# OceanGame Expansion 17 Visual Baseline Decision

Date: 2026-08-01

Issue: #1165 `Review and accept Expansion 17 visual differences`

Runtime source: `8d66c41b80977ed5f06a045d27dfbe60255ceafe`

## Decision

**Accepted** the current 14-image `production_level_01` baseline as one
coherent desktop/mobile set after bounded presentation correction #1175.

The accepted world difference is limited to the two source-authored wreck
relay presentations in existing Western Chasm and Abyssal Shelf water. The 18
focused Expansion 17 captures remain ignored local review evidence and were
not promoted into `visual_baselines/`.

No production-slice 01-04 baseline changed.

## Intentional Differences

- The full-level overview now includes the small western and abyssal relay
  artifact/backdrop signals.
- The lower-left context includes the Western Chasm Relay landmark, current
  seam presentation, and physical scanner artifact.
- The lower-right context includes the Abyssal Shelf Relay landmark, pressure
  seam presentation, and physical scanner artifact.
- Capture build metadata now identifies the accepted runtime source.

These additions reuse existing continuous geography. Terrain topology,
collision-facing edges, route connectivity, and camera definitions do not
change.

## Focused Review

The paired 1280x720 and 844x390 focused captures show:

- both night investigation leads and alternate abyssal pinning
- recognizable western and abyssal approach context
- held Scanner cone, target card, and 50% progress at each artifact
- one-fragment boat feedback naming the remaining relay
- two-fragment explicit `Q/USE` night analysis readiness
- one committed triangulation result and transfer-hub destination promise

Initial review found the final result copy twice. #1175 / PR #1176 corrected
the debrief feedback ownership boundary before acceptance; the final desktop
and mobile frames now show each result line exactly once.

The advanced mobile status surface remains dense and close to adjacent HUD
bounds, but review found no visible text, command, movement control, scanner
card, cargo, gear, or tool occlusion. This is a future HUD-simplification
observation, not an accepted overlap regression or an Expansion 17 blocker.

## Stable Areas

Before acceptance, all four production-slice difference columns were black.
Full-level changes outside the two relay presentation regions and current
capture metadata were black: player, boat, terrain, existing props, camera
framing, active-tool hotbar, passive-equipment strip, and unrelated routes
remained stable.

After acceptance, every configured full-level and production-slice difference
column is black. Accepted baseline directories contain no `.import` sidecars
or unexpected generated files.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 900 --capture-expansion-17-wreck-network
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 1200 --capture-expansion-09-full-level
python tools/check_camera_captures.py maps/production_level_01.greybox.json visual_captures/expansion_09_full_level --camera-id-prefix production_level_ --suffix 1280x720 --suffix mobile_844x390 --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_level_01 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact-SHA public Web verification remains scoped to #1166.
