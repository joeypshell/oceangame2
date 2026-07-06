# Terrain Tileset V2 Web Preview Verification

Date: 2026-07-06

Issue: #97 `Verify public web preview after terrain tileset v2 pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployed runtime commit:

```text
3ca2401a406a706ee64629d714fe683333e48900
```

The later #96 baseline decision commit was docs/baseline-only and did not trigger the Web export workflow. The deployed runtime commit above is the #95 terrain tileset v2 implementation commit, which changed the active terrain atlas and runtime script selection.

## GitHub Actions

Workflow:

```text
Godot Web Export
```

Run:

```text
https://github.com/joeypshell/oceangame2/actions/runs/28811477875
```

Result:

```text
success
```

The run built and deployed commit `3ca2401a406a706ee64629d714fe683333e48900`.

## Browser Check

Command:

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT = "tmp\web-preview-terrain-v2-check.png"
& "C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" tools/check_web_preview.cjs "https://joeypshell.github.io/oceangame2/" --expected-sha 3ca2401a406a706ee64629d714fe683333e48900
```

Result:

- `build_info.json` matched `3ca2401a406a706ee64629d714fe683333e48900`.
- Canvas rendered at `1280x720`.
- Default preview loaded `production_slice_01`.
- The screenshot showed the v2 cave terrain atlas, player sprite, boat entry sprite, salvage prop sprite, and background-depth art.
- The checker reported no failed requests, no missing texture warnings, no Godot `SCRIPT ERROR`, and no Godot `ERROR:` lines.
- Chromium emitted WebGL software/ReadPixels warnings only; those are expected checker-environment warnings and not project resource failures.

Screenshot:

```text
tmp/web-preview-terrain-v2-check.png
```

## Decision

The public Web preview is verified for the terrain tileset v2 runtime pass. No packaging follow-up is needed for the v2 atlas.
