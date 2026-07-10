# Expansion 06 Combat Source Contract

Date: 2026-07-10

Issues: #769-#777

Player-review correction: #811

Plan: `docs/current/OCEANGAME_EXPANSION_06_PLAN.md`

## Decision

The first hostile is a top-level `hostile_encounters` record, separate from static `hazard` entities and top-level `moving_hazards`. The first weapon remains a normal top-level `material_projects` record with a hostile target link. Neither record owns mutable runtime state.

## Hostile Record

The only supported Expansion 06 shape is:

```json
{
  "id": "deep_cache_territorial_eel",
  "kind": "territorial_eel",
  "x": 66,
  "y": 74,
  "behavior": "territorial_lunge",
  "territory": {"x": 60, "y": 71, "w": 10, "h": 8},
  "warning_radius_tiles": 4.0,
  "warning_seconds": 0.75,
  "lunge_speed_tiles_per_second": 6.0,
  "lunge_seconds": 0.45,
  "recovery_seconds": 1.25,
  "contact_radius_tiles": 0.75,
  "health": 3,
  "contact_damage": 1,
  "required_weapon_capability_id": "shock_prod",
  "warning_label": "Territorial eel - watch the lunge",
  "retreat_label": "Eel guarding cache - return with shock prod",
  "defeated_label": "Territory clear for today",
  "route_context": "deep_cache_pressure",
  "intent": "One territorial encounter hard-guarding the deep-right cache in unchanged geometry."
}
```

The exact home/territory coordinates shown here remain selected. #811 changes only the cache's progression metadata and opening objective membership; it does not move terrain, hazards, salvage, materials, or route topology.

#815 supersedes the original hard-lock decision. `salvage_deep_right_cache` owns only `guarded_by_hostile_id: deep_cache_territorial_eel` alongside normal timed-salvage metadata. It must not own `required_capability_id`, `locked_label`, or `guard_active_label`; eel contact and knockback behavior interrupt the attempt instead of cargo code rejecting it.

## Hostile Validation

- `hostile_encounters` is optional and must be an array.
- Every record uses exactly the fields above; `intent` is optional but recommended.
- `id` is nonempty and unique across all hostile, moving-hazard, entity, zone, survey, connector, and project ids.
- `kind`, `behavior`, and `required_weapon_capability_id` must equal the one supported values.
- Home point and every territory cell are in map bounds. Home must be non-solid and inside the territory.
- `territory` uses integer `x`, `y`, `w`, `h`; width/height are positive.
- All timing/radius/speed values are finite and positive. `health` is exactly 3 and `contact_damage` exactly 1 for this bounded pass.
- Labels are compact display-safe strings. `route_context` must match the selected deep-cache pressure route.
- The encounter, cache, and survey remain physically reachable; physical reachability does not bypass the cache's gameplay gate.
- The guarded cache must be timed salvage inside the territory, carry the behavioral guard link, omit hard collection-lock fields, and remain absent from every pre-weapon route objective.
- A source-derived lower-edge route remains viable for retreat without making the guarded payoff collectable.

Reject fields such as `current_health`, `current_position`, `phase`, `phase_timer`, `defeated`, `spawn_chance`, `seed`, `loot`, `drops`, `reward`, `score`, `cargo`, `wallet`, `discovery_id`, `runtime_state`, or arbitrary attack lists.

## Weapon Project Record

Append this one source-ordered record after `current_stabilizer_project`:

```json
{
  "id": "shock_prod_project",
  "required_project_id": "current_stabilizer_project",
  "required_discovery_id": "lower_right_anomaly_discovery",
  "required_materials": {"titanium_scrap": 2, "conductive_coil": 1},
  "unlocks_capability_id": "shock_prod",
  "target_hostile_id": "deep_cache_territorial_eel",
  "build_phase": "night_debrief",
  "project_label": "Shock prod project",
  "completion_label": "Shock prod built"
}
```

Project validation must prove:

- the required project/discovery/material/capability/target ids are exact and supported
- the hostile target exists and requires the same capability
- the prerequisite project chain is acyclic and source ordered
- both required materials already have guaranteed non-hostile authored candidate sources
- the recipe does not require a hostile, biological drop, score, wallet, salvage, or new material type
- labels are compact and source-owned; runtime does not branch on display text

The profile structure remains unchanged. Validator/runtime allowlists expand with one project and capability id while schema version remains 3.

## World And Renderer Boundary

- `greybox_world.gd` parses immutable records and delegates visuals to a focused hostile renderer.
- The renderer creates one node keyed by source id and draws a readable eel silhouette, warning/attack tint, and compact territory cue from source/runtime presentation state.
- The renderer does not create collision or mutate terrain. Contact uses the focused hostile controller's source-derived center/radius query.
- World APIs expose hostile source copies and narrow center/state visual setters. They never expose another subsystem's mutable dictionary by reference.
- Debug/review overlays may show the territory rectangle and id only when existing debug mode is enabled.

## Source-Of-Truth Workflow

1. Add a focused `tools/production_slice_01_expansion_06.py` module.
2. Aggregate its hostile/project records in the existing slice-01 generator.
3. Regenerate `maps/production_slice_01.greybox.json` and `references/greybox/production_slice_01.svg`.
4. Run focused schema tests, map validation, reachability, evade-lane validation, and terrain/collision parity.
5. Regenerate a second time and require a clean diff.
6. Use Godot capture only after source validation passes.

Do not hand-edit generated JSON, SVG topology, Godot polygons, terrain, collision, or accepted screenshots to place or move the encounter.
