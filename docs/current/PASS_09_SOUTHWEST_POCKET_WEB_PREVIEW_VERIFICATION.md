# Pass 09 Southwest Pocket Web Preview Verification

Date: 2026-07-08

Issue: #198 `Verify public Web preview after Pass 09 southwest pocket pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 09 public Web preview verification is complete for deployed runtime commit `211ca05ffe3dfef3f13f08359307ef7b5780cf55`.

Repository head at verification time was `3db9b2e63f3afc37569ab269e25a6047235ae4a9`, the #197 visual-baseline acceptance commit. That commit changed docs, captures, and accepted baseline artifacts only, so the expected deployed runtime build remains #196.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "211ca05",
  "git_sha": "211ca05ffe3dfef3f13f08359307ef7b5780cf55",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T08:10:10-05:00"
}
```

Workflow runs:

- Godot Web Export for deployed runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28945133816`, success.
- Godot Web Export for previous Pass 09 smoke commit: `https://github.com/joeypshell/oceangame2/actions/runs/28944857611`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH="$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_09_public_preview_211ca05.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 211ca05ffe3dfef3f13f08359307ef7b5780cf55
```

Result:

- `build_info.json` matched `211ca05ffe3dfef3f13f08359307ef7b5780cf55`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL/software-renderer and `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `211ca05` and salvage total `0/7`.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_09_public_preview_211ca05.png`
- Pass 09 visual baseline decision: `docs/current/PASS_09_SOUTHWEST_POCKET_VISUAL_BASELINE_DECISION.md`
- Focused Pass 09 capture: `visual_captures/southwest_pocket_decision/production_slice_01_southwest_pocket_decision.png`

## Follow-Up

No Web preview fix is needed. Pass 09 can close out under #199.
