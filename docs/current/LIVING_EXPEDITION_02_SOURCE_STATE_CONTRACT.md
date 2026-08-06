# Living Expedition 02 Source And State Contract

Status: implemented contract for completed milestone #46; owner GO recorded in
`LIVING_EXPEDITION_02_CLOSEOUT.md`.

## Purpose

Living Expedition 02 extends the implemented Spark Ray proof to exactly two
named individuals at the canonical boat:

- Kite, `spark_ray_juvenile_01`, keeps the existing mounted Spark Ray behavior.
- Mica, `veil_cuttle_juvenile_01`, is a non-mounted sensing companion.
- exactly one committed individual may be selected for a launched sortie.

This milestone does not create a general roster, a third species, passive stable
bonuses, offscreen simulation, or a broad creature framework.

## Stable IDs

| Role | ID |
| --- | --- |
| Existing species | `spark_ray` |
| Existing individual | `spark_ray_juvenile_01` |
| New species | `veil_cuttle` |
| New individual | `veil_cuttle_juvenile_01` |
| New callsign | `Mica` |
| Rescue | `veil_cuttle_rescue_01` |
| Boat habitat | `companion_habitat_01` |
| Optional trace | `veil_cuttle_trace_01` |
| Review camera | `veil_cuttle_review_01` |
| Base action | `reveal_trace` |
| Input action | `companion_command` |

These IDs become immutable when catalog, map, profile, or review fixtures use
them. Display labels and visual assets may change in a focused review issue.

## Immutable Source

`config/creature_catalog.json` owns:

- species ids and display labels;
- allowed independent or mounted roles;
- ride capability and clearance metadata;
- supported base, memory, and adaptation actions; and
- action effect kinds.

Generated `production_level_01` map source owns:

- Mica's rescue position and required existing interaction;
- canonical-boat commitment relationship;
- habitat, optional trace, and review-camera placement;
- trace reveal radius and source relationships; and
- stable provenance for every generated record.

Source does not own active selection, commitment, memories, adaptation, live
visibility, reveal completion, cooldowns, or companion position. This milestone
changes no terrain topology.

## Profile Schema V2

Schema v2 replaces the schema-v1 `individual` object with:

```json
{
  "schema_version": 2,
  "individuals": [],
  "active_individual_id": ""
}
```

Rules:

- `individuals` contains zero to two unique committed records.
- Records use the existing individual shape: `individual_id`, `species_id`,
  `callsign`, `rescue_committed`, `earned_memory_ids`, and
  `selected_adaptation_id`.
- Ordering is canonical by catalog individual order, not rescue time.
- Every individual id maps to exactly one supported species.
- An active id is empty or references one committed record.
- An empty active id is valid but cannot launch a companion.
- Kite retains its two memory/adaptation branches.
- Mica has no memory or adaptation branch in this milestone; its arrays remain
  empty and a non-empty selected adaptation is invalid.
- Ride availability derives from the selected species' `ride_capable` catalog
  field and rescue commitment. It is never a persisted flag.

## Migration

Migration from schema v1 is exact and idempotent:

1. An empty v1 `individual` becomes an empty v2 `individuals` array.
2. A committed Kite record becomes the sole v2 record without changing its
   callsign, rescue flag, earned-memory order/content, or selected adaptation.
3. The v1 `active_individual_id`, including an empty value, is preserved.
4. Loading or saving the migrated payload again does not duplicate or rewrite
   Kite.
5. Invalid v1 data still fails validation; migration does not repair unknown
   ids, unsupported relationships, or malformed fields silently.

Fresh first commitment may select that individual automatically. Committing a
second individual never replaces the existing active id. Mica therefore enters
the habitat on commitment and requires an explicit boat selection before the
next Mica sortie.

## Boat Habitat And Selection

- The canonical boat is the only rescue-commitment and selection authority.
- Habitat presentation is derived from committed profile records; no separate
  persistent habitat state exists.
- At the boat, both committed individuals are readable by callsign and species.
- BOND opens the selector only when two individuals are committed.
- Confirming a selection updates `active_individual_id` for the next launch.
- Selection cannot change outside the canonical boat.
- The selected individual stays in habitat until the player launches.
- On launch, only the selected individual receives a live sortie instance.
- On return, the active instance rejoins the habitat presentation.
- The inactive individual grants no passive effect and receives no simulation,
  resource yield, care debt, memory, or adaptation progress.

The selector emits a request to the profile owner; it does not write saves or
spawn companions directly. Existing BOND and shared desktop/mobile
selection/confirm actions remain authoritative.

## Rescue And Commitment

Mica's source rescue uses one already-understood diver interaction and an
existing capability. It must be reachable and returnable without Mica, another
companion, or a capability gained from the rescue itself.

- Rescue progress and the following Mica instance are sortie-local.
- Full cargo neither blocks the rescue nor deletes or converts Mica; cargo is
  unchanged.
- Returning together to the canonical boat commits Mica exactly once.
- Commitment does not bank cargo, end the day, or alter Kite's record.
- Duplicate commitment reports an explicit no-change reason.
- If the collection is already at two records, another commitment is rejected.

## Live Runtime

Only the selected individual is instantiated after launch. Position, velocity,
follow mode, target, command state, cooldowns, palette selection, mounted state,
trace visibility, and presentation effects are transient.

Kite keeps the focused Spark Ray owners for follow, riding, memories, and
adaptations. Mica uses focused non-mounted owners for close follow,
investigative excursions, and `reveal_trace`. Shared selection or sortie code
may dispatch by species, but it must not force Mica through mounted or
Spark-specific behavior.

Mica's BOND palette exposes Recall and Reveal Trace when valid and never Mount.
Kite retains its existing contextual palette and mounted hotbar. Switching the
profile selection does not hot-swap the live companion in open water.

## Reveal Trace Boundary

`reveal_trace` is a deliberate BOND action with visible direction, bounded
range, result, and cooldown. It may reveal only `veil_cuttle_trace_01` while
Mica is the active nearby companion.

Reveal Trace cannot:

- identify or complete a scanner subject;
- collect an entity or grant score, material, discovery, or progression;
- satisfy a required objective or capability edge;
- replace light, fins, pressure protection, oxygen, collision, a tool, the
  canonical boat, or another equipment/access owner; or
- remain globally revealed after failure unless later source design explicitly
  makes that evidence persistent.

The diver must still use the scanner to identify the optional trace.

## Failure, Retry, And Reload

- Failure before Mica commits discards rescue progress, frees the pending live
  instance, and restores the source rescue to available.
- Failure after commitment preserves both records and the active id exactly.
- Retry clears live position, target, commands, cooldowns, mounted state, trace
  visibility, and habitat/selection presentation state.
- Reload restores the committed records and active id, then begins unmounted
  with no live companion until the normal launch owner instantiates one.
- Review checkpoints use isolated profiles and cannot mutate normal progress.
- Existing oxygen, daylight, health, cargo, banking, night, tools, collision,
  equipment, discovery, material, and failure owners remain authoritative.

## Validation And Review

Automation must prove migration, duplicate/unknown ids, capacity, species/action
relationships, active-id validity, exact-once commitment, boat-only selection,
one active instance, no mid-sortie switch, species-specific actions, full-cargo
rescue, failure/retry/reload, optional trace behavior, progression acyclicity,
equipment-gate protection, and desktop/mobile controls.

The owner review must choose both partners across separate sorties and judge
identity, preparation value, inactive boat presence, and another-day
motivation. Automation cannot claim those experience outcomes.
