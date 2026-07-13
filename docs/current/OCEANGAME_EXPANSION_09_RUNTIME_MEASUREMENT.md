# OceanGame Expansion 09 Runtime Measurement

Recorded: 2026-07-13
Candidate: `maps/production_level_01.greybox.json`

## Result

The generated contiguous full-level candidate loaded and ran without an observed construction or framing blocker. This measurement preceded the player gate; final baseline acceptance and default promotion are recorded in `OCEANGAME_EXPANSION_09_CLOSEOUT.md`.

Local headless sample:

- map size: `158 x 161` tiles, `5056 x 5152` px
- terrain construction: `14,898` cells
- collision construction: `376` rectangles
- playable-map startup: `158.41 ms`
- 30-frame headless sample: `7.68 ms` average wall time per frame
- camera limits: left/top `0`, right `5056`, bottom `5152`
- camera zoom: `0.7`
- visible logical frame: approximately `1828.57 x 1028.57` world px
- desktop `1280 x 720` review frame: fits inside map bounds
- mobile `844 x 390` browser review frame using the same `1280 x 720` logical game frame: fits inside map bounds

No optimization was added because the measurement found no practical blocker. Visual edge behavior remains part of the focused Expansion 09 candidate review.

A local Web export also initialized the isolated candidate URL at both target browser sizes with no failed requests or matching `SCRIPT ERROR` / `ERROR:` output. The existing root framing and mobile touch-alignment checks remained green.

## Commands

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionLevelMap
```

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --measure-map-runtime
```

The deterministic probe also runs in `godot-smoke.yml`. It fails on the wrong map or dimensions, terrain/collision count drift, camera-limit drift, an oversized supported viewport frame, startup above 15 seconds, average sampled frame time above 100 ms, or any `SCRIPT ERROR` / `ERROR:` output.

## Selection Contract

- `production_level_01` is `DEFAULT_MAP_PATH`.
- `--production-level-map` and `-ProductionLevelMap` remain explicit compatibility selectors.
- Public root and map-unspecified review URLs load `production_level_01`.
- Explicit review URLs can still select a retained slice, for example `?review=<sha>&map=production_slice_01`.
