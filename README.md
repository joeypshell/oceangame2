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
- Core loop: leave boat/base, collect salvage, return to extraction, complete the run, restart
- Primary risk being tested: visual consistency

## Planning Docs

- [Game Spec](docs/GAME_SPEC.md)
- [Art Bible](docs/ART_BIBLE.md)
- [Map Spec](docs/MAP_SPEC.md)
- [Greybox Map 01](docs/planning/GREYBOX_MAP_01.md)
- [Terrain Art Placement Pass 01](docs/planning/TERRAIN_ART_PLACEMENT.md)
- [Cave Tileset Renderer Pass 01](docs/planning/CAVE_TILESET_RENDERER.md)
- [Visual Workflow](docs/VISUAL_WORKFLOW.md)
- [Reference Standard](docs/REFERENCE_STANDARD.md)
- [Asset Manifest](docs/ASSET_MANIFEST.md)
- [Milestones](docs/MILESTONES.md)
- [OceanGame Migration Notes](docs/OCEANGAME_MIGRATION.md)
- [Current Architecture](docs/current/ARCHITECTURE.md)
- [Tooling](docs/current/TOOLING.md)
- [Production Slice Index](docs/current/PRODUCTION_SLICE_INDEX.md)
- [Post-Slice Workflow Decision](docs/current/POST_SLICE_WORKFLOW_DECISION.md)
- [Controlled Visual Revision 01 Plan](docs/current/CONTROLLED_VISUAL_REVISION_01_PLAN.md)
- [Controlled Visual Revision 02 Plan](docs/current/CONTROLLED_VISUAL_REVISION_02_PLAN.md)
- [Prop Sprite Baseline Decision](docs/current/PROP_SPRITE_BASELINE_DECISION.md)
- [Backlog Refresh 2026-07-06](docs/current/BACKLOG_REFRESH_2026_07_06.md)
- [Backlog Refresh After Gameplay Pass 01](docs/current/BACKLOG_REFRESH_POST_GAMEPLAY_PASS_01_2026_07_06.md)
- [Controlled Gameplay Pass 02 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_02_PLAN.md)
- [Controlled Gameplay Pass 03 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_03_PLAN.md)
- [Controlled Gameplay Pass 04 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_04_CLOSEOUT.md)
- [Controlled Gameplay Pass 05 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_05_PLAN.md)
- [Controlled Gameplay Pass 05 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_05_CLOSEOUT.md)
- [Controlled Gameplay Pass 06 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_06_PLAN.md)
- [Controlled Gameplay Pass 06 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_06_CLOSEOUT.md)
- [Controlled Gameplay Pass 07 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_07_PLAN.md)
- [Controlled Gameplay Pass 07 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_07_CLOSEOUT.md)
- [Controlled Gameplay Pass 08 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_08_PLAN.md)
- [Controlled Gameplay Pass 08 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_08_CLOSEOUT.md)
- [Controlled Gameplay Pass 09 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_09_PLAN.md)
- [Controlled Gameplay Pass 09 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_09_CLOSEOUT.md)
- [Oxygen Pressure Baseline Decision](docs/current/OXYGEN_PRESSURE_BASELINE_DECISION.md)
- [Route Payoff Visual Baseline Decision](docs/current/ROUTE_PAYOFF_VISUAL_BASELINE_DECISION.md)
- [Route Payoff Web Preview Verification](docs/current/ROUTE_PAYOFF_WEB_PREVIEW_VERIFICATION.md)
- [Pass 04 Route Pressure Visual Baseline Decision](docs/current/PASS_04_ROUTE_PRESSURE_VISUAL_BASELINE_DECISION.md)
- [Pass 04 Route Pressure Web Preview Verification](docs/current/PASS_04_ROUTE_PRESSURE_WEB_PREVIEW_VERIFICATION.md)
- [Pass 05 Timed Salvage Visual And Web Verification](docs/current/PASS_05_TIMED_SALVAGE_VISUAL_WEB_VERIFICATION.md)
- [Pass 06 Timed Salvage Visual Baseline Decision](docs/current/PASS_06_TIMED_SALVAGE_VISUAL_BASELINE_DECISION.md)
- [Pass 06 Timed Salvage Web Preview Verification](docs/current/PASS_06_TIMED_SALVAGE_WEB_PREVIEW_VERIFICATION.md)
- [Pass 07 Hazard Pressure Visual Baseline Decision](docs/current/PASS_07_HAZARD_PRESSURE_VISUAL_BASELINE_DECISION.md)
- [Pass 07 Hazard Pressure Web Preview Verification](docs/current/PASS_07_HAZARD_PRESSURE_WEB_PREVIEW_VERIFICATION.md)
- [Pass 08 Route Extension Visual Baseline Decision](docs/current/PASS_08_ROUTE_EXTENSION_VISUAL_BASELINE_DECISION.md)
- [Pass 08 Route Extension Web Preview Verification](docs/current/PASS_08_ROUTE_EXTENSION_WEB_PREVIEW_VERIFICATION.md)
- [Pass 09 Southwest Pocket Visual Baseline Decision](docs/current/PASS_09_SOUTHWEST_POCKET_VISUAL_BASELINE_DECISION.md)
- [Pass 09 Southwest Pocket Web Preview Verification](docs/current/PASS_09_SOUTHWEST_POCKET_WEB_PREVIEW_VERIFICATION.md)

## Locked Visual Direction

The current primary direction is [visual_direction_b_modular_cave.png](references/visual/visual_direction_b_modular_cave.png): clean side-view underwater cave terrain built from a grid-aligned TileMap terrain renderer, with larger generated modules reserved for background silhouettes and landmarks.

The original greybox source map is [cave_salvage_test_01.greybox.json](maps/cave_salvage_test_01.greybox.json), with a generated preview at [cave_salvage_test_01.svg](references/greybox/cave_salvage_test_01.svg). It remains available as a comparison map.

The current default preview map is the first focused production slice: [production_slice_01.greybox.json](maps/production_slice_01.greybox.json), with a generated preview at [production_slice_01.svg](references/greybox/production_slice_01.svg). Run it locally with:

```powershell
.\tools\open_godot_project.ps1 -Run
```

Run the first organic playable salvage map explicitly with:

```powershell
.\tools\open_godot_project.ps1 -Run -OrganicMap
```

Run the original comparison map locally with:

```powershell
.\tools\open_godot_project.ps1 -Run -OriginalMap
```

The organic tileset stress-test map is [cave_tileset_test_01.greybox.json](maps/cave_tileset_test_01.greybox.json), with a generated preview at [cave_tileset_test_01.svg](references/greybox/cave_tileset_test_01.svg).

The first supplied full-map topology conversion draft is [full_cave_sketch_01.greybox.json](maps/full_cave_sketch_01.greybox.json), converted from [full_cave_sketch_01.png](references/source_maps/full_cave_sketch_01.png), with a generated preview at [full_cave_sketch_01.svg](references/greybox/full_cave_sketch_01.svg). This is a topology-only draft with a top-water `boat_spawn` marker and is not the default preview map.

Run the full-map topology draft locally with:

```powershell
.\tools\open_godot_project.ps1 -Run -FullSketchMap
```

The first focused production-slice source is generated from the top-center entry hub of the full sketch. It has a top-water `boat_spawn`, authored salvage, hazards, and named camera tests. It can also be selected explicitly with:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSliceMap
```

From Command Prompt, use the wrapper:

```cmd
run-production-slice-01.cmd
```

The second focused production-slice source is generated from the lower-right chamber route of the full sketch. It is a later-game destination/connector candidate with an in-water relay spawn and extraction zone, not an alternate first area. It can be selected explicitly with:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSlice2Map
```

From Command Prompt, use the wrapper:

```cmd
run-production-slice-02.cmd
```

The third focused production-slice source is generated from the upper-left room cluster of the full sketch. It is a connector/landmark room-cluster candidate with an in-water relay spawn and extraction zone. It can be selected explicitly with:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSlice3Map
```

From Command Prompt, use the wrapper:

```cmd
run-production-slice-03.cmd
```

The fourth focused production-slice source is generated from the lower-left loop of the full sketch. It is a connector/return-loop candidate with an in-water relay spawn and extraction zone. It can be selected explicitly with:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSlice4Map
```

From Command Prompt, use the wrapper:

```cmd
run-production-slice-04.cmd
```

Opening the Godot editor and pressing Play uses the default preview map unless Godot was launched with `--map-path`; the overlay should show the requested map id when a non-default slice is loaded correctly.

Local/editor review runs also show a small map selector in the review overlay. Use it to switch between the supported review maps without relaunching Godot. Command-line flags such as `-ProductionSlice3Map` or `-MapPath` still control the initial map that opens.

Regenerate and validate the greybox preview with:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
python tools/generate_organic_salvage_map.py
python tools/render_greybox_map.py maps/cave_salvage_organic_01.greybox.json references/greybox/cave_salvage_organic_01.svg
python tools/validate_greybox_map.py maps/cave_salvage_organic_01.greybox.json
python tools/generate_tileset_test_map.py
python tools/render_greybox_map.py maps/cave_tileset_test_01.greybox.json references/greybox/cave_tileset_test_01.svg
python tools/validate_greybox_map.py maps/cave_tileset_test_01.greybox.json
python tools/convert_full_cave_sketch_map.py
python tools/render_greybox_map.py maps/full_cave_sketch_01.greybox.json references/greybox/full_cave_sketch_01.svg
python tools/validate_greybox_map.py maps/full_cave_sketch_01.greybox.json
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/create_production_slice_02_map.py
python tools/render_greybox_map.py maps/production_slice_02.greybox.json references/greybox/production_slice_02.svg
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
python tools/create_production_slice_03_map.py
python tools/render_greybox_map.py maps/production_slice_03.greybox.json references/greybox/production_slice_03.svg
python tools/validate_greybox_map.py maps/production_slice_03.greybox.json
python tools/create_production_slice_04_map.py
python tools/render_greybox_map.py maps/production_slice_04.greybox.json references/greybox/production_slice_04.svg
python tools/validate_greybox_map.py maps/production_slice_04.greybox.json
```

Run the current Godot greybox with `project.godot`. The root scene is `scenes/main/Main.tscn`.

The preview shows compact review context in the upper-left corner with the loaded map id, build label, salvage progress, and scoped oxygen pressure. Local builds show `local` unless `build_info.json` is generated by tooling; the web export workflow writes the deployed commit into that file before export.

Current in-engine baseline screenshot: [001_greybox_in_engine.png](visual_baselines/001_greybox_in_engine.png)

Current named camera captures are generated under [visual_captures/latest](visual_captures/latest) from the default production slice.

## Browser Preview

GitHub Actions builds a Godot Web export in the `Godot Web Export` workflow. Download the `oceangame2-web-export` artifact from the latest run, or use the GitHub Pages preview at `https://joeypshell.github.io/oceangame2/` once Pages is enabled for GitHub Actions.

Local preview commands are documented in [Tooling](docs/current/TOOLING.md). The export writes to ignored `exports/web/` output and should be served over HTTP for testing. The export workflow also runs `tools/check_web_preview.cjs` in Chromium so missing terrain texture warnings fail CI before the Pages preview is deployed.

## First Success Condition

The first prototype succeeds when a small Godot scene can be captured as an approved baseline screenshot, then one targeted visual change can be made without damaging unrelated visuals.
