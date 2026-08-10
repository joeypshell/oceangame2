# Living Expedition 05 Visual Decision

Date: 2026-08-10

Issue: #1350

Status: **FOCUSED EVIDENCE ACCEPTED; BASELINES UNCHANGED; OWNER GATE PENDING**

## Decision

The focused Silt Hound evidence is suitable for the Living Expedition 05 owner
review. It presents Marl's rescue, boat commitment, three-partner selection,
independent follow identity, deliberate Excavate sequence, cargo-full
preservation, and successful titanium pickup at desktop and landscape-mobile
review sizes.

This is acceptance of the generated review evidence, not a production visual
baseline change. The focused captures remain ignored and no baseline is
accepted or replaced.

## Intentional Evidence

The generated `visual_captures/living_expedition_05/` set contains ten states at
desktop `1280x720` and landscape-mobile `844x390` (`693x390` logical canvas):

1. `rescue_cutting`
2. `pending_boat_return`
3. `three_partner_selection`
4. `marl_following`
5. `excavate_command`
6. `excavate_anticipation`
7. `excavate_impact`
8. `deposit_opened`
9. `cargo_full_preserved`
10. `titanium_held`

The runner derives each frame from the isolated checkpoint and normal rescue,
profile, habitat, command, excavation, material, and cargo owners. The checker
requires all 20 PNGs, exact dimensions, runtime HUD/control bounds, and
`baseline_accepted=false`.

The inherited status panel remains dense, particularly on mobile. The focused
frames keep action subjects, hotbar, habitat/command panels, and touch controls
inside the logical canvas without overlap. Broader HUD redesign is outside this
review and is not implicitly accepted here.

## Stable Areas

Rendered comparison sheets and `check-clean --all-slices` confirm no difference
for `production_level_01`, production slices 01-04, or
`transfer_hub_interior_01`. Terrain, authored cameras, diver, boat, Kite, Mica,
HUD owners, material visuals, props, collision, and map source remain unchanged
by this issue.

No generated capture, comparison sheet, visual asset, `.import` sidecar, or
baseline replacement is committed.

## Commands

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --script res://scripts/main/captures/living_expedition_05_capture_runner.gd --review-checkpoint=living_expedition_05_start
python tools/check_living_expedition_05_captures.py
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Issue #1351 remains the exact-Web verification and player-experience closeout.
This decision does not claim owner GO.
