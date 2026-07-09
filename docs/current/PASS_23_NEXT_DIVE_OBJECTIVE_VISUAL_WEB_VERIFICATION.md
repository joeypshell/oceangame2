# Pass 23 Next-Dive Objective Visual And Web Verification

Date: 2026-07-09

Issue: #530 `Review Pass 23 visual impact and verify public Web preview`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 23 is visually verified with no accepted baseline changes.

The public GitHub Pages preview is serving the latest Pass 23 capture/runtime commit and initializes cleanly in Chromium.

Verified commit:

```text
3d743bf96d8a74d60731da41f8e87970e3920cb8
```

## Visual Review

Commands:

```powershell
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
```

Result:

- `production_slice_01`: clean
- `production_slice_02`: clean
- `production_slice_03`: clean
- `production_slice_04`: clean

The slice-01 comparison sheet showed black/empty difference panels across the normal production-slice views. No terrain, player, boat, prop, camera, map, or accepted-baseline drift was accepted.

The intentional Pass 23 visual state is limited to the focused runtime capture command:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-23-next-dive-objective
```

That local capture showed the completed result panel with `Next dive: Investigate lower-left relay`. The generated PNG was used for review only and was not committed.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "3d743bf",
  "git_sha": "3d743bf96d8a74d60731da41f8e87970e3920cb8",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T13:03:26-05:00"
}
```

## GitHub Actions

- Godot Web Export: `https://github.com/joeypshell/oceangame2/actions/runs/29039230662` succeeded for `3d743bf96d8a74d60731da41f8e87970e3920cb8`.
- Godot Smoke: `https://github.com/joeypshell/oceangame2/actions/runs/29039230776` succeeded for `3d743bf96d8a74d60731da41f8e87970e3920cb8`.

## Browser Check

Command:

```powershell
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_23_next_dive_web_preview.png'
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools\check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 3d743bf96d8a74d60731da41f8e87970e3920cb8
```

Result:

- `build_info.json` matched the expected SHA.
- Godot canvas initialized at `1280x720`; wide canvas initialized at `1920x1080`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only; these are checker-environment warnings, not project failures.
- Screenshot showed the normal playable `production_slice_01` start state with build label `3d743bf`.

## Decision

Pass 23 visual impact is accepted as focused runtime UI only. No production-slice normal baseline, map source, capture PNG, asset, or generated sidecar changes were accepted in this verification pass.
