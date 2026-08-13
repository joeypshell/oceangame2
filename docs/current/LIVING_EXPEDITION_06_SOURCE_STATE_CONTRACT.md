# Living Expedition 06 Source And State Contract

Date: 2026-08-13

Issue: #1366 `Lock Living Expedition 06 Signal Reef source and state contract`

Status: implementation contract for milestone #50. Schema, source, profile,
runtime, evidence, and owner review land separately through #1367-#1375.

## Purpose

Living Expedition 06 returns already-adapted Kite to the existing Signal Reef.
One guaranteed juvenile filter-skate school is being displaced from its nursery.
The player's selected Kite adaptation provides one deliberate response inside
already-accessible geography, the result remains pending until canonical-boat
return, and the following day visibly remembers the pair's action.

This contract adds no fourth species, new adaptation, equipment, reward,
topology, broad ecosystem simulation, or slice-03 work.

## Stable IDs

| Role | ID |
| --- | --- |
| Existing species | `spark_ray` |
| Existing individual | `spark_ray_juvenile_01` |
| Existing callsign | `Kite` |
| Journey | `signal_reef_nursery_journey_01` |
| Passive school | `signal_reef_filter_skate_school_01` |
| Nursery | `signal_reef_filter_skate_nursery_01` |
| Non-damaging pressure | `signal_reef_jellyfish_pressure_01` |
| Anchor adaptation | `anchor_fins` |
| Existing Anchor action | `anchor_brace` |
| Anchor context | `spark_ray_anchor_nursery_context_01` |
| Guardian adaptation | `guardian_pulse` |
| Existing Guardian action | `guardian_pulse_action` |
| Guardian context | `spark_ray_guardian_nursery_context_01` |
| Commitment event | `signal_reef_nursery_commit_01` |
| Source map | `production_level_01` |
| Canonical commit entry | `surface_boat_entry` |

These ids become immutable once generated source or profile fixtures use them.
Player-facing labels may improve without changing ids.

## Existing Geography And Access

The journey relates to existing source records rather than replacing them:

- regional route `east_current_signal_reef_route`;
- current gates `lower_right_west_current_gate` and
  `lower_right_east_current_gate`;
- landmark `lower_right_signal_reef_landmark`;
- dark zone `signal_reef_deep_harmonic_dark_zone`; and
- canonical entry `surface_boat_entry`.

Both response contexts require existing `propulsion_fins` and `dive_light_1`.
Those systems remain the only hard-access authority. Kite, riding, Glide Surge,
Anchor Fins, and Guardian Pulse cannot satisfy, disable, or bypass either gate.
The optional nursery journey cannot become a prerequisite for a route, project,
resource, discovery, rescue, or later companion.

## Immutable Map Source Ownership

`tools/production_level_01_living_expedition_06.py` owns the immutable records
for the journey, school, nursery, pressure context, adaptation contexts, review
cameras, stable relationships, availability, and source provenance. It is a
composable transform called by `tools/create_production_level_01_map.py`.

The normal pipeline generates:

- `maps/production_level_01.greybox.json`;
- `references/greybox/production_level_01.svg`; and
- generated progression-review output.

Generated JSON and SVG are never edited as ownership. The transform must report
zero terrain changes and preserve existing collision, entities, gates, routes,
wildlife, resources, salvage, cameras, boat, and extraction.

The school and both response contexts use
`availability: all_supported_seeds`. The filter skates are passive unbondable
wildlife: they are not hostile, collectible, harvestable, cargo, companions, or
a source of score, materials, blueprints, discoveries, or hidden rewards.

Map JSON must not contain mutable journey phase, action progress, selected
branch, commitment, restoration, companion state, cooldown, or day state.

## Review IDs And States

The source owns these focused cameras:

- `living_expedition_06_approach_review_01`;
- `living_expedition_06_anchor_review_01`;
- `living_expedition_06_guardian_review_01`;
- `living_expedition_06_pending_return_review_01`; and
- `living_expedition_06_restored_review_01`.

The runtime exposes these state names for smoke, capture, and guidance:

- `unresolved`: school is visibly under pressure and neither action is active;
- `anchor_active`: matching Kite is deliberately bracing in the Anchor context;
- `guardian_active`: matching Kite is deliberately pulsing the pressure context;
- `sheltered_pending_return`: the school reached the nursery this sortie;
- `committed_waiting_next_day`: boat commitment succeeded exactly once; and
- `restored`: a later day shows the occupied nursery and Kite recognition.

Review checkpoints are `living_expedition_06_anchor_ready`,
`living_expedition_06_guardian_ready`, and
`living_expedition_06_restored_nursery`. They use isolated in-memory profiles,
spawn the pair in open water, and never read or write the normal profile.

## Persistent Profile Ownership

A focused versioned regional-journey subrecord composed by
`ExpansionProfileState` is the sole durable owner. Its bounded payload records:

- schema version;
- journey id and commitment event id;
- Kite individual id;
- the selected adaptation id used to resolve the field event;
- exact-once committed state and committed day number; and
- next-day restored state and restoration day number.

No state is written when the field action succeeds. The canonical boat may
commit `signal_reef_nursery_commit_01` only for pending
`signal_reef_nursery_journey_01`, matching Kite, and one of the two contracted
adaptations. Full cargo cannot block or alter this non-cargo transaction.

Repeated boat checks return `already_committed` without another history write.
The existing next-day transition marks the committed result restored only on a
later day and persists that transition. Reload then retains the committed or
restored state. Legacy profiles without the subrecord migrate to a valid empty
record and must not invent completion or change any Kite, Mica, or Marl data.

`CompanionProfileState` remains authoritative for Kite's identity, commitment,
active selection, memories, and mutually exclusive selected adaptation. The
regional-journey subrecord references that state; it does not duplicate it.

## Transient Runtime Ownership

A focused Signal Reef nursery runtime owns only current-sortie state:

- source records and selected response context;
- school pressure phase, movement, and shelter progress;
- local action handoff and immediate school response;
- unresolved versus sheltered-pending-return phase; and
- compact result data needed by guidance, smoke, and capture.

Focused world presentation projects the source-authored school, nursery,
pressure, movement, and restored state. It does not write profile data or
change collision.

Existing `CompanionAnchorFinsRuntime` and `CompanionGuardianPulseRuntime` remain
authoritative for matching-adaptation eligibility, independent/mounted dispatch,
action timing, cooldown, BOND palette/hotbar ownership, and visual action cues.
The nursery coordinator observes a successful action in its matching authored
context. It must not duplicate action logic, auto-fire, add a key, or reinterpret
an eel hit as nursery success.

Anchor Fins creates a visible lee and guides the school to shelter. Guardian
Pulse deliberately displaces the non-damaging jellyfish pressure long enough
for the same school to cross; it causes zero damage and no drop. Both produce
the same pending journey while preserving the adaptation id used.

## Failure, Retry, Reload, And Cargo

- Leaving or cancelling an action follows the existing adaptation owner's rules
  and does not complete the nursery response.
- Oxygen failure, health failure, manual Retry, map teardown, abandoned sortie,
  or reload before boat commitment discards the pending field result and
  restores the source-authored unresolved school.
- A committed history survives Retry and reload. It becomes restored only after
  the existing later-day transition records that change.
- Reload never restores active action progress, pressure phase, cooldown,
  movement target, selected context, or pending uncommitted success.
- Full cargo neither blocks the action nor changes held/banked cargo.
- The event grants no score, cargo, material, blueprint, recipe, discovery,
  capability, adaptation, or companion record.

## Preserved Authorities

Existing owners remain authoritative for Propulsion Fins, Dive Light, pressure
protection, oxygen, daylight, health, collision, boat detection, day transition,
active companion selection, riding, mounted controls, BOND whole-simulation
tactical pause, action dispatch, cargo, banking, and failure. The nursery proof
may consume read-only reports or narrow success signals; it may not replace
those owners.

Mica, Marl, unadapted Kite, and wrong-adaptation Kite may visit the complete
region. They receive clear non-completion but lose no access. Both response
branches remain optional within the same already-accessible geography.

## Non-Goals And Review Boundary

No fourth species, rescue, breeding, stable expansion, new adaptation,
equipment, reward, topology change, teleport, broad ecology simulation, combat
rewrite, creature health/death, generic quest system, HUD redesign, accepted-
baseline sweep, or #52/#53 work belongs in this milestone.

Automation must prove source relationships, all-seed availability, access-gate
authority, branch behavior, failure cleanup, exact-once commitment, next-day
restoration, reload, controls, visual evidence, and exact Web deployment. Only
the owner may decide whether the remembered nursery makes Kite and Signal Reef
worth revisiting.
