# oceangame2

`oceangame2` is a clean visual proof-of-concept growing toward a finished small side-view diver salvage game.

The purpose is not to rebuild the full OceanGame immediately. The current product target is a complete, compact diver game first: boat/base entry, authored cave routes, oxygen/cargo pressure, tool-like salvage interactions, limited progression, and a final small-game arc. The workflow must stay stable enough to scale later into the larger 2D Subnautica-like idea.

## Project Goal

Build a small side-view salvage game that proves:

- The map can be authored as data and rendered accurately in Godot.
- The art direction can stay coherent across revisions.
- Individual visual issues can be fixed without resetting the whole scene.
- Approved assets can be locked and reused.
- The core diver loop can become a finished small game before larger OceanGame expansion.

## Prototype Shape

- Genre: side-view 2D ocean salvage game
- Engine: Godot
- First map: small hand-authored modular underwater cave test map
- Core loop: leave boat/base, collect salvage, return to extraction, complete the run, restart
- Primary risks being tested: visual consistency, source-driven map production, expedition pressure, and small-game progression shape

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
- [Finished Simple Diver Game Roadmap](docs/current/SIMPLE_DIVER_GAME_ROADMAP.md)
- [OceanGame Migration Notes](docs/OCEANGAME_MIGRATION.md)
- [Current Architecture](docs/current/ARCHITECTURE.md)
- [Tooling](docs/current/TOOLING.md)
- [Parallel Codex Worktree Workflow](docs/current/PARALLEL_CODEX_WORKFLOW.md)
- [Greybox World Split Plan](docs/current/GREYBOX_WORLD_SPLIT_PLAN.md)
- [Greybox World Split Closeout](docs/current/GREYBOX_WORLD_SPLIT_CLOSEOUT.md)
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
- [Controlled Gameplay Pass 10 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_10_PLAN.md)
- [Controlled Gameplay Pass 10 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_10_CLOSEOUT.md)
- [Controlled Gameplay Pass 11 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_11_PLAN.md)
- [Controlled Gameplay Pass 11 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_11_CLOSEOUT.md)
- [Controlled Gameplay Pass 12 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_12_PLAN.md)
- [Controlled Gameplay Pass 12 Source Rules](docs/current/CONTROLLED_GAMEPLAY_PASS_12_SOURCE_RULES.md)
- [Controlled Gameplay Pass 12 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_12_CLOSEOUT.md)
- [Controlled Gameplay Pass 13 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_13_PLAN.md)
- [Controlled Gameplay Pass 13 Source Rules](docs/current/CONTROLLED_GAMEPLAY_PASS_13_SOURCE_RULES.md)
- [Controlled Gameplay Pass 13 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_13_CLOSEOUT.md)
- [Controlled Gameplay Pass 14 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_14_PLAN.md)
- [Controlled Gameplay Pass 14 Objective Cue Contract](docs/current/CONTROLLED_GAMEPLAY_PASS_14_OBJECTIVE_CUE_CONTRACT.md)
- [Controlled Gameplay Pass 14 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_14_CLOSEOUT.md)
- [Controlled Gameplay Pass 15 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_15_PLAN.md)
- [Controlled Gameplay Pass 15 Objective Step Cue Contract](docs/current/CONTROLLED_GAMEPLAY_PASS_15_OBJECTIVE_STEP_CUE_CONTRACT.md)
- [Controlled Gameplay Pass 15 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_15_CLOSEOUT.md)
- [Controlled Gameplay Pass 16 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_16_PLAN.md)
- [Controlled Gameplay Pass 16 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_16_CLOSEOUT.md)
- [Controlled Gameplay Pass 17 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_17_PLAN.md)
- [Controlled Gameplay Pass 17 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_17_CLOSEOUT.md)
- [Controlled Gameplay Pass 18 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_18_PLAN.md)
- [Controlled Gameplay Pass 18 Progression Contract](docs/current/CONTROLLED_GAMEPLAY_PASS_18_PROGRESSION_CONTRACT.md)
- [Controlled Gameplay Pass 18 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_18_CLOSEOUT.md)
- [Controlled Gameplay Pass 19 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_19_PLAN.md)
- [Controlled Gameplay Pass 19 Cargo Contract](docs/current/CONTROLLED_GAMEPLAY_PASS_19_CARGO_CONTRACT.md)
- [Controlled Gameplay Pass 19 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_19_CLOSEOUT.md)
- [Controlled Gameplay Pass 20 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_20_PLAN.md)
- [Controlled Gameplay Pass 20 Light Contract](docs/current/CONTROLLED_GAMEPLAY_PASS_20_LIGHT_CONTRACT.md)
- [Controlled Gameplay Pass 20 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_20_CLOSEOUT.md)
- [Controlled Gameplay Pass 21 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_21_PLAN.md)
- [Controlled Gameplay Pass 21 Connector Contract](docs/current/CONTROLLED_GAMEPLAY_PASS_21_CONNECTOR_CONTRACT.md)
- [Controlled Gameplay Pass 21 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_21_CLOSEOUT.md)
- [Controlled Gameplay Pass 22 Plan](docs/current/CONTROLLED_GAMEPLAY_PASS_22_PLAN.md)
- [Controlled Gameplay Pass 22 Destination Payoff Contract](docs/current/CONTROLLED_GAMEPLAY_PASS_22_DESTINATION_PAYOFF_CONTRACT.md)
- [Controlled Gameplay Pass 22 Closeout](docs/current/CONTROLLED_GAMEPLAY_PASS_22_CLOSEOUT.md)
- [First Feedback Audio Micro-Pass Plan](docs/current/FIRST_FEEDBACK_AUDIO_MICRO_PASS_PLAN.md)
- [First Feedback Audio Cue Contract](docs/current/FIRST_FEEDBACK_AUDIO_CUE_CONTRACT.md)
- [First Feedback Audio Review Note](docs/current/FIRST_FEEDBACK_AUDIO_REVIEW.md)
- [First Feedback Audio Closeout](docs/current/FIRST_FEEDBACK_AUDIO_CLOSEOUT.md)
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
- [Pass 10 Return Pressure Visual Baseline Decision](docs/current/PASS_10_RETURN_PRESSURE_VISUAL_BASELINE_DECISION.md)
- [Pass 10 Return Pressure Web Preview Verification](docs/current/PASS_10_RETURN_PRESSURE_WEB_PREVIEW_VERIFICATION.md)
- [Pass 11 Pre-Pickup Route Cue Visual Baseline Decision](docs/current/PASS_11_PRE_PICKUP_ROUTE_CUE_VISUAL_BASELINE_DECISION.md)
- [Pass 11 Pre-Pickup Route Cue Web Preview Verification](docs/current/PASS_11_PRE_PICKUP_ROUTE_CUE_WEB_PREVIEW_VERIFICATION.md)
- [Pass 12 Oxygen Rest Visual Baseline Decision](docs/current/PASS_12_OXYGEN_REST_VISUAL_BASELINE_DECISION.md)
- [Pass 12 Oxygen Rest Web Preview Verification](docs/current/PASS_12_OXYGEN_REST_WEB_PREVIEW_VERIFICATION.md)
- [Pass 13 Route Commitment Visual Baseline Decision](docs/current/PASS_13_ROUTE_COMMITMENT_VISUAL_BASELINE_DECISION.md)
- [Pass 13 Route Commitment Web Preview Verification](docs/current/PASS_13_ROUTE_COMMITMENT_WEB_PREVIEW_VERIFICATION.md)
- [Pass 14 Objective Cue Visual Baseline Decision](docs/current/PASS_14_OBJECTIVE_CUE_VISUAL_BASELINE_DECISION.md)
- [Pass 14 Objective Cue Web Preview Verification](docs/current/PASS_14_OBJECTIVE_CUE_WEB_PREVIEW_VERIFICATION.md)
- [Pass 15 Objective Follow-Through Visual Baseline Decision](docs/current/PASS_15_OBJECTIVE_FOLLOW_THROUGH_VISUAL_BASELINE_DECISION.md)
- [Pass 15 Objective Follow-Through Web Preview Verification](docs/current/PASS_15_OBJECTIVE_FOLLOW_THROUGH_WEB_PREVIEW_VERIFICATION.md)
- [Pass 16 Primary Dive Completion Visual Baseline Decision](docs/current/PASS_16_PRIMARY_DIVE_COMPLETION_VISUAL_BASELINE_DECISION.md)
- [Pass 16 Primary Dive Completion Web Preview Verification](docs/current/PASS_16_PRIMARY_DIVE_COMPLETION_WEB_PREVIEW_VERIFICATION.md)
- [Pass 17 Pry Salvage Visual Baseline Decision](docs/current/PASS_17_PRY_SALVAGE_VISUAL_BASELINE_DECISION.md)
- [Pass 17 Pry Salvage Web Preview Verification](docs/current/PASS_17_PRY_SALVAGE_WEB_PREVIEW_VERIFICATION.md)
- [Pass 18 Progression Visual Baseline Decision](docs/current/PASS_18_PROGRESSION_VISUAL_BASELINE_DECISION.md)
- [Pass 18 Progression Web Preview Verification](docs/current/PASS_18_PROGRESSION_WEB_PREVIEW_VERIFICATION.md)
- [Pass 19 Cargo Upgrade Visual Baseline Decision](docs/current/PASS_19_CARGO_UPGRADE_VISUAL_BASELINE_DECISION.md)
- [Pass 19 Cargo Upgrade Web Preview Verification](docs/current/PASS_19_CARGO_UPGRADE_WEB_PREVIEW_VERIFICATION.md)
- [Pass 20 Light Upgrade Visual Baseline Decision](docs/current/PASS_20_LIGHT_UPGRADE_VISUAL_BASELINE_DECISION.md)
- [Pass 20 Light Upgrade Web Preview Verification](docs/current/PASS_20_LIGHT_UPGRADE_WEB_PREVIEW_VERIFICATION.md)
- [Pass 21 World Connector Visual Baseline Decision](docs/current/PASS_21_WORLD_CONNECTOR_VISUAL_BASELINE_DECISION.md)
- [Pass 21 World Connector Web Preview Verification](docs/current/PASS_21_WORLD_CONNECTOR_WEB_PREVIEW_VERIFICATION.md)
- [Pass 22 Destination Payoff Visual Baseline Decision](docs/current/PASS_22_DESTINATION_PAYOFF_VISUAL_BASELINE_DECISION.md)
- [Pass 22 Destination Payoff Web Preview Verification](docs/current/PASS_22_DESTINATION_PAYOFF_WEB_PREVIEW_VERIFICATION.md)

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
