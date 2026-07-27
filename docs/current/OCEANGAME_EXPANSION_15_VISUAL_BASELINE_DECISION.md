# OceanGame Expansion 15 Visual Baseline Decision

Date: 2026-07-27

Issue: #1102 `Review and accept intentional Expansion 15 visual changes`

Runtime source: `6db42bf2d169616fd24fc5a51205907f5a7c6c57`

## Decision

**Accepted** the intentional Expansion 15 expedition-planning presentation.
The accepted scope is the focused night two-choice surface and the compact
selected-plan guidance shown during the following active day.

No established full-level or production-slice baseline image changed. The six
focused Expansion 15 PNGs and temporary contact sheet remain ignored local
review evidence and were not promoted into `visual_baselines/`.

## Intentional Differences

The focused night state adds one debrief-only planning panel containing:

- the Northwest Wreck Relay and Southwest Jellyfish Bloom choices
- source-derived summaries and readiness text
- distinct highlighted and pinned states
- compact `Tab/TOOL`, `E/ACT`, `P/BUILD`, and `N/DAY` instructions

The planner starts below the cargo/equipment strip and remains separate from
the night summary. Landscape-mobile controls remain visible and reachable
without covering the planner or debrief content.

The selected following-day state hides the full planner and adds only the
compact `Plan: Follow the archive signal northwest` guidance to the existing
status surface. It does not add a quest log, marker, route line, reward, or
second persistent panel.

## Correction Evidence

The first review was held because capture resizing placed the populated night
summary outside its visible panel and the planner overlapped the top cargo
strip. Issue #1113 corrected both defects before this acceptance.

The focused capture now fails automatically when:

- planner and cargo/equipment rectangles intersect
- planner and debrief rectangles intersect
- a mobile command intersects planning or debrief content
- the night summary is empty, outside its panel, or outside the viewport

Both corrected night summaries are visible at 1280x720 and the iPhone-landscape
review size. Choice text, readiness, instructions, highlight, and pin states
fit without clipping.

## Stable Areas

The established `production_level_01` and production-slice 01-04 review sheets
have black difference columns for every configured view. Terrain, collision,
landmarks, player, boat, camera framing, cargo/equipment, active-tool hotbar,
scanner readout, and unrelated HUD remain unchanged.

No runtime rule, map source, topology, asset, profile, project, reward, accepted
baseline, or generated sidecar changed during this review.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-15-expedition-planning
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact-SHA public Web verification remains scoped to #1103.
