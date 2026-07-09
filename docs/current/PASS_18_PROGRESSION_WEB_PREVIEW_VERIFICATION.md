# Pass 18 Progression Web Preview Verification

Date: 2026-07-09

Issue: #368 `Verify public Web preview after Pass 18 progression pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 18 public Web preview verification is complete for deployed runtime/export commit `c97b0ab9c7b7438057eacd3693b91eb8fcbbac9f`.

Repository head at verification time was `f98374d7510d218eeb37c84aa4384c8668762baa`, the #367 visual-decision doc commit. That commit changed documentation only and did not trigger the Web export workflow path filters, so the expected deployed build remains #376.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "c97b0ab",
  "git_sha": "c97b0ab9c7b7438057eacd3693b91eb8fcbbac9f",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T01:15:11-05:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 18 build: `https://github.com/joeypshell/oceangame2/actions/runs/28998167503`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_18_public_preview_c97b0ab.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha c97b0ab9c7b7438057eacd3693b91eb8fcbbac9f
```

Result:

- `build_info.json` matched `c97b0ab9c7b7438057eacd3693b91eb8fcbbac9f`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `c97b0ab`, salvage total `0/8`, wallet `0`, the `U: O2 +15 (500)` upgrade prompt, and `Objective: Deep cache 0/2` visible in the compact overlay.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_18_public_preview_c97b0ab.png`
- Focused Pass 18 capture: `visual_captures/pass_18_progression/production_slice_01_pass_18_progression.png`
- Visual decision: `docs/current/PASS_18_PROGRESSION_VISUAL_BASELINE_DECISION.md`
- Smoke: `--smoke-pass-18-progression`

## Follow-Up

No Web preview fix is needed. Pass 18 can close out under #369.
