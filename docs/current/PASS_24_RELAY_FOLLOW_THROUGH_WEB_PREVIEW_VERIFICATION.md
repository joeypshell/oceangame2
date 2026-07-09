# Pass 24 Relay Follow-Through Web Preview Verification

Date: 2026-07-09

Issue: #550 `Verify public Web preview after Pass 24 relay follow-through`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 24 public Web preview verification is complete for deployed runtime/export commit `840fa62f01b9d5fb9af1f35fa7d9e02d7af62e06`.

Repository head at verification time was `02bbdc6b656c0763271f6cab08a14def3a7d3b73`, the #549 visual-decision documentation commit. That commit changed documentation only and did not produce a newer Web export; the expected deployed build remains the #548 Pass 24 capture/runtime export.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "840fa62",
  "git_sha": "840fa62f01b9d5fb9af1f35fa7d9e02d7af62e06",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T14:21:44-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 24 build: `https://github.com/joeypshell/oceangame2/actions/runs/29044002428`, success.

## Browser Check

Command:

```powershell
$nodeRoot='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node'
$pnpm="$nodeRoot\node_modules\.pnpm"
$env:NODE_PATH=("$nodeRoot\node_modules","$pnpm\playwright@1.61.1\node_modules","$pnpm\playwright-core@1.61.1\node_modules" -join ';')
& "$nodeRoot\bin\node.exe" tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 840fa62f01b9d5fb9af1f35fa7d9e02d7af62e06
```

Result:

- `build_info.json` matched `840fa62f01b9d5fb9af1f35fa7d9e02d7af62e06`.
- Godot canvas initialized at `1280x720`.
- Wide viewport canvas initialized at `1920x1080`.
- Framing thumbnail mean difference was `1.26`, below the threshold of `18`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.

## Reviewed Artifacts

- Web preview checker screenshot: `exports/web-preview-check.png` (local ignored verification artifact, not committed).
- Focused Pass 24 capture command: `--capture-pass-24-relay-follow-through`.
- Visual decision: `docs/current/PASS_24_RELAY_FOLLOW_THROUGH_VISUAL_BASELINE_DECISION.md`.
- Smoke: `--smoke-pass-24-relay-follow-through`.

## Follow-Up

No Web preview fix is needed. Pass 24 can close out under #551.
