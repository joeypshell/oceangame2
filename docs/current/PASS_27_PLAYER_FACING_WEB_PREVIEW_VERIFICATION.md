# Pass 27 Player-Facing Web Preview Verification

Date: 2026-07-09

Issue: #609 `Verify public Web preview after Pass 27 player-facing pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 27 public Web preview verification is complete for deployed runtime/export commit `dcfa188a06af3c98c900875b29fc2744e0fff32d`.

Repository head at verification time was `e75c46ef02d5bd713e0773e0d5d5fbf0592205f2`, the #608 visual-decision documentation commit. That commit changed documentation only and did not produce a newer Web export; the expected deployed build remains the #607 Pass 27 player-facing capture/runtime export.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "dcfa188",
  "git_sha": "dcfa188a06af3c98c900875b29fc2744e0fff32d",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T21:49:03+00:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 27 build: `https://github.com/joeypshell/oceangame2/actions/runs/29052578740`, success.

## Browser Check

Command:

```powershell
$nodeRoot='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node'
$env:NODE_PATH=@("$nodeRoot\node_modules", "$nodeRoot\node_modules\.pnpm\node_modules") -join ';'
& "$nodeRoot\bin\node.exe" tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha dcfa188a06af3c98c900875b29fc2744e0fff32d
```

Result:

- `build_info.json` matched `dcfa188a06af3c98c900875b29fc2744e0fff32d`.
- Godot canvas initialized at `1280x720`.
- Wide viewport canvas initialized at `1920x1080`.
- Framing thumbnail mean difference was `1.27`, below the threshold of `18`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.

## Reviewed Artifacts

- Web preview checker screenshot: `exports/web-preview-check.png` (local ignored verification artifact, not committed).
- Focused Pass 27 capture command: `--capture-pass-27-player-facing`.
- Visual decision: `docs/current/PASS_27_PLAYER_FACING_VISUAL_BASELINE_DECISION.md`.
- Smoke: `--smoke-pass-27-facing-transitions`.

## Follow-Up

No Web preview fix is needed. Pass 27 can close out under #610.
