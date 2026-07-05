# Game Spec

## Working Title

Salvage POC

## Purpose

This is a visual-first prototype for a small ocean salvage game. The gameplay is intentionally simple so the project can focus on proving the map, art, and asset workflow that a larger OceanGame-style project would need.

## Player Fantasy

The player controls a diver and/or small research sub through a compact side-view underwater cave area, collects salvage, avoids hazards, and returns to a safe base or extraction point with rewards.

## Core Loop

1. Start at the base or extraction point.
2. Move into the underwater cave map.
3. Collect salvage objects.
4. Avoid hazards.
5. Return to the base or extraction point.
6. Bank score.
7. Restart or repeat.

## Minimum Playable Version

The first playable version must include:

- Player movement.
- Camera following the player.
- One small side-view cave map.
- Salvage collectibles.
- Hazards.
- Base, boat, sub, or extraction return zone.
- Score display.
- Restart flow.

## Excluded From First Version

These are intentionally out of scope until the visual workflow is proven:

- Procedural generation.
- Large world maps.
- Complex economy.
- Upgrade trees.
- Inventory depth.
- Weather systems.
- Dialogue.
- Multiple biomes.
- Final OceanGame mechanics.
- Complex terrain generation.

## Design Constraint

Every gameplay feature must support the visual proof-of-concept. If a feature does not help test map readability, asset consistency, or scene composition, it waits.

## Current Production Slice Constraints

The current focused production source is:

```text
maps/production_slice_01.greybox.json
```

It is a bounded top-center entry hub slice from `maps/full_cave_sketch_01.greybox.json`, not an attempt to produce the whole full sketch at once.

Accepted constraints for the next phase:

- The player enters and extracts through the authored `boat_spawn` entity.
- The first loop remains movement, salvage collection, hazard interaction, return to extraction, completion, and reset.
- Terrain and collision remain generated from JSON source data.
- Supplied sketch icons are ignored by terrain conversion until intentionally reauthored as JSON entities.
- Visual changes should target individual assets, source map data, or renderer rules; do not regenerate the whole scene to fix one visual problem.
- New gameplay pressure should stay scoped until the production-slice visual workflow is accepted.
