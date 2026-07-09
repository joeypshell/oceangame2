# Map Spec

## Purpose

The map must be a data source, not a screenshot to imitate. The game scene should render from authored map data so the in-game result can match the plan.

## First Map

Working name: `cave_salvage_test_01`

Current source:

```text
maps/cave_salvage_test_01.greybox.json
```

Current preview:

```text
references/greybox/cave_salvage_test_01.svg
```

Recommended size:

- Width: about 80 tiles.
- Height: about 45 tiles.
- Tile size: 32x32 pixels.

This is the gameplay/collision grid, not the final visible art scale.

## Required Areas

The first map should include:

- Base or extraction zone.
- Open water swim corridor.
- Grid-aligned cave floors, walls, ceilings, ledges, and arch-like terrain.
- Safe return/extraction point.
- Salvage cluster.
- Hazard cluster.
- Clear return path.
- Background depth silhouettes that do not affect collision.

## Placeholder Tile Meanings

Use simple greybox colors before final art:

- Open water: cyan or blue.
- Solid collision terrain: dark gray.
- One-way/pass-through ledge if used: purple.
- Base/extraction: brown or white.
- Salvage: yellow.
- Hazard: red.
- Player start: green.

## Debug Review Marker Roles

Normal previews should keep debug markers subtle or hidden. When `--show-debug-overlay` is enabled:

- Cyan grid/source overlay: authored map cells.
- White translucent rectangles: route or review marker zones.
- Amber outlines/labels: boat or extraction return rectangles.
- Green diamonds/labels: player entry or spawn cells.
- Yellow diamonds/labels: salvage entities.
- Red squares/labels: hazard entities.

## Spawn And Extraction Entities

Maps must define exactly one player entry entity:

- `spawn`: legacy in-water start cell for small test maps.
- `boat_spawn`: preferred top-water entry and extraction marker for production-style maps.

A `boat_spawn` entity has these required fields:

```json
{
  "id": "surface_boat_entry",
  "type": "boat_spawn",
  "x": 91,
  "y": 0,
  "w": 8,
  "h": 1,
  "entry_x": 91,
  "entry_y": 0,
  "facing": "right"
}
```

`x`, `y`, `w`, and `h` describe the boat/extraction rectangle in tile coordinates. `entry_x` and `entry_y` describe the open-water cell where the player actually starts and re-enters the map. The entry cell must be inside the boat rectangle, inside map bounds, non-solid, and reachable through open water.

Existing base/extraction zones remain valid. When a `boat_spawn` is present, runtime extraction checks also treat the boat rectangle as a valid return point. Production-style maps should render the boat rectangle as a readable surface craft, hatch, dock, or similar top-water marker so players can identify both expedition entry and salvage return without relying on debug overlays.

In-water `base` extraction zones should render as readable relay, sub, dock, or return-field visuals. If a legacy `spawn` point sits inside the base zone, the normal preview may add a small entry cue at the authored spawn cell. These visuals communicate start and return semantics only; they must not change collision, spawn coordinates, extraction bounds, salvage, hazards, or terrain topology by eye.

## Entity Semantics

Every authored entity must include:

- `id`: unique lower_snake_case identifier within the map's `entities` list.
- `type`: one of `spawn`, `boat_spawn`, `salvage`, or `hazard`.
- `x`, `y`: integer tile coordinates for point entities.

`spawn` is a legacy point entity:

```json
{
  "id": "player_start",
  "type": "spawn",
  "x": 9,
  "y": 31,
  "facing": "right"
}
```

`salvage` entities require `kind`. Current valid-style examples are `crate`, `wreck_fragment`, `relic`, and `stress_marker`. `stress_marker` is reserved for renderer/test maps and is not treated as a production salvage objective.
Production previews may use `kind` to choose first-pass prop art, but collection behavior is still determined by `type: "salvage"`.

Playable salvage may also include an optional `tier` field. If omitted, runtime and validation should treat the salvage as `common`. Supported tiers are:

- `common`: default salvage payoff/readability. Current prototype score value: 100.
- `valuable`: higher-payoff route-choice salvage. Current prototype score value: 300. Use sparingly so it reads as an authored decision point, not clutter. Normal previews render a small extra cue on top of the existing salvage prop.

Runtime salvage score is currently derived from `tier`, not from per-entity authored score values. Held salvage score banks only when the player returns to extraction; oxygen or hazard resets restore held pickups and clear their held score. Completed expeditions may add a small runtime oxygen bonus based on remaining oxygen, but that bonus is not authored in map data and does not change salvage banking semantics.

Collection feedback should name the tier-derived payoff in compact status text: common salvage reports its common score, and valuable salvage reports that it is valuable with its higher score.

Playable salvage may also include optional interaction metadata. If omitted, runtime and validation should treat the pickup as `instant`.

- `interaction`: optional interaction type. Supported values are `instant`, `timed_salvage`, and `pry_salvage`.
- `interaction_seconds`: required for `timed_salvage` and `pry_salvage`; must be a positive number of seconds.
- `pry_stages`: required for `pry_salvage`; must be a positive integer count of completed pry stages required before collection.
- `interaction_label`: optional compact label for overlay/capture text. Use lower_snake_case or short display-safe text.

Interaction metadata is intentionally narrow: an interacted pickup remains a normal salvage entity for placement, reachability, cargo, score, banking, route metadata, hazard reset, oxygen failure, and primary-objective rules. The only source-authored difference is that runtime may require the player to complete the authored interaction before the pickup enters held cargo. Interaction metadata is supported on salvage entities only.

A `timed_salvage` pickup uses `interaction_seconds` as one continuous in-range duration. Leaving range cancels the current timed progress according to runtime rules, and completing the duration allows the pickup to enter held cargo if capacity permits.

```json
{
  "id": "salvage_deep_right_cache",
  "type": "salvage",
  "x": 64,
  "y": 75,
  "kind": "relic",
  "tier": "valuable",
  "interaction": "timed_salvage",
  "interaction_seconds": 2.5,
  "interaction_label": "deep cache"
}
```

A `pry_salvage` pickup uses `interaction_seconds` as the duration of each pry stage and `pry_stages` as the required stage count. Completed pry stages may persist during normal exploration, while leaving range cancels only the current partial stage. Manual reset, hazard reset, or oxygen failure may clear uncollected pry progress. If all stages complete while cargo is full, the target must remain available and uncollected until cargo space is freed.

Recommended Pass 17 metadata:

```json
{
  "id": "salvage_pry_locker",
  "type": "salvage",
  "x": 36,
  "y": 64,
  "kind": "crate",
  "tier": "valuable",
  "interaction": "pry_salvage",
  "interaction_seconds": 1.2,
  "pry_stages": 3,
  "interaction_label": "sealed cache"
}
```

Interaction metadata must not author terrain topology, collision changes, score values, oxygen values, cargo limits, progress state, completion state, or primary-objective state.

Playable salvage may also include optional route-choice metadata. These fields are source annotations for validation, smoke tests, and review tooling; they do not change collision or collection behavior by themselves.

- `route_choice_id`: lower_snake_case id for this pickup's route/payoff role, such as `lower_loop_payoff`.
- `validation_route`: lower_snake_case id grouping pickups that should be validated by the same route smoke, such as `expanded_route_choice`.
- `route_order`: optional zero-or-greater integer for deterministic route traversal when a smoke should collect multiple targets in source-authored order.

Route-choice metadata is currently supported on salvage entities only. A route-tagged salvage entity must still satisfy normal salvage validation: it needs a valid `kind`, optional valid `tier`, in-bounds coordinates, non-solid placement, and reachability from the player entry cell.

For small optional detours, prefer a dedicated `validation_route` instead of reusing a broader route group. For example, the Pass 09 southwest pocket decision should tag its pocket payoff with a route id such as `southwest_pocket_decision` and a specific `route_choice_id` such as `southwest_pocket_detour`. This keeps deterministic smokes focused on the authored detour while preserving the existing safe/deep route metadata.

```json
{
  "id": "salvage_center_crossing",
  "type": "salvage",
  "x": 46,
  "y": 30,
  "kind": "wreck_fragment",
  "tier": "valuable",
  "route_choice_id": "central_payoff",
  "validation_route": "expanded_route_choice",
  "route_order": 1
}
```

## Route Commitment Objectives

Playable maps may include optional route commitment objectives under a top-level
`route_objectives` list. These records describe a compact run objective that
references existing source-authored salvage and marker ids. They do not create
new collision, collection behavior, scoring, oxygen, cargo, extraction, or
visual art by themselves.

Start-of-run objective cues should derive from these same objective records plus
runtime extraction/boat context. Pass 14 does not add separate cue metadata:
`id`, `label`, and `required_banked_targets` are sufficient for the compact
start cue, while runtime decides whether the player is currently in the
start/extraction area.

The first supported objective is intentionally narrow:

- `id`: unique lower_snake_case objective id.
- `route_context`: lower_snake_case route grouping.
- `label`: compact display-safe text for overlay/result surfaces.
- `required_banked_targets`: non-empty list of unique salvage entity ids that must be banked at extraction.
- `supporting_marker_ids`: optional list of unique marker zone ids for smoke/capture framing.
- `intent`: optional human-readable source intent.

Recommended Pass 13 metadata:

```json
{
  "id": "deep_cache_route_objective",
  "route_context": "deep_cache_commitment",
  "label": "Deep cache route",
  "required_banked_targets": [
    "salvage_lower_loop",
    "salvage_deep_right_cache"
  ],
  "supporting_marker_ids": [
    "lower_loop_route",
    "lower_loop_to_deep_cache_pressure",
    "lower_loop_oxygen_rest_pocket",
    "return_pressure_to_boat"
  ],
  "intent": "Pass 13 route commitment objective requiring the player to bank the lower-loop payoff and timed deep-right cache in one committed route chain."
}
```

Validation expectations:

- `route_objectives`, when present, must be a list.
- Each objective id must be unique and lower_snake_case.
- Each required target id must refer to an existing playable salvage entity, not a `stress_marker`.
- Required target salvage must still satisfy normal in-bounds, non-solid, reachable entity validation.
- Supporting marker ids, when present, must refer to existing `marker` zones with in-bounds rectangles and at least one reachable open cell.
- Objective records must not author coordinates, score values, oxygen values, cargo limits, runtime progress, completion state, or result text state.
- Objective cue visibility state must not be authored in map data; it is derived from existing objective metadata and runtime player/extraction state.
- `production_slice_01` should author only one Pass 13 route commitment objective.

## Primary Dive Objective Selection

Playable maps may optionally choose one route objective as the primary dive
completion objective with a top-level `primary_route_objective_id` field.

The field is a pointer to an existing `route_objectives` record. It does not
create a new objective, duplicate required targets, or author runtime state.
Runtime may use it to decide whether extraction completes the current run:

- When omitted, legacy behavior remains valid: the run completes after all
  playable salvage is banked.
- When present, returning to extraction may complete the run after the referenced
  route objective's `required_banked_targets` have been banked.
- Returning with partial or optional cargo should still bank that cargo and keep
  the dive active.

Recommended Pass 16 metadata:

```json
{
  "primary_route_objective_id": "deep_cache_route_objective"
}
```

Validation expectations:

- `primary_route_objective_id`, when present, must be a lower_snake_case string.
- The id must reference an existing route objective in `route_objectives`.
- The referenced route objective must satisfy normal route-objective validation.
- The source must not author completion flags, progress state, score values,
  oxygen values, cargo limits, result text state, or duplicate required target
  lists for the primary objective.

## Objective Step Cue Markers

Playable maps may include one optional objective-step cue marker under `zones`. This is a source-authored readability cue for an existing route objective, not a new objective, pickup, reward, or route.

The first supported cue is intentionally narrow:

- `type`: must be `marker`.
- `objective_step_cue`: must be `true`.
- `objective_id`: required route objective id.
- `target_id`: required playable salvage id that is included in the objective's `required_banked_targets`.
- `route_context`: required lower_snake_case route grouping that matches the objective's `route_context`.
- `objective_step_label`: required compact display-safe text.

The marker id should also appear in the referenced objective's `supporting_marker_ids` list so smoke and capture tooling can discover the cue as part of the objective context. The marker rectangle must stay in bounds, contain reachable open water, and must not overlap the boat/extraction area. It must not move salvage, change collision, create terrain, change score, alter cargo, or author objective completion state.

Recommended Pass 15 metadata:

```json
{
  "id": "deep_cache_first_step_cue",
  "type": "marker",
  "x": 28,
  "y": 58,
  "w": 4,
  "h": 3,
  "objective_step_cue": true,
  "objective_id": "deep_cache_route_objective",
  "target_id": "salvage_lower_loop",
  "route_context": "deep_cache_commitment",
  "objective_step_label": "Lower loop",
  "intent": "Pass 15 objective follow-through cue for the first required deep-cache route target."
}
```

## Oxygen Rest Markers

Playable maps may include one optional oxygen rest marker under `zones`. This is a source-authored route-pressure aid, not a second extraction zone.

The first supported rest marker is intentionally narrow:

- `type`: must be `marker`.
- `oxygen_rest`: must be `true` when rest metadata is present.
- `route_context`: optional lower_snake_case route grouping, such as `oxygen_rest_pressure`.
- `oxygen_rest_label`: optional compact label for overlay/capture text. Use lower_snake_case or short display-safe text.
- `oxygen_rest_cap_seconds`: required positive number; must not exceed the normal oxygen maximum.
- `oxygen_rest_refill_per_second`: required positive number.

The marker rectangle must stay inside map bounds, contain only non-solid reachable water cells, and remain source-authored through the map generator/source path. Runtime may use it to refill oxygen up to the authored cap while the player is inside the rectangle. It must not bank cargo, complete the expedition, create collision, move salvage, change score, or replace boat/base extraction.

```json
{
  "id": "lower_loop_oxygen_rest_pocket",
  "type": "marker",
  "x": 27,
  "y": 60,
  "w": 8,
  "h": 5,
  "route_context": "oxygen_rest_pressure",
  "oxygen_rest": true,
  "oxygen_rest_label": "Rest pocket",
  "oxygen_rest_cap_seconds": 45,
  "oxygen_rest_refill_per_second": 8
}
```

## World Connector Markers

Playable maps may include optional world connector markers under `zones`. A connector marker describes one source-authored transition point from the current map to another committed greybox map. It is a world-slice expansion cue, not terrain stitching, fast travel, a map screen, or persistent save data.

The first supported connector is intentionally narrow:

- `type`: must be `marker`.
- `world_connector`: must be `true` when connector metadata is present.
- zone `id`: connector id; must be unique and lower_snake_case.
- `connector_label`: compact display-safe text for overlay/capture text.
- `destination_map_id`: lower_snake_case id of the destination map.
- `destination_map_path`: committed `res://maps/*.greybox.json` destination path.
- `destination_entry_id`: existing `spawn` or `boat_spawn` id in the destination map.
- `connector_direction`: optional `forward`, `return`, or `bidirectional`; defaults conceptually to `forward`.

The marker rectangle must stay in bounds, contain only non-solid reachable water cells, and remain source-authored through the map generator/source path. Runtime may use it to show a compact prompt and load the destination map at the authored destination entry. It must not author score, wallet, cargo, oxygen, objective progress, save state, or collision changes.

Recommended Pass 21 metadata:

```json
{
  "id": "lower_left_loop_connector",
  "type": "marker",
  "x": 20,
  "y": 70,
  "w": 4,
  "h": 4,
  "world_connector": true,
  "connector_label": "Lower-left loop",
  "destination_map_id": "production_slice_04",
  "destination_map_path": "res://maps/production_slice_04.greybox.json",
  "destination_entry_id": "relay_sub_entry",
  "connector_direction": "forward",
  "intent": "Pass 21 connector from the default boat hub toward the lower-left loop reference slice."
}
```

## Current Gate Markers

Playable maps may include optional current gate markers under `zones`. A current gate is a source-authored water volume that pushes against entry or return travel until the player has the required movement upgrade. It is route pressure, not terrain collision.

The first supported current gate is intentionally narrow:

- `type`: must be `marker`.
- `current_gate`: must be `true` when current metadata is present.
- zone `id`: current gate id; must be unique and lower_snake_case.
- `current_direction`: required `left`, `right`, `up`, or `down`; this is the direction the water pushes the diver.
- `current_strength`: required positive number; prototype runtime treats it as a relative pushback strength.
- `required_upgrade_id`: required lower_snake_case upgrade id that disables or overcomes the current.
- `current_gate_label`: optional compact label for overlay/capture text. Use lower_snake_case or short display-safe text.
- `route_context`: optional lower_snake_case route grouping for smoke/capture discovery.

First runtime behavior should be soft pushback before the required upgrade, not hard no-entry and not an oxygen/time penalty. The marker rectangle must stay in bounds, contain only non-solid reachable water cells, and remain source-authored through the map generator/source path. It must not author collision, terrain edits, score, wallet, cargo, oxygen values, objective completion, upgrade ownership, save state, or destination loading.

Recommended first placement is one current gate near the `production_slice_01` to `production_slice_04` connection or inside `production_slice_04`'s return route, where it can make the new connected route feel like a meaningful place without expanding the full map.

Recommended metadata:

```json
{
  "id": "lower_loop_return_current",
  "type": "marker",
  "x": 38,
  "y": 68,
  "w": 5,
  "h": 4,
  "current_gate": true,
  "current_direction": "left",
  "current_strength": 1.0,
  "required_upgrade_id": "propulsion_fins",
  "current_gate_label": "Strong current",
  "route_context": "lower_loop_return"
}
```

## Progression Containers

Future chest/cache progression metadata is defined in `docs/current/LOCKED_CACHE_PROGRESSION_CONTRACT.md`. Use a top-level `progression_containers` list for upgrade chests, key chests, and locked salvage caches so they stay separate from terrain collision, marker-only route rectangles, and normal salvage entities.

The first implementation target is one `upgrade_chest` in `production_slice_01` that grants a small session wallet/reward beat without adding inventory UI, persistent keys, loot tables, or save-heavy state.

Future darkness/light metadata is defined in `docs/current/DEPTH_DARKNESS_LIGHT_GATE_CONTRACT.md`. First-pass visibility zones should be visual-only marker zones, not terrain, collision, oxygen, pickup, or objective gates.

`hazard` entities are static point hazards and require `kind`. Current valid-style examples are `mine`, `jellyfish`, and `stress_marker`.
Moving hazards are defined separately in `docs/current/MOVING_HAZARD_DODGE_CONTRACT.md` using top-level `moving_hazards`; production previews may use `kind` to choose first-pass prop art, but hazard behavior is still source-driven.

```json
{
  "id": "hazard_crossing_choke",
  "type": "hazard",
  "x": 52,
  "y": 34,
  "kind": "mine"
}
```

Validation expectations:

- Entity ids must be unique.
- Entity ids and kinds use lower_snake_case.
- Salvage `tier`, when present, must be `common` or `valuable`.
- Salvage interaction metadata, when present, must use supported fields: `interaction` as `instant`, `timed_salvage`, or `pry_salvage`; positive numeric `interaction_seconds` for timed or pry salvage; positive integer `pry_stages` for pry salvage; and optional lower_snake_case or short display-safe `interaction_label`.
- Salvage route-choice metadata, when present, must use supported fields: lower_snake_case `route_choice_id`, lower_snake_case `validation_route`, and/or integer `route_order` greater than or equal to zero.
- Route commitment objectives, when present, must reference existing reachable playable salvage ids and optional reachable marker zones without authoring runtime state.
- Objective-step cue metadata is supported only on marker zones. Cue rectangles must be in bounds, non-solid, reachable, outside the boat/extraction area, linked to an existing objective, and targeted at a required playable salvage id.
- Oxygen rest metadata is supported only on marker zones. Rest rectangles must be in bounds, non-solid, reachable, and use positive cap/refill values.
- World connector metadata is supported only on marker zones. Connector rectangles must be in bounds, non-solid, reachable, and reference a committed destination map plus an existing destination `spawn` or `boat_spawn` entry id.
- Current gate metadata is supported only on marker zones. Current rectangles must be in bounds, non-solid, reachable, use a supported direction, positive strength, and a lower_snake_case required upgrade id.
- Progression containers should follow `docs/current/LOCKED_CACHE_PROGRESSION_CONTRACT.md` and must not author terrain, collision, runtime opened state, save state, oxygen values, cargo limits, or UI layout.
- Moving hazards should follow `docs/current/MOVING_HAZARD_DODGE_CONTRACT.md` and must not author combat, AI state, health, loot, save state, oxygen penalty values, or collision changes.
- Entity coordinates must be inside map bounds, non-solid, and reachable from the player entry cell.
- Maps must define exactly one `spawn` or `boat_spawn`.
- Playable salvage maps must define a base extraction zone or use `boat_spawn` extraction. Renderer stress-test maps may use `stress_marker` salvage without an extraction zone.

## Source Of Truth Options

Use Godot `TileMapLayer` for the first prototype.

The TileMapLayer is the source of truth for gameplay topology and visible core terrain. Large generated terrain modules can be used as background or landmark decoration, but seam-critical gameplay terrain should be rendered from grid-aligned tiles rather than stretched over greybox rectangles.

## Accessibility Rule

Every authored gameplay area must be reachable from the player entry cell unless it is explicitly marked as non-collision background, decoration, or an intentionally inaccessible vista.

Before accepting any map change:

- Run the reachability validator from the player entry cell.
- Confirm all salvage, hazards, base/extraction zones, and gameplay routes are reachable.
- Confirm no open-water pocket is accidentally sealed by terrain.
- If an unreachable area is intentional, mark it as background/decorative data rather than leaving it as normal open gameplay space.
- Regenerate the preview from the source map after any topology edit.

Current check:

```bash
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
```

## Map Acceptance Criteria

The map is accepted when:

- The player start, extraction point, salvage, hazards, and blockers match the map spec.
- The map is navigable.
- Reachability validation passes from the player entry cell.
- No intended gameplay area, collectible, hazard, or return path is accidentally inaccessible.
- The camera framing makes hazards readable.
- The greybox screenshot is saved as a baseline.
- Replacing greybox tiles with grid-aligned terrain art does not change gameplay layout.
