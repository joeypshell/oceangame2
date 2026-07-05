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

- Dock or base zone.
- Open water swim corridor.
- Modular cave floors, walls, ceilings, ledges, and arches.
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

## Source Of Truth Options

Use Godot `TileMapLayer` for the first prototype.

The TileMapLayer is the source of truth for gameplay topology. Large generated terrain modules can be placed over it for visuals, but they must not redefine collision by eye.

## Map Acceptance Criteria

The map is accepted when:

- The player start, extraction point, salvage, hazards, and blockers match the map spec.
- The map is navigable.
- The camera framing makes hazards readable.
- The greybox screenshot is saved as a baseline.
- Replacing greybox tiles with large art modules does not change gameplay layout.
