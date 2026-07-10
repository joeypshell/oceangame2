# OceanGame Expansion 05 Visual Baseline Decision

Date: 2026-07-10

Issue: #756 `Review Expansion 05 practical-research visual impact`

## Decision

Approve the focused Expansion 05 practical-research presentation, but do not replace any accepted production-slice baseline in this issue.

The `--capture-expansion-05-practical-research` command rendered and verified four states at both 1280x720 and 1920x1080:

- incomplete mineral clue beyond the upper-right current gate
- mineral survey at 50% progress
- source-derived research finding committed at the surface boat
- following-day deep-cache coil habitat lead

The eight PNGs under `visual_captures/expansion_05_practical_research/` were local review evidence and remain uncommitted. No baseline `accept` command ran.

## Approved Differences

- The resource survey reuses the existing eye/ring marker grammar, with a yellow active ring during the partial scan.
- `Mineral trace | Composition unknown` communicates incomplete information without revealing a coordinate or exact route.
- `Survey mineral trace 50%` is readable beside oxygen and daylight pressure at both viewports.
- The pocket framing keeps the existing stabilizer boundary arrows, target marker, diver, and nearby valuable salvage distinct.
- The boat frame shows `Research: coils favor deep-cache machinery` and the exact commit note without overlap.
- The following-day frame pairs the deep-cache machinery prop and coil candidate with `Research lead | Coils near deep-cache machinery`.
- The durable finding remains visible above the following-day lead. This is the densest reviewed HUD state, but both lines fit and the repetition preserves finding-to-plan continuity.

No focused visual defect blocks Expansion 05. If later HUD work introduces a durable research log, it may shorten the repeated finding line, but this pass does not need a corrective issue.

## Baseline Result

The six standard slice-01 camera views were regenerated locally and `compare-all` rendered all four production-slice review sheets. Only the slice-01 sheet changed.

That sheet contains the intentional resource survey marker plus accumulated differences from earlier daylight, material/discovery, visibility, current-gate, HUD, and prop work. Accepting the combined sheet as an Expansion 05 baseline would exceed #756's scope and obscure which pass owns those older differences.

The tracked standard captures and slice-01 review sheet were restored after inspection. Accepted baseline directories for slices 01 through 04 stayed unchanged and clean.

## Stable Areas

- terrain topology, collision, and tile seams
- camera-test definitions and framing
- diver, boat, sealed wreck, existing salvage, hazards, and current boundary presentation
- water/background composition outside established visibility treatment
- production-slice 02, 03, and 04 current captures and comparison sheets
- all accepted production-slice baselines

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 30 --capture-expansion-05-practical-research
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 60 --capture-production-slice-map
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Public Web verification and the Expansion 05 player-experience closeout remain scoped to #757.
