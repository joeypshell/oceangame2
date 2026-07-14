# OceanGame Expansion 10 Visual Baseline Decision

Date: 2026-07-13

Issue: #887 `Review and accept intentional Expansion 10 visual baseline changes`

## Decision

**Accepted** the intentional Expansion 10 changes in the existing
`production_level_01` baseline. The accepted source capture is commit
`4a85c93`, which contains the focused journey-capture work after the regional
route, landmark, scanner payoff, runtime feedback, and smoke issues merged.

No production-slice baseline changed. No `.import` sidecar was accepted.

## Intentional Differences

Eight of the 14 configured full-level views changed at desktop and mobile sizes:

- overview: regional current affordances and the Signal Reef survey landmark
- lower-right: the Signal Reef background silhouette, survey target, and
  regional current affordances
- lower-left: the edge of the new regional affordances enters the wide frame
- upper-left: a small edge of the regional addition enters the wide frame

The differences are localized source-authorized route and destination feedback.
They do not alter the terrain silhouette or camera framing.

Focused evidence under `visual_captures/expansion_10_regional_journey/` also
shows the pre-fins current promise, post-fins regional entry, and pending-return
Signal Reef state at desktop and mobile sizes.

## Stable Areas

The following configured full-level views remained byte-identical:

- boat entry, desktop and mobile
- opening gameplay, desktop and mobile
- return to boat, desktop and mobile

Terrain topology, boat, diver, HUD, sprites, and camera framing remained stable
across the reviewed comparison sheet. All accepted slice-01 through slice-04
baselines remained clean and unchanged.

## Verification

```powershell
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py --slice production_level_01 accept
python tools/manage_production_slice_baseline.py --slice production_level_01 compare
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

The post-accept comparison sheet reports black difference panels for all 14
configured full-level views. Exact-SHA public Web verification remains scoped to
#888.
