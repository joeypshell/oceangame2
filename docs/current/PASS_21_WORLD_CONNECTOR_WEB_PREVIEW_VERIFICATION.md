# Pass 21 World Connector Web Preview Verification

Date: 2026-07-09

Issue: #428 `Verify public Web preview after Pass 21 connector pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 21 public Web preview verification is complete for deployed runtime/export commit `2d79675d92d2fb17efa54e67070a181a60d9ba57`.

Repository head at verification time was `fd8513b4d55f8c3faa7b66b0af4b7ca460a10395`, the #427 visual-decision documentation commit. That commit changed documentation only and did not match the Web export workflow path filters, so the expected deployed build remains the #426 connector capture/runtime export.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "2d79675",
  "git_sha": "2d79675d92d2fb17efa54e67070a181a60d9ba57",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T06:08:55-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 21 build: `https://github.com/joeypshell/oceangame2/actions/runs/29013875759`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_21_public_preview_2d79675.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 2d79675d92d2fb17efa54e67070a181a60d9ba57
```

Result:

- `build_info.json` matched `2d79675d92d2fb17efa54e67070a181a60d9ba57`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `2d79675`, salvage banked `0/8`, wallet `0`, the O2, cargo, and light upgrade prompts, and `Objective: Deep cache 0/2` visible in the compact overlay.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_21_public_preview_2d79675.png`
- Focused Pass 21 capture: `visual_captures/pass_21_world_connector/production_slice_04_world_connector_arrival.png`
- Visual decision: `docs/current/PASS_21_WORLD_CONNECTOR_VISUAL_BASELINE_DECISION.md`
- Smoke: `--smoke-pass-21-world-connector`

## Follow-Up

No Web preview fix is needed. Pass 21 can close out under #429.
