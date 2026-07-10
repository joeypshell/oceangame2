# OceanGame Expansion 06 Visual Baseline Decision

Date: 2026-07-10

Issue: #776 `Review Expansion 06 combat visual impact`

## Decision

**GO** for the focused Combat Foundation presentation. Do not replace any accepted production-slice baseline in this issue.

The `--capture-expansion-06-combat-foundation` command rendered and verified three states at both 1280x720 and 1920x1080:

- locked, unarmed territory warning
- unarmed lunge with retreat/evade context
- armed hit with the eel at 1/3 health

The six PNGs under `visual_captures/expansion_06_combat_foundation/` were local review evidence and remain uncommitted. No baseline `accept` command ran.

## Approved Differences

- The thin territory ring reads as an encounter boundary without hiding the lower-edge evade lane or existing route landmarks.
- The eel silhouette, warning direction, diver, and territory marker remain distinct at both viewports.
- `Territorial eel - watch the lunge` establishes the warning; `Eel territory - retreat or evade` keeps noncombat passage explicit during the lunge.
- `Health 3/3` and `Oxygen 90s` occupy separate overlay lines, so combat damage and expedition pressure are not conflated.
- `Shock prod locked` communicates the unarmed state. The armed frame shows cooldown state plus `Shock prod hit - eel health 1/3`, making damage and the not-yet-defeated enemy state explicit.
- The armed hit uses the same room framing as the unarmed states, so the weapon changes the response to a remembered place rather than replacing exploration context.

No overlap, clipping, blank render region, or focused visual defect blocks Expansion 06. Enemy defeat and day-local restoration remain deterministic runtime/smoke outcomes; the approved focused visual contract uses the armed-damage frame allowed by #775 rather than a separate victory frame.

## Baseline Result

The six standard slice-01 camera views were regenerated locally and `compare-all` rendered all four production-slice review sheets. Only the slice-01 sheet changed.

Its lower-loop view includes the intentional hostile territory and eel. The sheet also contains accumulated differences from earlier daylight, HUD, material/research, visibility, current-gate, route-cue, and prop work. Accepting that combined sheet as an Expansion 06 baseline would exceed #776 and blur ownership of older changes.

The tracked standard captures and slice-01 review sheet were restored after inspection. Accepted baseline directories for slices 01 through 04 stayed unchanged and clean.

## Stable Areas

- terrain topology, collision, tile seams, and camera-test definitions
- diver, boat, sealed wreck, salvage, material, research, and current-gate presentation outside the focused encounter
- existing jellyfish hazard and lower-edge evade geography
- route framing outside the authored deep-cache territory
- production-slice 02, 03, and 04 captures and comparison sheets
- all accepted production-slice baselines

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 40 --capture-expansion-06-combat-foundation
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 60 --capture-production-slice-map
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Public Web verification and the Expansion 06 player-experience closeout remain scoped to #777.
