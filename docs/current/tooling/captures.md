# Captures

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

Capture the focused route-outcome result view for Controlled Gameplay review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-route-outcome-result
```

This loads the default production slice, completes a deterministic route-tagged collect-return run, keeps map data and accepted baselines unchanged, and writes `visual_captures/route_outcome/production_slice_01_route_outcome_result.png`. Use this capture to review the compact route outcome/result panel before accepting or replacing broader visual baselines.

Capture the focused timed-salvage interaction view for Controlled Gameplay review:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-timed-salvage
```

This loads the default production slice, places the player on the authored timed salvage target, advances to a partial `Salvaging deep cache` progress state, frames the Pass 06 in-world marker and overlay progress bar, keeps map data and accepted baselines unchanged, and writes `visual_captures/timed_salvage/production_slice_01_timed_salvage.png`.

Capture the focused Pass 07 hazard/navigation pressure view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-07-hazard-pressure
```

This loads the default production slice, collects the lower-loop payoff into held cargo, places the player in warning-only range near `hazard_right_branch`, frames the selected pressure segment with the deep-cache payoff and overlay warning, keeps map data and accepted baselines unchanged, and writes `visual_captures/hazard_pressure/production_slice_01_hazard_pressure.png`.

Capture the focused Pass 08 route-extension view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-08-route-extension
```

This loads the default production slice, places the player near `salvage_southwest_return_cache` without collecting it, frames `southwest_return_pocket_extension` with compact overlay context, keeps map data and accepted baselines unchanged, and writes `visual_captures/route_extension/production_slice_01_route_extension.png`.

Capture the focused Pass 09 southwest pocket route-decision view:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-09-southwest-pocket-decision
```

This loads the default production slice, collects `salvage_southwest_return_cache` through the normal runtime path, frames `southwest_return_pocket_extension` with compact payoff feedback, keeps map data and accepted baselines unchanged, and writes `visual_captures/southwest_pocket_decision/production_slice_01_southwest_pocket_decision.png`.

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
