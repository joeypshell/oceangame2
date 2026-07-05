# Greybox Map 01

## Source

- Map data: `maps/cave_salvage_test_01.greybox.json`
- Preview: `references/greybox/cave_salvage_test_01.svg`
- Renderer: `tools/render_greybox_map.py`

## Intent

This is the first side-view cave layout for the visual proof-of-concept. It is not final art and should not be hand-tuned from screenshots. The JSON file is the source of truth.

The map tests:

- side-view swim space
- large modular cave terrain chunks
- a safe extraction point
- a clear first route out of the base
- a central open-water hazard
- salvage on multiple shelves/routes
- a lower return route
- background silhouettes that do not affect collision

## Layout Read

The player starts at the left extraction zone. From there, they can move upward toward the left shelf, push into the central swim corridor, collect salvage on the central shelf, then choose whether to continue to the right-side salvage or drop into the lower return route.

The central arch and bottom route are meant to test whether the map feels like swimming through a cave instead of jumping between platformer islands. The arch is raised enough to keep the lower return route connected.

## Review Questions

- Does the map leave enough open water to feel like swimming?
- Does the central arch create useful route identity without blocking readability?
- Are all intended open-water gameplay areas accessible from the player start?
- Are all salvage, hazards, and return/extraction routes reachable?
- Are the hazards creating pressure without making the first test map annoying?
- Are the solid regions easy to imagine as large generated terrain modules?
- Is the map small enough for the first Godot greybox implementation?

## Accessibility Check

Map topology is not accepted by visual inspection alone. After any source-map edit, run:

```bash
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
```

The check must pass before converting the map into Godot or adding art modules. If a pocket or vista should be inaccessible, represent it as `background` or another explicit decorative type instead of ordinary open gameplay space.

## Next Step

After review, convert this source into the first Godot `TileMapLayer` greybox scene. The scene should preserve the JSON topology exactly before any visual terrain modules are added.

Run these checks after any map edit:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
```
