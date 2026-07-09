# Pass 16 Primary Dive Completion Web Preview Verification

Date: 2026-07-09

Issue: #328 `Verify public Web preview after primary dive completion pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 16 public Web preview verification is complete for deployed runtime commit `9b1b530efde042287e6cbc6b143b866ca45709a4`.

Repository head at verification time was `819a9a83d7c42357e8333858a13d8173bca0d665`, the #327 visual-decision doc commit. That commit changed documentation only and did not trigger the Web export workflow path filters, so the expected deployed runtime build remains #336.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "9b1b530",
  "git_sha": "9b1b530efde042287e6cbc6b143b866ca45709a4",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T21:43:59-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 16 runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28990313668`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_16_public_preview_9b1b530.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 9b1b530efde042287e6cbc6b143b866ca45709a4
```

Result:

- `build_info.json` matched `9b1b530efde042287e6cbc6b143b866ca45709a4`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `9b1b530`, salvage total `0/7`, and `Objective: Deep cache 0/2` visible in the compact overlay.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_16_public_preview_9b1b530.png`
- Focused Pass 16 capture: `visual_captures/primary_dive_completion/production_slice_01_primary_dive_completion.png`
- Visual decision: `docs/current/PASS_16_PRIMARY_DIVE_COMPLETION_VISUAL_BASELINE_DECISION.md`
- Smoke: `--smoke-primary-dive-completion`

## Follow-Up

No Web preview fix is needed. Pass 16 can close out under #329.
