# OceanGame Expansion 07 Visual Baseline Decision

Date: 2026-07-10

Issue: #797 `Review Expansion 07 biological progression visual impact`

## Decision

**GO** for the focused Biological Resources And Weapon Progression presentation. Do not replace any accepted production-slice baseline in this issue.

The `--capture-expansion-07-biological-progression` command rendered and verified three states at both 1280x720 and 1920x1080:

- 50% nonlethal glow-anemone sample
- 50% explicit post-defeat eel harvest
- capacitor interruption with the eel in recovery

The six PNGs under `visual_captures/expansion_07_biological_progression/` were local review evidence and remain uncommitted. No baseline `accept` command ran.

## Approved Differences

- The glow anemone, diver, source aura, and current-pocket geography remain distinguishable at both viewports. `Sampling glow anemone 0.8/1.5s` makes the nonlethal timed action explicit.
- The defeated-eel frame keeps the remains, available harvest marker, diver, and territory context visible together. `Harvesting electrocyte 0.8/1.5s` communicates that defeat alone did not grant the component.
- The upgraded frame shows the surviving eel and diver in the same remembered territory. `Shock prod +capacitor 0.7s` and `Lunge interrupted - eel health 2/3` expose cooldown, tactical effect, and unchanged one-damage health result without a new panel.
- The existing overlay hierarchy contains all feedback without clipping, overlap, or unreadable wrapping at either viewport.
- The right-weighted framing is appropriate to the authored current-pocket and deep-cache locations at the map boundary; subjects and affordances remain fully visible.

No blank region, terrain artifact, source-marker ambiguity, or focused presentation defect blocks Expansion 07.

## Baseline Result

`compare-all` rendered the four standard production-slice review sheets. All 21 configured difference panels were black: current captures match accepted baselines for slices 01 through 04.

Expansion 07 therefore requires no standard baseline change. Accepted directories remained clean, and generated review sheets, focused captures, and `.import` sidecars are not part of this commit.

## Stable Areas

- terrain topology, collision, tiles, and camera-test definitions
- diver, boat, standard salvage, mineral, survey, hazard, eel, and route-cue presentation outside the focused states
- standard HUD framing and existing production-slice captures
- all accepted production-slice baselines

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 40 --capture-expansion-07-biological-progression
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact-SHA public Web verification remains scoped to #798. Player-experience GO/HOLD remains scoped to #799.
