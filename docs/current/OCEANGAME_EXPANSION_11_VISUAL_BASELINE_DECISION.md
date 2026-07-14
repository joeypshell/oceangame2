# OceanGame Expansion 11 Visual Baseline Decision

Date: 2026-07-14

Issue: #912 `Review and accept intentional Expansion 11 visual changes`

## Decision

**Accepted** the intentional Expansion 11 changes in the existing
`production_level_01` baseline. The accepted source capture is exact commit
`72ee4ec72993ea1e7664f9b5dcac1e3567b041fc`, after the source, runtime,
integrated journey, and focused capture issues merged.

No production-slice baseline changed. No `.import` sidecar was accepted.

## Intentional Differences

All 14 configured full-level views changed at desktop and mobile sizes because
the obsolete `L: Light +range (900)` score-purchase line was removed from the
status overlay. The overview, lower-right context, and visible wide-frame edge
also include the source-authorized deep-harmonic dark zone and survey target.

Focused evidence under
`visual_captures/expansion_11_deep_harmonic_light/` was inspected at both
supported sizes. It shows the pre-light requirement once, the exact incomplete
light recipe, post-light 50% survey progress without stale requirement text,
and a completed survey still pending the boat return.

## Stable Areas

Terrain topology and silhouette, collision-facing terrain edges, the boat,
diver, current route, Signal Reef landmark, unrelated props and HUD content,
camera framing, and touch controls remained stable across the reviewed views.

The accepted slice-01 through slice-04 baselines and their comparison sheets
remained unchanged. No map source, runtime, asset, topology, camera definition,
or unrelated capture changed during this review.

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

Every configured post-accept full-level difference panel is black. Exact-SHA
public Web verification remains scoped to #913.
