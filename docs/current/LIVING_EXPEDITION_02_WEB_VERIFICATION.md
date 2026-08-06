# Living Expedition 02 Web Verification

Date: 2026-08-05

Issue: #1261 `Verify Living Expedition 02 exact Web build and review checkpoint`

## Result

**PASS for exact deployment, isolated checkpoint startup, responsive framing,
mobile control dispatch, and the deterministic two-companion journey.**

- exact runtime SHA: `b639dcfeb2e65f8b6e99412b6649c898f8cdd945`
- build version: `b639dcf`
- `git_ref`: `main`
- `dirty`: `false`
- [Web export and Pages run 31087298550](https://github.com/joeypshell/oceangame2/actions/runs/31087298550):
  export browser verification and GitHub Pages deployment passed
- [PR #1271](https://github.com/joeypshell/oceangame2/pull/1271):
  the current checkpoint default and complete mobile-control probe landed

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=b639dcfeb2e65f8b6e99412b6649c898f8cdd945`
- Living Expedition 02 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=b639dcfeb2e65f8b6e99412b6649c898f8cdd945&checkpoint=living_expedition_02_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=b639dcfeb2e65f8b6e99412b6649c898f8cdd945&map=production_slice_01`

## Exact Build Evidence

Public `build_info.json` reports the full SHA above, clean `main`, and generated
timestamp `2026-08-06T04:02:09-05:00`. The independent post-deployment checker
confirmed:

- root and fresh review load `production_level_01`
- `living_expedition_02_start` loads an isolated profile on
  `production_level_01` with propulsion fins available
- the explicit fallback loads `production_slice_01`
- desktop canvas: 1280x720
- wide canvas: 1920x1080
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` with zero visual-viewport offset
- checkpoint touch differences: move-down `12.95`, oxygen `4.91`, cargo
  `5.50`, TOOL `5.52`, project `5.60`, day `5.40`, RESET `5.83`, ACT `5.17`,
  USE `5.10`, and BOND `5.82`, all above the required `2`
- root touch differences: move-down `8.60`; all command values match the
  checkpoint values and pass
- framing mean difference: `1.33`, below the maximum `18`
- no failed requests, page errors, uncaught browser exceptions, Godot
  `SCRIPT ERROR`, or Godot `ERROR:` occurred

Chromium emitted only the accepted WebGL `ReadPixels` performance warning.

## Checkpoint And Journey

The exact public checkpoint reports:

```text
Review checkpoint active: id=living_expedition_02_start persistence=false propulsion_fins=true.
Web map active: map=production_level_01 review=true.
```

It starts at the canonical boat with Kite committed and selected, Mica
unrescued, prior required progression complete, and empty cargo. It neither
reads nor mutates the normal durable profile.

The merged deterministic Living Expedition 02 journey provides the semantic
control evidence that the browser alignment probe intentionally does not fake:

1. Mica can be rescued, committed at the canonical boat, selected, confirmed,
   and launched as the one active companion.
2. Reveal Trace exposes only optional source-authored ecological evidence;
   Scanner identification grants no cargo, reward, or access bypass.
3. Hazard, oxygen, health, and manual-reset paths preserve the reviewed
   commitment and selection contract.
4. Returning to the habitat and selecting Kite restores Kite's mounted role
   and creature-action ownership.
5. Reload preserves both committed companions and the selected active
   companion while protected equipment gates remain authoritative.

The focused desktop/mobile capture set and its renderer bounds checks remain
recorded in `LIVING_EXPEDITION_02_VISUAL_DECISION.md`.

## Stable Areas

No drift was found in the public default map, explicit slice fallback,
desktop/wide framing, iPhone-landscape canvas placement, touch alignment,
isolated profile behavior, or named checkpoint selection. No runtime, map,
topology, asset, accepted baseline, generated capture, or export-workflow
change was made while recording this evidence.

This technical PASS did not by itself answer whether two recognizable partners
create a meaningful choice, attachment, or another-day motivation. The owner
subsequently supplied GO in #1262; `LIVING_EXPEDITION_02_CLOSEOUT.md` records
that player-experience decision.

## Verification

```powershell
gh run view 31087298550 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha b639dcfeb2e65f8b6e99412b6649c898f8cdd945
python tools/check_file_lengths.py
git diff --check
```
