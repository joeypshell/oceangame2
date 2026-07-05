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

Existing base/extraction zones remain valid. When a `boat_spawn` is present, runtime extraction checks also treat the boat rectangle as a valid return point.

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

```json
{
  "id": "salvage_center_crossing",
  "type": "salvage",
  "x": 46,
  "y": 30,
  "kind": "wreck_fragment"
}
```

`hazard` entities require `kind`. Current valid-style examples are `mine`, `jellyfish`, and `stress_marker`.

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
