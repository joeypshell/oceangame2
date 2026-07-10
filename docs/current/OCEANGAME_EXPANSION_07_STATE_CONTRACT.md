# Expansion 07 Biological State Contract

Date: 2026-07-10

Issues: #790-#799

Plan: `OCEANGAME_EXPANSION_07_PLAN.md`

## Decision

Expansion 07 adds one focused biological interaction owner and extends existing typed material/project allowlists. It does not create a biological inventory, loot system, generalized ecology manager, or second combat owner.

## Ownership

| State | Owner | Lifetime |
| --- | --- | --- |
| Immutable biological source records and rendered handles | world source/renderer helpers | loaded map |
| Active source id, interaction progress, current-day collected ids | focused biological interaction owner | expedition day |
| Held biological entries and quantities | existing material cargo state | unbanked expedition cargo |
| Banked biological quantities | existing expansion profile material inventory | durable profile |
| Project recipe/readiness/spend/text | existing material project runtime | source plus profile |
| Capacitor project/capability completion | existing expansion profile state | durable profile |
| Eel phase, position, health, and current-day defeat | existing territorial hostile controller | expedition day |
| Shock-prod range, cooldown, damage, and attack result | existing shock-prod controller | scene runtime |
| Cargo capacity, oxygen, health, daylight, connector, and failure state | existing focused owners | unchanged |
| Delegation and compact presentation composition | `main.gd` | scene runtime |

## Biological Interaction State

- On map load, immutable records are copied from the world. Source dictionaries are never mutated by reference.
- One interaction may be active at a time. It tracks source id and elapsed seconds only.
- Staying in collection range advances progress. Leaving range, losing eligibility, loading another map, reset, or failure cancels progress to zero.
- The passive source is eligible only when the scanner capability is present and the source is not collected for the current day.
- The hostile source is eligible only when its linked hostile is defeated for the current day and the source is not collected.
- Completion first checks shared cargo capacity. A full cargo reports blocking, keeps progress at completion-ready or resets it according to the focused owner, and never depletes the source.
- Successful completion adds one normal material cargo entry, marks the source collected for the current day, hides its affordance, and clears progress.
- Hostile defeat does not call collect, mutate cargo, or mark the harvest source collected.

## Cargo, Banking, And Restoration

- `insulating_gel` and `eel_electrocyte` use `material_quantity: 1` entries in the existing `MaterialCargoState`.
- Salvage plus all held materials share the existing capacity calculation.
- Boat commitment deposits all held typed materials atomically through `ExpansionProfileState.deposit_materials()` and clears held entries only after success.
- Connector travel preserves held entries and current-day collected ids; in-progress interaction cancels.
- Hazard, oxygen failure, combat defeat, and manual reset restore held biological source ids through the same unbanked-material path.
- If an eel electrocyte is restored after combat/reset also restores the eel, its source stays unavailable until the eel is defeated again. No material is lost or duplicated.
- Nightfall away from the boat discards unbanked cargo under existing semantics. The next fresh day replenishes both sources.
- Boat return, map reload within the day, and connector travel do not replenish collected sources.

## Day Replenishment

- The focused owner keeps collected ids in day state or another day-local owner with equivalent connector-preserved lifetime.
- `begin_next_day()` clears the biological collected set and interaction progress.
- The hostile controller independently restores the eel on a fresh day. The two resets are coordinated by orchestration but do not share mutable dictionaries.
- Banked profile quantities and completed project/capability remain unchanged across days.

## Project And Profile State

- Existing profile schema version 3 remains valid because payload shape is unchanged.
- Supported ids expand with `insulating_gel`, `eel_electrocyte`, `shock_prod_capacitor_project`, and `shock_prod_capacitor`.
- A completed capacitor project and unlocked capability must exist together, as with existing project/capability pairs.
- The project transaction validates source definition, prerequisite project, existing knowledge, exact material quantities, and night phase before mutating profile state.
- It deducts one conductive coil, one insulating gel, and one eel electrocyte and adds project/capability in one persisted transaction. Storage failure restores the previous payload.
- Rebuilding an already completed project does not spend materials.

## Tactical Interrupt

- `ShockProdController` remains the attack/cooldown owner and asks the profile/project facade whether the capacitor is unlocked.
- `TerritorialHostileController.apply_weapon_hit()` remains the only combat-health mutation path.
- A capacitor-enabled hit requests interruption. The hostile accepts it only when its pre-hit phase is `warning` or `lunge` and it survives the 1 damage.
- Accepted interruption sets phase to `recovery`, resets phase seconds to the source-authored recovery duration, preserves current position, and reports `interrupted: true`.
- A defeating hit remains `defeated`, not recovery. Hits in home, recovery, returning, or without the capability report `interrupted: false`.
- Attack range stays 72 px, cooldown stays 0.65 seconds, damage stays 1, eel health stays 3, and normal lunge/contact rules remain unchanged.

## Presentation Priority

Compact feedback uses existing overlay/result surfaces:

1. combat defeat or oxygen failure
2. accepted damage or successful `Lunge interrupted`
3. hostile warning/lunge/retreat
4. biological interaction progress or cargo-full block
5. biological collection/banking note
6. normal route/material/project cues

The fixed material line may compactly include `Bio Gel` and `Electro` banked/held counts when either source exists or either quantity is nonzero. Weapon text becomes `Shock prod +capacitor ready` when unlocked. No inventory, recipe tree, damage numbers, target reticle, or creature catalog is added.

## Failure And Reset Invariants

- Nonlethal sampling never changes health, oxygen, hostile phase, score, wallet, or discoveries.
- Eel defeat never grants cargo or profile state.
- Biological interaction time does not pause oxygen or daylight.
- Cargo-full, cancel, failure, connector, map reload, night, and new-day transitions cannot duplicate a source quantity.
- Existing banked salvage/materials, score, projects, capabilities, discoveries, day number, and connector state retain their current owners.
- Static hazards and moving jellyfish retain their existing semantics and never expose hostile harvest materials.

## Deterministic Reports

Focused state/smoke reports include active source id, progress/required seconds, eligible/collected ids, held and banked biological quantities, linked hostile phase/health/defeat, project/capability state, interrupt result, cargo capacity, oxygen, daylight, and failure reason. Reports use ids and numeric state, not display text, for assertions.
