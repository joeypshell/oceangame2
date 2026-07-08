# Pass 07 Hazard Pressure Web Preview Verification

Date: 2026-07-08

Issue: #178 `Verify public Web preview after Pass 07 hazard/navigation pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 07 public Web preview verification is complete for deployed runtime commit `1b90187a55c9d0c0baa11a46f35288b5d81c02ce`.

The later Pass 07 visual-baseline commit `b62ab126222e0d3ba4c0e3f6d1811bf881aae035` changed docs, captures, and accepted baselines only. It did not trigger `Godot Web Export` because the public runtime did not change after `1b90187`.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "1b90187",
  "git_sha": "1b90187a55c9d0c0baa11a46f35288b5d81c02ce",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T03:55:19+00:00"
}
```

Workflow runs:

- Godot Web Export for deployed runtime commit: `https://github.com/joeypshell/oceangame2/actions/runs/28916261068`, success.
- Godot Smoke for deployed runtime commit: `https://github.com/joeypshell/oceangame2/actions/runs/28916261027`, success.
- Godot Smoke for accepted visual-baseline commit: `https://github.com/joeypshell/oceangame2/actions/runs/28916414980`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\AppData\Local\Temp\oceangame2-web-preview-check\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_07_public_preview_1b90187.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 1b90187a55c9d0c0baa11a46f35288b5d81c02ce
```

Result:

- `build_info.json` matched `1b90187a55c9d0c0baa11a46f35288b5d81c02ce`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL software/performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `1b90187`.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_07_public_preview_1b90187.png`
- Pass 07 visual baseline decision: `docs/current/PASS_07_HAZARD_PRESSURE_VISUAL_BASELINE_DECISION.md`
- Pass 07 focused hazard-pressure capture: `visual_captures/hazard_pressure/production_slice_01_hazard_pressure.png`

## Follow-Up

No Web preview fix is needed. Pass 07 can close out and evaluate the next controlled gameplay pass direction.
