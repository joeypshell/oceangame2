# Pass 14 Objective Cue Web Preview Verification

Date: 2026-07-08

Issue: #285 `Verify public Web preview after Pass 14 objective cue`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 14 public Web preview verification is complete for deployed runtime commit `f43fd760e92821c72e1c2a0277b0503f95a3fda9`.

Repository head at verification time was `f9c5bd1d9c58e2b0f22b727d6cd9681a2cced9d8`, the #284 visual-decision doc commit. That commit changed documentation only and did not trigger the Web export workflow path filters, so the expected deployed runtime build remains #283.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "f43fd76",
  "git_sha": "f43fd760e92821c72e1c2a0277b0503f95a3fda9",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T18:46:19-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 14 runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28983550999`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_14_public_preview_f43fd76.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha f43fd760e92821c72e1c2a0277b0503f95a3fda9
```

Result:

- `build_info.json` matched `f43fd760e92821c72e1c2a0277b0503f95a3fda9`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `f43fd76`, salvage total `0/7`, and `Objective: Deep cache 0/2` visible in the compact overlay.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_14_public_preview_f43fd76.png`
- Focused Pass 14 capture: `visual_captures/pass_14_objective_cue/production_slice_01_objective_cue.png`
- Visual decision: `docs/current/PASS_14_OBJECTIVE_CUE_VISUAL_BASELINE_DECISION.md`
- Smoke: `--smoke-pass-14-objective-cue`

## Follow-Up

No Web preview fix is needed. Pass 14 can close out under #286.
