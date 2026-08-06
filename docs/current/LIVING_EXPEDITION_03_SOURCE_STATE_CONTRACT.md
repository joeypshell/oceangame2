# Living Expedition 03 Source And State Contract

Date: 2026-08-06

Issue: #1276 `Lock Living Expedition 03 ecological relationship and state contract`

Status: implementation contract for milestone #47. Schema, source, runtime,
evidence, and review land separately through #1277-#1285.

## Purpose

Living Expedition 03 turns Mica's optional anonymous trace into one real
jellyfish-migration observation. The player deliberately reveals the evidence,
identifies it with the Scanner, carries it back to the canonical boat, and
consolidates the shared memory into a practical next-sortie field skill.

This contract adds no third species, terrain, hard access, hazard disable,
reward economy, generic research wallet, broad ecology, or accepted baseline.

## Stable IDs

| Role | ID |
| --- | --- |
| Existing species | `veil_cuttle` |
| Existing individual | `veil_cuttle_juvenile_01` |
| Existing callsign | `Mica` |
| Existing base action | `reveal_trace` |
| Existing daily condition | `southwest_jellyfish_bloom` |
| Existing moving subject | `southwest_bloom_jellyfish_patrol` |
| Existing second patrol | `deep_route_jellyfish_patrol` |
| Migration relationship/trace | `southwest_bloom_migration_trace` |
| Observation | `southwest_bloom_migration_observation` |
| Memory opportunity | `veil_cuttle_bloom_memory_01` |
| Memory | `followed_the_bloom` |
| Adaptation payoff | `veil_cuttle_drift_lens_payoff_01` |
| Adaptation | `drift_lens` |
| Adapted action | `read_drift` |
| Field review context | `veil_cuttle_drift_review_01` |
| Review camera | `living_expedition_03_bloom_review_01` |
| Review checkpoint | `living_expedition_03_start` |

These ids are immutable after source, catalog, or profile fixtures use them.
Player-facing labels may improve without changing ids.

`veil_cuttle_trace_01` is retired from current generated source when #1278
lands. It was transient and never profile-persisted, so no save migration is
required. Existing LE02 fixtures, smokes, and runtime code must stop hardcoding
that id and use the authored relationship. The generator must emit one current
Mica trace, not both records.

## Immutable Source Ownership

`config/creature_catalog.json` owns:

- Mica's eligible `followed_the_bloom` memory;
- the memory-to-`drift_lens` relationship;
- `read_drift` as an independent, non-damaging field action; and
- the existing Veil Cuttle role and non-mounted boundary.

One focused Living Expedition 03 production-map source module owns:

- the migration relationship and trace anchor;
- links to `southwest_jellyfish_bloom` and
  `southwest_bloom_jellyfish_patrol`;
- the observation id, Mica memory opportunity, payoff context, review context,
  review camera, and provenance; and
- all-supported-seed availability and zero terrain changes.

The trace references the existing moving-hazard id. It must not copy a `path`,
speed, phase, position, or active state. `production_level_01` moving-hazard
source remains the only patrol-geometry authority.

Generated JSON does not own reveal state, Scanner progress, pending observation,
earned memory, selected adaptation, live patrol position, action cooldown, or
UI visibility.

## Profile Ownership And Compatibility

`CompanionProfileState` remains the only durable owner of:

- the two committed individual records;
- active next-sortie selection;
- each individual's earned memory ids; and
- each individual's selected adaptation id.

No profile-shape migration is required. Schema version 2 already provides
catalog-validated `earned_memory_ids` and `selected_adaptation_id` fields for
each individual. #1277 makes the new Mica ids legal in the catalog; existing
payloads with empty Mica memory/adaptation state remain valid and unchanged.

Do not add an ecological currency, generic discovery array, riding flag,
patrol knowledge flag, or separate Drift Lens boolean. Availability derives
from Mica's selected `drift_lens` adaptation.

Kite's record, memory order, selected adaptation, active selection, riding
derivation, and schema-v1-to-v2 migration remain unchanged.

## Transient Observation Ownership

A focused `companion_ecology_observation_state.gd` owner holds only:

- authored relationship records for the current map;
- revealed and identified relationship ids for the current sortie;
- at most one pending Mica observation id; and
- the last focused result needed for compact feedback.

It does not own Scanner timing/targeting, world-node visibility, profile writes,
boat detection, day/night state, or moving hazards.

`greybox_ecological_traces.gd` owns world-local hidden, revealed, and identified
projection state. `veil_cuttle_trace_runtime.gd` dispatches Mica's deliberate
Reveal Trace request. Existing Scanner owners retain cone targeting, held-use
progress, release/cancel behavior, subject identification, and local scan HUD.
Integration passes the successful authored identification to the observation
state; it does not create a second scan controller.

Identification creates `southwest_bloom_migration_observation` as pending only
when:

- active Mica revealed the linked relationship this sortie;
- the Scanner identified that exact relationship;
- the source-linked southwest bloom is active; and
- the observation is neither pending nor already represented by Mica's memory.

No cargo, score, material, blueprint, discovery reward, access, or adaptation is
granted at identification.

## Boat And Night Ownership

The existing canonical-boat check remains the sole commitment boundary.
`companion_ecology_observation_state.gd` may request
`CompanionProfileState.earn_memory("followed_the_bloom")` only while the player
is at that boat and Mica is the matching committed individual. A successful or
already-earned result clears pending state without duplicate writes.

The companion adaptation debrief remains the night input/presentation owner. It
must derive eligible options from the active individual's catalog-supported
memories rather than assume every option belongs to the Spark Ray. For Mica it
shows one deliberate Drift Lens option and calls the existing profile adaptation
selection path. It grants no score/material cost and cannot auto-select on day
transition.

## Moving-Hazard And Drift Lens Ownership

`MovingHazardController` remains authoritative for:

- active condition filtering;
- elapsed patrol phase and current position;
- hazard contact/warning data; and
- writing current centers to world presentation.

It may expose a duplicated, read-only snapshot for eligible authored jellyfish
patrols. Drift Lens cannot call reset, alter elapsed time, write a center, change
condition activation, suppress contact, or modify source.

A focused Drift Lens controller owns command eligibility, target selection,
cooldown, and result classification. A focused presentation owner projects the
selected patrol's source path, current direction, current position, and bounded
approach warning. Projection is temporary information, not persisted knowledge
or collision.

`read_drift` supports both `southwest_bloom_jellyfish_patrol` when active and
the existing `deep_route_jellyfish_patrol`. This proves a species field skill,
not a one-lock companion key.

## Controls And Presentation

- `Shift/BOND` or touch `BOND` opens Mica's existing slow-time palette.
- Before adaptation, valid Mica actions remain Recall and Reveal Trace.
- After adaptation, the contextual palette may show Recall, Reveal Trace, and
  Read Drift, never more than three actions and never Mount.
- Scanner identification continues through selected Scanner plus held
  `Space/USE` or touch `USE`.
- Read Drift is a deliberate BOND command. It does not reuse `Q`, `E/ACT`, or
  fire automatically.
- World feedback must read as a migration filament/path linked to moving
  jellyfish, not a generic circle.
- Compact guidance names the Southwest Jellyfish Bloom, pending boat return,
  shared memory, night choice, and practical field effect without adding a
  permanent quest panel.
- Out-of-range, inactive-subject, no-subject, cooldown, and unavailable states
  return visible feedback on desktop and landscape mobile.

## Exact Journey

1. `living_expedition_03_start` loads isolated Day 2 state with both individuals
   committed, Mica selected, Scanner available, the southwest bloom active, and
   no pending observation or Mica adaptation.
2. Existing forecast/guidance leads toward the named bloom.
3. Near the active patrol, Mica reacts and deliberate Reveal Trace exposes the
   linked migration filament.
4. The selected Scanner must be aimed and held to identify the named migration
   trail while oxygen, daylight, movement, and hazard pressure continue.
5. Identification records one pending observation and asks for canonical-boat
   return; it grants nothing else.
6. Returning to the boat commits `followed_the_bloom` to Mica exactly once.
7. Entering night presents Drift Lens only because that memory is committed.
8. `Space/USE` deliberately consolidates Drift Lens; no automatic selection or
   resource transaction occurs.
9. The next launched Mica sortie exposes Read Drift. Its deliberate use shows a
   patrol's path/direction without changing the hazard.
10. Selecting Kite for a later launch restores Kite's existing independent and
    mounted action ownership with no Mica action leakage.

## Failure, Retry, Reload, And Isolation

- Leaving range or releasing Scanner use follows existing cancellation rules.
- Hazard contact, oxygen failure, health failure, manual reset, Retry, map
  teardown, or abandoned uncommitted sortie clears reveal, identification,
  pending observation, and command/presentation state.
- A boat-committed memory and night-selected adaptation persist exactly once
  across day transition, Retry, and profile reload.
- Reload begins with no revealed trace, pending observation, active projection,
  or cooldown.
- Full cargo does not block observation, memory commitment, or adaptation and is
  not modified by them.
- Review checkpoints use isolated profiles and cannot read or mutate the normal
  durable profile.

## Preserved Authorities

Existing owners remain authoritative for terrain/collision, fins/light/pressure
and tool access, oxygen, daylight, health, moving-hazard contact, cargo, banking,
boat detection, day transition, active companion selection, Scanner interaction,
and Kite riding/adaptations. Mica cannot cross a blocked route, protect the diver
from contact, stop time outside the existing BOND slow-time contract, or turn
knowledge into access.

## Validation And Review

Automation must prove source links, no copied patrol geometry, reachability,
profile compatibility, exact-once observation/memory/adaptation state, Scanner
authority, both jellyfish subjects, no hazard mutation, no rewards/access,
failure/reload/isolation, Kite regressions, and desktop/mobile controls.

The full release-candidate suite runs once after integrated evidence is ready.
Focused captures compare both review viewports and all accepted baseline
families without accepting replacements. Exact Web verification precedes the
owner gate. Only the owner may judge whether the living observation and useful
next-day adaptation make Mica worth choosing again.
