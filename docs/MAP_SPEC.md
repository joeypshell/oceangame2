# Map Spec

## Purpose

The map must be a data source, not a screenshot to imitate. The game scene should render from the authored map data so the in-game result can match the plan.

## First Map

Working name: `salvage_test_01`

Recommended size:

- Width: 40 tiles.
- Height: 25 tiles.
- Tile size: 32x32 pixels.

## Required Areas

The first map should include:

- Dock or base zone.
- Open water navigation area.
- Shallow water transition.
- Small island or sandbar.
- Rock barrier.
- Salvage cluster.
- Hazard cluster.
- Clear return path.

## Placeholder Tile Meanings

Use simple greybox colors before final art:

- Deep water: dark blue.
- Shallow water: cyan.
- Sand or island: tan.
- Rock or blocker: gray.
- Dock: brown.
- Salvage: yellow.
- Hazard: red.
- Player start: green.

## Source Of Truth Options

Choose one for the prototype:

- Godot TileMapLayer.
- LDtk.
- Tiled.
- JSON grid.

The first implementation should use the simplest option that keeps the map editable and reviewable.

## Map Acceptance Criteria

The map is accepted when:

- The player start, dock, salvage, hazards, and blockers match the map spec.
- The map is navigable.
- The camera framing makes hazards readable.
- The greybox screenshot is saved as a baseline.
- Replacing greybox tiles with art does not change gameplay layout.

