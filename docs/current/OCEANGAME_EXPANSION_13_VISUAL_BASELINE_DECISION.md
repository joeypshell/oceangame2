# OceanGame Expansion 13 Visual Baseline Decision

Date: 2026-07-16

Issue: #967 `Review and accept the Expansion 13 visual baseline`

## Decision

**Accepted** the intentional Expansion 13 changes in the existing
`production_level_01` baseline. The accepted source capture is exact commit
`d6426bfd87d6196d3b11e05444339bb6c7636c8f`, after the source, runtime,
journey-smoke, and focused-capture issues merged.

No production-slice baseline changed. No `.import` sidecar or ignored focused
capture was accepted.

## Intentional Differences

Outside the review header, only the overview and lower-right desktop/mobile
views changed. Those pixels are confined to the source-authored southeast
wreck backdrop, recorder, and archive-survey cues in the existing open chamber.
The repeated outside-header differences were 777/66 pixels in overview and
4,128/1,196 pixels in lower-right desktop/mobile frames.

Every configured view also advances the review-only build line from the prior
accepted run to the last verified Expansion 12 runtime `d864a9e`. Gameplay HUD
content is otherwise unchanged. A repeated full-level capture produced
identical SHA-256 hashes for all 14 configured files before acceptance.

Focused evidence under ignored
`visual_captures/expansion_13_southeast_wreck/` was inspected at both sizes. It
shows the broad wreck promise, arrival with cutter requirement, 50% recorder
cut, 50% explicit scanner survey, and pending canonical-boat return.

## Stable Areas

Terrain topology and silhouette, collision-facing edges, the boat, diver,
pressure landmark, existing props, camera geometry, non-contextual gameplay
HUD, and unrelated lighting remained stable. The full-level source adds no
terrain or collision records.

The accepted slice-01 through slice-04 baselines and comparison sheets remain
unchanged. No map source, runtime, asset, camera definition, or unrelated
capture changed during this review.

## Verification

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --capture-expansion-09-full-level
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_level_01 accept
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Every configured post-accept difference panel is black. Exact-SHA public Web
verification remains scoped to #968.
