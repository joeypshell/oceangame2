# OceanGame Expansion 03 Visual Baseline Decision

Date: 2026-07-10

Issue: #714 `Capture and review Expansion 03 material project visual impact`

## Decision

Do not replace any accepted production-slice baseline for Expansion 03.

Approve the material/project feedback as intentional presentation in the focused `--capture-expansion-03-material-project` review states:

- held titanium with return-to-boat guidance
- sealed wreck locked behind the salvage cutter
- night debrief with the ready cutter project choice
- sealed wreck cutting at 50% progress

Each state was rendered and inspected at 1280x720 and 1920x1080. The generated PNGs under `visual_captures/expansion_03_material_project/` are local review evidence and remain uncommitted. No baseline `accept` command ran.

## Intentional Differences

- The active HUD reports typed material totals and held material deltas.
- Held material gives one compact return-to-boat instruction.
- The locked sealed wreck reports `Cutter required` while retaining its valuable-target marker.
- The night debrief exposes the `P: Build salvage cutter` project action when its recipe is affordable.
- Active cutting reports the sealed-wreck action and a bounded progress bar.

At both viewports, text remains inside its panel and does not obscure the reviewed target. The diver overlaps the wreck marker slightly at interaction range, but the crate, valuable marker, interaction ring, and diver silhouette remain distinct.

## Stable Areas

`compare-all` regenerated the four review sheets without tracked differences, and `check-clean --all-slices` reports every accepted baseline directory clean:

- `production_slice_01`: clean
- `production_slice_02`: clean
- `production_slice_03`: clean
- `production_slice_04`: clean

Terrain topology and tile seams, collision, water/background depth, diver, boat, existing props and hazards, camera framing, and accepted production-slice baselines remain unchanged. The capture command does not mutate map source or accept baselines.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 30 --capture-expansion-03-material-project
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Public Web verification and the Expansion 03 player-experience closeout remain scoped to #715.
