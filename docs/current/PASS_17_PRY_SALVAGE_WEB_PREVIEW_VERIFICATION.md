# Pass 17 Pry Salvage Web Preview Verification

Date: 2026-07-09

Issue: #348 `Verify public Web preview after Pass 17 pry salvage pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 17 public Web preview verification is complete for deployed runtime/export commit `7fb78dc3eb4715583dec7ffd6b81925a6dda0bcd`.

Repository head at verification time was `07c1ebb86cda0fe3cef97dc7c425769ac09c6c9e`, the #347 visual-decision doc commit. That commit changed documentation only and did not trigger the Web export workflow path filters, so the expected deployed build remains #356.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "7fb78dc",
  "git_sha": "7fb78dc3eb4715583dec7ffd6b81925a6dda0bcd",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T00:00:34-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 17 build: `https://github.com/joeypshell/oceangame2/actions/runs/28995226155`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_17_public_preview_7fb78dc.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 7fb78dc3eb4715583dec7ffd6b81925a6dda0bcd
```

Result:

- `build_info.json` matched `7fb78dc3eb4715583dec7ffd6b81925a6dda0bcd`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `7fb78dc`, salvage total `0/8`, and `Objective: Deep cache 0/2` visible in the compact overlay.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_17_public_preview_7fb78dc.png`
- Focused Pass 17 capture: `visual_captures/pry_salvage/production_slice_01_pry_salvage.png`
- Visual decision: `docs/current/PASS_17_PRY_SALVAGE_VISUAL_BASELINE_DECISION.md`
- Smoke: `--smoke-pry-salvage`

## Follow-Up

No Web preview fix is needed. Pass 17 can close out under #349.
