# Living Expedition 05 Verification Matrix

This matrix keeps the Silt Hound proof deterministic without copying every
shared-owner assertion into one slow smoke.

| Boundary | Authoritative check | CI lane |
| --- | --- | --- |
| empty/v1/v2 migration, no silent Marl, exact profile reload | `smoke_companion_profile_state.gd` | core runtime |
| three-row desktop/mobile habitat and selection | `smoke_companion_habitat_selection.gd` | core runtime |
| rescue, follow, recovery, collision, equipment-gate denial | `smoke_silt_hound_companion.gd` | core runtime |
| deliberate phases, cargo-full, reset, pickup, bank | `smoke_silt_hound_excavate.gd` | core runtime |
| physical/state-derived copy and prior-guidance isolation | `smoke_silt_hound_journey_guidance.gd` | core runtime |
| continuous rescue -> Retry -> commit -> select -> launch -> Excavate -> reload -> bank | `smoke_living_expedition_05_journey.gd` | regional journey |
| Kite/Mica rescue, selection, ecology, eel, and BOND regressions | Living Expedition 01-04 journey smokes | regional journey |
| schema, ids, reachability, optional supply, and progression relationships | Living Expedition 05 Python fixtures plus map validation | source/progression |

Run the focused boundary locally:

```powershell
& $godot --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_05_journey.gd --review-checkpoint=living_expedition_05_start
```

`tools/ci/run_godot_checked.sh` treats `SCRIPT ERROR` and `ERROR:` output as a
failure even if Godot exits zero. The integrated PR runs each CI lane once; do
not duplicate the full historical release suite inside this smoke.
