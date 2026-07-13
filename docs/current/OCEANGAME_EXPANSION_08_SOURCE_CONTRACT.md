# Expansion 08 Daily Condition Source Contract

Date: 2026-07-13

Issue: #838

Plan: `OCEANGAME_EXPANSION_08_PLAN.md`

## Decision

Add one optional top-level `daily_conditions` list and two narrow condition links. Omitted metadata preserves every existing map and runtime path.

```json
{
  "daily_conditions": [
    {
      "id": "southwest_jellyfish_bloom",
      "schedule": "even_days_v1",
      "forecast_label": "Tomorrow: Southwest jellyfish bloom",
      "active_label": "Southwest bloom: jellyfish + coil trace",
      "route_context": "southwest_pocket_decision",
      "intent": "Forecast one optional southwest risk-reward opportunity."
    }
  ]
}
```

`even_days_v1` is inactive on odd expedition days and active on even days. Source does not store current day, selected condition, forecast state, depletion, or visibility.

## Optional Bonus Pool

The exact pool is:

```json
{
  "id": "southwest_bloom_coil_bonus_pool",
  "material_id": "conductive_coil",
  "selection_strategy": "day_rotation_v1",
  "select_count": 1,
  "candidate_ids": ["material_coil_southwest_bloom"],
  "pool_role": "optional_bonus",
  "daily_condition_id": "southwest_jellyfish_bloom"
}
```

The candidate remains a normal `material_candidate` linked to that pool. The pool is selected only while its condition is active. Its yield is excluded from all mandatory recipe-floor calculations and progression requirements; existing unconditional pools must satisfy every project under every day state.

## Migration Patrol

`southwest_bloom_jellyfish_patrol` remains a normal `linear_patrol` moving-hazard record with one additional field:

```json
{
  "daily_condition_id": "southwest_jellyfish_bloom"
}
```

The patrol must use `kind: jellyfish` and `route_context: southwest_pocket_decision`. Its full authored path follows the existing moving-hazard contract. `deep_route_jellyfish_patrol` remains unconditional and must not gain condition metadata.

## Validation Rules

- The collection is optional. A present collection contains exactly the one locked condition in this pass.
- Ids use lower_snake_case, labels are compact single-line text, and the schedule/route/labels match the plan.
- Condition ids are unique across source collections.
- `daily_condition_id` is supported only on material pools and moving hazards; `pool_role` is supported only on material pools.
- The one condition links to exactly the locked bonus pool and migration patrol. Dangling, duplicate, or misplaced links fail.
- The bonus pool uses exactly one locked conductive-coil candidate and `pool_role: optional_bonus`.
- Optional bonus yield never contributes to project guarantee validation or mandatory progression-graph propagation.
- Existing material and moving-hazard validators still own candidate metadata, open/reachable placement, patrol bounds/path reachability, and runtime-field rejection.
- Fields such as `active`, `current_day`, `next_condition`, `selected`, `depleted`, `visible`, `spawned`, `cargo`, `profile_state`, or arbitrary weights/effects are forbidden.

## Source Workflow

1. Add a focused Expansion 08 generator module and compose it through the established slice-01 path.
2. Regenerate JSON and SVG.
3. Run focused condition tests, full map validation, parity/reachability, and the progression audit.
4. Regenerate again and require a clean diff.
5. Use Godot smoke/capture only after source validation passes.

Do not hand-edit generated JSON/SVG, terrain, collision, Godot polygons, camera tests, or accepted baselines.
