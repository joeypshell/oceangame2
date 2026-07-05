# Tooling

## Local Checks

Validate map reachability:

```bash
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
python tools/validate_greybox_map.py maps/cave_tileset_test_01.greybox.json
```

Regenerate the SVG preview from source data:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
python tools/render_greybox_map.py maps/cave_tileset_test_01.greybox.json references/greybox/cave_tileset_test_01.svg
```

Run whitespace checks:

```bash
git diff --check
```

Run the Godot headless launch smoke check on this Windows setup:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
```

The headless command can exit `0` even when script errors appear in output, so treat `SCRIPT ERROR` or `ERROR:` lines as failures.

Build a local Web export preview:

```powershell
python tools/write_web_export_preset.py
New-Item -ItemType Directory -Force exports/web | Out-Null
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --export-release Web exports/web/index.html
python -m http.server 8060 --directory exports/web
```

Open `http://127.0.0.1:8060/` after the server starts. Do not open `exports/web/index.html` directly; Godot Web exports need to be served over HTTP.

If the local export reports missing `web_nothreads_*` templates, install the Godot 4.7 export templates through the editor or use the GitHub Actions artifact; CI installs templates during the workflow.

GitHub Actions builds the same preview in `Godot Web Export`. Download the `oceangame2-web-export` artifact from the workflow run when you need to inspect a build. The workflow also deploys GitHub Pages from `main` when Pages is already enabled for the repository. If the Pages job says it skipped deployment, open repository Settings, enable Pages, and set the source to GitHub Actions. The latest preview should then be available at `https://joeypshell.github.io/oceangame2/`.

Capture the current greybox screenshot baseline:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 5 --capture-greybox-screenshot
```

Do not use `--headless` for screenshot capture on this local setup. Headless uses Godot's dummy renderer here, so the viewport texture is unavailable. Use headless for smoke checks and non-headless for visual capture.

Capture the current named camera test views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-camera-tests
```

This reads `camera_tests` from `maps/cave_salvage_test_01.greybox.json` and writes PNGs to `visual_captures/latest/`.
Normal gameplay and capture views hide the greybox source grid. Add `--show-debug-overlay` when you specifically need the source TileMap/grid overlay for map debugging.

Capture the organic tileset stress-test views:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-tileset-test
```

This reads `camera_tests` from `maps/cave_tileset_test_01.greybox.json` and writes PNGs to `visual_captures/tileset_test/`.

Regenerate the cave tileset and organic stress-test map:

```bash
python tools/generate_cave_tileset.py
python tools/generate_tileset_test_map.py
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
