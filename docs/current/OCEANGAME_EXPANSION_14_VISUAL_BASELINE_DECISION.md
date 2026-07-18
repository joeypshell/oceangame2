# OceanGame Expansion 14 Visual Baseline Decision

Date: 2026-07-18

Issue: #1038 `Review and accept intentional Expansion 14 visual baseline changes`

## Decision

**Accepted** the intentional Expansion 14 changes in the existing
`production_level_01` baseline. The accepted source capture is exact commit
`00980855b4dfb3defd79b488592ee610f189f667`, after the contract, source,
runtime, HUD, smoke, and focused-capture issues merged.

All 14 configured full-level images were affected by the bounded held-cargo
strip, so the complete configured set is the minimum coherent acceptance.
No production-slice baseline changed. The 16 focused Expansion 14 captures,
their generated `.import` sidecars, and temporary contact sheets remain local
review evidence and were not accepted.

## Intentional Differences

Every configured desktop/mobile view gains the compact held-cargo strip above
the separate active-tool panel. Before acceptance, the 12 boat, opening,
lower-left, lower-right, and return frames differed only in the top UI region:
no changed pixel appeared below row 180 on desktop or row 135 on mobile.

The overview and upper-left pairs also show the source-authored advanced
current, Northwest Wreck Relay pocket, relay core, and associated payoff cues.
Outside the top UI, the overview changed by 15,784 desktop pixels and 51 mobile
pixels; the upper-left view changed by 3,905 desktop pixels and 1,136 mobile
pixels. The review-only build text also advanced with the source commit.

Focused desktop and landscape-mobile evidence shows the blocked current,
stabilizer project promise, enabled crossing, relay arrival, mixed full cargo,
50% relay survey, pending boat return, and archive result. The scanner cone,
selected tool, cargo contents, result/status text, and mobile touch controls
remain readable without overlap.

## Stable Areas

Terrain topology and collision-facing edges, player, boat, existing landmarks,
camera framing, lower-left and lower-right world presentation, and established
route silhouettes remained stable. No runtime, map source, topology, camera,
or asset changed during this review.

The accepted slice-01 through slice-04 baselines and their comparison sheets
remain unchanged. Post-accept comparison panels are black for every configured
full-level and slice view. No bounded visual follow-up is required from this
review.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-09-full-level
python tools/check_camera_captures.py maps/production_level_01.greybox.json visual_captures/expansion_09_full_level --camera-id-prefix production_level_ --suffix 1280x720 --suffix mobile_844x390 --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_level_01 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Two consecutive full-level capture runs produced identical SHA-256 hashes for
all 14 PNGs. Exact-SHA public Web verification remains scoped to #1039.
