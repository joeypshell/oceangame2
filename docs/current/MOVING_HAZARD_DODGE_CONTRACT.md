# Moving Hazard Dodge Contract

Date: 2026-07-09

Issues: #449 `Design first enemy-as-moving-hazard dodge encounter`; #450 `Prototype one moving-hazard dodge encounter`

## Decision

Treat the first enemy-like encounter as one deterministic moving hazard, not as combat, creature AI, health, loot, drops, or an ecosystem. Its purpose is a readable dodge-pressure beat on an authored route.

The first implementation adds one source-authored patrol in `production_slice_01`, then stops for smoke/capture review before adding more moving hazards.

## Target Experience

The player sees a slow hazard crossing a route, waits or swims around it, and understands that touching it uses the existing hazard penalty. The encounter should create timing pressure while preserving the current oxygen, cargo, objective, and reset loop.

Recommended first route:

- Map: `production_slice_01`
- Implemented hazard: `deep_route_jellyfish_patrol`
- Context: the `lower_loop_to_deep_cache_pressure` / `hazard_right_branch` route toward the primary deep-cache objective
- Role: make the lower-loop-to-deep-cache transition feel more alive and risky after the player has committed to the deeper route
- Non-role: do not block the route permanently, require a weapon, or add a new objective

## Source Metadata

Use a top-level `moving_hazards` list so patrols stay separate from static hazard point entities and route marker rectangles.

Required fields:

- `id`: unique lower_snake_case id.
- `kind`: existing hazard visual family such as `jellyfish` or `mine`.
- `x`, `y`: initial tile cell.
- `movement`: `linear_patrol` for the first implementation.
- `path`: two or more tile points, each with integer `x` and `y`.
- `speed_tiles_per_second`: positive number.
- `route_context`: lower_snake_case route grouping.
- `display_label`: compact display-safe text.

Optional fields:

- `phase_offset_seconds`: non-negative deterministic offset for capture/smoke framing.
- `intent`: human-readable source note.

Recommended metadata shape:

```json
{
  "id": "deep_route_jellyfish_patrol",
  "kind": "jellyfish",
  "x": 55,
  "y": 44,
  "movement": "linear_patrol",
  "path": [
    {"x": 53, "y": 44},
    {"x": 59, "y": 44}
  ],
  "speed_tiles_per_second": 1.0,
  "route_context": "deep_cache_pressure",
  "display_label": "Jellyfish patrol",
  "intent": "First deterministic moving hazard on the lower-loop to deep-cache route."
}
```

## Validation

Validation should confirm:

- `moving_hazards`, when present, is a list.
- ids are unique and lower_snake_case.
- `kind`, `movement`, `route_context`, and `display_label` are valid compact strings.
- initial cell and every path point are in bounds, non-solid, and reachable.
- first implementation uses `linear_patrol` only.
- speed is positive.
- source does not author oxygen penalty amount, runtime position, AI state, health, damage, loot, score, cargo, wallet, save state, or collision changes.

## Runtime Semantics

Movement should be deterministic ping-pong movement along the authored path. It should keep running while oxygen drains normally.

Contact should reuse existing hazard semantics unless implementation discovers a concrete reason to vary them:

- apply the existing hazard oxygen penalty
- reset player position to spawn/entry
- restore held/unbanked salvage
- clear in-progress timed/pry interactions
- preserve session progression such as wallet, upgrades, opened chests, and best score

Static hazards must keep existing behavior.

## Readability

The moving hazard needs a compact warning/readability treatment:

- use an existing hazard prop if possible
- show a simple patrol motion, not erratic AI
- prefer slow motion over fast reaction tests
- keep the warning prompt short, such as `Moving hazard - wait`
- avoid adding new UI panels

## Smoke And Capture

Add one focused smoke in the implementation issue:

- suggested flag: `--smoke-moving-hazard`
- verify deterministic position changes over time
- verify warning/contact behavior
- verify cargo/reset/oxygen semantics match static hazards
- verify existing static hazard and route smokes still pass

Add one focused capture:

- suggested flag: `--capture-moving-hazard`
- frame the patrol route and warning prompt
- save under `visual_captures/moving_hazard/`
- do not accept baselines in the implementation issue

## Deferred

- combat, weapons, health bars, drops, loot tables, enemy spawners, broad AI, enemy ecosystems, persistent save state, and multiple moving hazards
- hard route locks that require defeating or disabling the hazard
- adding the moving hazard to slice 03 or the full sketch before the default slice proves the beat

## Implementation Status

#450 implements only the first `linear_patrol` moving hazard, its validator/runtime support, one smoke, one capture, and compact docs/tooling updates. Next work should review the capture/baseline impact before adding additional moving hazards.
