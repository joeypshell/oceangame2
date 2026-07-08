# Pass 11 Pre-Pickup Route Cue Web Preview Verification

Date: 2026-07-08

Issue: #221 `Verify public Web preview after Pass 11`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 11 public Web preview verification is complete for deployed runtime commit `4231d5fa8760840452acb9cdb3581f4199c74b95`.

Repository head at verification time was `7411c6403e4ab3f061544d77748a19ab5d29c6d1`, the #220 visual-baseline acceptance commit. That commit changed docs, captures, review sheets, and accepted baseline artifacts only, so the expected deployed runtime build remains #219.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "4231d5f",
  "git_sha": "4231d5fa8760840452acb9cdb3581f4199c74b95",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T16:15:45+00:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 11 runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28957866956`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH="$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_11_public_preview_4231d5f.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 4231d5fa8760840452acb9cdb3581f4199c74b95
```

Result:

- `build_info.json` matched `4231d5fa8760840452acb9cdb3581f4199c74b95`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL/software-renderer and `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `4231d5f` and salvage total `0/7`.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_11_public_preview_4231d5f.png`
- Pass 11 visual baseline decision: `docs/current/PASS_11_PRE_PICKUP_ROUTE_CUE_VISUAL_BASELINE_DECISION.md`
- Focused Pass 11 capture: `visual_captures/pass_11_pre_pickup_route_cue/production_slice_01_pre_pickup_route_cue.png`

## Follow-Up

No Web preview fix is needed. Pass 11 can close out under #222.
