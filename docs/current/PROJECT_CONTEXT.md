# Project Context

Last updated: 2026-07-05

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
- Default preview map source: `maps/cave_salvage_organic_01.greybox.json`
- Original comparison map source: `maps/cave_salvage_test_01.greybox.json`
- Organic tileset stress-test map: `maps/cave_tileset_test_01.greybox.json`
- Current terrain atlas: `assets/terrain_tiles/cave_tileset_v1.png`
- Web export workflow: `.github/workflows/godot-web-export.yml`

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
- Hides the source grid in normal preview mode.
- Supports `--show-debug-overlay` for map debugging.

Current map-loading helper:

- Open the editor: `.\tools\open_godot_project.ps1`
- Run the default organic map locally: `.\tools\open_godot_project.ps1 -Run`
- Run the original comparison map locally: `.\tools\open_godot_project.ps1 -Run -OriginalMap`

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
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

Capture normal visual views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-camera-tests
```

Capture the organic tileset stress-test views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-tileset-test
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

Current issue state as of 2026-07-05:

- Open: #15 `Add preview review framing and version watermark`
- Open: #16 `Add minimal salvage collection and extraction loop`
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

- Terrain art is still first-pass structural placeholder art.
- `cave_salvage_organic_01` is the default preview map, but it is still a first playable organic source-map pass.
- `cave_salvage_test_01` is preserved as the original rectangular comparison map.
- Collision is rectangular per terrain block.
- Salvage and hazards are visual markers only.
- There is no scoring, inventory, health, oxygen, extraction loop, or real enemy behavior yet.
- Background art is still rough and secondary to proving terrain readability.
- The source map/grid can be shown with `--show-debug-overlay`, but normal preview should be terrain-first.

## Recommended Next Work

The most logical next work is probably one of:

1. Implement issue #15 to make visual review easier with map/build context and stable framing.
2. Implement issue #16 for the first tiny salvage collection/extraction loop.
3. Create a small backlog expansion pass so the repo returns closer to about 10 open actionable issues.

Keep new work small. If a task touches visual style, map topology, renderer behavior, and gameplay at once, split it into separate issues.

## Project Instructions For Future Sessions

Use this as the short project instruction text if moving context into a ChatGPT Project:

```text
This project is for oceangame2, a Godot 4.7 side-view ocean salvage visual prototype.

Prioritize visual consistency, map/source-of-truth discipline, GitHub issue workflow, and small scoped implementation passes. Before making changes, read AGENTS.md, docs/current/PROJECT_CONTEXT.md, and relevant current docs. Use GitHub issues for actionable work. Do not regenerate the whole visual scene to fix one visual issue. For terrain/map changes, update source data or renderer first, then verify with screenshots/web preview.
```

