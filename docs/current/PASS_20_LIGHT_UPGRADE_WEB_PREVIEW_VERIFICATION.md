# Pass 20 Light Upgrade Web Preview Verification

Date: 2026-07-09

Issue: #408 `Verify public Web preview after Pass 20 light upgrade pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 20 public Web preview verification is complete for deployed runtime/export commit `a86a4f7064cd9d8ca15caa4ad4543603a848ed55`.

Repository head at verification time was `73561ed23a5c7fdda82e144c72d5edd87f4fd12c`, the #407 visual-decision documentation commit. That commit changed documentation only and did not trigger the Web export workflow path filters, so the expected deployed build remains #416.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "a86a4f7",
  "git_sha": "a86a4f7064cd9d8ca15caa4ad4543603a848ed55",
  "git_ref": "main",
  "dirty": false
}
```

Workflow run:

- Godot Web Export for deployed Pass 20 build: `https://github.com/joeypshell/oceangame2/actions/runs/29008331579`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_20_public_preview_a86a4f7.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha a86a4f7064cd9d8ca15caa4ad4543603a848ed55
```

Result:

- `build_info.json` matched `a86a4f7064cd9d8ca15caa4ad4543603a848ed55`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `a86a4f7`, salvage total `0/8`, wallet `0`, the `U: O2 +15 (500)` prompt, the `C: Cargo +1 (700)` prompt, the new `L: Light +range (900)` prompt, and `Objective: Deep cache 0/2` visible in the compact overlay.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_20_public_preview_a86a4f7.png`
- Focused Pass 20 capture: `visual_captures/pass_20_light_upgrade/production_slice_01_pass_20_light_upgrade.png`
- Visual decision: `docs/current/PASS_20_LIGHT_UPGRADE_VISUAL_BASELINE_DECISION.md`
- Smoke: `--smoke-pass-20-light-upgrade`

## Follow-Up

No Web preview fix is needed. Pass 20 can close out under #409.
