# Simple Diver Game 08 Local Run Verification

Date: 2026-07-09

Issue: #627

## Decision

The documented local import and launch path is valid for the Simple Diver Game 08 release-candidate handoff. The default local run still opens the current default preview map, `maps/production_slice_01.greybox.json`, and the explicit production-slice wrapper still passes that map path directly.

## Verified Commands

Dry-run helper checks:

```powershell
.\tools\open_godot_project.ps1 -CheckOnly
.\tools\open_godot_project.ps1 -Run -CheckOnly
.\tools\open_godot_project.ps1 -Run -ProductionSliceMap -CheckOnly
```

Observed behavior:

- `-CheckOnly` resolves editor mode with `--editor --path <repo>`.
- `-Run -CheckOnly` resolves project mode with `--path <repo>`.
- `-Run -ProductionSliceMap -CheckOnly` resolves project mode with `--path <repo> --map-path=res://maps/production_slice_01.greybox.json`.

Godot verification:

```powershell
& "C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path . --import
& "C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe" --headless --path . --quit-after 1
```

Both completed with no `SCRIPT ERROR` or `ERROR:` lines.

Wrapper review:

- `run-production-slice-01.cmd` still calls `tools/open_godot_project.ps1 -Run -ProductionSliceMap`.
- The wrapper remains the recommended Command Prompt path for launching slice 01.

## Local Caveats

- `-CheckOnly` validates Godot resolution and launch arguments without opening the editor or game window.
- Opening the editor and pressing Play uses the default preview map unless Godot was launched with `--map-path`.
- From Command Prompt, use the `.cmd` wrappers instead of typing a `.ps1` path directly; local file associations may open PowerShell scripts in an editor.
- Headless runs are appropriate for import/startup/smoke verification. Local screenshot capture may still need a non-headless run depending on the machine.
- Local/editor overlays show `Build local`; public Web preview overlays show `Build <sha>` from deployed `build_info.json`.

## Not Changed

No gameplay, maps, assets, captures, baselines, workflows, or generated map sources changed in this verification pass.
