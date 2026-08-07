# Living Expedition 03 Web Verification

Date: 2026-08-06

Issue: #1284 `Verify Living Expedition 03 exact Web build and review checkpoint`

## Result

**PASS for exact deployment, isolated checkpoint startup, responsive framing,
mobile control dispatch, and the deterministic Mica ecology journey.**

- exact runtime SHA: `61b474520684752976822ad353cdfa1c68ac521c`
- build version: `61b4745`
- `git_ref`: `main`
- `dirty`: `false`
- generated UTC: `2026-08-06T21:02:19-05:00`
- [Web export and Pages run 31139903274](https://github.com/joeypshell/oceangame2/actions/runs/31139903274):
  export browser verification and GitHub Pages deployment passed
- [PR #1293](https://github.com/joeypshell/oceangame2/pull/1293):
  focused visual evidence and the current checkpoint capture surface

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=61b474520684752976822ad353cdfa1c68ac521c`
- Living Expedition 03 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=61b474520684752976822ad353cdfa1c68ac521c&checkpoint=living_expedition_03_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=61b474520684752976822ad353cdfa1c68ac521c&map=production_slice_01`

## Exact Build Evidence

Public `build_info.json` reports the full SHA above, clean `main`, and the
generated timestamp above. The independent post-deployment checker confirmed:

- root and fresh review load `production_level_01`
- `living_expedition_03_start` loads an isolated profile on
  `production_level_01` with propulsion fins available
- the explicit fallback loads `production_slice_01`
- desktop canvas: 1280x720
- wide canvas: 1920x1080
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` with zero visual-viewport offset
- checkpoint touch differences: move-down `14.40`, oxygen `4.91`, cargo
  `5.50`, TOOL `5.52`, project `5.60`, day `5.40`, RESET `5.83`, ACT `5.17`,
  USE `5.10`, and BOND `5.82`, all above the required `2`
- root touch differences: move-down `8.60`; all command values match the
  checkpoint values and pass
- framing mean difference: `1.30`, below the maximum `18`
- no failed requests, page errors, uncaught browser exceptions, Godot
  `SCRIPT ERROR`, or Godot `ERROR:` occurred

Chromium emitted only the accepted WebGL `ReadPixels` performance warning.

## Checkpoint And Journey

The exact public checkpoint reports:

```text
Review checkpoint active: id=living_expedition_03_start persistence=false propulsion_fins=true.
Web map active: map=production_level_01 review=true.
```

It starts on Day 2 with Kite and Mica committed, Mica selected, Scanner and
required prior progression available, and normal durable profile persistence
disabled.

The deterministic integration smoke provides the semantic journey evidence
that the browser alignment probe intentionally does not fake:

1. Mica reacts to the active southwest bloom before revealing its migration.
2. Reveal Trace exposes linked evidence but does not identify it; the held
   Scanner completes the 1.5-second identification.
3. Oxygen, daylight, and moving-hazard pressure continue while the observation
   grants no reward, cargo, access, or progression.
4. Failure clears only uncommitted observation state; canonical-boat return
   commits `Followed the Bloom` exactly once.
5. Night deliberately consolidates Drift Lens, and reload preserves it.
6. Read Drift projects both conditional and unconditional patrol direction
   without mutating the hazards; Kite selection, riding, and actions remain
   unchanged.

The focused desktop/mobile evidence and accepted-baseline comparisons remain
recorded in `LIVING_EXPEDITION_03_VISUAL_DECISION.md`.

## Stable Areas

No drift was found in the public default map, explicit slice fallback,
desktop/wide framing, iPhone-landscape placement, touch alignment, isolated
profile behavior, or named checkpoint selection. No runtime, map, topology,
asset, accepted baseline, generated capture, or export-workflow change was made
while recording this evidence.

This technical PASS does not answer whether the living observation is
motivating, whether the Mica/Scanner handoff is intuitive to a player, or
whether Drift Lens creates another-day desire. Issue #1285 owns that human
GO/HOLD decision.

## Verification

```powershell
gh run view 31139903274 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 61b474520684752976822ad353cdfa1c68ac521c --checkpoint living_expedition_03_start
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_03_integration.gd
python tools/check_file_lengths.py
git diff --check
```
