# Project Context

Last updated: 2026-07-06

This file is the compact handoff for new Codex or ChatGPT Project sessions. It captures the useful context from the initial planning and implementation chat without preserving the whole conversation.

## Current Goal

`oceangame2` is a visual-first Godot prototype for a side-view ocean salvage game. It is not trying to rebuild OceanGame yet. The immediate purpose is to prove a stable workflow for:

- authored map data as the source of truth
- generated-but-controlled terrain art
- repeatable screenshots and browser preview
- fixing one visual issue without resetting unrelated visuals
- eventually scaling the workflow into the larger OceanGame idea

The project is intentionally simple on gameplay until the visual pipeline is trustworthy.

## Repository

- GitHub repo: `joeypshell/oceangame2`
- Public preview: `https://joeypshell.github.io/oceangame2/`
- Engine: Godot 4.7, GDScript
- Main scene: `scenes/main/Main.tscn`
- Default preview map source: `maps/production_slice_01.greybox.json`
- Original comparison map source: `maps/cave_salvage_test_01.greybox.json`
- Organic tileset stress-test map: `maps/cave_tileset_test_01.greybox.json`
- Full-map sketch topology draft: `maps/full_cave_sketch_01.greybox.json`
- First production slice source: `maps/production_slice_01.greybox.json`
- Second production slice source: `maps/production_slice_02.greybox.json`
- Third production slice source: `maps/production_slice_03.greybox.json`
- Fourth production slice source: `maps/production_slice_04.greybox.json`
- Current terrain atlas: `assets/terrain_tiles/cave_tileset_v2.png`
- Web export workflow: `.github/workflows/godot-web-export.yml`
- Latest full-sketch evaluation: `docs/current/FULL_SKETCH_EVALUATION_01.md`
- Production-slice selection criteria: `docs/current/PRODUCTION_SLICE_SELECTION_CRITERIA.md`
- Production-slice-02 evaluation: `docs/current/PRODUCTION_SLICE_02_EVALUATION.md`
- Production-slice-03 decision: `docs/current/PRODUCTION_SLICE_03_DECISION.md`
- Production-slice-03 evaluation: `docs/current/PRODUCTION_SLICE_03_EVALUATION.md`
- Production-slice-03 visual baseline decision: `docs/current/PRODUCTION_SLICE_03_VISUAL_BASELINE_DECISION.md`
- Production-slice-03 default preview decision: `docs/current/PRODUCTION_SLICE_03_DEFAULT_PREVIEW_DECISION.md`
- Production-slice-04 decision: `docs/current/PRODUCTION_SLICE_04_DECISION.md`
- Production-slice-04 evaluation: `docs/current/PRODUCTION_SLICE_04_EVALUATION.md`
- Production-slice-04 visual baseline decision: `docs/current/PRODUCTION_SLICE_04_VISUAL_BASELINE_DECISION.md`
- Production-slice status index: `docs/current/PRODUCTION_SLICE_INDEX.md`
- Production-slice-01 visual baseline reconciliation: `docs/current/PRODUCTION_SLICE_01_VISUAL_BASELINE_RECONCILIATION.md`
- Post-slice workflow decision: `docs/current/POST_SLICE_WORKFLOW_DECISION.md`
- First controlled visual-revision plan: `docs/current/CONTROLLED_VISUAL_REVISION_01_PLAN.md`
- Second controlled visual-revision plan: `docs/current/CONTROLLED_VISUAL_REVISION_02_PLAN.md`
- Third controlled visual-revision plan: `docs/current/CONTROLLED_VISUAL_REVISION_03_PLAN.md`
- Fourth controlled visual-revision plan: `docs/current/CONTROLLED_VISUAL_REVISION_04_PLAN.md`
- Fifth controlled visual-revision plan: `docs/current/CONTROLLED_VISUAL_REVISION_05_PLAN.md`
- Controlled visual-revision checklist: `docs/current/CONTROLLED_VISUAL_REVISION_CHECKLIST.md`
- Prop sprite baseline decision: `docs/current/PROP_SPRITE_BASELINE_DECISION.md`
- Player sprite baseline decision: `docs/current/PLAYER_SPRITE_BASELINE_DECISION.md`
- Player sprite web preview verification: `docs/current/PLAYER_SPRITE_WEB_PREVIEW_VERIFICATION.md`
- Player-facing fix web preview verification: `docs/current/PLAYER_FACING_WEB_PREVIEW_VERIFICATION.md`
- Boat spawn entry baseline decision: `docs/current/BOAT_SPAWN_ENTRY_BASELINE_DECISION.md`
- Boat spawn web preview verification: `docs/current/BOAT_SPAWN_WEB_PREVIEW_VERIFICATION.md`
- Background depth baseline decision: `docs/current/BACKGROUND_DEPTH_BASELINE_DECISION.md`
- Background depth web preview verification: `docs/current/BACKGROUND_DEPTH_WEB_PREVIEW_VERIFICATION.md`
- Terrain tileset v2 baseline decision: `docs/current/TERRAIN_TILESET_V2_BASELINE_DECISION.md`
- Terrain tileset v2 web preview verification: `docs/current/TERRAIN_TILESET_V2_WEB_PREVIEW_VERIFICATION.md`
- Current backlog refresh: `docs/current/BACKLOG_REFRESH_POST_GAMEPLAY_PASS_01_2026_07_06.md`
- Controlled Gameplay Pass 01 plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_01_PLAN.md`
- Controlled Gameplay Pass 02 plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_02_PLAN.md`
- Controlled Gameplay Pass 03 plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_03_PLAN.md`
- Movement-feel baseline decision: `docs/current/MOVEMENT_FEEL_BASELINE_DECISION.md`
- Salvage/oxygen feedback plan: `docs/current/SALVAGE_OXYGEN_FEEDBACK_PLAN.md`
- Salvage/oxygen feedback baseline decision: `docs/current/SALVAGE_OXYGEN_FEEDBACK_BASELINE_DECISION.md`
- Salvage/oxygen feedback web preview verification: `docs/current/SALVAGE_OXYGEN_FEEDBACK_WEB_PREVIEW_VERIFICATION.md`
- Oxygen pressure baseline decision: `docs/current/OXYGEN_PRESSURE_BASELINE_DECISION.md`
- Route payoff visual baseline decision: `docs/current/ROUTE_PAYOFF_VISUAL_BASELINE_DECISION.md`
- Route payoff web preview verification: `docs/current/ROUTE_PAYOFF_WEB_PREVIEW_VERIFICATION.md`

Start every new coding session by reading `AGENTS.md`, this file, `README.md`, and the relevant docs under `docs/current/`.

## Visual Direction

The approved direction is a clean side-view underwater cave prototype with readable dark blue-gray cave terrain, clear blue water, sparse props, and gameplay-readable scale. The closest reference target in-repo is:

```text
references/visual/visual_direction_b_modular_cave.png
```

Important visual decisions:

- Perspective is side-view, roughly Dave-the-Diver scale and feel.
- The style should be simpler and more AI-generation-friendly than Dave the Diver.
- Seam-critical terrain must be generated/rendered as grid-aligned tiles, not stretched modules.
- Large generated modules are allowed only for background silhouettes, landmarks, and non-collision decoration.
- Do not regenerate whole scenes to fix one visual defect. Edit or replace individual named assets.
- Avoid retro SNES/pixel cave style, crowded mobile-platformer collectibles, and obvious repeated square-tile identity in final art.

## Map And Terrain Source Of Truth

Maps are data, not screenshots. The current source format is JSON greybox data rendered in Godot.

For map/terrain changes:

1. Update the machine-readable source map or renderer.
2. Regenerate previews/captures.
3. Run reachability validation.
4. Use screenshots or browser preview only as final rendering confirmation.

Do not visually interpret screenshots and hand-tune Godot polygons as topology fixes.

Current terrain renderer:

- `scripts/world/greybox_world.gd`
- Builds `CaveTerrainTileMapLayer` from solid cells in the JSON map.
- Selects 32x32 terrain atlas tiles from neighbor masks.
- Keeps collision generated from JSON terrain rectangles.
- Exposes a headless parity report so tooling can compare Godot terrain/collision cells with the JSON source.
- Hides the source grid in normal preview mode.
- Supports `--show-debug-overlay` for map debugging.

The main scene also shows a compact preview overlay with map id, build label, banked score, salvage progress, held salvage capacity/score, and a scoped oxygen timer. A compact expedition result panel appears after run completion or oxygen failure with score, salvage, oxygen, and retry status. The minimal gameplay loop lets the player collect authored salvage, return to the extraction zone to complete the run, and press `R` to reset. Hazards now have a small bump/reset interaction without a full health system.

Maps may use either a legacy `spawn` entity or the newer `boat_spawn` entity. `boat_spawn` is the preferred top-water entry/extraction marker for production-style maps; the player starts at its `entry_x`/`entry_y` cell, and runtime extraction checks also accept its boat rectangle.

The greybox validator now checks entity schema as well as reachability: unique lower_snake_case entity ids, supported entity types, required salvage/hazard kinds, optional salvage `tier` values, coordinate bounds, exactly one player entry, and extraction requirements for playable salvage maps.

Current map-loading helper:

- Open the editor: `.\tools\open_godot_project.ps1`
- Run the default production slice locally: `.\tools\open_godot_project.ps1 -Run`
- Run the organic comparison map locally: `.\tools\open_godot_project.ps1 -Run -OrganicMap`
- Run the original comparison map locally: `.\tools\open_godot_project.ps1 -Run -OriginalMap`
- Run the full-map sketch draft locally: `.\tools\open_godot_project.ps1 -Run -FullSketchMap`
- Run the first production slice locally: `.\tools\open_godot_project.ps1 -Run -ProductionSliceMap`
- Run the second production slice locally: `.\tools\open_godot_project.ps1 -Run -ProductionSlice2Map`
- Run the third production slice locally: `.\tools\open_godot_project.ps1 -Run -ProductionSlice3Map`
- Run the fourth production slice locally: `.\tools\open_godot_project.ps1 -Run -ProductionSlice4Map`
- From Command Prompt, use the root wrappers instead of invoking `.ps1` files directly: `run-production-slice-01.cmd`, `run-production-slice-02.cmd`, `run-production-slice-03.cmd`, or `run-production-slice-04.cmd`.
- Opening the Godot editor and pressing Play uses the default preview map unless Godot was launched with `--map-path`; the overlay should show the requested map id.
- Local/editor review runs show a small map selector in the review overlay for switching supported maps without relaunching. It is hidden for capture/smoke automation and exported builds unless explicitly enabled with `--review-map-selector`.

## Web Preview Status

The public preview should show the cave terrain, not the blue greybox fallback:

```text
https://joeypshell.github.io/oceangame2/
```

The GitHub Pages source is configured for GitHub Actions publishing. The `Godot Web Export` workflow:

- downloads Godot 4.7 and export templates
- generates ignored `export_presets.cfg` with `tools/write_web_export_preset.py`
- writes `build_info.json` and copies it beside `exports/web/index.html` as plain external Pages metadata
- exports to ignored `exports/web/`
- serves the export and runs `tools/check_web_preview.cjs --expected-sha "${GITHUB_SHA}"` in Chromium to catch missing texture assets and stale build metadata before deploy
- uploads the `oceangame2-web-export` artifact
- deploys to GitHub Pages when Pages is enabled

Important fixed pitfall: Web exports did not package dynamically loaded PNG terrain assets. The fix was:

- preload terrain textures in `scripts/world/greybox_world.gd`
- include `*.json,*.png,*.svg` in `tools/write_web_export_preset.py`
- fail the web export workflow if the browser console reports missing terrain textures or TileSet creation errors

If the browser preview ever shows only blue water, faint rectangles, markers, no cave tiles, or fallback prop art, check browser logs for missing `res://assets/...png` warnings and verify the export package includes the assets.

If the public preview looks stale, fetch `https://joeypshell.github.io/oceangame2/build_info.json` or run `tools/check_web_preview.cjs` with `--expected-sha` to compare the deployed external metadata with the expected commit.

## Current Validation Commands

Run these after relevant changes:

```powershell
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
python tools/validate_greybox_map.py maps/cave_salvage_organic_01.greybox.json
python tools/validate_greybox_map.py maps/cave_tileset_test_01.greybox.json
python tools/validate_greybox_map.py maps/full_cave_sketch_01.greybox.json
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
python tools/validate_greybox_map.py maps/production_slice_03.greybox.json
python tools/validate_greybox_map.py maps/production_slice_04.greybox.json
python tools/check_production_slice_captures.py
python tools/check_map_parity.py
python tools/check_asset_manifest.py
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-02-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-03-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-04-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expanded-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-map-selector
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-interaction
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-cargo-capacity
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-movement-feel
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-feedback-overlay
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

Capture normal visual views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-camera-tests
```

Capture the organic tileset stress-test views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-tileset-test
```

Capture the full-map sketch topology draft views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-full-sketch-map
```

For local Web export:

```powershell
python tools/write_web_export_preset.py
New-Item -ItemType Directory -Force exports/web | Out-Null
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --export-release Web exports/web/index.html
python -m http.server 8060 --directory exports/web
```

Open `http://127.0.0.1:8060/`. Do not open `exports/web/index.html` directly.

## Issue Workflow

Use GitHub Issues for meaningful feature, bug, workflow, tooling, and demo work. Issues should include acceptance criteria, relevant files, implementation notes, and verification steps. When implementing immediately, still create the issue and close it with commit hashes and verification notes.

Current issue state as of 2026-07-06:

- Open active batch: #120-#128 cover Controlled Gameplay Pass 03, focused on scored salvage, cargo pressure, deterministic validation, run results, retry flow, one additional source-authored default-slice route choice, visual baseline review, and public Web preview verification.
- Closed: #119 verified the public Web preview after the route-payoff pass
- Closed: #118 accepted the route-payoff visual baseline for production slice 01
- Deferred: #52 and #53 remain optional slice-03 camera/topology polish. Do not pull them into the active queue unless slice-03 presentation becomes the selected goal.
- Closed: #108 verified the public Web preview after the salvage/oxygen feedback polish
- Closed: #107 accepted the salvage/oxygen feedback overlay baselines for production slices 01-04
- Closed: #106 implemented the salvage/oxygen feedback overlay polish and focused review capture
- Closed: #105 planned the salvage/oxygen feedback readability pass
- Closed: #104 accepted the Controlled Gameplay Pass 01 movement-feel baseline
- Closed: #103 tuned the player swim acceleration/deceleration constants for Controlled Gameplay Pass 01
- Closed: #102 added a deterministic `--smoke-movement-feel` probe for Controlled Gameplay Pass 01
- Closed: #101 planned Controlled Gameplay Pass 01 as a movement-feel/readability pass
- Closed: #100 added `--smoke-player-facing` to the `Godot Smoke` workflow
- Closed: #84 planned Controlled Visual Revision 03 as the boat spawn entry art pass
- Closed: #92 verified the public Web preview after the background-depth pass
- Closed: #91 accepted the Controlled Visual Revision 04 background-depth baseline
- Closed: #90 implemented the controlled background-depth art pass
- Closed: #89 added a focused background-depth review capture
- Closed: #88 planned Controlled Visual Revision 04 as the background-depth pass
- Closed: #99 verified the public Web preview after the #98 player-facing fix
- Closed: #98 fixed the player direction-change double-facing flash by keeping the root transform stable and flipping only visual children
- Closed: #97 verified the public Web preview after the terrain tileset v2 pass
- Closed: #96 accepted the Controlled Visual Revision 05 terrain tileset v2 baselines
- Closed: #95 implemented the controlled cave terrain tileset v2 pass
- Closed: #94 added a terrain atlas coverage review tool for the Controlled Visual Revision 05 terrain pass
- Closed: #93 planned Controlled Visual Revision 05 as the terrain tileset v2 pass
- Closed: #87 verified the public Web preview after the boat entry art pass
- Closed: #86 accepted the boat spawn entry art baseline
- Closed: #85 implemented the controlled boat spawn entry art pass
- Closed: #83 adds a controlled visual revision checklist/template
- Closed: #81 exposes Web export build metadata so public-preview checks can detect stale Pages deploys
- Closed: #80 validates committed asset manifest paths
- Closed: #79 verified the public web preview after the player sprite pass
- Closed: #78 accepted the player sprite baseline after implementation and review
- Closed: #77 implemented the controlled player sprite pass
- Closed: #76 added a focused player-readability capture path for CVR02 review
- Closed: #82 prevented baseline acceptance tooling from retaining ignored `.import` sidecars in accepted baseline directories
- Closed: #74 refreshed the actionable backlog and recorded the recommended order in `docs/current/BACKLOG_REFRESH_2026_07_06.md`
- Closed: #73 selected the player/diver placeholder replacement as Controlled Visual Revision 02 and documented the follow-up issue shape
- Closed: #72 hardened the web preview check for generic texture asset failures and verified the public preview after deployment
- Closed: #75 reconciled the `production_slice_01` accepted baseline with the current six-view capture set
- Closed: #71 accepted the #70 sprite-prop pass for current prototype use and updated accepted baselines for production slices 02, 03, and 04 while leaving slice 01 to #75
- Closed: #70 implemented the controlled sprite prop pass for salvage and hazards while keeping source maps, collision, gameplay behavior, debug markers, and accepted baselines unchanged
- Closed: #69 selected the first controlled visual revision target and created #70 for implementation
- Closed: #68 added `python tools/manage_production_slice_baseline.py compare-all` for aggregate accepted-baseline review sheets
- Closed: #67 refreshed the roadmap after accepted production slices and recorded the controlled visual-revision phase decision
- Closed: #66 added `docs/current/PRODUCTION_SLICE_INDEX.md` as the compact status index for slices 01-04
- Closed: #65 added all four production-slice route smokes to the `Godot Smoke` workflow
- Closed: #64 accepted the current five-view `production_slice_02` normal captures as a named visual baseline
- Closed: #57 added a local/editor review map selector and a headless selector reload smoke
- Closed: #60 added an aggregate production-slice capture completeness check and runs it in `Godot Smoke`
- Closed: #63 accepted the current five-view `production_slice_04` normal captures as a named visual baseline
- Closed: #62 evaluated `production_slice_04` and recommended keeping it as a validated lower-left connector/return-loop reference slice, not the default preview
- Closed: #61 authored `production_slice_04` from the lower-left loop with generator, validation, route smoke, captures, and review sheet
- Closed: #59 selected the lower-left loop as the production-slice-04 candidate and created #61 for implementation
- Closed: #58 decided not to promote `production_slice_03`; `production_slice_01` remains the default preview map
- Closed: #55 accepted the current five-view `production_slice_03` normal captures as a named visual baseline
- Closed: #54 extended production-slice visual baseline tooling so compare/accept can target slice 01, 02, or 03 without accepting new baselines by default
- Closed: #51 evaluated `production_slice_03` and recommended keeping it as a validated connector/landmark reference slice, not the default preview
- Closed: #56 added simple Command Prompt wrappers for production slice 01/02/03 local launches and documented the editor Play/default-map caveat
- Closed: #50 authored `production_slice_03` from the upper-left room cluster with generator, validation, captures, route smoke, and review sheet
- Closed: #49 selected upper-left room cluster as production-slice-03 candidate and deferred implementation to follow-up issue
- Closed: #48 evaluated production-slice-02 against workflow goals and recommended moving to slice 03 planning
- Closed: #47 added camera capture completeness checker for map-authored camera tests
- Closed: #46 documented production-slice roles, selection criteria, entry/extraction choices, and lessons from slices 01/02
- Closed: #45 added readable relay/sub extraction visual for in-water base zones and regenerated slice 02 captures
- Closed: #44 tuned production-slice-02 camera framing and regenerated normal/debug captures
- Closed: #43 deferred production-slice-02 visual baseline pending focused framing and relay-extraction visual blockers
- Closed: #42 added production-slice-02 source/render/collision review sheet
- Closed: #41 added production-slice-02 route smoke
- Closed: #40 selected and authored second production slice from the full sketch
- Closed: #39 scoped oxygen pressure prototype for the production slice
- Closed: #38 tuned production-slice camera framing and expanded the capture set
- Closed: #37 debug/review marker meanings and capture route
- Closed: #36 accepted production-slice visual baseline workflow
- Closed: #35 readable boat-spawn entry and return visual
- Closed: #34 readable salvage and hazard props
- Closed: #33 production-slice topology artifact cleanup
- Closed: #32 production slice source-render-collision review artifact
- Closed: #31 production slice promoted to default preview
- Closed: #30 roadmap expansion after first production slice decision
- Closed: #29 terrain visual polish pass for accepted production slice
- Closed: #28 full-sketch conversion fidelity tooling
- Closed: #27 salvage and object semantics in map JSON
- Closed: #26 first scoped hazard interaction
- Closed: #25 player swim feel and collision clearance for production slice
- Closed: #24 production slice preview shortcut and capture route
- Closed: #23 first production slice JSON from selected full sketch region
- Closed: #22 boat and top-water spawn/extraction model
- Closed: #21 full sketch topology evaluation and first production slice selection
- Closed: #18 JSON-to-Godot map render and collision parity check
- Closed: #16 minimal salvage collection and extraction loop
- Closed: #15 preview review framing and version watermark
- Closed: #20 full sketch map local preview workflow
- Closed: #19 full-map sketch topology draft conversion
- Closed: #17 web preview greybox terrain fallback regression
- Closed: #14 organic map default preview workflow
- Closed: #13 local Godot preview helper
- Closed: #1 Godot greybox scene
- Closed: #2 modular cave terrain asset kit
- Closed: #3 terrain modules over greybox
- Closed: #4 first in-engine visual baseline
- Closed: #5 Godot headless smoke check workflow
- Closed: #6 named camera visual capture workflow
- Closed: #7 grid-aligned cave TileSet visual refinement
- Closed: #8 first real cave TileSet terrain renderer
- Closed: #9 exact-mask cave tileset upgrade and stress test
- Closed: #10 Godot Web export preview pipeline
- Closed: #11 web preview cave terrain rendering fix
- Closed: #12 organic salvage cave map source pass

Recent important commits:

- `c2cc2e6` Polish production slice terrain tiles
- `686c8b9` Add full sketch conversion review artifact
- `1940ab1` Refine greybox entity validation
- `3f08ce5` Add scoped hazard interaction
- `53438f0` Tune production slice swim clearance
- `bd77145` Add production slice preview shortcut
- `a55e3de` Add first production slice map
- `6e18c02` Add boat spawn extraction model
- `44e758f` Evaluate full sketch production slice
- `918d0e1` Add parity checks preview overlay and salvage loop
- `46a833b` Expose full sketch map preview workflow
- `7bd6d65` Add full cave sketch map draft
- `9c9abd8` Import Godot assets before smoke check
- `9c4f34a` Prevent web preview greybox fallback
- `1ab4c27` Expose organic map as default preview
- `d2cd895` Add organic salvage cave map pass
- `367172e` Add local Godot preview helper
- `1a8ceb6` Refine cave tileset top edges
- `90d1f10` Add Godot smoke workflow
- `3c63de4` Package terrain assets in web export
- `c6f6e6b` Fix web preview cave terrain rendering
- `6f96fb1` Add Godot web export preview pipeline
- `280e373` Add organic cave tileset stress test
- `61501ca` Build grid-aligned cave terrain renderer

## Known Limits

- Terrain art has a first targeted polish pass, but it is still structural prototype art rather than final production art.
- `production_slice_01` is the default preview map.
- `cave_salvage_organic_01` is preserved as a first playable organic source-map comparison pass.
- `cave_salvage_test_01` is preserved as the original rectangular comparison map.
- `full_cave_sketch_01` is a topology-only draft conversion from a supplied full-map sketch; icons are intentionally ignored and the top-water `boat_spawn` is present for entry/extraction validation.
- `docs/current/PRODUCTION_SLICE_SELECTION_CRITERIA.md` defines reusable roles and checklist criteria for choosing future focused slices from the full sketch.
- `docs/current/PRODUCTION_SLICE_INDEX.md` summarizes the current production slices, including role, source, launch command, route smoke, capture folders, source/render/collision review sheet, and accepted baseline status.
- `docs/current/POST_SLICE_WORKFLOW_DECISION.md` records that the focused slice workflow is repeatable enough to move into controlled visual-revision work without productionizing the whole full sketch.
- `docs/current/CONTROLLED_VISUAL_REVISION_01_PLAN.md` selects the first controlled visual-revision target: replace procedural salvage/hazard prop drawings with named committed sprite assets under #70.
- `docs/current/CONTROLLED_VISUAL_REVISION_02_PLAN.md` selects the next controlled visual-revision target: replace the procedural player placeholder with a named committed `player_diver_01.png` sprite while preserving collision, movement, camera behavior, map data, and gameplay logic.
- `docs/current/CONTROLLED_VISUAL_REVISION_03_PLAN.md` selects the next controlled visual-revision target: replace the procedural `boat_spawn` entry craft with a named committed `boat_spawn_01.png` sprite while preserving source-map boat entry/extraction semantics, player spawn, collision, movement, camera behavior, map data, and gameplay logic.
- `docs/current/CONTROLLED_VISUAL_REVISION_04_PLAN.md` selects the next controlled visual-revision target: improve the non-collision background/depth layer with a named `background_rocks_02.png` variant while preserving maps, terrain tiles, collision, movement, camera behavior, gameplay logic, approved foreground sprites, and accepted baselines until review.
- `docs/current/CONTROLLED_VISUAL_REVISION_05_PLAN.md` selects the next controlled visual-revision target: create a named `cave_tileset_v2.png` atlas variant while preserving map data, terrain/collision cells, route design, camera tests, accepted foreground/background assets, gameplay behavior, and default preview selection.
- `docs/current/CONTROLLED_GAMEPLAY_PASS_01_PLAN.md` selects the next controlled prototype target: tune player movement feel and readability while preserving map source data, terrain/collision, player sprite art, camera framing, salvage/hazard/oxygen semantics, and accepted visual baselines until review.
- `docs/current/MOVEMENT_FEEL_BASELINE_DECISION.md` records #104: the current movement-feel baseline is accepted for the prototype at `200 px/s` swim speed, `620 px/s^2` acceleration, and `900 px/s^2` deceleration.
- `docs/current/SALVAGE_OXYGEN_FEEDBACK_PLAN.md` selects the next controlled prototype target: improve the existing review overlay feedback for held/banked salvage, oxygen pressure, and reset/failure moments while preserving gameplay semantics.
- `docs/current/SALVAGE_OXYGEN_FEEDBACK_BASELINE_DECISION.md` records #107: the clearer salvage/oxygen overlay is accepted in normal production-slice visual baselines for slices 01-04.
- `docs/current/SALVAGE_OXYGEN_FEEDBACK_WEB_PREVIEW_VERIFICATION.md` records #108: the public Pages preview deployed the salvage/oxygen feedback runtime commit successfully, matched external build metadata, loaded without missing-resource or Godot errors, and showed the separated overlay lines in the browser screenshot.
- `docs/current/TERRAIN_TILESET_V2_BASELINE_DECISION.md` records #96: `cave_tileset_v2.png` is approved for the current prototype terrain baseline, and accepted baselines were updated for production slices 01-04.
- `docs/current/TERRAIN_TILESET_V2_WEB_PREVIEW_VERIFICATION.md` records #97: the public Pages preview deployed the terrain tileset v2 runtime commit successfully, matched external build metadata, and loaded the updated runtime without missing texture warnings.
- `assets/terrain_tiles/cave_tileset_v2.png` is the active approved runtime terrain atlas; `cave_tileset_v1.png` remains committed for comparison and rollback.
- `tools/render_terrain_atlas_coverage.py` renders `references/asset_reviews/cave_tileset_v1_coverage_review.png` and validates that atlas coordinates used by `scripts/world/greybox_world.gd` are present in the terrain manifest before terrain tileset revisions are accepted.
- `docs/current/CONTROLLED_VISUAL_REVISION_CHECKLIST.md` is the reusable checklist for future controlled visual revisions, covering planning, source-of-truth constraints, capture comparison, baseline acceptance, Web preview verification, and follow-up issues.
- `docs/current/PROP_SPRITE_BASELINE_DECISION.md` records #71: the prop sprites are approved for the current prototype, accepted baselines were updated for slices 02-04, and slice 01 baseline reconciliation was split into #75.
- `docs/current/PLAYER_SPRITE_BASELINE_DECISION.md` records #78: the player sprite is approved for the current prototype, and accepted baselines were updated for slices 01-04.
- `docs/current/PLAYER_SPRITE_WEB_PREVIEW_VERIFICATION.md` records #79: the public Pages preview deployed the player sprite runtime commit successfully, loaded terrain/player assets without missing texture warnings, and showed the player sprite in the browser screenshot.
- `docs/current/BOAT_SPAWN_ENTRY_BASELINE_DECISION.md` records #86: the boat spawn entry sprite is approved for the current prototype, and the accepted slice-01 baseline was updated for the new boat visual.
- `docs/current/BOAT_SPAWN_WEB_PREVIEW_VERIFICATION.md` records #87: the public Pages preview deployed the boat sprite runtime commit successfully, matched external build metadata, loaded assets without missing texture warnings, and showed the updated boat in the browser screenshot.
- `docs/current/BACKGROUND_DEPTH_BASELINE_DECISION.md` records #91: `background_rocks_02.png` is approved for the current prototype, and accepted baselines were updated for production slices 01-04.
- `docs/current/BACKGROUND_DEPTH_WEB_PREVIEW_VERIFICATION.md` records #92: the public Pages preview deployed the background-depth runtime commit successfully, matched external build metadata, and loaded the updated runtime without missing texture warnings.
- `docs/current/PRODUCTION_SLICE_01_VISUAL_BASELINE_RECONCILIATION.md` records #75: the default slice accepted baseline now covers the current six-view capture set.
- `docs/current/BACKLOG_REFRESH_2026_07_06.md` records the recommended issue order after #74.
- `docs/current/BACKLOG_REFRESH_POST_GAMEPLAY_PASS_01_2026_07_06.md` records the active recommended issue order after Controlled Gameplay Pass 01 and the salvage/oxygen feedback pass.
- `docs/current/CONTROLLED_GAMEPLAY_PASS_02_PLAN.md` selects the next controlled prototype target: one readable route-choice loop in `production_slice_01`, pairing a safer salvage route with a more valuable pickup under oxygen pressure while preserving source-of-truth map discipline.
- `docs/current/CONTROLLED_GAMEPLAY_PASS_03_PLAN.md` selects the next controlled prototype target: make the default loop feel like an expedition by adding scored salvage, cargo pressure, compact run results, retry flow, and one more authored route decision.
- `docs/current/OXYGEN_PRESSURE_BASELINE_DECISION.md` records #113: the current oxygen baseline keeps a 90-second tank, starts `LOW` feedback at 35 seconds, escalates to `CRITICAL` at 12 seconds, and preserves the existing refill/depletion semantics.
- `docs/current/ROUTE_PAYOFF_VISUAL_BASELINE_DECISION.md` records #118: the tiny valuable-salvage cue on `salvage_lower_loop` is accepted in the `production_slice_01` visual baseline.
- `docs/current/ROUTE_PAYOFF_WEB_PREVIEW_VERIFICATION.md` records #119: the public Pages preview deployed the route/payoff runtime commit successfully, matched external build metadata, initialized the Godot canvas, and emitted no missing-resource or Godot error messages.
- `references/greybox/full_cave_sketch_01_conversion_review.png` is generated by the full-sketch converter and compares source sketch, generated tiles, and overlay with conversion stats.
- `references/greybox/production_slice_01_source_render_collision_review.png` compares production-slice JSON topology, expected collision rectangles, and the Godot overview capture.
- `references/greybox/production_slice_02_source_render_collision_review.png` compares slice 02 JSON topology, expected collision rectangles, and the Godot overview capture.
- `references/greybox/production_slice_03_source_render_collision_review.png` compares slice 03 JSON topology, expected collision rectangles, and the Godot overview capture.
- `references/greybox/production_slice_04_source_render_collision_review.png` compares slice 04 JSON topology, expected collision rectangles, and the Godot overview capture.
- `production_slice_01` is the first focused slice from the full sketch's top-center entry hub; it preserves the selected topology, seals left/right/bottom crop edges, fills unreachable conversion pockets, applies targeted one-cell tip/notch cleanup in source generation, and adds authored boat spawn, salvage, hazards, route markers, and camera tests.
- `production_slice_01` marks `salvage_lower_loop` and `salvage_deep_right_cache` as current `valuable` route-choice payoff targets.
- `production_slice_02` is the second focused slice from the full sketch's lower-right chamber route. It is a later-game destination/connector candidate, not an alternate first area. It uses an in-water `spawn` and `base` extraction zone because the region has no natural top-water boat opening.
- `production_slice_03` is the third focused slice from the full sketch's upper-left room cluster. It is a connector/landmark room-cluster candidate with compact stacked-room navigation and an east-side in-water `spawn` plus `base` relay extraction zone.
- `production_slice_04` is the fourth focused slice from the full sketch's lower-left loop. It is a connector/return-loop candidate with curved-corridor movement and an east-side in-water `spawn` plus `base` relay extraction zone.
- `docs/current/PRODUCTION_SLICE_02_DECISION.md` records the bounds, rationale, spawn/extraction plan, and verification for the second slice.
- `docs/current/PRODUCTION_SLICE_02_VISUAL_BASELINE_DECISION.md` records the original slice-02 baseline deferral and the 2026-07-06 update accepting the current captures as the named visual baseline.
- `docs/current/PRODUCTION_SLICE_02_EVALUATION.md` records that slice 02 should stay a validated later-game reference slice, now with an accepted five-view visual baseline.
- `docs/current/PRODUCTION_SLICE_03_DECISION.md` selects the upper-left room cluster as the third focused slice candidate with starting bounds `x=0, y=8, w=76, h=82` and likely `spawn + base` relay extraction.
- `docs/current/PRODUCTION_SLICE_03_EVALUATION.md` records that slice 03 is a validated connector/landmark reference slice. Relay readability is accepted for the prototype pass, camera/source cleanup is not blocking, baseline acceptance remains separate, and slice 01 should stay the default preview for now.
- `docs/current/PRODUCTION_SLICE_03_DEFAULT_PREVIEW_DECISION.md` records that slice 03 should stay a reference slice and should not replace slice 01 as the Godot or public web default preview.
- `docs/current/PRODUCTION_SLICE_04_DECISION.md` selects the lower-left loop as the fourth focused slice candidate with bounds `x=0, y=86, w=88, h=50`, a `spawn + base` relay plan near global `(74, 104)`, and follow-up implementation issue #61.
- `docs/current/PRODUCTION_SLICE_04_DECISION.md` also records implementation status for #61 and points to #62 for the evaluation pass.
- `docs/current/PRODUCTION_SLICE_04_EVALUATION.md` records that slice 04 is a validated lower-left connector/return-loop reference slice. Source/collision, route smoke, relay readability, and capture completeness pass; baseline status remains separate under #63.
- `docs/current/PRODUCTION_SLICE_04_VISUAL_BASELINE_DECISION.md` records that current slice 04 captures are accepted as the named slice-04 visual baseline.
- `--smoke-production-slice-02-route` verifies `production_slice_02` by swimming through authored salvage with the normal movement controller and returning to the relay extraction zone.
- `--smoke-production-slice-03-route` verifies `production_slice_03` by swimming through authored salvage with the normal movement controller and returning to the relay extraction zone.
- `--smoke-production-slice-04-route` verifies `production_slice_04` by swimming through authored salvage with the normal movement controller and returning to the relay extraction zone.
- `--smoke-player-facing` verifies the player direction-change path by keeping the root transform stable while flipping only the diver body and light-cone visuals.
- `--smoke-movement-feel` drives the player controller through start, stop, horizontal reversal, and diagonal movement phases, then reports measured velocities for the Controlled Gameplay Pass 01 tuning pass.
- `--smoke-route-choice` drives the player through the default slice route-choice probe by swimming from the boat entry to the authored `valuable` salvage target, collecting it, returning to extraction, and reporting the target/collection/return state.
- `--smoke-expanded-route-choice` verifies the `expanded_route_choice` source metadata, swims through `salvage_lower_loop` and `salvage_deep_right_cache`, banks both valuable pickups at the boat, and reports targets, cargo, score, return, and oxygen.
- `--smoke-cargo-capacity` fills the current two-pickup cargo capacity, verifies held score is not banked before extraction, verifies an extra nearby salvage stays available while full, banks held salvage/score at extraction, then verifies the blocked pickup can be collected after capacity frees up.
- `--smoke-salvage-loop` also verifies the completion-only expedition result panel reports banked score and salvage totals after a full collect-return run.
- `--capture-feedback-overlay` writes `visual_captures/feedback_overlay/production_slice_01_feedback_overlay.png` as the focused review capture for the salvage/oxygen feedback overlay pass.
- The `Godot Smoke` workflow runs the salvage loop, scoring/cargo smoke, all four production-slice route smokes, the default-slice route-choice smoke, the expanded route-choice smoke, and the player-facing smoke, so CI covers the default slice, its valuable salvage routes, cargo banking, the later reference slices, and the direction-change regression path.
- `production_slice_02` has five tuned camera captures: overview, relay entry, main chamber, lower terminal, and return route. Normal captures live in `visual_captures/production_slice_02/`; debug captures live in `visual_captures/production_slice_02_debug/`.
- `production_slice_03` has five authored camera captures: overview, relay entry, stacked rooms, connector, and return route. Normal captures live in `visual_captures/production_slice_03/`; debug captures live in `visual_captures/production_slice_03_debug/`.
- `production_slice_04` has five authored camera captures: overview, relay entry, lower-left loop, curved corridor, and return route. Normal captures live in `visual_captures/production_slice_04/`; debug captures live in `visual_captures/production_slice_04_debug/`.
- `tools/check_camera_captures.py` checks that a capture directory contains every PNG named by a map's authored `camera_tests`, ignoring Godot `.import` sidecars and reporting missing, extra, invalid, or stale-looking captures.
- `tools/check_production_slice_captures.py` runs the committed-capture completeness check for all production slices. The `Godot Smoke` workflow runs it without `--fail-on-stale` so CI catches missing, extra, or invalid captures without requiring a display renderer or relying on checkout mtimes.
- `tools/check_asset_manifest.py` verifies that `draft`, `approved`, and `locked` table entries in `docs/ASSET_MANIFEST.md` still point to committed files under `assets/` or `references/asset_reviews/`, while ignoring planned future assets.
- `visual_baselines/production_slice_01_accepted/` stores the accepted six-view production-slice visual baseline. Use `python tools/manage_production_slice_baseline.py compare` to render `references/asset_reviews/production_slice_01_visual_baseline_review.png` before accepting future visual changes.
- `tools/manage_production_slice_baseline.py` supports `--slice production_slice_01`, `--slice production_slice_02`, `--slice production_slice_03`, and `--slice production_slice_04` for compare/accept workflows. Use an explicit `--baseline-dir visual_captures/<slice>` only for tooling sanity checks, not as acceptance.
- `visual_baselines/production_slice_02_accepted/` stores the accepted five-view slice-02 visual baseline. Use `python tools/manage_production_slice_baseline.py --slice production_slice_02 compare` to render `references/asset_reviews/production_slice_02_visual_baseline_review.png` before accepting future slice-02 visual changes.
- `visual_baselines/production_slice_03_accepted/` stores the accepted five-view slice-03 visual baseline. Use `python tools/manage_production_slice_baseline.py --slice production_slice_03 compare` to render `references/asset_reviews/production_slice_03_visual_baseline_review.png` before accepting future slice-03 visual changes.
- `visual_baselines/production_slice_04_accepted/` stores the accepted five-view slice-04 visual baseline. Use `python tools/manage_production_slice_baseline.py --slice production_slice_04 compare` to render `references/asset_reviews/production_slice_04_visual_baseline_review.png` before accepting future slice-04 visual changes.
- Use `python tools/manage_production_slice_baseline.py compare-all` to refresh every accepted production-slice baseline/current/difference review sheet before controlled visual-revision work.
- `boat_spawn` now renders as a small top-water surface craft with a hatch/tether cue at the authored entry cell while still using the source rectangle for extraction.
- In-water `base` extraction zones now render as compact relay/sub return visuals with a spawn cue when a legacy `spawn` point sits inside the zone. The visual does not change source collision, spawn, extraction, salvage, hazard, or terrain data.
- The review overlay includes a local/editor-only map selector for supported review maps. It reloads world/player state cleanly, preserves the debug-overlay mode, and is covered by `--smoke-map-selector`.
- Collision is rectangular per terrain block; player collision is tuned smaller than the placeholder body art for production-slice clearance.
- Player movement is currently tuned to `200 px/s` swim speed, `620 px/s^2` acceleration, and `900 px/s^2` deceleration for Controlled Gameplay Pass 01.
- Player facing now keeps the `CharacterBody2D` root at normal scale and flips only the `Body` sprite plus `LightCone`, avoiding transient double-facing artifacts from mirroring the whole player node.
- `docs/current/PLAYER_FACING_WEB_PREVIEW_VERIFICATION.md` records #99: the public Pages preview deployed the #98 player-facing runtime fix successfully, matched external build metadata, initialized the Godot canvas, and emitted no missing-resource or Godot error messages.
- The salvage/oxygen overlay now separates banked salvage, held salvage, oxygen, and prompt/state lines so held-return, low oxygen, depletion, hazard reset, and run completion states are easier to read.
- Salvage has a minimal collect-return-complete-reset loop.
- Hazards now have a tiny scoped interaction: touching one bumps the player back to spawn, briefly tints the player, and restores held/unbanked salvage to the map.
- The first scoped expedition pressure is a simple oxygen timer: oxygen drains away from extraction, refills at the boat/extraction area, and depletion surfaces the player while restoring held/unbanked salvage to the map.
- Current oxygen pressure timing keeps a 90-second tank, starts `LOW` feedback at 35 seconds, and escalates to `CRITICAL` at 12 seconds.
- Salvage map data may include optional `tier` values. Missing tiers default conceptually to `common`; the current supported tiers are `common` and `valuable`. Runtime score is tier-derived for now: `common` is worth 100 and `valuable` is worth 300.
- Held salvage capacity is currently 2 pickups. Full cargo blocks additional collection without hiding or banking the blocked pickup, and returning to extraction frees capacity.
- Run completion shows a compact result panel with final score, salvage banked, oxygen, and retry prompt. Oxygen depletion now shows the same result panel as a failed expedition and pauses the run until reset. The panel stays hidden during normal exploration.
- There is no health, inventory screen, upgrade economy, or real enemy behavior yet.
- Background art is still rough and secondary to proving terrain readability.
- Normal preview uses approved current-prototype sprite assets for salvage and hazard props, with procedural fallback if a sprite cannot be loaded.
- `valuable` salvage renders with a small extra gold cue over the existing salvage prop; `common` or omitted tiers keep the existing prop appearance.
- The first controlled visual-revision target landed as #70 and was reviewed under #71. It adds `assets/props/` sprites generated by `tools/generate_prop_sprites.py`, keeps map data, collision, behavior, and debug markers unchanged, updates accepted baselines for slices 02-04, and leaves slice 01 baseline reconciliation to #75. #75 later reconciled slice 01 to the current six-view default-slice baseline.
- The second controlled visual-revision target is the player placeholder. #77 added `assets/player/player_diver_01.png`, `tools/generate_player_sprite.py`, `references/asset_reviews/player_sprite_01_review.png`, and updated `scenes/player/Player.tscn` without changing the player collision shape, movement controller, camera behavior, light cone, map data, or gameplay logic. #78 accepted the sprite and refreshed accepted baselines for slices 01-04.
- The third controlled visual-revision target is the top-water boat entry visual. #85 added `assets/vehicles/boat_spawn_01.png`, `tools/generate_boat_spawn_sprite.py`, `references/asset_reviews/boat_spawn_01_review.png`, and renderer integration in `scripts/world/greybox_world.gd` without changing maps, boat entry/extraction source semantics, collision, player spawn, movement, camera behavior, or gameplay logic. #86 accepted the sprite and refreshed the accepted `production_slice_01` baseline. #87 verified the public Web preview against deployed build metadata.
- `--capture-player-readability` writes `visual_captures/player_readability/production_slice_01_player_start.png` as the close default-slice review shot for the player sprite pass.
- The source map/grid and entity review markers can be shown with `--show-debug-overlay`; dedicated production-slice debug captures are written with `--capture-production-slice-debug-map` to `visual_captures/production_slice_01_debug/`.
- Debug marker roles are: cyan source grid, white route rectangles, amber boat/extraction outlines, green entry/spawn labels, yellow salvage diamonds, and red hazard squares.
- `production_slice_01` now has six authored camera captures: overview, entry shaft, first route choice, central crossing, lower loop, and return-to-boat context. Use `--quit-after 20` when regenerating this set so every view is written.

## Recommended Next Work

The first full-sketch evaluation selected the top-center entry hub as the first production slice target:

```text
x: 58
y: 0
w: 72
h: 84
```

The first production slice is meant to test a focused version of the intended workflow: supplied full-sketch topology becomes JSON source data, Godot renders that source through grid-aligned terrain, collision remains source-derived, the player starts at a top-water boat entry, and a small collect-return route can be validated repeatedly.

Accepted constraints for the next batch:

- Do not move the entire full sketch into production yet; work from focused slices.
- Keep `production_slice_01` bounded to the selected top-center entry hub region unless a source-data cleanup issue intentionally revises it.
- Use `boat_spawn` as the preferred production-style entry and extraction model.
- Keep gameplay scoped to movement, salvage, hazards, extraction, reset, and review UI until the visual pipeline is trustworthy.
- Keep the visual target clean side-view underwater cave terrain with grid-aligned seam-critical tiles; fix individual assets or source data instead of regenerating whole scenes.

Recommended next order:

1. Work through the Controlled Gameplay Pass 03 batch: scored salvage, cargo pressure, run summary, retry flow, and one additional source-authored route decision.
2. Keep #52/#53 as optional post-baseline slice-03 improvement issues unless the selected goal shifts back to slice-03 presentation.

Keep new work small. If a task touches visual style, map topology, renderer behavior, and gameplay at once, split it into separate issues.

## Project Instructions For Future Sessions

Use this as the short project instruction text if moving context into a ChatGPT Project:

```text
This project is for oceangame2, a Godot 4.7 side-view ocean salvage visual prototype.

Prioritize visual consistency, map/source-of-truth discipline, GitHub issue workflow, and small scoped implementation passes. Before making changes, read AGENTS.md, docs/current/PROJECT_CONTEXT.md, and relevant current docs. Use GitHub issues for actionable work. Do not regenerate the whole visual scene to fix one visual issue. For terrain/map changes, update source data or renderer first, then verify with screenshots/web preview.
```

