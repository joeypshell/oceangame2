# Tooling

## Local Checks

Validate map reachability:

```bash
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
```

Regenerate the SVG preview from source data:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
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
