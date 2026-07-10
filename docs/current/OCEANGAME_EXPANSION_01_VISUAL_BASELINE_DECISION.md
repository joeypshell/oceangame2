# OceanGame Expansion 01 Visual Baseline Decision

Date: 2026-07-09

Issue: #670 `Add focused anomaly survey captures and visual baseline decision`

## Decision

Do not replace any accepted production-slice baseline for Expansion 01.

Accept the new anomaly marker, active survey state, `Survey anomaly 50%` feedback, committed discovery text, and next-lead text only as intentional changes in the dedicated review captures:

- `visual_captures/anomaly_survey/production_slice_02_anomaly_survey_progress.png`
- `visual_captures/anomaly_survey/production_slice_01_anomaly_discovery_commit.png`

The focused pair is review evidence, not a new production-slice baseline. No baseline `accept` command ran.

## Review Evidence

The survey frame uses the source-authored `lower_right_anomaly_survey` target, shows the active marker beside the diver, and freezes deterministic 50% progress while oxygen remains visible. The commit frame shows the canonical slice-01 surface boat, diver, `Discovery logged: Lower-right anomaly`, `Next lead: investigate territorial signal`, and the exact commit note.

All production-slice comparison sheets were rendered after restoring the reviewed current capture sets. Every difference panel is black:

- `production_slice_01`: no accepted/current difference.
- `production_slice_02`: no accepted/current difference.
- `production_slice_03`: no accepted/current difference.
- `production_slice_04`: no accepted/current difference.

## Rejected Drift

A review-only regeneration of the affected slice-02 and slice-04 camera sets exposed unrelated expanded HUD text and local black terrain failures. Those captures were rejected and were not retained or accepted. They do not represent intentional Expansion 01 changes.

The following remain stable in accepted production views:

- terrain, collision, camera framing, and background depth
- diver, boat, relay, salvage, hazard, chest, and other prop presentation
- existing production-slice HUD and camera-test images
- all accepted baseline directories

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-anomaly-survey
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

The focused captures were visually inspected at their original 1280x720 resolution. Web deployment verification remains scoped to #671.
