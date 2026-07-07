# Pass 04 Route Pressure Web Preview Verification

Date: 2026-07-07

Issue: #147 `Verify public Web preview after Pass 04 route-pressure pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

The public GitHub Pages preview is serving the latest Pass 04 runtime-affecting commit and initializes cleanly in Chromium.

Expected deployed runtime commit:

```text
088a608e005bb6a79e9ef101bcd47c5b15f15e57
```

Repository head at verification time:

```text
9adc0a5656ce0262b46100f51e23744a59c00091
```

The repository head is the #146 visual-baseline acceptance commit. It changed docs, the review sheet, and the accepted baseline manifest only, so it did not trigger the Web export workflow. The deployed runtime commit remains `088a608`, which includes the Pass 04 route-outcome capture/runtime support and follows #144's route-outcome result-panel runtime change.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "088a608",
  "git_sha": "088a608e005bb6a79e9ef101bcd47c5b15f15e57",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-07T17:22:38-05:00"
}
```

## GitHub Actions

Web export workflow:

```text
Godot Web Export
https://github.com/joeypshell/oceangame2/actions/runs/28902755903
success
```

Godot smoke workflow:

```text
Godot Smoke
https://github.com/joeypshell/oceangame2/actions/runs/28902755908
success
```

Both runs used head SHA `088a608e005bb6a79e9ef101bcd47c5b15f15e57`.

## Browser Check

Command:

```powershell
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_04_route_pressure_web_preview.png'
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 088a608
```

Result:

- `build_info.json` matched `088a608e005bb6a79e9ef101bcd47c5b15f15e57`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only; these are checker-environment warnings, not project resource failures.
- The browser screenshot showed the default `production_slice_01` preview with cave terrain, water, boat, player, salvage, build label `088a608`, score, salvage, held cargo, and oxygen overlay.

The public preview starts in the normal playable state, not in a completed route-result state. The completed route outcome panel is verified by `--smoke-route-outcome-result` and the focused `visual_captures/route_outcome/production_slice_01_route_outcome_result.png` capture from #145.

## Decision

The public Web preview is verified for the Pass 04 route-pressure pass. The deployed Pages build matches the expected runtime commit, initializes cleanly, and shows the updated production-slice preview without missing resources or stale-build symptoms.
