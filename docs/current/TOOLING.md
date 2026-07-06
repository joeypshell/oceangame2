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

Use `docs/current/PRODUCTION_SLICE_INDEX.md` for a compact status table of the current production slices, including launch flags, route smoke flags, capture folders, review sheets, and accepted baseline status.

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

Command Prompt wrapper:

```cmd
run-production-slice-01.cmd
```

Run the second production slice:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSlice2Map
```

Command Prompt wrapper:

```cmd
run-production-slice-02.cmd
```

Run the third production slice:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSlice3Map
```

Command Prompt wrapper:

```cmd
run-production-slice-03.cmd
```

Run the fourth production slice:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSlice4Map
```

Command Prompt wrapper:

```cmd
run-production-slice-04.cmd
```

In Command Prompt, run the `.cmd` wrappers instead of executing `.ps1` files directly. Depending on local file associations, typing a PowerShell script path from Command Prompt may open it in an editor instead of running it.

Opening the Godot editor and pressing Play uses the default preview map unless Godot was launched with a `--map-path` argument. For non-default slices, the in-game overlay should show the requested map id; if it reads `Map production_slice_01 v1`, the default map was launched.

Local/editor review runs show a small map selector in the review overlay. Use it to switch between the supported review maps without relaunching Godot. It is hidden for capture/smoke automation and exported builds unless explicitly enabled with `--review-map-selector`. Command-line flags such as `-ProductionSlice3Map` or `-MapPath` still control the initial map that opens.

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
python tools/validate_greybox_map.py maps/production_slice_03.greybox.json
python tools/validate_greybox_map.py maps/production_slice_04.greybox.json
```

Check that Godot's runtime terrain and collision match the authored JSON source:

```bash
python tools/check_map_parity.py
```

Check one map only:

```bash
python tools/check_map_parity.py maps/cave_salvage_organic_01.greybox.json
```

Validate committed asset-manifest paths:

```bash
python tools/check_asset_manifest.py
```

The checker reads table rows in `docs/ASSET_MANIFEST.md` whose asset path is the first column and whose status is `draft`, `approved`, or `locked`. It fails only for missing files under committed asset folders such as `assets/` and `references/asset_reviews/`, so planned future assets and prose examples do not block the check.

Regenerate the SVG preview from source data:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
python tools/render_greybox_map.py maps/cave_salvage_organic_01.greybox.json references/greybox/cave_salvage_organic_01.svg
python tools/render_greybox_map.py maps/cave_tileset_test_01.greybox.json references/greybox/cave_tileset_test_01.svg
python tools/render_greybox_map.py maps/full_cave_sketch_01.greybox.json references/greybox/full_cave_sketch_01.svg
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/render_greybox_map.py maps/production_slice_02.greybox.json references/greybox/production_slice_02.svg
python tools/render_greybox_map.py maps/production_slice_03.greybox.json references/greybox/production_slice_03.svg
python tools/render_greybox_map.py maps/production_slice_04.greybox.json references/greybox/production_slice_04.svg
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

Regenerate the third focused production slice:

```bash
python tools/create_production_slice_03_map.py
python tools/render_greybox_map.py maps/production_slice_03.greybox.json references/greybox/production_slice_03.svg
python tools/validate_greybox_map.py maps/production_slice_03.greybox.json
python tools/check_map_parity.py maps/production_slice_03.greybox.json
```

This slice is generated from `maps/full_cave_sketch_01.greybox.json` using bounds `x=0, y=8, w=76, h=82`. It is an upper-left connector/landmark room-cluster candidate with an in-water `spawn` and `base` extraction zone near the east-side relay context.

Regenerate the fourth focused production slice:

```bash
python tools/create_production_slice_04_map.py
python tools/render_greybox_map.py maps/production_slice_04.greybox.json references/greybox/production_slice_04.svg
python tools/validate_greybox_map.py maps/production_slice_04.greybox.json
python tools/check_map_parity.py maps/production_slice_04.greybox.json
```

This slice is generated from `maps/full_cave_sketch_01.greybox.json` using bounds `x=0, y=86, w=88, h=50`. It is a lower-left connector/return-loop candidate with an in-water `spawn` and `base` relay extraction zone near the east-side connector context.

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
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-03-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-04-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-map-selector
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-interaction
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
```

The import command is important on a fresh clone or CI checkout because `.godot/` and `*.import` files are intentionally untracked. The headless command can exit `0` even when script errors appear in output, so treat `SCRIPT ERROR` or `ERROR:` lines as failures.

The salvage-loop smoke check loads the default production slice, collects all authored salvage through the same runtime methods used in play, returns to extraction, confirms completion, resets, and exits.

The production-slice route smoke loads `production_slice_01`, asks the world for open-water paths to each authored salvage point and back to the boat, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The production-slice-02 route smoke loads `production_slice_02`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The production-slice-03 route smoke loads `production_slice_03`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The production-slice-04 route smoke loads `production_slice_04`, asks the world for open-water paths to each authored salvage point and back to the relay extraction zone, swims the player through those paths with the normal movement controller, confirms completion, resets, and exits.

The `Godot Smoke` workflow runs all four production-slice route smoke flags so CI catches broken authored routes across the accepted/reference slices, not only the default preview loop.

The map-selector smoke loads the default map, reloads `production_slice_03`, then reloads `production_slice_01` through the same clean map/player reload path used by the local review selector.

The hazard-interaction smoke loads `production_slice_01`, collects one salvage item, touches an authored hazard, confirms the player resets to spawn and the held salvage is restored, recollects it, resets, and exits.

The oxygen-pressure smoke loads `production_slice_01`, collects one salvage item, forces oxygen depletion, confirms the player surfaces at spawn with held salvage restored, recollects it, returns to extraction, confirms oxygen refills and salvage banks, resets, and exits.

Generate optional local build metadata for the preview overlay:

```bash
python tools/write_build_info.py
```

This writes ignored `build_info.json`. The web export workflow generates that file from `GITHUB_SHA` before export, so the public preview can identify the deployed commit.

Build a local Web export preview:

```powershell
python tools/write_build_info.py
python tools/write_web_export_preset.py
New-Item -ItemType Directory -Force exports/web | Out-Null
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --export-release Web exports/web/index.html
Copy-Item build_info.json exports/web/build_info.json
python -m http.server 8060 --directory exports/web
```

Open `http://127.0.0.1:8060/` after the server starts. Do not open `exports/web/index.html` directly; Godot Web exports need to be served over HTTP.

If the local export reports missing `web_nothreads_*` templates, install the Godot 4.7 export templates through the editor or use the GitHub Actions artifact; CI installs templates during the workflow.

Verify a served Web export in Chromium:

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
npm install --prefix "$env:TEMP\oceangame2-web-preview-check" playwright@1.55.0
& "$env:TEMP\oceangame2-web-preview-check\node_modules\.bin\playwright.cmd" install chromium
node tools/check_web_preview.cjs http://127.0.0.1:8060/ --expected-sha (git rev-parse HEAD)
```

The check fails if the web preview logs missing texture warnings such as `Unable to open texture asset`, `Unable to create cave TileSet`, `SCRIPT ERROR`, `ERROR:`, failed resource requests, a missing Godot canvas, or an external `build_info.json` whose `git_sha` does not match the expected commit. Omit `--expected-sha` when checking an older export that does not include external build metadata.

GitHub Actions builds the same preview in `Godot Web Export`. The workflow writes `build_info.json`, copies it beside `exports/web/index.html` as external Pages metadata, serves the exported build, and runs `tools/check_web_preview.cjs` with the expected `GITHUB_SHA` before uploading the artifact or deploying Pages. Download the `oceangame2-web-export` artifact from the workflow run when you need to inspect a build. The workflow also deploys GitHub Pages from `main` when Pages is already enabled for the repository. If the Pages job says it skipped deployment, open repository Settings, enable Pages, and set the source to GitHub Actions. The latest preview should then be available at `https://joeypshell.github.io/oceangame2/`.

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

Capture the focused player-readability view for Controlled Visual Revision review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-player-readability
```

This loads the default production slice, places the player a few tiles below the source-defined boat entry for a readable start-context shot, uses a close runtime camera, and writes `visual_captures/player_readability/production_slice_01_player_start.png`. Use this capture to review player sprite changes without changing map topology, gameplay, camera tests, or accepted baselines.

Capture the focused background-depth view for Controlled Visual Revision review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-background-depth
```

This loads the default production slice, keeps map data and authored camera tests unchanged, frames the entry/crossing background silhouettes with terrain, water, player, props, and boat context, and writes `visual_captures/background_depth/production_slice_01_background_depth.png`. Use this capture to review non-collision background-depth changes without changing map topology, gameplay, camera tests, or accepted baselines.

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

Capture the third production slice:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-03-map
```

This reads `camera_tests` from `maps/production_slice_03.greybox.json` and writes five PNGs to `visual_captures/production_slice_03/`: overview, relay entry, stacked rooms, connector, and return route.

Capture the third production slice with debug/review markers visible:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-03-debug-map
```

This writes the same five camera views to `visual_captures/production_slice_03_debug/`.

Capture the fourth production slice:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-04-map
```

This reads `camera_tests` from `maps/production_slice_04.greybox.json` and writes five PNGs to `visual_captures/production_slice_04/`: overview, relay entry, lower-left loop, curved corridor, and return route.

Capture the fourth production slice with debug/review markers visible:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-04-debug-map
```

This writes the same five camera views to `visual_captures/production_slice_04_debug/`.

Check that a capture directory contains every authored `camera_tests` view for a map:

```bash
python tools/check_camera_captures.py maps/production_slice_01.greybox.json visual_captures/production_slice_01
python tools/check_camera_captures.py maps/production_slice_01.greybox.json visual_captures/production_slice_01_debug
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02_debug
python tools/check_camera_captures.py maps/production_slice_03.greybox.json visual_captures/production_slice_03
python tools/check_camera_captures.py maps/production_slice_03.greybox.json visual_captures/production_slice_03_debug
python tools/check_camera_captures.py maps/production_slice_04.greybox.json visual_captures/production_slice_04
python tools/check_camera_captures.py maps/production_slice_04.greybox.json visual_captures/production_slice_04_debug
```

The checker reads expected PNG names from the map JSON, ignores Godot `.import` sidecars, fails on missing/extra/invalid PNGs, and reports captures that look older than the source map. It does not regenerate visual files.

Run the aggregate committed-capture check for every production slice:

```bash
python tools/check_production_slice_captures.py
```

Use the stale-file check locally after regenerating map JSON and captures in the same workspace:

```bash
python tools/check_production_slice_captures.py --fail-on-stale
```

The `Godot Smoke` workflow runs the aggregate check without `--fail-on-stale` so CI catches missing, extra, or invalid committed captures without relying on git checkout file mtimes or a display renderer.

List configured production-slice baseline targets:

```bash
python tools/manage_production_slice_baseline.py --list-slices
```

Accept the current production-slice captures as the named visual baseline:

```bash
python tools/manage_production_slice_baseline.py accept
python tools/manage_production_slice_baseline.py --slice production_slice_02 accept
python tools/manage_production_slice_baseline.py --slice production_slice_03 accept
python tools/manage_production_slice_baseline.py --slice production_slice_04 accept
```

The default command remains `production_slice_01` for backward compatibility. Slice-specific acceptance copies the configured captures into `visual_baselines/<slice>_accepted/` and writes a small manifest. Only run `accept` after that slice's current visuals are intentionally accepted as the comparison target.

The accept command only manages the configured PNG view files and `manifest.json`. It removes generated Godot/OS sidecars such as `*.import` from the target accepted-baseline directory and fails if other unexpected files are present. To clean or verify accepted baseline directories without accepting new images:

```bash
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
```

Render the accepted-baseline comparison sheet:

```bash
python tools/manage_production_slice_baseline.py compare
python tools/manage_production_slice_baseline.py --slice production_slice_02 compare
python tools/manage_production_slice_baseline.py --slice production_slice_03 compare
python tools/manage_production_slice_baseline.py --slice production_slice_04 compare
```

This writes the slice-specific review sheet under `references/asset_reviews/`, showing accepted baseline, current capture, and difference columns for the configured views. If the difference column reveals an unexpected visual change, keep the baseline fixed and create a follow-up issue.

Render all configured accepted-baseline comparison sheets with one command:

```bash
python tools/manage_production_slice_baseline.py compare-all
```

This compares `production_slice_01` through `production_slice_04` using the committed baseline-manager config. It fails if a configured current capture or accepted baseline view is missing or unreadable, and it does not accept or overwrite baseline PNGs.

For a future slice that has current captures but no accepted baseline yet, compare against the current capture directory as a tooling sanity check without accepting anything:

```powershell
python tools/manage_production_slice_baseline.py --slice production_slice_02 --baseline-dir visual_captures/production_slice_02 compare --output "$env:TEMP\production_slice_tooling_sanity_review.png"
```

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

Generate the third production slice source/render/collision review sheet:

```bash
python tools/render_map_review.py maps/production_slice_03.greybox.json references/greybox/production_slice_03_source_render_collision_review.png --godot-capture visual_captures/production_slice_03/production_slice_03_overview.png
```

This writes `references/greybox/production_slice_03_source_render_collision_review.png`, comparing authored JSON topology, expected collision rectangles from the JSON terrain source, and the Godot rendered overview capture. Run `python tools/check_map_parity.py maps/production_slice_03.greybox.json` alongside it to verify Godot runtime terrain/collision cells match the source.

Generate the fourth production slice source/render/collision review sheet:

```bash
python tools/render_map_review.py maps/production_slice_04.greybox.json references/greybox/production_slice_04_source_render_collision_review.png --godot-capture visual_captures/production_slice_04/production_slice_04_overview.png
```

This writes `references/greybox/production_slice_04_source_render_collision_review.png`, comparing authored JSON topology, expected collision rectangles from the JSON terrain source, and the Godot rendered overview capture. Run `python tools/check_map_parity.py maps/production_slice_04.greybox.json` alongside it to verify Godot runtime terrain/collision cells match the source.

Regenerate the cave tileset and organic stress-test map:

```bash
python tools/generate_cave_tileset.py
python tools/generate_tileset_test_map.py
python tools/generate_organic_salvage_map.py
```

Render the terrain atlas coverage review sheet:

```bash
python tools/render_terrain_atlas_coverage.py
```

This writes `references/asset_reviews/cave_tileset_v1_coverage_review.png`, labels manifest tile names, atlas coordinates, mask/open-side roles, renderer selection roles, and fails if any coordinate used by `scripts/world/greybox_world.gd` is missing from the terrain manifest. Use it before reviewing terrain tileset changes so the art pass preserves exact mask coverage.

Regenerate the first-pass salvage and hazard prop sprites:

```bash
python tools/generate_prop_sprites.py
```

This writes the draft 32x32 prop sprites under `assets/props/` and the review sheet at `references/asset_reviews/prop_sprites_01_review.png`. Runtime prop selection still comes from JSON entity `kind` values, and the renderer keeps procedural fallback art if a sprite asset cannot be loaded.

Regenerate the draft player diver sprite:

```bash
python tools/generate_player_sprite.py
```

This writes `assets/player/player_diver_01.png` and the review sheet at `references/asset_reviews/player_sprite_01_review.png`. The player scene uses this sprite while preserving the existing collision shape, movement script, camera, and light cone.

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
