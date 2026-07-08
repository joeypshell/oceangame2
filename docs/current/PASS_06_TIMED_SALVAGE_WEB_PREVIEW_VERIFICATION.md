# Pass 06 Timed-Salvage Web Preview Verification

Date: 2026-07-08

Issue: #168 `Verify public Web preview after Pass 06 timed-salvage feedback pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 06 public Web preview verification is complete for deployed runtime commit `2608fc166af07738dc764143365f1a833890b675`.

The later Pass 06 capture/baseline commits are documentation and visual-review artifacts only. They do not trigger the `Godot Web Export` workflow because the public runtime did not change after `2608fc1`.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "2608fc1",
  "git_sha": "2608fc166af07738dc764143365f1a833890b675",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-07T21:43:55-05:00"
}
```

Workflow runs:

- Godot Web Export: `https://github.com/joeypshell/oceangame2/actions/runs/28913642138`, success.
- Godot Smoke for deployed runtime commit: `https://github.com/joeypshell/oceangame2/actions/runs/28913642135`, success.
- Godot Smoke for focused capture commit: `https://github.com/joeypshell/oceangame2/actions/runs/28913735363`, success.
- Godot Smoke for accepted visual-baseline commit: `https://github.com/joeypshell/oceangame2/actions/runs/28913871682`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_06_public_preview_2608fc1.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 2608fc1
```

Result:

- `build_info.json` matched `2608fc166af07738dc764143365f1a833890b675`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `2608fc1`.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_06_public_preview_2608fc1.png`
- Pass 06 visual baseline decision: `docs/current/PASS_06_TIMED_SALVAGE_VISUAL_BASELINE_DECISION.md`
- Pass 06 focused timed-salvage capture: `visual_captures/timed_salvage/production_slice_01_timed_salvage.png`

## Follow-Up

No Web preview fix is needed. The next pass can proceed from the Pass 06 closeout after #169 records the recommended direction.
