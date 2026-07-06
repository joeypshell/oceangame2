# Tooling

## Local Checks

Open the project in the Godot editor:

```powershell
.\tools\open_godot_project.ps1
```

Or double-click `open-godot.cmd` from the repository root.

Run the current project scene locally:

```powershell
.\tools\open_godot_project.ps1 -Run
```

The current default preview map is `maps/production_slice_01.greybox.json`.

Run with the source map/grid overlay visible:

```powershell
.\tools\open_godot_project.ps1 -Run -DebugOverlay
```

Run the original rectangular salvage map for comparison:

```powershell
.\tools\open_godot_project.ps1 -Run -OriginalMap
```

Run the organic salvage map explicitly:

```powershell
.\tools\open_godot_project.ps1 -Run -OrganicMap
```

Run the full-map sketch topology draft:

```powershell
.\tools\open_godot_project.ps1 -Run -FullSketchMap
```

Run the first production slice:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSliceMap
```

Run the second production slice:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSlice2Map
```

Run any map source by path:

```powershell
.\tools\open_godot_project.ps1 -Run -MapPath "res://maps/cave_salvage_organic_01.greybox.json"
```

If Godot is installed somewhere else, either set `GODOT_EXE` or pass `-GodotPath`:

```powershell
.\tools\open_godot_project.ps1 -GodotPath "C:\Path\To\Godot_v4.7-stable_win64.exe"
```

Check which executable and project path the helper will use without launching Godot:

```powershell
.\tools\open_godot_project.ps1 -CheckOnly
```

Validate map reachability:

```bash
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
python tools/validate_greybox_map.py maps/cave_salvage_organic_01.greybox.json
python tools/validate_greybox_map.py maps/cave_tileset_test_01.greybox.json
python tools/validate_greybox_map.py maps/full_cave_sketch_01.greybox.json
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
```

Check that Godot's runtime terrain and collision match the authored JSON source:

```bash
python tools/check_map_parity.py
```

Check one map only:

```bash
python tools/check_map_parity.py maps/cave_salvage_organic_01.greybox.json
```

Regenerate the SVG preview from source data:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
python tools/render_greybox_map.py maps/cave_salvage_organic_01.greybox.json references/greybox/cave_salvage_organic_01.svg
python tools/render_greybox_map.py maps/cave_tileset_test_01.greybox.json references/greybox/cave_tileset_test_01.svg
python tools/render_greybox_map.py maps/full_cave_sketch_01.greybox.json references/greybox/full_cave_sketch_01.svg
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/render_greybox_map.py maps/production_slice_02.greybox.json references/greybox/production_slice_02.svg
```

Regenerate the supplied full-map sketch topology draft:

```bash
python tools/convert_full_cave_sketch_map.py
python tools/render_greybox_map.py maps/full_cave_sketch_01.greybox.json references/greybox/full_cave_sketch_01.svg
python tools/validate_greybox_map.py maps/full_cave_sketch_01.greybox.json
```

This draft converts `references/source_maps/full_cave_sketch_01.png` into topology only. White source regions become open water, gray/black source regions become solid terrain/collision, icons are ignored by filling small non-white holes, and a `boat_spawn` entity marks the top-water entry/extraction point.

The converter also writes `references/greybox/full_cave_sketch_01_conversion_review.png`, a side-by-side review sheet showing the source thumbnail, generated open/solid tiles, and source-plus-generated overlay. It prints and embeds conversion stats such as open tiles, filled icon pixels, open components, thin corridor tiles, edge transitions, and open boundary tiles.

Regenerate the first focused production slice:

```bash
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
```

This slice is generated from `maps/full_cave_sketch_01.greybox.json` using bounds `x=58, y=0, w=72, h=84`. It keeps the top-water shaft open for `boat_spawn`, seals left/right/bottom crop edges, and fills unreachable open pockets created by the high-fidelity sketch conversion.

Regenerate the second focused production slice:

```bash
python tools/create_production_slice_02_map.py
python tools/render_greybox_map.py maps/production_slice_02.greybox.json references/greybox/production_slice_02.svg
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
python tools/check_map_parity.py maps/production_slice_02.greybox.json
```

This slice is generated from `maps/full_cave_sketch_01.greybox.json` using bounds `x=88, y=78, w=66, h=72`. It is a later-game destination/connector candidate with an in-water `spawn` and `base` extraction zone rather than a top-water boat.

Run whitespace checks:

```bash
git diff --check
```

Run the Godot headless launch smoke check on this Windows setup:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-02-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-interaction
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
```

The import command is important on a fresh clone or CI checkout because `.godot/` and `*.import` files are intentionally untracked. The headless command can exit `0` even when script errors appear in output, so treat `SCRIPT ERROR` or `ERROR:` lines as failures.

The salvage-loop smoke check loads the default production slice, collects all authored salvage through the same runtime methods used in play, returns to extraction, confirms completion, resets, and exits.

The production-slice route smoke loads `production_slice_01`, asks the world for open-water paths to each authored salvage point and back to the boat, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The production-slice-02 route smoke loads `production_slice_02`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The hazard-interaction smoke loads `production_slice_01`, collects one salvage item, touches an authored hazard, confirms the player resets to spawn and the held salvage is restored, recollects it, resets, and exits.

The oxygen-pressure smoke loads `production_slice_01`, collects one salvage item, forces oxygen depletion, confirms the player surfaces at spawn with held salvage restored, recollects it, returns to extraction, confirms oxygen refills and salvage banks, resets, and exits.

Generate optional local build metadata for the preview overlay:

```bash
python tools/write_build_info.py
```

This writes ignored `build_info.json`. The web export workflow generates that file from `GITHUB_SHA` before export, so the public preview can identify the deployed commit.

Build a local Web export preview:

```powershell
python tools/write_web_export_preset.py
New-Item -ItemType Directory -Force exports/web | Out-Null
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --export-release Web exports/web/index.html
python -m http.server 8060 --directory exports/web
```

Open `http://127.0.0.1:8060/` after the server starts. Do not open `exports/web/index.html` directly; Godot Web exports need to be served over HTTP.

If the local export reports missing `web_nothreads_*` templates, install the Godot 4.7 export templates through the editor or use the GitHub Actions artifact; CI installs templates during the workflow.

Verify a served Web export in Chromium:

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
npm install --prefix "$env:TEMP\oceangame2-web-preview-check" playwright@1.55.0
& "$env:TEMP\oceangame2-web-preview-check\node_modules\.bin\playwright.cmd" install chromium
node tools/check_web_preview.cjs http://127.0.0.1:8060/
```

The check fails if the web preview logs `Unable to open terrain art texture`, `Unable to create cave TileSet`, `SCRIPT ERROR`, `ERROR:`, failed resource requests, or a missing Godot canvas.

GitHub Actions builds the same preview in `Godot Web Export`. The workflow serves the exported build and runs `tools/check_web_preview.cjs` before uploading the artifact or deploying Pages. Download the `oceangame2-web-export` artifact from the workflow run when you need to inspect a build. The workflow also deploys GitHub Pages from `main` when Pages is already enabled for the repository. If the Pages job says it skipped deployment, open repository Settings, enable Pages, and set the source to GitHub Actions. The latest preview should then be available at `https://joeypshell.github.io/oceangame2/`.

Capture the current greybox screenshot baseline:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 5 --capture-greybox-screenshot
```

Do not use `--headless` for screenshot capture on this local setup. Headless uses Godot's dummy renderer here, so the viewport texture is unavailable. Use headless for smoke checks and non-headless for visual capture.

Capture the current named camera test views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-camera-tests
```

This reads `camera_tests` from the default preview map, currently `maps/production_slice_01.greybox.json`, and writes PNGs to `visual_captures/latest/`.
Normal gameplay and capture views hide the greybox source grid. Add `--show-debug-overlay` when you specifically need the source TileMap/grid overlay for map debugging.

Capture the original rectangular salvage map comparison views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-original-map
```

This reads `camera_tests` from `maps/cave_salvage_test_01.greybox.json` and writes PNGs to `visual_captures/original_salvage/`.

Capture the organic tileset stress-test views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-tileset-test
```

This reads `camera_tests` from `maps/cave_tileset_test_01.greybox.json` and writes PNGs to `visual_captures/tileset_test/`.

Capture the organic salvage map pass:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-organic-map
```

This reads `camera_tests` from `maps/cave_salvage_organic_01.greybox.json` and writes PNGs to `visual_captures/organic_salvage/`.

Capture the full-map sketch topology draft:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-full-sketch-map
```

This reads `camera_tests` from `maps/full_cave_sketch_01.greybox.json` and writes PNGs to `visual_captures/full_cave_sketch/`.

Capture the first production slice:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-map
```

This reads `camera_tests` from `maps/production_slice_01.greybox.json` and writes six PNGs to `visual_captures/production_slice_01/`: overview, entry shaft, first route choice, central crossing, lower loop, and return-to-boat context.

Capture the first production slice with debug/review markers visible:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-debug-map
```

This writes PNGs to `visual_captures/production_slice_01_debug/`. The debug overlay uses cyan source grid, white route rectangles, amber boat/extraction outlines, green entry/spawn labels, yellow salvage diamonds, and red hazard squares. Normal production-slice captures stay terrain-first and should not be overwritten with debug views.

Capture the second production slice:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-map
```

This reads `camera_tests` from `maps/production_slice_02.greybox.json` and writes five PNGs to `visual_captures/production_slice_02/`: overview, relay entry, main chamber, lower terminal, and return route.

Capture the second production slice with debug/review markers visible:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-debug-map
```

This writes the same five camera views to `visual_captures/production_slice_02_debug/`.

Check that a capture directory contains every authored `camera_tests` view for a map:

```bash
python tools/check_camera_captures.py maps/production_slice_01.greybox.json visual_captures/production_slice_01
python tools/check_camera_captures.py maps/production_slice_01.greybox.json visual_captures/production_slice_01_debug
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02_debug
```

The checker reads expected PNG names from the map JSON, ignores Godot `.import` sidecars, fails on missing/extra/invalid PNGs, and reports captures that look older than the source map. It does not regenerate visual files.

Accept the current production-slice captures as the named visual baseline:

```bash
python tools/manage_production_slice_baseline.py accept
```

This copies the four production-slice captures into `visual_baselines/production_slice_01_accepted/` and writes a small manifest. Only run it after the current visuals are intentionally accepted as the comparison target.

Render the accepted-baseline comparison sheet:

```bash
python tools/manage_production_slice_baseline.py compare
```

This writes `references/asset_reviews/production_slice_01_visual_baseline_review.png`, showing accepted baseline, current capture, and difference columns for the key production-slice views. If the difference column reveals an unexpected visual change, keep the baseline fixed and create a follow-up issue.

Generate the production slice source/render/collision review sheet:

```bash
python tools/render_map_review.py maps/production_slice_01.greybox.json references/greybox/production_slice_01_source_render_collision_review.png --godot-capture visual_captures/production_slice_01/production_slice_overview.png
```

This writes `references/greybox/production_slice_01_source_render_collision_review.png`, comparing authored JSON topology, expected collision rectangles from the JSON terrain source, and the Godot rendered overview capture. Run `python tools/check_map_parity.py maps/production_slice_01.greybox.json` alongside it to verify Godot runtime terrain/collision cells match the source.

Generate the second production slice source/render/collision review sheet:

```bash
python tools/render_map_review.py maps/production_slice_02.greybox.json references/greybox/production_slice_02_source_render_collision_review.png --godot-capture visual_captures/production_slice_02/production_slice_02_overview.png
```

This writes `references/greybox/production_slice_02_source_render_collision_review.png`, comparing authored JSON topology, expected collision rectangles from the JSON terrain source, and the Godot rendered overview capture. Run `python tools/check_map_parity.py maps/production_slice_02.greybox.json` alongside it to verify Godot runtime terrain/collision cells match the source.

Regenerate the cave tileset and organic stress-test map:

```bash
python tools/generate_cave_tileset.py
python tools/generate_tileset_test_map.py
python tools/generate_organic_salvage_map.py
```

Process locally generated raw chroma-key terrain assets into exact-size transparent draft PNGs:

```bash
python tools/process_terrain_kit.py
```

This expects local raw generations under `tmp/imagegen/terrain_raw/`, writes final modules to `assets/terrain/`, and writes the review sheet to `references/asset_reviews/terrain_kit_01.png`.

## Generated Files

Do not commit:

- `.godot/`
- `.import/`
- `*.import`
- `builds/`
- `exports/`
- local editor state
