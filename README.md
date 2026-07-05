# oceangame2

`oceangame2` is a clean visual proof-of-concept for a small side-view ocean salvage game.

The purpose is not to rebuild OceanGame immediately. The purpose is to prove a stable workflow for ocean visuals, maps, reusable assets, and controlled iteration. Gameplay stays simple until the visual pipeline is trustworthy.

## Project Goal

Build a small side-view salvage game that proves:

- The map can be authored as data and rendered accurately in Godot.
- The art direction can stay coherent across revisions.
- Individual visual issues can be fixed without resetting the whole scene.
- Approved assets can be locked and reused.
- The workflow can eventually scale into the larger OceanGame idea.

## Prototype Shape

- Genre: side-view 2D ocean salvage game
- Engine: Godot
- First map: small hand-authored modular underwater cave test map
- Core loop: leave base, collect salvage, avoid hazards, return to extraction, score, restart
- Primary risk being tested: visual consistency

## Planning Docs

- [Game Spec](docs/GAME_SPEC.md)
- [Art Bible](docs/ART_BIBLE.md)
- [Map Spec](docs/MAP_SPEC.md)
- [Greybox Map 01](docs/planning/GREYBOX_MAP_01.md)
- [Terrain Art Placement Pass 01](docs/planning/TERRAIN_ART_PLACEMENT.md)
- [Visual Workflow](docs/VISUAL_WORKFLOW.md)
- [Reference Standard](docs/REFERENCE_STANDARD.md)
- [Asset Manifest](docs/ASSET_MANIFEST.md)
- [Milestones](docs/MILESTONES.md)
- [OceanGame Migration Notes](docs/OCEANGAME_MIGRATION.md)
- [Current Architecture](docs/current/ARCHITECTURE.md)
- [Tooling](docs/current/TOOLING.md)

## Locked Visual Direction

The current primary direction is [visual_direction_b_modular_cave.png](references/visual/visual_direction_b_modular_cave.png): clean side-view underwater cave terrain built from large modular chunks over a simple collision/map grid.

The first greybox source map is [cave_salvage_test_01.greybox.json](maps/cave_salvage_test_01.greybox.json), with a generated preview at [cave_salvage_test_01.svg](references/greybox/cave_salvage_test_01.svg).

Regenerate and validate the greybox preview with:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
```

Run the current Godot greybox with `project.godot`. The root scene is `scenes/main/Main.tscn`.

Current in-engine baseline screenshot: [001_greybox_in_engine.png](visual_baselines/001_greybox_in_engine.png)

Current named camera captures are generated under [visual_captures/latest](visual_captures/latest).

## First Success Condition

The first prototype succeeds when a small Godot scene can be captured as an approved baseline screenshot, then one targeted visual change can be made without damaging unrelated visuals.
