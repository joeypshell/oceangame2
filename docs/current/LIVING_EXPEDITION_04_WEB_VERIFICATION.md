# Living Expedition 04 Web Verification

Date: 2026-08-08

Issue: #1322 `Verify Living Expedition 04 exact Web build and review checkpoint`

## Result

**PASS for the exact deployment, checkpoint startup, responsive framing, touch
dispatch, and deterministic companion-shaped encounter contract.**

- exact runtime SHA: `ce6f23f2fd72939de40bfa78c70d7344da00de46`
- build version: `ce6f23f`
- `git_ref`: `main`
- `dirty`: `false`
- generated timestamp: `2026-08-09T00:59:29-05:00`
- [Web export and Pages run 31297858844](https://github.com/joeypshell/oceangame2/actions/runs/31297858844):
  export browser verification and GitHub Pages deployment passed
- [Godot Smoke run 31297858805](https://github.com/joeypshell/oceangame2/actions/runs/31297858805):
  source/map validation, core runtime, and regional journey jobs passed at the
  same SHA
- [Progression Audit run 31297858818](https://github.com/joeypshell/oceangame2/actions/runs/31297858818):
  passed at the same SHA

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=ce6f23f2fd72939de40bfa78c70d7344da00de46`
- Living Expedition 04 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=ce6f23f2fd72939de40bfa78c70d7344da00de46&checkpoint=living_expedition_04_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=ce6f23f2fd72939de40bfa78c70d7344da00de46&map=production_slice_01`

## Exact Build Evidence

Public `build_info.json` reports the full SHA above, clean `main`, and the
generated timestamp above. The independent post-deployment Chromium checker
confirmed:

- root and fresh review load `production_level_01`
- `living_expedition_04_start` loads an isolated profile on
  `production_level_01` with propulsion fins available
- the explicit fallback loads `production_slice_01`
- desktop canvas: `1280x720`
- wide canvas: `1920x1080`
- iPhone-landscape canvas: `2532x1170` intrinsic at `844x390` CSS, positioned
  at `(0, 0)` with zero visual-viewport offset
- checkpoint touch differences: move-down `12.95`, oxygen `4.91`, cargo
  `5.50`, TOOL `5.52`, project `5.61`, day `5.40`, RESET `5.83`, ACT `5.17`,
  USE `5.10`, and BOND `5.82`, all above the required `2`
- root touch differences: move-down `8.60`; every command value also passed
- framing mean difference: `1.32`, below the maximum `18`
- no failed requests, page errors, uncaught browser exceptions, Godot
  `SCRIPT ERROR`, or Godot `ERROR:` occurred

Chromium emitted only the accepted WebGL `ReadPixels` performance warning.

## Encounter Contract

The exact deployed SHA is also the head SHA of the passing regional journey
job. A focused deterministic replay at that revision confirmed:

1. Mica reads the existing eel's warning phase, westward lunge direction, and
   retreat response without moving, damaging, slowing, or pacifying it.
2. Ordinary retreat remains viable without a companion action.
3. Guardian Pulse recoils the eel by `84px`, creates a `1.25s` opening, and
   leaves its health at `3/3`.
4. The Shock Prod remains the only damage owner and defeats the eel in the
   stable health sequence `2`, `1`, `0`.
5. Defeat exposes one electrocyte harvest; full cargo blocks collection without
   deleting it, later harvesting and banking work, and the guarded cache stays
   uncollected.
6. Retry, connector reload, map reload, and the fresh-day reset preserve or
   restore the encounter according to the source-owned day-local contract.

The public checkpoint logs `persistence=false`; it uses an isolated in-memory
profile and does not read, delete, or write the normal durable profile.

## Known Limits

This is a technical PASS, not a claim that the encounter is understandable,
interesting, or motivating. The inherited full status panel also remains dense
on mobile; no HUD baseline or presentation change was accepted here. Issue
#1323 remains the required human owner GO/HOLD gate.

## Verification

```powershell
gh run view 31297858844 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha ce6f23f2fd72939de40bfa78c70d7344da00de46 --checkpoint living_expedition_04_start
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_04_journey.gd --review-checkpoint=living_expedition_04_start
python tools/check_file_lengths.py
git diff --check
```
