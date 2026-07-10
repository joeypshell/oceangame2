# OceanGame Expansion 03 Source Contract

Date: 2026-07-10

Issue: #708

Plan: `docs/current/OCEANGAME_EXPANSION_03_PLAN.md`

State: `docs/current/OCEANGAME_EXPANSION_03_STATE_CONTRACT.md`

## Scope

Expansion 03 adds three source concepts to a greybox map:

1. typed material candidate salvage entities at authored coordinates
2. ordered candidate pools selected deterministically by day
3. one material project linked to one cutter-gated salvage payoff

The source never stores selected, depleted, held, banked, completed, unlocked, seed, progress, score, oxygen, or UI state.

## Material Candidate Entity

Material slots remain `salvage` point entities so existing map bounds, terrain, reachability, rendering, and parity checks apply.

```json
{
  "id": "material_titanium_entry",
  "type": "salvage",
  "x": 20,
  "y": 24,
  "kind": "wreck_fragment",
  "interaction": "instant",
  "material_id": "titanium_scrap",
  "material_quantity": 1,
  "candidate_pool_id": "titanium_scrap_pool"
}
```

Rules:

- Supported materials are `titanium_scrap` and `conductive_coil`.
- `material_quantity` is exactly `1` in this pass.
- `candidate_pool_id` must reference one top-level pool whose `material_id` matches.
- The candidate id must appear exactly once in that pool's ordered `candidate_ids`.
- Candidate interaction is omitted/default instant or explicitly `instant`.
- Candidate entities must be in bounds, non-solid, and reachable from the authored entry.
- Material candidates add no source score, wallet, profile, or selection state.

## Candidate Pool

```json
{
  "id": "titanium_scrap_pool",
  "material_id": "titanium_scrap",
  "selection_strategy": "day_rotation_v1",
  "select_count": 2,
  "candidate_ids": [
    "material_titanium_entry",
    "material_titanium_crossing",
    "material_titanium_lower_loop",
    "material_titanium_return"
  ]
}
```

Rules:

- `candidate_ids` is the stable authored order. Runtime must not depend on entity/node iteration order.
- `day_rotation_v1` derives an offset from map id, pool id, and day number with the documented stable runtime algorithm, then selects `select_count` consecutive ids with wraparound.
- `select_count` is a positive integer no greater than the candidate count.
- `titanium_scrap` requires at least four candidates and selects two.
- `conductive_coil` requires at least two candidates and selects one.
- Candidate ids are unique within and across pools.
- Pools must guarantee at least the material quantities required by the project every day.
- Runtime may hide unselected slots; it may not move them or author alternatives.

## Material Project

```json
{
  "id": "salvage_cutter_project",
  "required_discovery_id": "lower_right_anomaly_discovery",
  "required_materials": {
    "titanium_scrap": 2,
    "conductive_coil": 1
  },
  "unlocks_capability_id": "salvage_cutter",
  "target_id": "salvage_sealed_wreck_cache",
  "build_phase": "night_debrief"
}
```

Expansion 03 supports exactly this project, discovery, recipe, capability, and build phase. This closed contract avoids creating a generic recipe language before one loop is proved.

The project id must be unique, the target must exist, and the selected pool yields must satisfy the full recipe.

## Cutter Target Entity

```json
{
  "id": "salvage_sealed_wreck_cache",
  "type": "salvage",
  "x": 48,
  "y": 36,
  "kind": "crate",
  "tier": "valuable",
  "interaction": "cutter_salvage",
  "interaction_seconds": 2.0,
  "interaction_label": "sealed wreck",
  "required_tool_id": "salvage_cutter",
  "tool_project_id": "salvage_cutter_project"
}
```

Rules:

- `cutter_salvage` is supported only on salvage entities.
- `interaction_seconds` is positive and `interaction_label` follows existing salvage label rules.
- `required_tool_id` is exactly `salvage_cutter`.
- `tool_project_id` references the sole project, and that project references this target.
- The target uses `tier: valuable` so it has an existing bankable payoff.
- The target may not also be a material candidate.
- It must be in bounds, non-solid, and reachable before the tool exists; the tool gates collection, not geography.

## Forbidden Source State

Material pools, projects, candidates, and the cutter target must not author:

- selected/active/depleted candidate ids or day seed
- held/banked material quantities or cargo capacity
- project ready/completed state or capability ownership
- interaction progress, collected state, result text, score, wallet, oxygen, or daylight
- profile/save paths, UI visibility/layout, terrain, collision, or generated coordinates

## Validation Entry Points

```powershell
python tools/test_validate_material_sources.py
python tools/validate_material_sources.py maps/production_slice_01.greybox.json
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
```

`validate_greybox_map.py` delegates this contract to the focused validator so normal release map validation remains authoritative without growing the 500-line owner.
