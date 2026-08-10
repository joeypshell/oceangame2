# Living Expedition 04 Source And State Contract

Date: 2026-08-08

Amended: 2026-08-09 by #1335 after owner HOLD

Status: current implementation contract for milestone #48.

## Purpose

Living Expedition 04 links Guardian-Pulse Kite to one existing territorial eel
as a deliberate non-damaging interruption. The diver may still evade, and the
Shock Prod remains the only damage and defeat path. Only defeat exposes the
existing explicit eel electrocyte harvest.

The original contract also linked Drift-Lens Mica as a hostile-intent reader.
The owner rejected that interaction as non-useful. Mica's eel response is no
longer active source, but her moving-ecology `Read Drift` skill remains intact.
The generic hostile reader stays dormant and source-gated for possible later
evaluation.

This contract adds no individual, species, memory, adaptation, resource,
weapon, profile field, terrain, hard access, generic combat layer, or baseline.

## Stable IDs

| Role | ID |
| --- | --- |
| Relationship | `deep_cache_eel_companion_response` |
| Existing hostile | `deep_cache_territorial_eel` |
| Existing guarded salvage | `salvage_deep_right_cache` |
| Existing hostile harvest | `deep_cache_eel_electrocyte_harvest` |
| Existing harvest material | `eel_electrocyte` |
| Existing diver weapon access | `shock_prod` |
| Existing Spark Ray individual | `spark_ray_juvenile_01` |
| Existing Spark Ray adaptation | `guardian_pulse` |
| Existing Spark Ray action | `guardian_pulse_action` |
| Review context | `living_expedition_04_eel_review_01` |
| Review camera | `living_expedition_04_eel_review_camera_01` |
| Review checkpoint | `living_expedition_04_start` |

## Relationship Source Shape

The focused production-level source module owns this bounded relationship:

```json
{
  "id": "deep_cache_eel_companion_response",
  "kind": "companion_hostile_response",
  "hostile_id": "deep_cache_territorial_eel",
  "guarded_salvage_id": "salvage_deep_right_cache",
  "hostile_harvest_id": "deep_cache_eel_electrocyte_harvest",
  "review_context_id": "living_expedition_04_eel_review_01",
  "responses": [
    {
      "species_id": "spark_ray",
      "individual_id": "spark_ray_juvenile_01",
      "required_adaptation_id": "guardian_pulse",
      "action_id": "guardian_pulse_action",
      "effect_kind": "support_interrupt",
      "damage": 0,
      "required_access_ids": ["shock_prod"]
    }
  ],
  "availability": "all_supported_seeds"
}
```

The record references existing source. It does not copy territory, position,
phase timings, health, cache placement, harvest quantity, action definitions,
adaptation relationships, or mutable state.

## Immutable Source Ownership

`config/creature_catalog.json` remains authoritative for species, individuals,
adaptations, actions, legal roles, and non-damaging action metadata. Existing
production source remains authoritative for the eel, territory, guarded cache,
electrocyte harvest, equipment progression, and route.

The focused LE04 generator module adds only the relationship, review context,
review camera, checkpoint provenance, and all-supported-seed availability.
Generated JSON never owns active selection, hostile state, cooldown, companion
position, interruption result, defeat, harvest collection, cargo, failure, or
UI state.

## Ownership Matrix

| State or behavior | Authoritative owner | Lifetime |
| --- | --- | --- |
| Relationship and stable links | generated immutable map source | loaded map |
| Species, action, adaptation, legal roles | creature catalog | immutable |
| Commitment, selection, memories, adaptation | `CompanionProfileState` | profile |
| Eel phase, position, health, recovery, defeat | hostile controller | expedition day |
| Kite aim, charge, cooldown, result | Guardian Pulse runtime | sortie |
| Support recoil and recovery | hostile controller request API | expedition day |
| Shock Prod range, cooldown, damage | existing Shock Prod owners | runtime |
| Harvest eligibility and collection | biological interaction owner | expedition day |
| Held and banked material | cargo/profile owners | sortie/profile |
| Oxygen, daylight, health, tools, failure | existing focused owners | unchanged |

No LE04 state is added directly to `main.gd`.

## Outcome Matrix

| Approach | Moves/recovers eel | Changes health | Defeats | Exposes harvest |
| --- | --- | --- | --- | --- |
| Ordinary evade | existing phase machine only | no | no | no |
| Guardian-Pulse Kite | temporary support interrupt | no | no | no |
| Shock Prod | weapon recoil/recovery | yes | at zero | yes |
| Post-defeat harvest | no | no | no new defeat | collects material |

Information, interruption, damage, defeat, and collection remain separate.
No companion action may call the harvest owner or profile material deposit.

## Mica Boundary

The active relationship contains no `veil_cuttle` response. Therefore
`veil_cuttle_drift_lens_runtime.gd` receives no territorial-eel snapshot from
this map and cannot label its action `Predict Lunge` here. Journey guidance
must not advertise Mica as an eel solution.

The generic hostile snapshot reader is not deleted. It remains inert unless a
future reviewed source relationship explicitly provides a compatible Mica
response. Existing authored jellyfish subjects, `Read Drift` label, cooldown,
projection, denial, memory, adaptation, and profile behavior remain supported.

## Kite Interruption Contract

Guardian Pulse retains its `shock_prod` and `guardian_pulse` requirements,
independent/mounted roles, deliberate aim, charge, cone, cooldown, separation,
and mode-change rules. A valid hit may recoil the threatening eel and enter its
existing recovery phase. It must report zero damage, unchanged health, no
defeat, and a temporary opening.

Guardian Pulse cannot expose a harvest, mark a cache clear, award a memory, or
imply health loss. Anchor-Fins Kite receives no combat action or adaptation
swap.

## Damage, Harvest, And Persistence

`TerritorialHostileController.apply_weapon_hit()` remains the only eel-health
mutation path. Existing Shock Prod damage, cooldown, recoil, and three-health
defeat rules remain unchanged.

The biological owner exposes the linked electrocyte only after defeat for the
current day. The player must complete the timed harvest, have cargo space,
return to the canonical boat, and bank through existing owners. Failure restores
unbanked state; same-day connector/reload behavior and fresh-day restoration
remain unchanged.

`CompanionProfileState` schema version 2 remains unchanged. Exactly one active
individual launches, selection remains boat-only, and both existing adaptations
survive Retry, day transition, and reload.

## Controls And Presentation

- Preserve toggle `B/BOND`, numbered commands, `Tab/TOOL`, and `Space/USE`.
- Touch uses sequential BOND/TOOL/USE controls.
- Guardian Pulse shows aim, charge, hit/miss, recoil, opening, and cooldown.
- Eel health feedback changes only after Shock Prod damage.
- Existing diver/mounted hotbar ownership remains authoritative.
- #1336 must verify and correct complete-simulation timing while BOND is open.

## Validation And Review

Automation proves stable links, one legal response, no copied source state,
Guardian zero damage, Shock Prod damage authority, defeat-only harvest,
cargo/reset/day behavior, ordinary evade, Anchor Fins isolation, selection,
equipment gates, and LE01-LE03 regressions. LE03 ecology coverage specifically
protects Mica's retained moving-hazard `Read Drift` behavior.

Focused evidence contains Guardian opening, Shock Prod damage, and explicit
harvest availability at desktop and landscape-mobile sizes. Rejected Mica eel
frames are not current evidence or accepted baselines. #52/#53 remain deferred.
