# Living Expedition 07 Visual Decision

Date: 2026-09-20

Issue: #1396

Status: **FOCUSED EVIDENCE REVIEWED; BASELINES UNCHANGED; OWNER VERDICT PENDING**

## Decision

The regenerated Marl evidence shows the blocked refuge, physical dig and
scallop retreat, pending boat return, deliberate night choice, hooked-fin
growth, and grounded hold/release. It is suitable for the separate #1397 owner
review, not a claim that the interaction is fun or that the HUD is finished.

Reviewed runtime: `5819f1d46425a5c6b0e3c4c5f2e0448b915816f3` (#1395 / PR #1404).
Local ignored build metadata was refreshed before the final capture run so
the displayed build matches the source, rather than an older local label.
Exact public browser evidence and limitations are in the
[Web verification](LIVING_EXPEDITION_07_WEB_VERIFICATION.md).

## Focused Evidence

All eighteen PNGs in ignored `visual_captures/living_expedition_07/` were
regenerated and inspected. Nine states each have desktop `1280x720` and
landscape-mobile `844x390` window variants (the native mobile canvas is
letterboxed to `693x390`):

- `refuge_closed`, `refuge_digging`, `refuge_retreat`, `pending_return`
- `night_choice`
- `unadapted_ready`, `adapted_ready`, `pin_held`, `pin_released`

The real-Main runner uses three isolated checkpoints and existing state owners.
Its checker passed image/source fingerprints, expected state and identity,
dimensions, subject/HUD bounds, matched framing, ignored output, and
`baseline_accepted=false`. `run.json` records provenance beside the images.
Deterministic capture stepping is not a real-time playthrough.

The closed/open arch and moving scallops distinguish the refuge from the
unchanged LE05 material mound. The pending frame explicitly requests the
surface boat. The night panel names Marl, Guarded the Nest, Root Claws, and
Ground Pin rather than showing an unexplained generic upgrade.

Matched readiness frames preserve Marl's six-fin silhouette and add hooked
tips without replacing the individual. The hold frame shows contact with the
eel at the ledge; release lifts Marl back into follow recovery and exposes the
cooldown. The diver retains the normal tool hotbar. Native mobile evidence
keeps the testing controls visible, with the subject between stick and buttons.

## Baseline Boundary

Rendered and inspected all six configured comparison sheets under ignored
`references/asset_reviews/*_visual_baseline_review.png`: full level, production
slices 01-04, and transfer hub. Their 41 configured RGB views matched accepted
baselines pixel-for-pixel; `check-clean --all-slices` passed.

These comparisons use the retained configured captures, not fresh full-map
renders of this commit. Only the affected LE07 set was regenerated. Therefore
they prove retained baseline stability, not new whole-map pixel parity.

No baseline was accepted or replaced. This review changes no terrain, map
source, diver, boat, Kite, Mica, materials, LE06 nursery, camera implementation,
runtime, or asset. The LE07 evidence covers only the named refuge/growth/action
changes already implemented by earlier issues.

## Known Limits

- The inherited diagnostic HUD remains dense and overlaps some header text.
  The reviewed field action stays outside it; this is not polished-UI approval.
- Hooked fin tips and night text are small at landscape-mobile scale. The
  capture-only mobile overview uses 0.55 zoom versus 0.7 desktop; live review
  keeps its existing camera behavior.
- Ground Pin is deliberately conditional on an eel near the floor. Native
  contact/release evidence establishes the state, not ease of timing for a
  person. That distinction is central to #1397's usefulness verdict.
- Live Chromium field checkpoints emit WebGL buffer warnings. No missing
  subject was observed in the inspected frames; details and diagnostic #1405
  remain in the Web record rather than being hidden behind a clean checker exit.

## Verification

```powershell
python tools/write_build_info.py
python tools/capture_living_expedition_07.py --godot "$godot"
python tools/check_living_expedition_07_captures.py
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

See [review tooling](tooling/living_expedition_07.md) for the local Godot path
and checkpoint controls. Non-headless rendering is required on this machine.
No generated PNG, manifest, comparison sheet, `.import`, or build metadata is
committed. Reuse [#1395 integration evidence](LIVING_EXPEDITION_07_INTEGRATED_VERIFICATION.md);
the full release suite is not rerun for these documentation-only edits.
