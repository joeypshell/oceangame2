# Living Expedition 01 Map Schema

Status: source/schema contract for milestone #45. Runtime support and final
`production_level_01` placement remain separate issues.

## Boundary

`config/creature_catalog.json` is the immutable source for species, actions,
memories, and adaptations. Generated map JSON may place opportunities and link
them to that catalog; it never owns rescued, committed, mounted, selected,
earned, progress, cooldown, or other profile/runtime state.

All first-proof creature map records are optional as a group. A map with none
retains existing behavior. Once any collection is present, the complete Spark
Ray proof relationship must validate.

## Immutable Catalog

The version-1 catalog defines only `spark_ray` and uses globally unique ids.

Species records require:

- `id`, `display_name`, and supported `roles`
- boolean `ride_capable`
- positive `rider_footprint_px` and `dismount_clearance_px` dimensions
- `base_action_ids`, `memory_ids`, and `adaptation_ids`

Action records require `id`, role list, `effect_kind`, and boolean `damaging`.
Memory records bind one `event_kind` to legal `adaptation_ids`. Adaptation
records bind one `required_memory_id`, independent and mounted action ids, and a
symmetric `mutually_exclusive_with` list.

The first catalog contains:

| Kind | IDs |
| --- | --- |
| Species | `spark_ray` |
| Base action | `glide_surge` |
| Adaptation actions | `anchor_brace`, `guardian_pulse_action` |
| Memories | `held_the_flow`, `stood_ground` |
| Adaptations | `anchor_fins`, `guardian_pulse` |

The catalog remains `implementation_status: proposed` until the corresponding
runtime issue lands. Progression reports use the same visible status.

## Map Collections

Every record requires a unique lower_snake_case `id` and
`availability: all_supported_seeds`. Required progression cannot use a daily
condition, random spawn chance, seed, or weight.

### Creature Rescues

Top-level `creature_rescues` contains exactly `spark_ray_rescue_01` for the
first proof. It requires:

- `species_id: spark_ray` and `individual_id: spark_ray_juvenile_01`
- point `x` and `y`
- `rescue_kind: physical_aid`
- one existing `required_capability_id` representing the understood diver verb
- source-map `commit_map_id` and canonical boat `commit_entry_id`
- `riding_review_context_id` linked to the mounted route review

The record describes the physical opportunity and commit destination. It does
not declare whether rescue or commitment has happened.

### Companion Contexts

Top-level `companion_contexts` supports three focused `context_kind` values:

- `mounted_route_review`
- `independent_action_review`
- `mounted_action_review`

Every context requires `species_id`, `action_id`, and guaranteed availability.
Action-review contexts also require `required_adaptation_id` and `target_id`.
The role implied by the context must be supported by the action and adaptation.

The first mounted route is `spark_ray_riding_review_01`. It uses a base mounted
action, at least two ordered tile-space `route_points`, a
`required_access_ids` list, and a reviewed clear `dismount` point:

```json
{
  "id": "spark_ray_riding_review_01",
  "context_kind": "mounted_route_review",
  "species_id": "spark_ray",
  "action_id": "glide_surge",
  "route_points": [{"x": 10, "y": 20}, {"x": 14, "y": 20}],
  "required_access_ids": [],
  "dismount": {"outcome": "clear", "x": 14, "y": 20},
  "availability": "all_supported_seeds"
}
```

Validation applies the catalog rider footprint to every authored segment. Any
equipment-gate rectangle crossed by the route must have its requirement in
`required_access_ids`. The dismount point uses the catalog clearance footprint.

### Memory Opportunities

Top-level `creature_memory_opportunities` contains exactly:

- `spark_ray_current_memory_01` -> `held_the_flow`
- `spark_ray_eel_memory_01` -> `stood_ground`

Each record requires `species_id`, `individual_id`, catalog `event_kind`,
`target_id`, legal `adaptation_ids`, `payoff_id`, and guaranteed availability.
The current memory targets a source-authored current gate. The hostile memory
targets a source-authored hostile encounter. A memory may not require the
adaptation it awards.

### Adaptation Payoffs

Top-level `creature_adaptation_payoffs` contains exactly:

- `spark_ray_anchor_current_01` -> `anchor_fins`
- `spark_ray_guardian_eel_01` -> `guardian_pulse`

Each payoff requires `species_id`, `adaptation_id`, `target_id`,
`required_access_ids`, `independent_context_id`, `mounted_context_id`, and
guaranteed availability. Both contexts must target the same source record and
use the catalog action for their role. A payoff must retain every equipment
requirement already owned by its target.

## Validation

Run:

```bash
python tools/validate_greybox_map.py maps/production_level_01.greybox.json
python tools/test_validate_living_expedition_schema.py
python tools/test_progression_graph_creatures.py
python tools/audit_progression_graph.py
```

The focused fixtures cover duplicate and dangling ids, invalid catalog
relationships, circular adaptation requirements, mutable state, seed-dependent
required records, malformed payoff links, rider clipping, equipment bypass, and
missing dismount outcomes.
