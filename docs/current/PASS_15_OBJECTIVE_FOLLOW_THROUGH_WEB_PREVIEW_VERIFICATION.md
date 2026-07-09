# Pass 15 Objective Follow-Through Web Preview Verification

Date: 2026-07-08

Issue: #306 `Verify public Web preview after Pass 15 objective follow-through`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 15 public Web preview verification is complete for deployed runtime commit `263dbaf245cc37b29128d45a4dd691a10c9fedc8`.

Repository head at verification time was `0bcbac186a971423e2b386d6c7bfe684a2d52bfc`, the #305 visual-decision doc commit. That commit changed documentation only and did not trigger the Web export workflow path filters, so the expected deployed runtime build remains #304.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "263dbaf",
  "git_sha": "263dbaf245cc37b29128d45a4dd691a10c9fedc8",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T20:18:55-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 15 runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28987226002`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_15_public_preview_263dbaf.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 263dbaf245cc37b29128d45a4dd691a10c9fedc8
```

Result:

- `build_info.json` matched `263dbaf245cc37b29128d45a4dd691a10c9fedc8`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `263dbaf`, salvage total `0/7`, and `Objective: Deep cache 0/2` visible in the compact overlay.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_15_public_preview_263dbaf.png`
- Focused Pass 15 capture: `visual_captures/pass_15_objective_follow_through/production_slice_01_objective_follow_through.png`
- Visual decision: `docs/current/PASS_15_OBJECTIVE_FOLLOW_THROUGH_VISUAL_BASELINE_DECISION.md`
- Smoke: `--smoke-pass-15-objective-follow-through`

## Follow-Up

No Web preview fix is needed. Pass 15 can close out under #307.
