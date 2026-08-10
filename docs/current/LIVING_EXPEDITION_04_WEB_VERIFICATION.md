# Living Expedition 04 Web Verification

Date: 2026-08-09

Issue: #1322 initial verification; #1335/#1336 HOLD corrections; #1323 closeout

## Result

**FINAL TECHNICAL PASS FOR THE CORRECTED HOLD BUILD.** The public deployment
contains Mica's eel-response retirement and the complete-simulation BOND
tactical pause. This verifies the runtime being closed, not player acceptance
of the rejected prediction experiment.

- exact runtime SHA: `bbcc255fb35339bb62aa5b2626526490b33d596b`
- build version: `bbcc255`
- `git_ref`: `main`
- `dirty`: `false`
- generated timestamp: `2026-08-09T19:57:43-05:00`
- [Web export and Pages run 31345781293](https://github.com/joeypshell/oceangame2/actions/runs/31345781293):
  export browser verification and GitHub Pages deployment passed
- [Godot Smoke run 31345781298](https://github.com/joeypshell/oceangame2/actions/runs/31345781298):
  source/map validation, core runtime, and regional journey jobs passed at the
  same SHA
- [Progression Audit run 31345781382](https://github.com/joeypshell/oceangame2/actions/runs/31345781382):
  passed at the same SHA

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=bbcc255fb35339bb62aa5b2626526490b33d596b`
- Living Expedition 04 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=bbcc255fb35339bb62aa5b2626526490b33d596b&checkpoint=living_expedition_04_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=bbcc255fb35339bb62aa5b2626526490b33d596b&map=production_slice_01`

## Exact Build Evidence

Public `build_info.json` reports the full SHA and clean `main` metadata above.
The independent post-deployment Chromium checker confirmed:

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
- framing mean difference: `1.31`, below the maximum `18`
- no failed requests, page errors, uncaught browser exceptions, Godot
  `SCRIPT ERROR`, or Godot `ERROR:` occurred

Chromium emitted only the accepted WebGL `ReadPixels` performance warning.

## Corrected Runtime Contract

At the exact deployed SHA:

1. Mica is absent from the eel's active response source, command guidance,
   journey evidence, and current focused captures.
2. Mica's moving-ecology `Read Drift` role remains unchanged, and the generic
   source-gated hostile reader remains dormant.
3. Guardian Pulse remains the only active companion response: it creates a
   temporary zero-damage opening without exposing the harvest.
4. Ordinary retreat remains viable; Shock Prod alone damages and defeats the
   eel; only defeat exposes the electrocyte.
5. BOND command selection freezes eel phase/timer/position, player and companion
   positions, oxygen, daylight, moving hazards, and relevant cooldowns while
   keyboard/mobile command input remains active. Closing the palette restores
   simulation, and Retry/debrief/map-change/scene-exit paths release pause.
6. Map, access, cache ownership, reward, profile, and progression behavior are
   unchanged.

The public checkpoint logs `persistence=false`; it uses an isolated in-memory
profile and does not read, delete, or write the normal durable profile.

## Historical Candidate

The initial exact runtime `ce6f23f2fd72939de40bfa78c70d7344da00de46`
passed technical Web verification but is not the final closeout build. It still
contained Mica's rejected eel prediction. The later presentation correction at
`80bdef4a87941afb974e449e1a9b7154efa8ffae` also received owner HOLD. Neither
candidate is an accepted product result.

## Owner Verdict

Automation proves deployment and regression boundaries only. The owner found
the prediction non-useful and rejected it. `LIVING_EXPEDITION_04_CLOSEOUT.md`
records that HOLD and closes the experiment without claiming GO.

## Verification

```powershell
gh run view 31345781293 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha bbcc255fb35339bb62aa5b2626526490b33d596b --checkpoint living_expedition_04_start
python tools/check_file_lengths.py
git diff --check
```
