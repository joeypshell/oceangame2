# Expansion 07 Biological Source Contract

Date: 2026-07-10

Issues: #790-#799

Plan: `OCEANGAME_EXPANSION_07_PLAN.md`

## Decision

Add one optional top-level `biological_resource_sources` list. These records describe immutable source identity, interaction, material yield, replenishment, labels, and either a point or hostile link. They are separate from normal salvage, generic material candidates, surveys, hazards, and hostile mutable state.

## Passive Source

```json
{
  "id": "upper_right_glow_anemone_sample",
  "source_role": "passive_sample",
  "organism_kind": "glow_anemone",
  "x": 68,
  "y": 41,
  "required_capability_id": "survey_scanner_1",
  "interaction": "timed_sample",
  "interaction_seconds": 1.5,
  "material_id": "insulating_gel",
  "material_quantity": 1,
  "replenishment": "new_day",
  "display_label": "Glow anemone",
  "interaction_label": "Sampling glow anemone",
  "collected_label": "Insulating gel held",
  "route_context": "upper_right_current_pocket",
  "intent": "One nonlethal biological sample beyond the remembered current gate."
}
```

The planned `(71, 42)` point proved solid, and the next eastward point was out of slice bounds. `(68, 41)` is the canonical nearest in-bounds, open, reachable, non-overlapping point east of the same upper-right gate; terrain and the gate remain unchanged.

## Hostile Harvest Source

```json
{
  "id": "deep_cache_eel_electrocyte_harvest",
  "source_role": "hostile_harvest",
  "organism_kind": "territorial_eel",
  "hostile_id": "deep_cache_territorial_eel",
  "interaction": "post_defeat_harvest",
  "interaction_seconds": 1.5,
  "material_id": "eel_electrocyte",
  "material_quantity": 1,
  "replenishment": "new_day",
  "display_label": "Eel electrocyte",
  "interaction_label": "Harvesting electrocyte",
  "collected_label": "Electrocyte held",
  "route_context": "deep_cache_pressure",
  "intent": "One explicit harvest from the existing eel after current-day defeat."
}
```

Its runtime center derives from the linked hostile's defeated position. Source does not author another point, drop chance, corpse position, or mutable availability.

## Capacitor Project

Append this source-ordered project after `shock_prod_project`:

```json
{
  "id": "shock_prod_capacitor_project",
  "required_project_id": "shock_prod_project",
  "required_discovery_id": "lower_right_anomaly_discovery",
  "required_materials": {
    "conductive_coil": 1,
    "insulating_gel": 1,
    "eel_electrocyte": 1
  },
  "unlocks_capability_id": "shock_prod_capacitor",
  "target_hostile_id": "deep_cache_territorial_eel",
  "capability_effect": "interrupt_warning_lunge",
  "build_phase": "night_debrief",
  "project_label": "Shock-prod capacitor project",
  "completion_label": "Shock-prod capacitor built"
}
```

The profile payload shape and schema version remain unchanged. Only supported material, project, capability, and project-rule allowlists expand.

## Validation Rules

- `biological_resource_sources` is optional and must be an array with at most the two supported records in this milestone.
- Ids are nonempty lower-snake-case and unique across all top-level source collections.
- Only exact locked roles, organism kinds, interactions, material ids, quantities, replenishment, capability/hostile links, and route contexts are supported.
- Timings are finite and positive; quantities equal 1; labels are short and display-safe.
- A passive source has integer `x`/`y`, no `hostile_id`, and requires `survey_scanner_1`.
- A hostile harvest has exact `hostile_id`, no `x`/`y` or capability field, and links to the existing territorial eel.
- Passive placement is in bounds, non-solid, reachable after the existing current-stabilizer gate, and does not overlap the cache, survey, hazard, hostile home, or another interaction center.
- The hostile, its unarmed evade lane, and its existing payoffs remain reachable. The harvest link cannot make defeat mandatory for existing progression.
- Both sources replenish on `new_day`; random spawn, quantity ranges, seed weights, and permanent depletion are unsupported.
- The project follows `shock_prod_project`, uses the exact recipe, targets the linked eel, and cannot be completed before the base weapon exists.
- Every mandatory input has a guaranteed source. One fresh day can provide one of each biological input.

Reject fields such as `available`, `collected`, `progress`, `current_position`, `defeated`, `current_health`, `spawn_chance`, `drop_chance`, `loot`, `drops`, `reward`, `score`, `wallet`, `cargo`, `seed`, `runtime_state`, `inventory`, or arbitrary effect/attack lists.

## World And Renderer Boundary

- The world coordinator exposes duplicated source records and narrow source-center/visibility/state APIs.
- A focused renderer draws one readable passive organism and one defeated-harvest affordance. It does not create collision or change terrain.
- The hostile harvest visual follows the linked runtime hostile center and remains hidden before defeat or after current-day collection.
- Debug review may label source ids only in existing debug mode.

## Source Workflow

1. Add `tools/production_slice_01_expansion_07.py`.
2. Compose its biological records and project through `production_slice_01_expansions.py`.
3. Regenerate slice-01 JSON and SVG.
4. Run focused schema tests, full map validation, reachability, parity, and preview review.
5. Regenerate a second time and require a clean diff.
6. Use Godot smoke/capture only after source validation passes.

Do not hand-edit generated JSON/SVG, Godot polygons, terrain, collision, accepted captures, or the existing hostile to author these records.
