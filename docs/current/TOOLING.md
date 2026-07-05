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

The current default preview map is `maps/cave_salvage_organic_01.greybox.json`.

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
```

Regenerate the SVG preview from source data:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
python tools/render_greybox_map.py maps/cave_salvage_organic_01.greybox.json references/greybox/cave_salvage_organic_01.svg
python tools/render_greybox_map.py maps/cave_tileset_test_01.greybox.json references/greybox/cave_tileset_test_01.svg
python tools/render_greybox_map.py maps/full_cave_sketch_01.greybox.json references/greybox/full_cave_sketch_01.svg
```

Regenerate the supplied full-map sketch topology draft:

```bash
python tools/convert_full_cave_sketch_map.py
python tools/render_greybox_map.py maps/full_cave_sketch_01.greybox.json references/greybox/full_cave_sketch_01.svg
python tools/validate_greybox_map.py maps/full_cave_sketch_01.greybox.json
```

This draft converts `references/source_maps/full_cave_sketch_01.png` into topology only. White source regions become open water, gray/black source regions become solid terrain/collision, icons are ignored by filling small non-white holes, and the spawn is temporary until the boat/top-of-water spawn exists.

Run whitespace checks:

```bash
git diff --check
```

Run the Godot headless launch smoke check on this Windows setup:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --import
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
```

The import command is important on a fresh clone or CI checkout because `.godot/` and `*.import` files are intentionally untracked. The headless command can exit `0` even when script errors appear in output, so treat `SCRIPT ERROR` or `ERROR:` lines as failures.

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
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-camera-tests
```

This reads `camera_tests` from the default preview map, currently `maps/cave_salvage_organic_01.greybox.json`, and writes PNGs to `visual_captures/latest/`.
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
