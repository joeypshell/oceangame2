# Pass 13 Route Commitment Web Preview Verification

Date: 2026-07-08

Issue: #244 `Verify public Web preview after Pass 13`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 13 public Web preview verification is complete for deployed runtime commit `b7b19811de09678d5b3bf6c2da161109a8453682`.

Repository head at verification time was `ec274cf81fc9dba9c7ca54d1ffd9335b49059a32`, the #243 visual-decision doc commit. That commit changed documentation only and did not trigger the Web export workflow path filters, so the expected deployed runtime build remains #242.

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "b7b1981",
  "git_sha": "b7b19811de09678d5b3bf6c2da161109a8453682",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-08T21:06:16+00:00"
}
```

Workflow run:

- Godot Web Export for deployed Pass 13 runtime: `https://github.com/joeypshell/oceangame2/actions/runs/28975691065`, success.

## Browser Check

Command:

```powershell
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_13_public_preview_b7b1981.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha b7b19811de09678d5b3bf6c2da161109a8453682
```

Result:

- `build_info.json` matched `b7b19811de09678d5b3bf6c2da161109a8453682`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `b7b1981` and salvage total `0/7`.

## Reviewed Artifacts

- Public preview screenshot: `visual_captures/web_preview/pass_13_public_preview_b7b1981.png`
- Pass 13 visual decision: `docs/current/PASS_13_ROUTE_COMMITMENT_VISUAL_BASELINE_DECISION.md`
- Focused Pass 13 capture: `visual_captures/pass_13_route_commitment/production_slice_01_route_commitment.png`
- Pass 13 smoke: `--smoke-pass-13-route-commitment`

The default public camera starts before objective progress, so the route-commitment state is verified by the focused capture and deterministic smoke rather than by immediate first-screen text.

## Follow-Up

No Web preview fix is needed. Pass 13 can close out under #245.
