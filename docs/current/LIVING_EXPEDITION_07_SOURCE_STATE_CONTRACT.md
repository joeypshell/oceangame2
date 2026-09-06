# Living Expedition 07 Source And State Contract

Date: 2026-09-06. Schema issue: [#1389](https://github.com/joeypshell/oceangame2/issues/1389).
Active [milestone #51](https://github.com/joeypshell/oceangame2/milestone/51);
ordered batch and experience decision: [LE07 plan](LIVING_EXPEDITION_07_PLAN.md).

## Implemented Boundary

Catalog declarations, Python source validation, proposed progression graph, and
negative fixtures are implemented. Production source authoring is #1390; refuge
runtime, memory commitment/night UI, and Ground Pin are #1391-#1393. None of those
behaviors is live merely because its catalog id exists. No map, collider,
profile version, runtime script, art, capture, or accepted baseline changes here.

The catalog remains version 3 / `partial_runtime`. Marl is the existing
`silt_hound_juvenile_01`, species `silt_hound`, independent-only, base `excavate`.
Only this species may own `guarded_the_nest` -> `root_claws` -> `ground_pin`.
The new action is non-damaging `grounded_hold`; it has no mounted role.
Vein Whiskers is directional, not an unavailable second night option.

## Immutable Source Records

`tools/living_expedition_07_contract.py` owns exact ids, fields, and cross-links;
`validate_living_expedition_schema.py` calls it from normal map validation.
The optional relationship is supported only on `production_level_01`.

| Collection | Id | Responsibility |
| --- | --- | --- |
| `burrow_refuges` | `deep_cache_burrow_refuge_01` | One `soft_silt_burrow` with passive `burrow_scallop_group`, base Excavate, bounds, approach/dig points, and shelter path |
| `creature_memory_opportunities` | `marl_guarded_nest_opportunity_01` | Marl, refuge, live eel, four required observations, memory/payoff, existing rescue, canonical boat |
| `companion_contexts` | `deep_cache_eel_marl_ground_pin` | Independent action review, Root Claws, live eel, floor anchors, 1.75-second maximum hold, 8-second cooldown, zero damage |
| `creature_adaptation_payoffs` | `silt_hound_root_claws_payoff_01` | Root Claws and the matching independent context/hostile target |

All four records name the same species/individual and use
`availability: all_supported_seeds`. Refuge and event are optional, rewardless;
the group is neither bondable nor harvestable. All required observations are
`physical_dig_complete`, `live_warning_lunge`, `group_sheltered`, `pair_present`.

The refuge declares existing `lower_loop_to_deep_cache_pressure`, visual-only
`deep_cache_dark_pocket`, and `deep_cache_territorial_eel`. Refuge/event require
`dive_light_1`; the intended armed pin review declares Light plus `shock_prod`.
The eel still guards attemptable `salvage_deep_right_cache`, with its existing
2.5-second timed pickup and no hard capability lock. The optional Marl chain
cannot fund or become a prerequisite of required equipment, rescues, or routes.
No new collision is inferred from darkness. Existing survival/access rules stay
authoritative; Ground Pin cannot replace Shock Prod damage or defeat-only harvest.

Author through `tools/production_level_01_living_expedition_07.py`, composed by
the full-level generator in #1390. `source.living_expedition_07` records that
source path, exact refuge/opportunity/context/payoff lists, review camera ids,
the availability guarantee, and empty `terrain_changes`.
Review camera ids are `living_expedition_07_refuge_review_01` and
`living_expedition_07_pin_review_01`. No transform is implemented in #1389.

Bounds and points use integer tile coordinates, excluding booleans. Refuge
bounds must be positive, in bounds, and non-solid; dig point ends inside shelter.
The wildlife path has 2-8 points and ends inside shelter. There are 1-4 unique
pin anchors in existing eel territory, each with solid floor directly below.
All source points and canonical boat entry must be reachable. Unknown fields,
duplicate relationships, wrong species/ids, malformed timing, random availability,
mutable state, unsupported links, and circular prerequisites fail validation.

Tile-valid fixtures are not approved gameplay placement. #1390 must additionally
prove real diver/Marl/eel footprints, swept approach/contact clearance, live eel
reach, and return accessibility in the unchanged topology. Do not copy synthetic
test positions into production without that evidence or teleport an actor to pass.
LE05 rescue/deposit and LE06 nursery source relationships remain unchanged.

## Event And Commitment

The future focused Marl event owner must receive source ids and authoritative
physical-action, hostile-phase, and group-shelter observations. It tracks one
attempt with its individual id, never whichever companion becomes selected later.

1. Active, already committed Marl physically finishes the refuge dig.
2. A real source-bound warning/lunge occurs during this attempt while the diver
   handles the existing eel. Idle proximity or issuing a command is not evidence.
3. The passive group reaches shelter with the pair still present. These combined
   observations produce one pending `guarded_the_nest`, not permanent growth.
4. Canonical `production_level_01` / `surface_boat_entry` return commits the
   captured individual's memory through existing profile/save ownership once.
5. Night deliberately selects Root Claws or defers. The next sortie may use Pin.

| Situation | Required outcome |
| --- | --- |
| Quiet/defeated eel; ordinary deposit, pickup, scan, idle time | Shelter can open, but no fabricated memory |
| Repeat Excavate or repeated qualifying snapshots | No progress farming, stacked attempts, or duplicate pending reward |
| Recall/separation/invalid target before completion | Cancel the attempt; no partial durable progress |
| Failure, Retry, reload, abandoned field result | Discard uncommitted event/hold state; retain committed memory/adaptation |
| Full cargo at canonical return | Memory still commits once; ordinary material/cargo banking is unchanged |
| Repeated boat return, confirm, save/load | No duplicate memory/adaptation or second reward |
| Defer at night | Keep secured memory available for a later deliberate choice |
| Next eligible day without secured memory | Reset opportunity with normal daily eel lifecycle, never early resurrection |

The existing hostile still targets the diver. The small group observes its
snapshots; no prey-target AI, wildlife damage/death, or ecosystem state is added.

## State Ownership

`CompanionProfileState` remains schema v3, three individuals maximum, one active
selection, one `selected_adaptation_id` per individual. Existing identity,
committed rescue, `earned_memory_ids`, and selected adaptation own lasting growth.
Root Claws requires this individual's secured memory and an empty adaptation slot.
The existing runtime has no Marl night option until #1392; catalog membership
does not automatically select it or grant the memory.

Derive the lasting sheltered refuge from the committed Marl memory. Do not add
a second nursery-history store. Source JSON stays immutable. Dig/attempt flags,
pending memory, group travel, positions, command selection, pin target, approach,
hold, and cooldown are transient and must clear through normal lifecycle hooks.

Keep the event owner separate from Spark Ray-specific memory qualification;
extend existing profile commitment and `companion_adaptation_debrief.gd` only
at their established boundaries. Reuse the existing Silt Hound action owner for
physical approach/dig with distinct deposit-versus-refuge outcomes. Do not copy
action state or move responsibilities into `main.gd`.

## Ground Pin Runtime Interface

This is the required #1393 implementation boundary, not a new API implemented here.
The companion requests one bounded hold only after physically reaching a valid
floor/contact anchor near the source-bound live eel in warning/lunge. No snapping
the eel down, wall homing, or remote freeze. Marl cannot dig and pin concurrently.

`territorial_hostile_controller.gd` remains sole owner of position, phase, health,
movement, attack, and contact. Its narrow hold request/release boundary suspends
only that target for at most 1.75 gameplay seconds. Marl's action owner applies
8 seconds cooldown after release; whole-simulation BOND pause freezes both clocks.
Never simulate Pin by repeatedly calling Kite's recoil-based Guardian Pulse.

Release on timeout, Recall, separation, lost floor/line of sight, any weapon hit,
failure, Retry, reload, day transition, or teardown. Restore normal recovery,
not stale mid-lunge velocity/contact. Weapon hit releases first, then preserves
normal damage/recoil/defeat. Invalid approach cancels without a hold. No refresh,
stacking, damage, harvest, creature health, or immunity to other hazards.

Keep `B/BOND` toggle, desktop `1`-`3`, and sequential mobile `BOND/TOOL/USE`.
At most Recall, contextual Excavate, and learned Ground Pin appear. Show compact
denial reasons such as too high, blocked approach, or cooldown. No held chord,
new key, riding, or creature action in the diver's tool hotbar.

## Progression And Verification

The proposed graph retains Cutter -> physical rescue -> canonical boat commitment
-> active Marl selection -> Light/refuge event -> secured memory -> deliberate
night (`root_claws_night`) -> adaptation -> next-sortie action -> armed context.
The night/action graph nodes are audit concepts, not new save fields. Graph labels
remain `[proposed]` and expose seed guarantees; automation cannot prove fun or a
physical event occurred. Production graph output remains unchanged until #1390.

```powershell
python tools/test_living_expedition_07_contract.py
python tools/test_living_expedition_05_contract.py
python tools/test_progression_graph_creatures.py
python tools/validate_greybox_map.py maps/production_level_01.greybox.json
python tools/audit_progression_graph.py
python tools/check_file_lengths.py
git diff --check
```

The Progression Audit workflow runs the new schema/graph fixtures. Integrated
runtime/real-input coverage belongs to #1395, focused visual/Web review to #1396,
and the owner GO/HOLD to #1397. #52/#53, Vein Whiskers, release/legacy, a fourth
species, and broad combat/ecosystem work remain deferred.
