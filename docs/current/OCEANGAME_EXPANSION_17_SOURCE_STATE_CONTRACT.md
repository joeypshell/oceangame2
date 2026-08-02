# OceanGame Expansion 17 Source And State Contract

Date: 2026-08-02

Issues: #1158, corrected by #1181-#1184

Plan: `docs/current/OCEANGAME_EXPANSION_17_PLAN.md`

## Decision

Expansion 17 turns `far_west_deeper_wreck_discovery` into one investigation
with two parallel physical relay leads in existing `production_level_01`.
Either lead may be pinned for guidance, but both artifacts remain valid. Each
scan creates one pending fragment, each fragment commits only at the canonical
boat, and both committed fragments enable one automatic night comparison.

The analysis grants knowledge and a broad destination promise. It spends no
score or materials and grants no recipe, capability, cargo, or loaded-map
transition.

## Stable IDs

| Role | ID |
| --- | --- |
| investigation | `wreck_network_triangulation` |
| prerequisite discovery | `far_west_deeper_wreck_discovery` |
| west journey | `western_chasm_wreck_fragment_journey` |
| west artifact | `western_chasm_relay_artifact` |
| west survey | `western_chasm_wreck_fragment_survey` |
| west fragment discovery | `western_chasm_wreck_fragment_discovery` |
| west route capability | `current_stabilizer` |
| abyssal journey | `abyssal_shelf_wreck_fragment_journey` |
| abyssal artifact | `abyssal_shelf_relay_artifact` |
| abyssal survey | `abyssal_shelf_wreck_fragment_survey` |
| abyssal fragment discovery | `abyssal_shelf_wreck_fragment_discovery` |
| abyssal route capability | `pressure_suit_1` |
| scanner capability | `survey_scanner_1` |
| final discovery | `wreck_network_triangulation_discovery` |
| canonical map | `production_level_01` |
| canonical return | `surface_boat_entry` |
| review checkpoint | `expansion_17_start` |

Exact clear cells and review cameras belong to source authoring issue #1160.
They must be selected through footprint, reachability, route, and camera
validation rather than by editing generated JSON.

## Aggregate Source Contract

The map adds one top-level `wreck_network_investigations` collection. Its one
record normalizes the aggregate rule that existing journey and survey records
cannot express without duplicating truth:

```json
{
  "id": "wreck_network_triangulation",
  "required_discovery_id": "far_west_deeper_wreck_discovery",
  "fragment_discovery_ids": [
    "western_chasm_wreck_fragment_discovery",
    "abyssal_shelf_wreck_fragment_discovery"
  ],
  "analysis_discovery_id": "wreck_network_triangulation_discovery",
  "analysis_phase": "night_debrief",
  "analysis_label": "Compare transfer-hub coordinates",
  "analysis_result_label": "Transfer hub coordinates recovered",
  "next_lead_label": "Destination: transfer hub beyond mapped cave",
  "commit_map_id": "production_level_01",
  "commit_entry_id": "surface_boat_entry"
}
```

The array order is presentation order only. Runtime readiness is set-based and
must not infer a one-fragment-per-day sequence. The record owns no selected
lead, pending fragment, completed fragment, analysis readiness, completion
flag, profile data, UI visibility, score, material, or cargo state.

The focused source helper owns this record, two regional journeys, two
physical artifact presentations, two surveys, broad labels, camera tests,
review questions, and provenance. Generated JSON and SVG remain outputs.

## Journey And Artifact Contract

Both regional journeys use the existing `regional_journeys` shape:

- `required_discovery_id` is the shared far-west prerequisite
- `survey_target_id` references exactly one fragment survey
- `required_capability_id` names the route capability
- `route_context` is unique and matches the artifact's regional context
- `expedition_lead` supplies distinct broad label, summary, guidance, and order
- neither journey requires the other fragment or final analysis discovery

The west route combines durable `current_stabilizer` traversal with the active
scanner. The abyssal route combines durable `pressure_suit_1` survival with
the active scanner. Both capabilities are available before the shared
prerequisite can commit. Their use must be physically true of the authored
route, not decorative metadata.

Each artifact is a visible, non-solid wreck component with a stable identity.
It is not a generic ring, proximity reward, collision gate, connector, or
teleport. The survey points at its artifact id and uses:

```text
interaction = survey
interaction_seconds = 3.0
required_capability_id = survey_scanner_1
commit_map_id = production_level_01
commit_entry_id = surface_boat_entry
investigation_id = wreck_network_triangulation
```

The survey discovery id is the matching fragment id. Facing, range, held
scanner input, progress, release/leave cancellation, full-cargo independence,
and pending-finding behavior remain owned by existing scanner and discovery
owners.

## State And Transaction Contract

`ExpansionProfileState` stores the two fragment discovery ids and final
analysis discovery in its existing completed-discovery set. No profile schema
change or parallel save object is required.

`ExpeditionDiscoveryState` continues to own one pending discovery. A completed
fragment scan calls the existing pending transaction with source-authored
commit map/entry metadata. A second artifact cannot replace a pending fragment;
the player must return to the boat first. This is an existing one-pending-item
constraint, not an artificial daily lock.

At `surface_boat_entry`, the pending fragment commits exactly once through
`ExpansionProfileState.complete_discovery`. Wrong-map or wrong-entry contact
does nothing. Partial scan and pending state clear under existing oxygen,
combat, hazard, retry, and fresh-session failure semantics; committed profile
discoveries persist.

A focused `WreckNetworkInvestigationState` reads the aggregate record and
profile state to derive:

- whether the prerequisite is committed
- required, committed, and remaining fragment ids
- whether both coordinate halves are ready for night comparison
- whether final triangulation is already complete
- compact lead/result labels from source

Its analysis transaction succeeds only during debrief, after both fragments,
and before final completion. It calls the existing profile discovery
transaction once. It owns no profile storage, scanner progress, pending
discovery, plan selection, day transition, HUD node, or map mutation.

## Planning, Night, And Presentation

`ExpeditionLeadResolver` exposes both unresolved journeys after the shared
prerequisite. Committing one fragment removes only its resolved lead. Pinning
through `ExpeditionPlanState` changes compact guidance only; it never controls
target visibility, scanner eligibility, collision, or discovery validity.

`ExpeditionDayDebrief` invokes the comparison automatically when debrief
begins with both coordinate halves committed. It records the final discovery
once and presents the result without blocking next-day start behind `Q`,
`Space`, or mobile `USE`. Entering night remains deliberate; only the
redundant comparison command is removed.

Presentation projects source/state reports only:

- two distinguishable broad leads before either fragment
- selected lead guidance without an exact route line
- pending fragment return-to-boat feedback
- one-fragment remaining-lead feedback
- automatic two-fragment comparison result
- broad next promise with no separate command prompt

The final result is knowledge, not score, wallet value, salvage count, recipe,
capability, or unexplained inventory.

## Ownership

| Owner | Responsibility |
| --- | --- |
| Expansion 17 source helper | immutable investigation, journeys, artifacts, surveys, labels, review metadata |
| map/progression validators | schema, references, topology, capability order, aggregate dependencies |
| `GreyboxWorld` | source loading, artifact rendering, read-only collection queries |
| scanner owners | facing/range/hold progress, cancellation, physical-target feedback |
| `ExpeditionDiscoveryState` | one pending fragment and canonical boat commit |
| `ExpansionProfileState` | committed fragment and final discovery ids |
| `ExpeditionLeadResolver` | unresolved lead eligibility/readiness |
| `ExpeditionPlanState` | day-scoped guidance selection only |
| focused investigation state | fragment-set derivation and exact-once analysis transaction |
| night debrief/presentation | automatic transaction delegation and compact result projection |
| `main.gd` | initialization, delegation, and refresh only |

## Validation Obligations

Issues #1159-#1166 must prove:

- exact ids, fields, references, uniqueness, and forbidden mutable metadata
- the sole prerequisite and two-fragment final dependency
- capability availability before both fragment routes
- distinct labels, route contexts, and capability shapes
- physical non-solid targets with collision-active boat round trips
- selection-independent scanner eligibility
- held-scan cancellation and one-pending-fragment behavior
- failure cleanup and exact-once canonical boat commits
- automatic no-cost night comparison, no extra input gate, and profile reload
- focused journey smoke, desktop/mobile captures, intentional visual review,
  and exact-SHA public Web initialization

Issue #1167 remains open until the owner reports GO or HOLD. #52/#53 remain
deferred optional slice-03 presentation work.

## Non-Goals

No new recipe, capability, material, enemy, weapon, economy, inventory screen,
terrain, connector, teleport, loaded interior, exact route line, broad HUD
replacement, baseline reset, or Expansion 18 selection belongs to this pass.
