# Pass 25 Final-Dive Objective Web Preview Verification

Date: 2026-07-09

Issue: #570 `Verify public Web preview after Pass 25 final-dive objective`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 25 public Web preview verification is complete for deployed runtime/export commit `92dede0978ac10be9e07bc53df16cedd97b15cd4`.

Repository head at verification time was `6b63c95c531ab7d6669788549bbded7477c8dc5d`, the #569 visual-decision documentation commit. That commit changed documentation only and did not produce a newer Web export; the expected deployed build remains the #568 Pass 25 capture/runtime export.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "92dede0",
  "git_sha": "92dede0978ac10be9e07bc53df16cedd97b15cd4",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T15:13:05-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 25 build: `https://github.com/joeypshell/oceangame2/actions/runs/29047075603`, success.

## Browser Check

Command:

```powershell
$nodeRoot='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node'
$pnpm="$nodeRoot\node_modules\.pnpm"
$env:NODE_PATH=@("$nodeRoot\node_modules", "$pnpm\playwright@1.61.1\node_modules", "$pnpm\playwright-core@1.61.1\node_modules") -join ';'
& "$nodeRoot\bin\node.exe" tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 92dede0978ac10be9e07bc53df16cedd97b15cd4
```

Result:

- `build_info.json` matched `92dede0978ac10be9e07bc53df16cedd97b15cd4`.
- Godot canvas initialized at `1280x720`.
- Wide viewport canvas initialized at `1920x1080`.
- Framing thumbnail mean difference was `1.28`, below the threshold of `18`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.

## Reviewed Artifacts

- Web preview checker screenshot: `exports/web-preview-check.png` (local ignored verification artifact, not committed).
- Focused Pass 25 capture command: `--capture-pass-25-final-dive-objective`.
- Visual decision: `docs/current/PASS_25_FINAL_DIVE_OBJECTIVE_VISUAL_BASELINE_DECISION.md`.
- Smoke: `--smoke-pass-25-final-dive-objective`.

## Follow-Up

No Web preview fix is needed. Pass 25 can close out under #571.
