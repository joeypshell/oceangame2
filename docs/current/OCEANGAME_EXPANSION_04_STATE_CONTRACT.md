# OceanGame Expansion 04 State Contract

Date: 2026-07-10

Issue: #727 `Define Expansion 04 project, profile, and gate ownership`

Plan: `docs/current/OCEANGAME_EXPANSION_04_PLAN.md`

## Decision

Expansion 04 extends the existing profile/project/current owners; it does not add a parallel upgrade or inventory system.

- `current_stabilizer_project` is the second source-ordered night project.
- `current_stabilizer` is a durable profile capability unlocked only by that project transaction.
- `propulsion_fins` remains a session-only wallet upgrade and continues to own only the legacy lower-left connector gate.
- The upper-right current pocket is source state plus derived runtime presentation. It has no mutable open/closed save flag.
- The authored payoff uses existing salvage, sortie, cargo, failure, offload, and score owners.

## Durable Profile Schema

Expansion 04 advances the profile to schema version 3 without adding fields. The supported id sets grow; the stored shape remains:

```json
{
  "schema_version": 3,
  "completed_discoveries": [],
  "unlocked_capabilities": [],
  "material_inventory": {},
  "completed_projects": []
}
```

Supported Expansion 04 ids:

- project: `current_stabilizer_project`
- capability: `current_stabilizer`
- prerequisite project: `salvage_cutter_project`
- prerequisite discovery: `lower_right_anomaly_discovery`
- materials: `titanium_scrap`, `conductive_coil`

The project and capability form an exact pair. A payload containing only one is invalid. A completed stabilizer pair without the completed cutter pair is also invalid.

## Migration

`expansion_profile_state.gd` owns all migration and validation.

| Input | Result |
| --- | --- |
| Missing profile | Fresh in-memory schema-v3 state. |
| Valid schema v1 | Preserve scanner/discovery; initialize materials/projects; save as v3 on next write. |
| Valid schema v2 | Preserve discoveries, capabilities, materials, and cutter project; save as v3 on next write. |
| Valid schema v3 | Load without semantic change. |
| Invalid pair/prerequisite/id | Reject as `invalid_schema`; do not partially load. |
| Interrupted atomic write | Preserve the existing backup/recovery behavior. |

Migration must not synthesize the stabilizer. Only a completed project transaction may add it.

## Project Catalog Ownership

The source map owns ordered project definitions. `material_project_runtime.gd` owns the derived catalog state for the loaded boat-hub map.

Project order is:

1. `salvage_cutter_project`
2. `current_stabilizer_project`

The active project is the first source-ordered incomplete project. A later project cannot bypass an incomplete `required_project_id`.

For the active project, the runtime derives:

- `unavailable`: source definition missing or invalid
- `prerequisite_required`: prior project incomplete
- `knowledge_required`: discovery incomplete
- `incomplete`: banked material recipe incomplete
- `ready`: all prerequisites met during any active/debrief phase
- `completed`: exact project/capability pair present
- `inconsistent_profile`: pair or prerequisite invariant broken

`P` during debrief attempts only the active project. `P` outside debrief is ignored by the debrief owner. Building does not start the next day; `N` retains that responsibility.

There is no selection cursor, recipe list, queue, equip state, durability, charge, or build timer.

## Stabilizer Transaction

`expansion_profile_state.gd` owns the atomic transaction:

1. Validate the source project definition and supported ids.
2. Require the completed cutter project/capability pair.
3. Require `lower_right_anomaly_discovery`.
4. Require exactly 2 banked titanium and 1 banked coil.
5. Snapshot material, completed-project, and capability dictionaries.
6. Consume the exact recipe.
7. Add `current_stabilizer_project` and `current_stabilizer` together.
8. Save atomically when persistence is enabled.
9. Restore all snapshots if saving fails.

Repeated completion returns `already_completed` and consumes nothing. Direct `unlock_capability("current_stabilizer")` returns `project_transaction_required`.

## Gate Requirement Ownership

The source gate owns exactly one requirement field:

- legacy gate: `required_upgrade_id: propulsion_fins`
- Expansion 04 gate: `required_capability_id: current_stabilizer`

`current_gate_controller.gd` owns requirement extraction, blocked/unblocked state, pushback, and prompt text. It receives separate read-only callbacks for session upgrades and durable capabilities; it does not own either state.

`main.gd` may adapt those callbacks and present the result. It must not store a second current-gate unlock flag.

The world owner exposes gate source data and derived pixel bounds. A focused renderer may derive current arrows/lines from the source record, but it stores no progression state.

## Runtime State Matrix

| State | Owner | Cross-map | Next day | Reset/failure | Profile reload |
| --- | --- | --- | --- | --- | --- |
| Banked materials | profile | yes | yes | preserved | yes |
| Completed cutter project/capability | profile | yes | yes | preserved | yes |
| Completed stabilizer project/capability | profile | yes | yes | preserved | yes |
| Project catalog/readiness | material-project runtime | reload from source/profile | recompute | recompute | recompute |
| Session `propulsion_fins` | session progression | current session | current session only | existing behavior | no |
| Current push/prompt | current-gate controller | reset per map | recompute | clear | recompute |
| Current affordance | world renderer | source-derived | source-derived | unchanged | source-derived |
| Held payoff | sortie/cargo | existing connector rules | cleared/committed by day rules | restore to world | no |
| Banked payoff/score | existing run/day/profile owners | existing rules | existing rules | preserved | existing rules |

## Failure And Day Rules

- Oxygen failure, hazard recovery, manual reset, and forced night clear current interaction/prompt state.
- Those paths never remove a completed project or durable capability.
- A cargo-full payoff remains visible and uncollected.
- An unbanked collected payoff returns to the world after recoverable failure/reset under existing salvage rules.
- Boat banking remains the only successful payoff commit path in the default slice.
- Day changes rotate material candidates through the existing day owner; project/capability state remains durable.
- Current crossing itself has no persistent consumed/open state. Owning the capability is sufficient on every return.

## Source And Validator Responsibilities

Source owns:

- project order and ids
- prerequisite project/discovery
- exact recipe
- gate requirement kind/id
- gate geometry, direction, strength, label, and route context
- payoff id, position, tier, and route role

Validators reject:

- both or neither current requirement fields
- unsupported capability/project ids
- missing, forward-invalid, self, or circular project prerequisites
- mismatched project-to-gate backlinks
- recipes not guaranteed by candidate pools
- solid, out-of-bounds, or unreachable gate/payoff source
- runtime/profile fields in source

Runtime must not invent coordinates, alter topology, or serialize source-derived gate geometry.

## Required Verification

- schema-v1 to v3 migration
- schema-v2 to v3 migration preserving cutter/material state
- valid v3 reload with both project/capability pairs
- invalid missing-pair and missing-prerequisite payloads
- direct-unlock rejection
- cutter prerequisite, discovery prerequisite, and material prerequisite ordering
- exact recipe consumption, repeated-build no-op, and save-failure rollback
- legacy session gate and new durable gate resolved by separate owners
- reset/day/connector/profile durability
- cargo-full/failure/boat payoff behavior through existing owners

Every new or edited focused source file should remain under 500 lines. `main.gd` may gain only minimal delegation when no existing hook can route the callbacks.
