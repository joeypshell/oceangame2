# Expansion 07 Player Gate Correction

Date: 2026-07-10

Issue: #815

Status: implemented correction contract; #799 remains the player GO/HOLD gate.

## Decision

Correct the reviewed journey without adding a new region, economy, crafting UI, or Expansion 08 content:

1. `salvage_deep_right_cache` is guarded by encounter behavior, not a collection permission.
2. `propulsion_fins` is durable equipment built from ingredients, not bought with score.
3. The lower-left relay current has a source-derived normal-world affordance.
4. The fins build uses the existing night debrief for this correction only; future blueprint research timing remains undecided.

## Behavioral Eel Guard

The deep cache remains normal `timed_salvage` with a 2.5-second continuous interaction and `guarded_by_hostile_id: deep_cache_territorial_eel`.

- It does not author `required_capability_id`, `locked_label`, or `guard_active_label`.
- An unarmed diver may start normal salvage progress.
- Eel warning, lunge, contact, damage, and knockback interrupt the in-progress attempt before completion.
- Defeating the eel lets the same target finish through normal cargo, failure restoration, and boat banking.
- `guarded_by_hostile_id` records the encounter relationship for validation and review; it is not a hidden capability check in cargo collection.

## Fins Recipe And Sources

`propulsion_fins_project` is known from the start and requires exactly:

```text
2 titanium_scrap + 1 rubber_sheet
```

The project has no discovery prerequisite, builds only in `night_debrief`, consumes materials atomically, spends no wallet, and unlocks durable profile capability `propulsion_fins`.

Guaranteed pre-eel source pools in `production_slice_01`:

| Material | Pool guarantee | Authored candidates |
| --- | --- | --- |
| `titanium_scrap` | select 2 of 4 each day | `material_titanium_entry` (42,22), `material_titanium_crossing` (55,30), `material_titanium_return` (23,59), `material_titanium_lower_loop` (15,69) |
| `rubber_sheet` | select 1 of 2 each day | `material_rubber_entry` (43,22), `material_rubber_lower_loop` (16,69) |

All candidates must remain reachable from the boat without collecting the eel cache. The progression graph and material validator enforce the guaranteed counts and project backlink.

## Relay Readability

`lower_left_loop_current` uses `required_capability_id: propulsion_fins` and overlaps the existing `lower_left_loop_connector`. Its label is `Lower-left relay current`; the connector label is `Lower-left relay`.

The world renderer derives current arrows for every authored current gate, regardless of whether its requirement owner is a session upgrade or durable profile capability. Before fins, the current pushes right and feedback names the fins requirement. After fins, the same visible location presents `E` for the relay connector. The east `upper_right_current_pocket_gate` remains a distinct left-pushing, swim-through `current_stabilizer` gate.

## Durable Progression Rule

Equipment projects use explicit ingredients. Score may later gate access to blueprint research, but it must not replace recipe materials. Existing direct-score oxygen, cargo, light, and scanner paths are migration debt and are outside this correction.

This pass does not decide whether future blueprints consume an overnight research step or whether every known recipe must wait for debrief. It only locks the current fins recipe to the already-supported debrief transaction so the reviewed journey is explicit and testable.

## Verification Contract

- Source regeneration, map validation, parity, and progression audit prove placement and non-circularity.
- Material state checks prove exact spend, direct-unlock rejection, idempotence, and profile/day persistence.
- Current-gate and anomaly journeys prove guaranteed acquisition, unchanged wallet, visible affordance, and connector use.
- Combat coverage proves an unarmed attempt starts, active eel behavior interrupts it, and armed completion/banking succeeds.
- #799 repeats the player journey after the merged Web build and remains the only GO/HOLD closeout.
