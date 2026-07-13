# Local Run

Open the project in the Godot editor:

```powershell
.\tools\open_godot_project.ps1
```

Or double-click `open-godot.cmd` from the repository root.

Run the current project scene locally:

```powershell
.\tools\open_godot_project.ps1 -Run
```

The current default preview map is `maps/production_level_01.greybox.json`.

Use `docs/current/PRODUCTION_SLICE_INDEX.md` for a compact status table of the current production slices, including launch flags, route smoke flags, capture folders, review sheets, and accepted baseline status.

Current release-candidate local import/run verification is recorded in [Simple Diver Game 08 Local Run Verification](../SIMPLE_DIVER_GAME_08_LOCAL_RUN_VERIFICATION.md).

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

Run the generated contiguous full level explicitly (the flag remains useful for scripts and review):

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionLevelMap
```

The matching raw Godot flag is `--production-level-map`. Measure default full-level startup, terrain/collision construction, camera limits, and a short frame sample headlessly with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --measure-map-runtime
```

The first candidate measurement is recorded in [OceanGame Expansion 09 Runtime Measurement](../OCEANGAME_EXPANSION_09_RUNTIME_MEASUREMENT.md).

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

Opening the Godot editor and pressing Play uses the default preview map unless Godot was launched with a `--map-path` argument. For non-default slices, the in-game overlay should show the requested map id; `Map production_level_01 v1` identifies the default map.

Local/editor review runs show a small map selector in the review overlay. Use it to switch between the supported review maps without relaunching Godot. It is hidden for capture/smoke automation and exported builds unless explicitly enabled with `--review-map-selector`. Command-line flags such as `-ProductionSlice3Map` or `-MapPath` still control the initial map that opens.

When comparing local/editor and public Web preview screenshots, compare matching commits and map selections. `Build local` means the editor is running the current checkout or worktree; `Build <sha>` in the Web overlay is the deployed export commit from `build_info.json`. The public export intentionally hides the editor-only map selector unless `--review-map-selector` is explicitly enabled.

Start an isolated local player-review run without reading or changing the normal durable profile:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --fresh-review-profile
```

The review overlay reports `Review profile fresh/isolated` and whether propulsion fins are currently owned.

## Mobile Testing Controls

Touch-capable devices automatically show a testing-only overlay in normal play; rotate the phone to landscape before playing. The layout reserves a bottom interaction inset for phone gesture/home-indicator areas. The left stick swims; the command pad exposes oxygen, cargo, and light upgrades, scanner, project build/guidance, day transition, reset, connector interaction, and shock-prod attack. Capture/smoke automation keeps the overlay hidden.

Force the overlay in a local desktop run for mouse testing:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --show-mobile-controls
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
