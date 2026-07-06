# Salvage/Oxygen Feedback Web Preview Verification

Date: 2026-07-06

Issue: #108 `Verify public Web preview after feedback polish`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployed runtime commit:

```text
f6bfe77cd94e0a7f8e544e97192ed8f0435547e5
```

The later #107 baseline acceptance commit changed docs, captures, baselines, and review sheets. It did not trigger the path-filtered Web export workflow. The deployed runtime commit above is the #106 salvage/oxygen feedback overlay implementation commit.

## GitHub Actions

Workflow:

```text
Godot Web Export
```

Run:

```text
https://github.com/joeypshell/oceangame2/actions/runs/28815139340
```

Result:

```text
success
```

The run built and deployed commit `f6bfe77cd94e0a7f8e544e97192ed8f0435547e5`.

## Browser Check

Command:

```powershell
$env:NODE_PATH = "C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules"
$env:WEB_PREVIEW_SCREENSHOT = "exports\web-preview-feedback-check.png"
& "C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" tools/check_web_preview.cjs "https://joeypshell.github.io/oceangame2/" --expected-sha f6bfe77
```

Result:

- `build_info.json` matched `f6bfe77cd94e0a7f8e544e97192ed8f0435547e5`.
- Canvas rendered at `1280x720`.
- No failed requests were reported.
- No missing texture/resource warnings were reported.
- No Godot `SCRIPT ERROR` or Godot `ERROR:` lines were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only; those are expected checker-environment warnings and not project resource failures.
- The browser screenshot showed the separated overlay lines: `Salvage banked`, `Held`, and `Oxygen`.

Screenshot:

```text
exports/web-preview-feedback-check.png
```

## Decision

The public Web preview is verified for the salvage/oxygen feedback overlay runtime pass. No packaging or deployment follow-up is needed for this pass.
