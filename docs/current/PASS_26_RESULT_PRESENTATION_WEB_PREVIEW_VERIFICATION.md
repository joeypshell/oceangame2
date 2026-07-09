# Pass 26 Result Presentation Web Preview Verification

Date: 2026-07-09

Issue: #589 `Verify public Web preview after Pass 26 presentation polish`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 26 public Web preview verification is complete for deployed runtime/export commit `c0f6e899e32271231863de26f4053705ca8a4635`.

Repository head at verification time was `f9db0cca6a6ec2da1cd869292773c583622ea6c1`, the #588 visual-decision documentation commit. That commit changed documentation only and did not produce a newer Web export; the expected deployed build remains the #587 Pass 26 result-presentation capture/runtime export.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "c0f6e89",
  "git_sha": "c0f6e899e32271231863de26f4053705ca8a4635",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T16:08:44-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 26 build: `https://github.com/joeypshell/oceangame2/actions/runs/29050335140`, success.

## Browser Check

Command:

```powershell
$nodeRoot='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node'
$env:NODE_PATH=@("$nodeRoot\node_modules", "$nodeRoot\node_modules\.pnpm\node_modules") -join ';'
& "$nodeRoot\bin\node.exe" tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha c0f6e899e32271231863de26f4053705ca8a4635
```

Result:

- `build_info.json` matched `c0f6e899e32271231863de26f4053705ca8a4635`.
- Godot canvas initialized at `1280x720`.
- Wide viewport canvas initialized at `1920x1080`.
- Framing thumbnail mean difference was `1.26`, below the threshold of `18`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.

## Reviewed Artifacts

- Web preview checker screenshot: `exports/web-preview-check.png` (local ignored verification artifact, not committed).
- Focused Pass 26 capture command: `--capture-pass-26-result-presentation`.
- Visual decision: `docs/current/PASS_26_RESULT_PRESENTATION_VISUAL_BASELINE_DECISION.md`.
- Smoke: `--smoke-pass-26-result-presentation`.

## Follow-Up

No Web preview fix is needed. Pass 26 can close out under #590.
