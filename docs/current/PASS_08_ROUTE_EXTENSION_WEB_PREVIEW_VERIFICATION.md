# Pass 08 Route Extension Web Preview Verification

Date: 2026-07-08

Issue: #189 `Verify public Web preview after Pass 08 route-scale pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 08 public Web preview verification is complete for deployed runtime commit `722837d2d35b4c904f90a475c1251f533d2468ec`.

Repository head at verification time was `8b2ca0b28225e7cf3da99ab51e9dfa3fe8d2993f`, the #188 visual-baseline acceptance commit. That commit changed docs, captures, and accepted baseline artifacts only, so it did not trigger `Godot Web Export`. The deployed runtime commit `722837d` includes the Pass 08 route-extension source/runtime state through #187.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "722837d",
  "git_sha": "722837d2d35b4c904f90a475c1251f533d2468ec",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T04:53:53+00:00"
}
```

Workflow runs:

- Godot Web Export for deployed runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28918449755`, success.
- Godot Smoke for deployed runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28918449733`, success.
- Godot Smoke for visual-baseline acceptance: `https://github.com/joeypshell/oceangame2/actions/runs/28918561538`, success.

## Browser Check

Command:

```powershell
$env:PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin;' + $env:PATH
$env:NODE_PATH="$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_08_public_preview_722837d.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 722837d2d35b4c904f90a475c1251f533d2468ec
```

Result:

- `build_info.json` matched `722837d2d35b4c904f90a475c1251f533d2468ec`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL/software-renderer and `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `722837d` and salvage total `0/7`.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_08_public_preview_722837d.png`
- Pass 08 visual baseline decision: `docs/current/PASS_08_ROUTE_EXTENSION_VISUAL_BASELINE_DECISION.md`
- Focused route-extension capture: `visual_captures/route_extension/production_slice_01_route_extension.png`

## Follow-Up

No Web preview fix is needed. Pass 08 can close out under #190.
