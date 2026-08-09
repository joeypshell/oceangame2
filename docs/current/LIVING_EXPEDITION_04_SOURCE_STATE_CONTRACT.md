# Living Expedition 04 Source And State Contract

Date: 2026-08-08

Issue: #1314 `Lock Living Expedition 04 companion-shaped eel source and state contract`

Status: implementation contract for milestone #48. Validation, source,
runtime, evidence, Web review, and owner closeout land separately through
#1315-#1323.

## Purpose

Living Expedition 04 makes the current active-companion choice matter inside
one existing territorial eel encounter. Drift-Lens Mica provides deliberate
information, Guardian-Pulse Kite creates a temporary non-damaging opening, the
diver may still evade, and the Shock Prod remains the only damage/defeat path.
Only defeat exposes the existing explicit eel electrocyte harvest.

This contract adds no individual, species, memory, adaptation, resource,
weapon, profile field, terrain, hard access, generic combat layer, wildlife
reputation, or accepted baseline.

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
| Existing Veil Cuttle individual | `veil_cuttle_juvenile_01` |
| Existing Veil Cuttle adaptation | `drift_lens` |
| Existing Veil Cuttle action | `read_drift` |
| Review context | `living_expedition_04_eel_review_01` |
| Review camera | `living_expedition_04_eel_review_camera_01` |
| Review checkpoint | `living_expedition_04_start` |

These ids become immutable when validator, generated source, or checkpoint
fixtures use them. Player-facing labels may improve independently.

## Relationship Source Shape

One focused production-level source module owns a record equivalent to:

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
      "species_id": "veil_cuttle",
      "individual_id": "veil_cuttle_juvenile_01",
      "required_adaptation_id": "drift_lens",
      "action_id": "read_drift",
      "effect_kind": "hostile_intent_read",
      "mutation": "none"
    },
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

The schema issue may improve field ordering but not broaden allowed kinds or
effects. The record references existing source; it does not copy territory,
position, path, phase timings, health, cache placement/timing, harvest quantity,
action definitions, adaptation relationships, or mutable state.

## Immutable Source Ownership

`config/creature_catalog.json` remains authoritative for:

- species and individual eligibility;
- Guardian Pulse and Drift Lens adaptation relationships;
- `guardian_pulse_action` as independent/mounted support interruption; and
- `read_drift` as an independent informational action.

Existing production source remains authoritative for the eel, territory,
guarded salvage, electrocyte harvest, equipment progression, and route. One
focused Living Expedition 04 module adds only the relationship, review context,
review camera, checkpoint provenance, and all-supported-seed availability.

Generated JSON must not own live hostile phase/position/health, active
companion, profile adaptations, action cooldown, projection visibility,
interruption result, defeat, harvest eligibility/collection, cargo, failure, or
UI state.

## Ownership Matrix

| State or behavior | Authoritative owner | Lifetime |
| --- | --- | --- |
| Relationship and stable links | generated immutable map source | loaded map |
| Species, actions, adaptations, allowed roles | creature catalog | immutable |
| Individual commitment, active next-sortie selection, memories, adaptation | `CompanionProfileState` | durable profile |
| Eel phase, target, position, health, contact, recovery, defeat | `TerritorialHostileController` | expedition day |
| Mica eligibility, target choice, cooldown, result | focused Drift Lens runtime | sortie |
| Mica world projection | focused Drift Lens presentation | temporary |
| Kite eligibility, aim, charge, cooldown, result | Guardian Pulse runtime | sortie |
| Support recoil and recovery transition | hostile controller request API | expedition day |
| Shock Prod range, cooldown, damage request | existing Shock Prod owners | runtime |
| Harvest eligibility/progress/collection | biological interaction owner | expedition day |
| Held/banked material and capacity | existing cargo/profile owners | sortie/profile |
| Oxygen, daylight, health, tools, boat, failure | existing focused owners | unchanged |

No Living Expedition 04 state is added directly to `main.gd`.

## Outcome Matrix

| Approach | Reads hostile | Moves or recovers hostile | Changes health | Marks defeat | Exposes electrocyte | Grants other reward |
| --- | --- | --- | --- | --- | --- | --- |
| Ordinary evade/retreat | player-visible existing cues | existing phase machine only | no | no | no | no |
| Drift-Lens Mica | yes | no | no | no | no | no |
| Guardian-Pulse Kite | yes for targeting | yes, temporary support interrupt | no | no | no | no |
| Shock Prod | normal target report | weapon recoil/recovery rules | yes | at zero health | yes, through harvest owner | no |
| Post-defeat harvest | linked defeat state | no | no | no new defeat | collects one timed material | no automatic reward |

Information, interruption, damage, defeat, and collection are separate results.
No companion action may call the harvest owner or profile material deposit.

## Mica Read Contract

`veil_cuttle_drift_lens_runtime.gd` may consume a duplicated read-only snapshot
containing stable hostile id, phase, current/home position, lunge target,
territory rectangle, phase seconds, warning/recovery durations, and defeat
status. A focused projection may show:

- current warning, lunge, recovery, returning, home, or defeated phase;
- current position and projected lunge direction/target;
- source-owned territory edge; and
- remaining warning or recovery time.

Read Drift cannot call hostile update/reset/hit/interrupt methods, write world
centers, suppress contact, extend recovery, change condition state, expose the
harvest, collect the cache, grant access, or persist knowledge. Existing
jellyfish subjects and cooldown/denial behavior remain supported.

## Kite Interruption Contract

Guardian Pulse retains its existing `shock_prod` and `guardian_pulse`
requirements, independent/mounted roles, deliberate aim, charge, cone, cooldown,
separation, and mode-change rules. It may call only the hostile controller's
support-interrupt path while the source-linked eel is threatening.

A successful support interrupt may recoil the eel and enter its existing
recovery phase. It reports `damage: 0`, unchanged health, `defeated: false`, and
the temporary recovery duration. It cannot expose a harvest, mark a cache clear,
award a memory, or imply health loss in player-facing copy.

Anchor-Fins Kite has no LE04 combat action and receives no adaptation swap.

## Damage, Defeat, And Harvest Contract

`TerritorialHostileController.apply_weapon_hit()` remains the only eel-health
mutation path. Existing Shock Prod damage, range, cooldown, recoil, capacitor
interrupt, and three-health defeat rules remain unchanged.

The biological interaction owner exposes
`deep_cache_eel_electrocyte_harvest` only after the linked eel is defeated for
the current day. Defeat itself grants nothing. The player must complete the
existing timed harvest, have cargo space, return to the canonical boat, and bank
through existing owners. A nonlethal opening never satisfies eligibility.

## Profile And Selection Compatibility

`CompanionProfileState` schema version 2 remains unchanged. LE04 adds no memory,
adaptation, unlock, familiarity, injury, reputation, or encounter field.

Exactly one active individual launches. Selection remains boat-only and affects
the next sortie; the inactive individual remains in the habitat. Review
checkpoint setup may configure existing Guardian Pulse and Drift Lens choices on
their respective individuals but uses an isolated profile and cannot mutate the
normal save. Normal Anchor Fins or unadapted records remain valid.

## Controls And Presentation

- Preserve toggle `B/BOND`, direct numbered palette commands, `Tab/TOOL`, and
  `Space/USE`; do not restore held key chords or reuse `Q`/`E`.
- Touch uses sequential BOND/TOOL/USE controls and the same authority rules.
- Mica feedback stays world-local near the eel and temporary.
- Guardian Pulse shows charge, direction, hit/miss, recoil, opening, and
  cooldown without health-loss copy.
- Eel health feedback changes only after Shock Prod damage.
- Existing diver/mounted hotbar ownership and compact HUD priorities remain.
- No companion health bar, party HUD, combat meter, permanent quest panel, or
  exact travel arrow is added.

## Failure, Reload, And Day Boundaries

- Health, oxygen, hazard, manual reset, or Retry clears temporary Mica
  projection, Guardian charge/cooldown/result, active hostile interaction,
  in-progress cache/harvest, and unbanked sortie state under existing rules.
- Failure restoration resets eel defeat and therefore hides the harvest until a
  new valid defeat. It cannot duplicate held or banked electrocytes.
- Connector travel and same-day map reload preserve day-local defeat/collection
  according to existing owners but clear transient projection and charge state.
- Canonical-boat return banks held cargo and preserves the selected active
  individual under current semantics; it does not persist an encounter result.
- Night and a fresh day restore the eel and its one harvest source through their
  separate existing owners.
- Durable companion adaptations survive Retry, day transition, and reload.

## Validation And Review

Automation must prove stable links, role/effect compatibility, no copied source
geometry/state, Mica mutation-free reports, Guardian zero damage, Shock Prod
damage authority, defeat-only harvest, cargo/full/reset/day behavior, ordinary
evade, Anchor Fins isolation, one-active-companion selection, equipment gates,
desktop/mobile controls, and all LE01-LE03 regressions.

The complete release suite runs once after integrated focused coverage. Visual
evidence compares desktop and landscape-mobile states without accepting
unrelated baselines. Exact Web verification precedes the owner gate. Only the
owner can judge whether companion choice and the nonlethal-versus-harvest
decision feel understandable and worth another expedition.

#52/#53 remain deferred optional slice-03 presentation work.
