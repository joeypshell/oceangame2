# Pass 22 Destination Payoff Web Preview Verification

Date: 2026-07-09

Issue: #510 `Verify public Web preview after Pass 22 destination payoff`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 22 public Web preview verification is complete for deployed runtime/export commit `06db749884e31c681c7cff89d9959dddd43b349f`.

Repository head at verification time was `1699e4f821e03d8f30aaea88f6300d09c371957d`, the #509 visual-decision documentation commit. That commit changed documentation only and did not produce a newer Web export; the expected deployed build remains the #508 destination-payoff capture/runtime export.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "06db749",
  "git_sha": "06db749884e31c681c7cff89d9959dddd43b349f",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T12:06:48-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 22 build: `https://github.com/joeypshell/oceangame2/actions/runs/29035840841`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH="$env:TEMP\oceangame2-web-preview-check\node_modules"
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 06db749884e31c681c7cff89d9959dddd43b349f
```

Result:

- `build_info.json` matched `06db749884e31c681c7cff89d9959dddd43b349f`.
- Godot canvas initialized at `1280x720`.
- Wide viewport canvas initialized at `1920x1080`.
- Framing thumbnail mean difference was `1.28`, below the threshold of `18`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL/software fallback and `ReadPixels` performance warnings only.

## Reviewed Artifacts

- Web preview checker screenshot: `exports/web-preview-check.png` (local generated verification artifact, not committed)
- Focused Pass 22 capture command: `--capture-pass-22-destination-payoff`
- Visual decision: `docs/current/PASS_22_DESTINATION_PAYOFF_VISUAL_BASELINE_DECISION.md`
- Smoke: `--smoke-pass-22-destination-payoff`

## Follow-Up

No Web preview fix is needed. Pass 22 can close out under #511.
