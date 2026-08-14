# Living Expedition 06 Visual Decision

Date: 2026-08-13

Issue: #1374

Status: **FOCUSED EVIDENCE ACCEPTED; BASELINES UNCHANGED**

## Decision

The focused Signal Reef evidence is suitable for exact-build Web review. It
shows the unresolved wildlife relationship, partial Anchor brace, Guardian
displacement without damage, immediate movement toward shelter, pending boat
return, and a visibly larger next-day nursery at desktop and landscape-mobile
review sizes.

This accepts generated review evidence only. It does not accept or replace a
production visual baseline, and it is not the owner experience verdict.

## Intentional Evidence

The ignored `visual_captures/living_expedition_06/` set contains six states at
desktop `1280x720` and landscape-mobile `844x390` (`693x390` rendered canvas):

1. `approach`
2. `anchor_action`
3. `guardian_action`
4. `immediate_sheltering`
5. `pending_return`
6. `restored_next_day`

The runner derives each state from the three isolated LE06 checkpoints and the
normal adaptation, coordinator, nursery, companion, equipment, and status
owners. The checker requires all 12 PNGs, exact dimensions, passive-wildlife
semantics, branch outcomes, companion identity, equipment context, mobile
controls, runtime subject/HUD bounds, and `baseline_accepted=false`.

Anchor uses the existing cyan brace/lee response. Guardian uses the existing
yellow pulse and visible jellyfish displacement while recording zero damage.
The pending frame removes local pressure, and the restored frame shows seven
greener filter skates occupying the nursery instead of the unresolved five.

Landscape-mobile frames retain the full testing controls. Broad relationship
frames stay wide; local action and restored frames use closer subject-aware
framing in the interaction-free lower band. The inherited status panel remains
dense, but it names Kite, the local response, and the required equipment
without covering the reviewed subject.

## Stable Areas

Rendered comparison sheets and `check-clean --all-slices` confirm no accepted
baseline difference for `production_level_01`, production slices 01-04, or
`transfer_hub_interior_01`. Terrain, authored map topology, diver, boat, Kite,
Mica, Marl, cargo/equipment HUD ownership, collision, and map source remain
unchanged by this issue.

No generated capture, comparison sheet, visual asset, `.import` sidecar, or
baseline replacement is committed.

## Commands

```powershell
& $godot --path . --script res://scripts/main/captures/living_expedition_06_capture_runner.gd --review-checkpoint=living_expedition_06_anchor_ready
& $godot --path . --script res://scripts/main/captures/living_expedition_06_capture_runner.gd --review-checkpoint=living_expedition_06_guardian_ready
& $godot --path . --script res://scripts/main/captures/living_expedition_06_capture_runner.gd --review-checkpoint=living_expedition_06_restored_nursery
python tools/check_living_expedition_06_captures.py
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Exact deployed SHA and browser evidence belong in the separate LE06 Web
verification record after this evidence tooling is merged and deployed.
