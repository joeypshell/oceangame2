# Pass 19 Cargo Upgrade Web Preview Verification

Date: 2026-07-09

Issue: #388 `Verify public Web preview after Pass 19 cargo upgrade pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 19 public Web preview verification is complete for deployed runtime/export commit `6df5388f7cc0971bf7f14cbe4fc753b5b147c152`.

Repository head at verification time was `14821f82d35a39641af555bfa2684db64a61650f`, the #387 visual-decision doc commit. That commit changed documentation only and did not trigger the Web export workflow path filters, so the expected deployed build remains #396.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "6df5388",
  "git_sha": "6df5388f7cc0971bf7f14cbe4fc753b5b147c152",
  "git_ref": "main",
  "dirty": false
}
```

Workflow run:

- Godot Web Export for deployed Pass 19 build: `https://github.com/joeypshell/oceangame2/actions/runs/29001747091`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_19_public_preview_6df5388.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 6df5388f7cc0971bf7f14cbe4fc753b5b147c152
```

Result:

- `build_info.json` matched `6df5388f7cc0971bf7f14cbe4fc753b5b147c152`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `6df5388`, salvage total `0/8`, wallet `0`, the `U: O2 +15 (500)` prompt, the `C: Cargo +1 (700)` prompt, and `Objective: Deep cache 0/2` visible in the compact overlay.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_19_public_preview_6df5388.png`
- Focused Pass 19 capture: `visual_captures/pass_19_cargo_upgrade/production_slice_01_pass_19_cargo_upgrade.png`
- Visual decision: `docs/current/PASS_19_CARGO_UPGRADE_VISUAL_BASELINE_DECISION.md`
- Smoke: `--smoke-pass-19-cargo-upgrade`

## Follow-Up

No Web preview fix is needed. Pass 19 can close out under #389.
