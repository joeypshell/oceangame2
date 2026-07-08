# Pass 10 Return Pressure Web Preview Verification

Date: 2026-07-08

Issue: #208 `Verify public Web preview after Pass 10 return-pressure pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 10 public Web preview verification is complete for deployed runtime commit `977ad13808e63cf3630d67e945de1a3e66aa7f3f`.

Repository head at verification time was `aeb25747b4ab7405c3f9c8f1e7cab548dd8c90b1`, the #207 visual-baseline acceptance commit. That commit changed docs, captures, and accepted baseline artifacts only, so the expected deployed runtime build remains #206.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "977ad13",
  "git_sha": "977ad13808e63cf3630d67e945de1a3e66aa7f3f",
  "git_ref": "main"
}
```

Workflow run:

- Godot Web Export for deployed Pass 10 runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28952478251`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH="$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_10_public_preview_977ad13.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 977ad13808e63cf3630d67e945de1a3e66aa7f3f
```

Result:

- `build_info.json` matched `977ad13808e63cf3630d67e945de1a3e66aa7f3f`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL/software-renderer and `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `977ad13` and salvage total `0/7`.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_10_public_preview_977ad13.png`
- Pass 10 visual baseline decision: `docs/current/PASS_10_RETURN_PRESSURE_VISUAL_BASELINE_DECISION.md`
- Focused Pass 10 capture: `visual_captures/pass_10_return_pressure/production_slice_01_return_pressure.png`

## Follow-Up

No Web preview fix is needed. Pass 10 can close out under #209.
