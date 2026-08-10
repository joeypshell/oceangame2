# Living Expedition 05 Web Verification

Date: 2026-08-10

Issue: #1351

Status: **TECHNICAL PASS; OWNER VERDICT PENDING**

## Result

The exact public Living Expedition 05 runtime initializes successfully at both
review checkpoints on desktop and landscape mobile. This verifies deployment,
state seeding, canvas framing, touch dispatch, and error-free browser startup;
it does not prove attachment, clarity, usefulness, or another-day motivation.

- exact runtime SHA: `267c5e1e16503355ce63416e08c181d31bca793d`
- build version: `267c5e1`
- `git_ref`: `main`
- `dirty`: `false`
- generated timestamp: `2026-08-10T15:21:09-05:00`
- [Web export and Pages run 31428518968](https://github.com/joeypshell/oceangame2/actions/runs/31428518968):
  export browser verification and GitHub Pages deployment passed
- [Godot Smoke run 31428518880](https://github.com/joeypshell/oceangame2/actions/runs/31428518880):
  source/map validation, core runtime, and regional journey jobs passed
- [Progression Audit run 31428518804](https://github.com/joeypshell/oceangame2/actions/runs/31428518804):
  Living Expedition 05 schema, creature progression, and graph audit passed

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated profile:
  `https://joeypshell.github.io/oceangame2/?review=267c5e1e16503355ce63416e08c181d31bca793d`
- fresh Silt Hound rescue:
  `https://joeypshell.github.io/oceangame2/?review=267c5e1e16503355ce63416e08c181d31bca793d&checkpoint=living_expedition_05_start`
- excavation-ready handoff:
  `https://joeypshell.github.io/oceangame2/?review=267c5e1e16503355ce63416e08c181d31bca793d&checkpoint=living_expedition_05_excavate_ready`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=267c5e1e16503355ce63416e08c181d31bca793d&map=production_slice_01`

## Browser Evidence

The independent post-deployment Chromium checker ran once per checkpoint. Both
runs confirmed the exact build metadata, full-level root/fresh/checkpoint
markers, explicit slice fallback, and no failed requests, page errors, browser
exceptions, Godot `SCRIPT ERROR`, or Godot `ERROR:`.

Shared framing evidence:

- desktop canvas: `1280x720`
- wide canvas: `1920x1080`
- iPhone-landscape canvas: `2532x1170` intrinsic at `844x390` CSS, positioned
  at `(0, 0)` with zero visual-viewport offset
- framing thumbnail mean difference: `1.32`, below the maximum `18`

Fresh-rescue checkpoint touch differences were move-down `14.37`, oxygen
`4.91`, cargo `5.50`, TOOL `5.52`, project `5.61`, day `5.40`, RESET `5.83`,
ACT `5.17`, USE `5.10`, and BOND `5.82`. Excavation-ready differences were
move-down `10.39`, oxygen `8.32`, cargo `5.49`, TOOL `5.51`, project `5.81`, day
`5.38`, RESET `17.85`, ACT `5.17`, USE `5.10`, and BOND `5.82`. Every value is
above the required `2`.

Separate retained browser screenshots confirmed:

- the rescue checkpoint begins at the canonical boat with Kite and Mica
  committed and Marl unresolved;
- the excavation-ready checkpoint frames Marl beside the closed mound with the
  `Excavate` prompt still incomplete;
- the mobile BOND control is rendered inside the canvas at both checkpoints;
- the desktop and mobile pages reported zero console warnings or errors during
  that focused inspection.

Chromium emitted only the accepted WebGL `ReadPixels` performance warning.

## Release Evidence

The local release-candidate validator passed its complete map/source,
progression, profile, material, parity, baseline-cleanliness, core runtime,
Expansion 03-17, and Living Expedition 01-04 matrix. The separate current
checks also passed:

- `smoke_living_expedition_05_journey.gd`: schema-v3 migration, rescue,
  commitment, selection, complete Excavate phases, cargo-full preservation,
  pickup, banking, restoration, duplicate prevention, and equipment gates;
- `smoke_review_checkpoint_fixture.gd`: both LE05 checkpoint boundaries and
  isolated persistence behavior;
- every accepted production-level/slice/transfer-hub baseline remains clean;
- #52/#53 remain deferred optional slice-03 presentation work.

The [Living Expedition 05 Visual Decision](LIVING_EXPEDITION_05_VISUAL_DECISION.md)
records the focused desktop/mobile evidence and no-baseline-change decision.

## Known Limits

- The inherited status panel remains dense, particularly on mobile.
- The rescue checkpoint preserves the actual swim to Marl; use the
  excavation-ready checkpoint to review the action without replaying that leg.
- Automation cannot answer whether Marl creates attachment, whether the action
  is sufficiently clear, or whether the payoff motivates another expedition.

## Verification

```powershell
python tools/run_release_candidate_validation.py --require-godot
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_05_journey.gd --review-checkpoint=living_expedition_05_start
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_review_checkpoint_fixture.gd
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 267c5e1e16503355ce63416e08c181d31bca793d --checkpoint living_expedition_05_start
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 267c5e1e16503355ce63416e08c181d31bca793d --checkpoint living_expedition_05_excavate_ready
python tools/check_file_lengths.py
git diff --check
```

Issue #1351 and milestone #49 remain open for the explicit owner verdict.
