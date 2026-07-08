# Pass 07 Hazard Pressure Web Preview Verification

Date: 2026-07-08

Issue: #178 `Verify public Web preview after Pass 07 hazard/navigation pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 07 public Web preview verification is complete for deployed build commit `99d5fff60e388f9c58ab26a797f617366cfbb509`.

The behavior-changing Pass 07 runtime/capture work was deployed at `1b90187a55c9d0c0baa11a46f35288b5d81c02ce`. The later visual-baseline commit `b62ab126222e0d3ba4c0e3f6d1811bf881aae035` changed docs, captures, and accepted baselines only, so it did not trigger `Godot Web Export`.

A final source-state cleanup commit, `99d5fff60e388f9c58ab26a797f617366cfbb509`, added the missing Godot `.uid` sidecar for the Pass 07 smoke helper. That changed public build metadata but did not change map data, gameplay behavior, visuals, or capture acceptance.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "99d5fff",
  "git_sha": "99d5fff60e388f9c58ab26a797f617366cfbb509",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T04:08:50+00:00"
}
```

Workflow runs:

- Godot Web Export for behavior-changing runtime commit: `https://github.com/joeypshell/oceangame2/actions/runs/28916261068`, success.
- Godot Smoke for behavior-changing runtime commit: `https://github.com/joeypshell/oceangame2/actions/runs/28916261027`, success.
- Godot Smoke for accepted visual-baseline commit: `https://github.com/joeypshell/oceangame2/actions/runs/28916414980`, success.
- Godot Web Export for final `.uid` sidecar source-state commit: `https://github.com/joeypshell/oceangame2/actions/runs/28916764273`, success.
- Godot Smoke for final `.uid` sidecar source-state commit: `https://github.com/joeypshell/oceangame2/actions/runs/28916764245`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\AppData\Local\Temp\oceangame2-web-preview-check\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='exports/web-preview-check-99d5fff.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 99d5fff60e388f9c58ab26a797f617366cfbb509
```

Result:

- `build_info.json` matched `99d5fff60e388f9c58ab26a797f617366cfbb509`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL software/performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `99d5fff`.

## Reviewed Artifacts

- Public preview screenshot from the behavior-changing runtime check: `visual_captures/web_preview/pass_07_public_preview_1b90187.png`
- Pass 07 visual baseline decision: `docs/current/PASS_07_HAZARD_PRESSURE_VISUAL_BASELINE_DECISION.md`
- Pass 07 focused hazard-pressure capture: `visual_captures/hazard_pressure/production_slice_01_hazard_pressure.png`

## Follow-Up

No Web preview fix is needed. Pass 07 can close out and evaluate the next controlled gameplay pass direction.
