# OceanGame Expansion 03 State Contract

Date: 2026-07-10

Issue: #707

Plan: `docs/current/OCEANGAME_EXPANSION_03_PLAN.md`

## Purpose

This contract separates material state by lifetime before runtime implementation. It adds one typed material-to-project path without turning score, wallet, cargo, maps, or the profile into a general inventory system.

## State Lifetimes

| State | Lifetime | Owner | Persistent |
| --- | --- | --- | --- |
| Held material entries | current expedition until boat commit/failure | focused material cargo owner | no |
| Selected candidate ids by map | current day | expedition day state | no |
| Depleted candidate ids by map | current day | expedition day state | no |
| Day material seed | current day | expedition day state | no |
| Banked material quantities | profile | expansion profile state | yes |
| Completed project ids | profile | expansion profile state | yes |
| Cutter capability | profile | expansion profile state | yes |
| Knowledge/discovery | profile | existing expansion profile state | yes |
| Score cargo and score | current run/session | existing sortie/main owners | no change |
| Wallet and legacy upgrades | current session | existing session progression | no change |

No candidate, held cargo, project-progress, daylight, oxygen, score, wallet, or map-local state is written to the profile.

## Focused Owners

### Expedition Day State

`scripts/main/expedition_day_state.gd` stores:

- `material_day_seed`
- selected candidate ids keyed by map and pool
- depleted candidate ids keyed by map

It resets this material-day state only in `begin_day`. Connector transitions and map reloads preserve it. Selection logic belongs in a small pure helper so the day owner stores results without becoming a source parser.

### Material Cargo Runtime

A focused helper under `scripts/main/` owns:

- held material entries keyed by source candidate id
- held quantities by material id
- candidate pickup and restoration coordination
- connector preservation
- canonical-boat deposit requests
- compact held/banked reports for presentation and smoke

Each held entry records candidate id, map id, material id, and quantity. This supports exact restoration without guessing which source slot produced an item.

### Expansion Profile State

`scripts/main/expansion_profile_state.gd` owns the only durable additions:

```json
{
  "schema_version": 2,
  "completed_discoveries": [],
  "unlocked_capabilities": [],
  "material_inventory": {
    "titanium_scrap": 0,
    "conductive_coil": 0
  },
  "completed_projects": []
}
```

Supported additions are deliberately closed:

- materials: `titanium_scrap`, `conductive_coil`
- project: `salvage_cutter_project`
- capability: `salvage_cutter`

Zero quantities may be omitted from serialized output if validation treats omission as zero. Negative, fractional, unknown, or non-numeric quantities are invalid.

### Project Runtime

A focused project helper reads profile state and owns:

- recipe definition
- knowledge/material readiness
- exact-once build transaction
- compact debrief text

The recipe is not map state and is not inferred from UI text. Source schema may name the project/tool requirement, while the supported recipe remains one explicit runtime/profile contract for this pass.

### Main And Existing Owners

- `main.gd` delegates selection, collection, commit, project input, and presentation. It does not own material dictionaries or recipe truth.
- `sortie_state.gd` keeps existing oxygen and salvage cargo semantics. Cargo-capacity checks use existing held salvage plus material held count.
- `offload_controller.gd` keeps legacy salvage offload behavior. A separate material commit is attempted only when the world reports the canonical boat.
- `expedition_day_debrief.gd` routes `P` to the project helper and `N` to the existing next-day path.
- `greybox_world.gd` exposes source metadata/availability queries; it does not choose the daily seed or own durable depletion.

## Candidate Selection And Depletion

1. On first load of a map during a day, a pure selector receives map id, pool metadata, authored ordered candidate ids, and the day number/seed.
2. It returns an exact valid selected set for each pool.
3. The day state stores that set and returns it on every same-day reload.
4. The world shows selected, non-depleted candidates and hides unselected/depleted candidates.
5. Pickup marks the candidate depleted in day state and adds one held entry.
6. Recoverable failure removes the held entry, clears that candidate's depleted mark, and restores the same source slot.
7. Successful canonical-boat commit clears held entries but keeps their candidate ids depleted for the rest of the day.

The selector never reads wall-clock time, platform RNG, node order, or generated coordinates.

## Cargo Capacity And Value

```text
occupied cargo = held salvage count + held material unit count
```

- Every material candidate yields one unit and occupies one slot.
- Materials have zero salvage score and zero wallet payout.
- A full hold blocks material pickup and cutter payoff collection without hiding or depleting the source target.
- Existing cargo upgrades increase the shared capacity exactly as they do for salvage.
- Normal salvage remains in `sortie_state`; material entries remain in the focused material owner.
- Project consumption happens only from profile-banked materials, never held cargo.

## Travel And Commitment

### Connector Transition

Unbanked materials travel with the diver through source-authored connectors. Selected/depleted day state also survives the map change. Arrival does not commit or discard material cargo.

### Relay Or Generic Base Extraction

Relay/base extraction may preserve existing normal salvage offload behavior. It does not commit, consume, or clear typed materials. This keeps the canonical-boat return meaningful without rewriting historical map behavior in this pass.

### Canonical Boat

Material commitment requires all of:

- current map id is `production_slice_01`
- world reports the player inside the authored `boat_spawn` rectangle
- held material count is greater than zero

Open surface outside the boat and generic extraction zones do not qualify.

The deposit transaction adds all held quantities to profile inventory and saves once. On success, held entries clear and remain depleted for that day. On storage failure, profile changes roll back and held entries remain available for retry.

Normal salvage offload remains independent; a material storage failure does not roll back an already valid score-bank transaction.

## Failure And Reset Matrix

| Transition | Held materials | Day selection/depletion | Profile materials/tool |
| --- | --- | --- | --- |
| Connector | preserve | preserve | unchanged |
| Relay/base entry | preserve | preserve | unchanged |
| Canonical boat | commit then clear | selected pickups stay depleted | deposit atomically |
| Hazard recovery | clear and restore source slots | same-day set preserved | unchanged |
| Oxygen depletion | clear and restore source slots | same-day set preserved until day resolves | unchanged |
| Manual run reset | clear and restore source slots | same-day set preserved | unchanged |
| Voluntary night at boat | commit before debrief | day ends | durable state preserved |
| Nightfall at boat | commit before debrief | day ends | durable state preserved |
| Forced nightfall away | clear without commit | discarded with ended day | unchanged |
| Start next day | empty | recompute for next day | durable state preserved |
| Map reload, same day | preserve | reuse stored ids/depletion | unchanged |
| Profile reload | no held state | no day state | reload validated durable state |

## Project Transaction

The project is ready only when:

- `lower_right_anomaly_discovery` is committed in the profile
- profile has at least 2 `titanium_scrap`
- profile has at least 1 `conductive_coil`
- `salvage_cutter_project` is not complete
- `salvage_cutter` is not already unlocked

On `P` during debrief:

1. Revalidate all requirements.
2. Snapshot material inventory, completed projects, and capabilities.
3. Subtract exactly 2 titanium and 1 coil.
4. Add the project and cutter capability.
5. Save the profile once.
6. On failure, restore the snapshot and report storage failure.

Repeated input after success is idempotent and consumes nothing. Building does not alter wallet, score, day totals, salvage, discovery, or automatically start the next day.

## Profile Migration

- Schema v1 is the only legacy version accepted for migration.
- A valid v1 profile migrates in memory to v2 with empty material inventory and completed projects while preserving scanner capability and completed anomaly discovery.
- The migrated profile is written as v2 on the next successful durable mutation; loading alone need not rewrite disk.
- Invalid JSON, unknown legacy schema versions, unsupported ids, or invalid quantities preserve the existing safe-empty fallback/report behavior.
- Atomic temp/backup recovery remains unchanged.

## Presentation Boundary

The existing overlay may show compact material state only when relevant. The debrief may show one cutter-project line plus the existing next-day action. UI text is derived from owner reports and never becomes state.

No inventory panel, material grid, recipe list, crafting tree, tool slot, save selector, or wallet/material exchange is introduced.

## Verification Contract

Focused checks must prove:

- deterministic selected ids and same-day reload stability
- valid next-day reselection and guaranteed recipe quantities
- combined cargo capacity and zero score/wallet material value
- connector preservation and relay non-commit
- canonical-boat exact-once deposit plus storage rollback
- hazard, oxygen, reset, and forced-night cleanup/restoration
- v1-to-v2 migration, invalid-schema fallback, and profile reload
- project knowledge/material gating, atomic consumption, idempotence, and durable cutter
- existing score cargo, scanner/discovery, daylight, and debrief behavior remain unchanged
