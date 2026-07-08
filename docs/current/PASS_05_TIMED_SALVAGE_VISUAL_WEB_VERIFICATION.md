# Pass 05 Timed Salvage Visual And Web Verification

Date: 2026-07-08

Issues: #156 `Review and accept Pass 05 timed-salvage visual baseline`, #157 `Verify public Web preview after Pass 05 timed-salvage pass`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

## Result

Pass 05 visual review and public Web verification are complete for runtime commit `0a412bf82d0cf329bd9ea4e8ad032bfa5b2c66c9`.

No normal production-slice baseline update was accepted. The only accepted visual difference is the focused timed-salvage review state for `salvage_deep_right_cache`.

## Reviewed Artifacts

- Focused timed-salvage capture: `visual_captures/timed_salvage/production_slice_01_timed_salvage.png`
- Focused route-outcome capture: `visual_captures/route_outcome/production_slice_01_route_outcome_result.png`
- Baseline comparison sheets:
  - `references/asset_reviews/production_slice_01_visual_baseline_review.png`
  - `references/asset_reviews/production_slice_02_visual_baseline_review.png`
  - `references/asset_reviews/production_slice_03_visual_baseline_review.png`
  - `references/asset_reviews/production_slice_04_visual_baseline_review.png`
- Public preview screenshot: `visual_captures/web_preview/pass_05_public_preview_0a412bf.png`

## Accepted Differences

Accepted for focused review only:

- `salvage_deep_right_cache` shows the timed-salvage overlay state `Salvaging deep cache 52%`.
- The route-outcome focused capture remains valid after the route completion path waits through the timed target.

Not accepted as baseline changes:

- No normal production-slice capture differences were accepted.
- No terrain, player, boat, prop, hazard, background, camera, topology, collision, or broad asset differences were accepted.
- No `.import` sidecars are part of accepted production-slice baselines.

## Stable Areas

`python tools/manage_production_slice_baseline.py compare-all` rendered all four production-slice review sheets. Pixel comparison against the accepted normal baselines showed zero changed pixels for every configured production-slice view.

Stable:

- production slices 01-04 normal captures
- cave terrain and seams
- water and background depth art
- player, boat, salvage, hazard, and prop sprites
- normal camera-test framing
- normal review overlay layout

## Public Build Metadata

Fetched from `https://joeypshell.github.io/oceangame2/build_info.json`:

```json
{
  "version": "0a412bf",
  "git_sha": "0a412bf82d0cf329bd9ea4e8ad032bfa5b2c66c9",
  "git_ref": "main",
  "dirty": false
}
```

Workflow runs:

- Godot Smoke: `https://github.com/joeypshell/oceangame2/actions/runs/28911760512`, success.
- Godot Web Export: `https://github.com/joeypshell/oceangame2/actions/runs/28911760531`, success.

## Browser Check

Command:

```powershell
$env:WEB_PREVIEW_SCREENSHOT='visual_captures/web_preview/pass_05_public_preview_0a412bf.png'
$env:NODE_PATH='C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 0a412bf
```

Result:

- `build_info.json` matched `0a412bf82d0cf329bd9ea4e8ad032bfa5b2c66c9`.
- Godot canvas initialized at `1280x720`.
- No failed network requests were reported.
- No missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only.
- Screenshot showed the default `production_slice_01` public preview with build label `0a412bf`.

## Verification Commands

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-timed-salvage
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-route-outcome-result
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
```

## Follow-Up

No follow-up visual issue is needed for the normal production-slice baselines; they remained pixel-stable.
