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
- Current terrain atlas: `assets/terrain_tiles/cave_tileset_v1.png`
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
- Post-slice workflow decision: `docs/current/POST_SLICE_WORKFLOW_DECISION.md`

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

The main scene also shows a compact preview overlay with map id, build label, salvage progress, and a scoped oxygen timer. The minimal gameplay loop lets the player collect authored salvage, return to the extraction zone to complete the run, and press `R` to reset. Hazards now have a small bump/reset interaction without a full health system.

Maps may use either a legacy `spawn` entity or the newer `boat_spawn` entity. `boat_spawn` is the preferred top-water entry/extraction marker for production-style maps; the player starts at its `entry_x`/`entry_y` cell, and runtime extraction checks also accept its boat rectangle.

The greybox validator now checks entity schema as well as reachability: unique lower_snake_case entity ids, supported entity types, required salvage/hazard kinds, coordinate bounds, exactly one player entry, and extraction requirements for playable salvage maps.

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
- exports to ignored `exports/web/`
- serves the export and runs `tools/check_web_preview.cjs` in Chromium to catch missing terrain assets before deploy
- uploads the `oceangame2-web-export` artifact
- deploys to GitHub Pages when Pages is enabled

Important fixed pitfall: Web exports did not package dynamically loaded PNG terrain assets. The fix was:

- preload terrain textures in `scripts/world/greybox_world.gd`
- include `*.json,*.png,*.svg` in `tools/write_web_export_preset.py`
- fail the web export workflow if the browser console reports missing terrain textures or TileSet creation errors

If the browser preview ever shows only blue water, faint rectangles, markers, and no cave tiles, check browser logs for missing `res://assets/...png` warnings and verify the export package includes the assets.

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
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-02-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-03-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-04-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-map-selector
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-interaction
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
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
- `references/greybox/full_cave_sketch_01_conversion_review.png` is generated by the full-sketch converter and compares source sketch, generated tiles, and overlay with conversion stats.
- `references/greybox/production_slice_01_source_render_collision_review.png` compares production-slice JSON topology, expected collision rectangles, and the Godot overview capture.
- `references/greybox/production_slice_02_source_render_collision_review.png` compares slice 02 JSON topology, expected collision rectangles, and the Godot overview capture.
- `references/greybox/production_slice_03_source_render_collision_review.png` compares slice 03 JSON topology, expected collision rectangles, and the Godot overview capture.
- `references/greybox/production_slice_04_source_render_collision_review.png` compares slice 04 JSON topology, expected collision rectangles, and the Godot overview capture.
- `production_slice_01` is the first focused slice from the full sketch's top-center entry hub; it preserves the selected topology, seals left/right/bottom crop edges, fills unreachable conversion pockets, applies targeted one-cell tip/notch cleanup in source generation, and adds authored boat spawn, salvage, hazards, route markers, and camera tests.
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
- The `Godot Smoke` workflow runs all four production-slice route smokes, so CI covers the default slice and the later reference slices.
- `production_slice_02` has five tuned camera captures: overview, relay entry, main chamber, lower terminal, and return route. Normal captures live in `visual_captures/production_slice_02/`; debug captures live in `visual_captures/production_slice_02_debug/`.
- `production_slice_03` has five authored camera captures: overview, relay entry, stacked rooms, connector, and return route. Normal captures live in `visual_captures/production_slice_03/`; debug captures live in `visual_captures/production_slice_03_debug/`.
- `production_slice_04` has five authored camera captures: overview, relay entry, lower-left loop, curved corridor, and return route. Normal captures live in `visual_captures/production_slice_04/`; debug captures live in `visual_captures/production_slice_04_debug/`.
- `tools/check_camera_captures.py` checks that a capture directory contains every PNG named by a map's authored `camera_tests`, ignoring Godot `.import` sidecars and reporting missing, extra, invalid, or stale-looking captures.
- `tools/check_production_slice_captures.py` runs the committed-capture completeness check for all production slices. The `Godot Smoke` workflow runs it without `--fail-on-stale` so CI catches missing, extra, or invalid captures without requiring a display renderer or relying on checkout mtimes.
- `visual_baselines/production_slice_01_accepted/` stores the accepted four-view production-slice visual baseline. Use `python tools/manage_production_slice_baseline.py compare` to render `references/asset_reviews/production_slice_01_visual_baseline_review.png` before accepting future visual changes.
- `tools/manage_production_slice_baseline.py` supports `--slice production_slice_01`, `--slice production_slice_02`, `--slice production_slice_03`, and `--slice production_slice_04` for compare/accept workflows. Use an explicit `--baseline-dir visual_captures/<slice>` only for tooling sanity checks, not as acceptance.
- `visual_baselines/production_slice_02_accepted/` stores the accepted five-view slice-02 visual baseline. Use `python tools/manage_production_slice_baseline.py --slice production_slice_02 compare` to render `references/asset_reviews/production_slice_02_visual_baseline_review.png` before accepting future slice-02 visual changes.
- `visual_baselines/production_slice_03_accepted/` stores the accepted five-view slice-03 visual baseline. Use `python tools/manage_production_slice_baseline.py --slice production_slice_03 compare` to render `references/asset_reviews/production_slice_03_visual_baseline_review.png` before accepting future slice-03 visual changes.
- `visual_baselines/production_slice_04_accepted/` stores the accepted five-view slice-04 visual baseline. Use `python tools/manage_production_slice_baseline.py --slice production_slice_04 compare` to render `references/asset_reviews/production_slice_04_visual_baseline_review.png` before accepting future slice-04 visual changes.
- Use `python tools/manage_production_slice_baseline.py compare-all` to refresh every accepted production-slice baseline/current/difference review sheet before controlled visual-revision work.
- `boat_spawn` now renders as a small top-water surface craft with a hatch/tether cue at the authored entry cell while still using the source rectangle for extraction.
- In-water `base` extraction zones now render as compact relay/sub return visuals with a spawn cue when a legacy `spawn` point sits inside the zone. The visual does not change source collision, spawn, extraction, salvage, hazard, or terrain data.
- The review overlay includes a local/editor-only map selector for supported review maps. It reloads world/player state cleanly, preserves the debug-overlay mode, and is covered by `--smoke-map-selector`.
- Collision is rectangular per terrain block; player collision is tuned smaller than the placeholder body art for production-slice clearance.
- Salvage has a minimal collect-return-complete-reset loop.
- Hazards now have a tiny scoped interaction: touching one bumps the player back to spawn, briefly tints the player, and restores held/unbanked salvage to the map.
- The first scoped expedition pressure is a simple oxygen timer: oxygen drains away from extraction, refills at the boat/extraction area, and depletion surfaces the player while restoring held/unbanked salvage to the map.
- There is no health, inventory screen, upgrade economy, or real enemy behavior yet.
- Background art is still rough and secondary to proving terrain readability.
- Normal preview uses first-pass readable salvage and hazard props instead of abstract marker shapes.
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

1. Do #69 to choose the first controlled visual-revision target before changing art, renderer rules, or runtime visuals.
2. Run `python tools/manage_production_slice_baseline.py compare-all` before and after controlled visual-revision work to inspect accepted-baseline differences.
3. Keep #52/#53 as optional post-baseline slice-03 improvement issues if the accepted slice-03 reference needs intentional camera or source cleanup.

Keep new work small. If a task touches visual style, map topology, renderer behavior, and gameplay at once, split it into separate issues.

## Project Instructions For Future Sessions

Use this as the short project instruction text if moving context into a ChatGPT Project:

```text
This project is for oceangame2, a Godot 4.7 side-view ocean salvage visual prototype.

Prioritize visual consistency, map/source-of-truth discipline, GitHub issue workflow, and small scoped implementation passes. Before making changes, read AGENTS.md, docs/current/PROJECT_CONTEXT.md, and relevant current docs. Use GitHub issues for actionable work. Do not regenerate the whole visual scene to fix one visual issue. For terrain/map changes, update source data or renderer first, then verify with screenshots/web preview.
```

