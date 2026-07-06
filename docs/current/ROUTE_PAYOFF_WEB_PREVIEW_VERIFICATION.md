# Route Payoff Web Preview Verification

Date: 2026-07-06

Issue: #119 `Verify public Web preview after route-payoff pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployed runtime commit:

```text
c92572a8f8aa8f5b65a01c9587c6a45fd4b8d5d8
```

The later #118 visual-baseline acceptance commit `69d018ef2e2cc79a527fc13db5d4187499197646` changed docs, captures, accepted baselines, and the review sheet only. It did not change the exported runtime map, assets, scenes, or scripts. The deployed commit above includes the route/payoff runtime state: `production_slice_01` marks `salvage_lower_loop` as the valuable route-choice payoff target, the runtime renders valuable salvage with a small cue, and the route-choice smoke validates the collect-return path.

## GitHub Actions

Web export workflow:

```text
Godot Web Export
```

Run:

```text
https://github.com/joeypshell/oceangame2/actions/runs/28819525495
```

Result:

```text
success
```

The run built, browser-checked, and deployed commit `c92572a8f8aa8f5b65a01c9587c6a45fd4b8d5d8`.

Godot smoke workflow:

```text
Godot Smoke
```

Run:

```text
https://github.com/joeypshell/oceangame2/actions/runs/28819525521
```

Result:

```text
success
```

The smoke run for the same commit passed the default route-choice probe and the production-slice route smoke checks.

## Browser Check

Command:

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT = "exports\web-preview-route-payoff-check.png"
& "C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" tools/check_web_preview.cjs "https://joeypshell.github.io/oceangame2/" --expected-sha c92572a
```

Result:

- `build_info.json` matched `c92572a8f8aa8f5b65a01c9587c6a45fd4b8d5d8`.
- Canvas rendered at `1280x720`.
- No failed requests were reported.
- No missing texture/resource warnings were reported.
- No Godot `SCRIPT ERROR` or Godot `ERROR:` lines were reported.
- Chromium emitted WebGL fallback and `ReadPixels` performance warnings only; those are checker-environment warnings, not project resource failures.
- The browser screenshot showed the default `production_slice_01` preview, build label `c92572a`, the player, boat entry, cave terrain, water, background silhouettes, and salvage/oxygen overlay.

Screenshot:

```text
exports/web-preview-route-payoff-check.png
```

## Decision

The public Web preview is verified for the route/payoff pass. The deployed Pages build matches the route-payoff runtime commit, initializes cleanly in Chromium, and keeps the default production-slice preview rendering with no missing-resource or stale-build failure.
