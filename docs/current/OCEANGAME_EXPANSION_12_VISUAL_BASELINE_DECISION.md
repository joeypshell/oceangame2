# OceanGame Expansion 12 Visual Baseline Decision

Date: 2026-07-15

Issue: #939 `Review and accept the Expansion 12 visual baseline`

## Decision

**Accepted** the intentional Expansion 12 changes in the existing
`production_level_01` baseline. The accepted source capture is exact commit
`b6999d6b83adf33f5298569ded68b65041446283`, after the source, runtime,
integrated journey, and focused capture issues merged.

No production-slice baseline changed. No `.import` sidecar or ignored focused
capture was accepted.

## Intentional Differences

The overview and lower-left/lower-right contexts now show the source-authored
abyssal landmark backdrop and harmonic marker in the existing lower-central
basin. The change is visible at desktop and mobile review sizes without new
terrain, collision, or camera geometry.

The remaining wide frames contain only small edge-of-frame differences from
the same newly authored deep markers. A repeated full-level capture produced
identical SHA-256 hashes for all 14 configured files before acceptance.

Focused evidence under ignored
`visual_captures/expansion_12_abyssal_pressure/` was inspected at both sizes.
It shows the pre-suit retreat warning, exact Ti1/2 + Rubber1/1 + Gel1/1 night
recipe, protected crossing feedback, 50% abyssal survey progress, and the
completed finding still pending on the boat approach.

## Stable Areas

Terrain topology and silhouette, collision-facing terrain edges, the boat,
diver, unrelated props, existing lighting, camera framing, mobile framing, and
non-contextual HUD content remained stable. The pressure zone changes oxygen
and contextual feedback only; it does not alter terrain or player position.

The accepted slice-01 through slice-04 baselines and their comparison sheets
remain unchanged. No map source, runtime, asset, topology, camera definition,
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
public Web verification remains scoped to #940.
