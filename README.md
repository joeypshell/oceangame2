# oceangame2

`oceangame2` is a clean visual proof-of-concept for a small ocean salvage game.

The purpose is not to rebuild OceanGame immediately. The purpose is to prove a stable workflow for ocean visuals, maps, reusable assets, and controlled iteration. Gameplay stays simple until the visual pipeline is trustworthy.

## Project Goal

Build a small top-down salvage game that proves:

- The map can be authored as data and rendered accurately in Godot.
- The art direction can stay coherent across revisions.
- Individual visual issues can be fixed without resetting the whole scene.
- Approved assets can be locked and reused.
- The workflow can eventually scale into the larger OceanGame idea.

## Prototype Shape

- Genre: top-down 2D ocean salvage game
- Engine: Godot
- First map: small hand-authored ocean test map
- Core loop: leave dock, collect salvage, avoid hazards, return to dock, score, restart
- Primary risk being tested: visual consistency

## Planning Docs

- [Game Spec](docs/GAME_SPEC.md)
- [Art Bible](docs/ART_BIBLE.md)
- [Map Spec](docs/MAP_SPEC.md)
- [Visual Workflow](docs/VISUAL_WORKFLOW.md)
- [Asset Manifest](docs/ASSET_MANIFEST.md)
- [Milestones](docs/MILESTONES.md)
- [OceanGame Migration Notes](docs/OCEANGAME_MIGRATION.md)

## First Success Condition

The first prototype succeeds when a small Godot scene can be captured as an approved baseline screenshot, then one targeted visual change can be made without damaging unrelated visuals.

