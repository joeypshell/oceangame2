# Pass 12 Oxygen Rest Web Preview Verification

Date: 2026-07-08

Issue: #232 `Verify public Web preview after Pass 12`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 12 public Web preview verification is complete for deployed runtime commit `fbcf63dcfc54e7d6481618d74fd67709da097ddb`.

Repository head at verification time was `9b1d26c96287c79b5afef94b8414c1b15cefb6c0`, the #231 visual-baseline acceptance commit. That commit changed docs, captures, review sheets, and accepted baseline artifacts only, so the expected deployed runtime build remains #230.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "fbcf63d",
  "git_sha": "fbcf63dcfc54e7d6481618d74fd67709da097ddb",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T12:13:50-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 12 runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28961573281`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_12_public_preview_fbcf63d.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha fbcf63dcfc54e7d6481618d74fd67709da097ddb
```

Result:

- `build_info.json` matched `fbcf63dcfc54e7d6481618d74fd67709da097ddb`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `fbcf63d` and salvage total `0/7`.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_12_public_preview_fbcf63d.png`
- Pass 12 visual baseline decision: `docs/current/PASS_12_OXYGEN_REST_VISUAL_BASELINE_DECISION.md`
- Focused Pass 12 capture: `visual_captures/pass_12_oxygen_rest_pressure/production_slice_01_oxygen_rest_pressure.png`
- Pass 12 smoke: `--smoke-pass-12-oxygen-rest-pressure`

## Follow-Up

No Web preview fix is needed. Pass 12 can close out under #233.
