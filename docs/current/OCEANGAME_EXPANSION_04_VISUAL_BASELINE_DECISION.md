# OceanGame Expansion 04 Visual Baseline Decision

Date: 2026-07-10

Issue: #734 `Capture and review Expansion 04 current-pocket visual impact`

## Decision

Approve the focused Expansion 04 current-pocket presentation, but do not replace any accepted production-slice baseline in this issue.

The `--capture-expansion-04-current-pocket` command rendered and verified five states at both 1280x720 and 1920x1080:

- locked current with the valuable payoff still visible
- stabilizer-ready night debrief
- unlocked crossing beyond the current boundary
- valuable payoff held in cargo
- payoff banked at the boat

The ten generated PNGs under `visual_captures/expansion_04_current_pocket/` are local review evidence and remain uncommitted. No baseline `accept` command ran.

## Approved Differences

- Two restrained boundary lines and three left-pointing flow arrows make the source-authored current direction readable.
- `Ripping current - need current stabilizer` stays inside the compact status panel.
- The payoff marker remains visible beyond the locked gate and is distinct from the diver and nearby sealed-wreck marker.
- The unlocked frame places the diver beyond the boundary while retaining the same terrain edge, arrows, and payoff context.
- Held feedback reports `Upper-right current pocket +300`; the boat frame reports one banked salvage and score 300.
- The night panel shows `P: Build current stabilizer` and `N: Start day 2` without overlap.

All reviewed text fits at both viewports. A first local held-payoff render exposed black camera-resize artifacts; forcing the focused camera to update after each viewport resize removed them in both regenerated frames.

## Baseline Result

The six standard slice-01 camera views were regenerated locally and compared against the accepted baseline. The review sheet contained the intended current-pocket additions plus accumulated non-#734 differences from earlier day-loop HUD, material/discovery, and visibility work.

Accepting that combined sheet as an Expansion 04 baseline would exceed this issue's scope. The tracked standard captures and generated review sheet were restored after inspection, while all accepted baseline directories stayed unchanged and clean.

## Stable Areas

- terrain topology, collision, and tile seams
- camera-test definitions and framing
- diver, boat, sealed wreck, existing props, and hazards
- water/background composition outside established visibility presentation
- legacy lower-left current presentation
- accepted production-slice baselines for slices 01 through 04

No focused visual defect blocks Expansion 04. Any future consolidation of the older slice-01 accepted baseline must be a separate, explicitly scoped review of the accumulated differences.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 60 --capture-expansion-04-current-pocket
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 60 --capture-production-slice-map
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Public Web verification and the Expansion 04 player-experience closeout remain scoped to #735.
