# OceanGame Expansion 17 Web Preview Verification

Date: 2026-08-01

Issue: #1166 `Verify exact public Web preview for Expansion 17`

## Result

**PASS for exact deployment, browser initialization, responsive framing, and
the isolated Expansion 17 checkpoint.** The verified candidate is:

- exact SHA: `9de14371c061b5dcc6283f07f8df848ddb4b8227`
- build version: `9de1437`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Smoke run 30724423196](https://github.com/joeypshell/oceangame2/actions/runs/30724423196):
  source/map validation, core runtime, and regional journey jobs passed
- [Progression Audit run 30724423184](https://github.com/joeypshell/oceangame2/actions/runs/30724423184):
  focused fixtures and source-derived progression graph passed
- [Godot Web Export run 30724423177](https://github.com/joeypshell/oceangame2/actions/runs/30724423177):
  export browser check and GitHub Pages deployment passed

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=9de14371c061b5dcc6283f07f8df848ddb4b8227`
- focused Expansion 17 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=9de14371c061b5dcc6283f07f8df848ddb4b8227&checkpoint=expansion_17_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=9de14371c061b5dcc6283f07f8df848ddb4b8227&map=production_slice_01`

## Bounded Correction

Initial verification of pre-correction SHA `051efd3` found that the source/state
contract named `expansion_17_start`, but the runtime still rejected that id to
a fresh profile. Verification was held rather than recording a partial pass.

#1178 / PR #1179 added the missing isolated checkpoint and deterministic
boundary coverage without changing map source, progression rules, visuals, or
the accepted baseline. This document records only the corrected deployed SHA.

## Public Browser Evidence

The repository checker confirmed:

- public `build_info.json` reports the exact full candidate SHA
- root continuing play, fresh isolated review, retained Expansion 14
  checkpoint, and explicit slice-01 fallback initialize
- root/review load `production_level_01`; explicit fallback loads
  `production_slice_01`
- desktop canvas: 1280x720
- wide canvas: 1920x1080
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` with zero visual-viewport offset
- mobile touch differences are `8.60` for move-down, `4.91` for oxygen,
  `5.60` for build/project, and `5.10` for use, all above the required `2`
- framing mean difference is `1.31`, below the maximum `18`
- no failed requests, browser-console errors, Godot `SCRIPT ERROR`, or Godot
  `ERROR:` occurred

Chromium emitted only the accepted WebGL `ReadPixels` performance warnings.

## Expansion 17 Checkpoint

A separate public Playwright probe opened `expansion_17_start` at desktop
1280x720 and touch-emulated iPhone landscape 844x390. Both runs reported:

```text
Review checkpoint active: id=expansion_17_start persistence=false propulsion_fins=true.
Web map active: map=production_level_01 review=true.
```

Both canvases initialized at the expected dimensions with zero failed
requests, page errors, or fatal console lines. The checkpoint starts at the
canonical boat with prior equipment and the far-west discovery committed,
while both relay fragments and final triangulation remain unresolved.

Desktop `N` and the rendered mobile `DAY` touch control both opened the night
planning surface. Visual inspection confirmed that Western Chasm Relay and
Abyssal Shelf Relay are simultaneously visible, ready, and identified as
distinct Stabilizer and Pressure-suit routes. The planning panel, cargo/gear
surface, active-tool hotbar, movement control, and command controls remain
visible and non-overlapping at both review sizes.

The checkpoint does not read or mutate the normal durable profile.

## Stable Areas

No deployment drift was found in default full-level selection, explicit
slice-01 fallback, terrain, collision-facing edges, camera framing, player,
boat entry, desktop/wide presentation, landscape-mobile canvas placement,
touch alignment, or isolated-profile behavior.

No gameplay rule, map source, topology, asset, workflow, accepted baseline,
generated capture, or generated Web export changed in this verification issue.

## Owner Review Path

Issue #1167 remains open for the real GO/HOLD decision. From the focused URL:

1. At the boat, enter night with `N` or `DAY`; confirm both relay leads are
   understandable and that pinning one does not disable the other.
2. Start the day and follow either the Western Chasm or Abyssal Shelf lead.
3. Face and hold Scanner on the physical artifact, then return its pending
   fragment to the canonical boat.
4. Follow the remaining lead and commit its fragment at the boat.
5. Enter night and explicitly triangulate the completed network.
6. Decide whether the two-place investigation feels connected and creates a
   reason to plan another expedition.

This technical PASS does not declare the player journey GO.

## Verification

```powershell
gh run view 30724423196 --repo joeypshell/oceangame2
gh run view 30724423184 --repo joeypshell/oceangame2
gh run view 30724423177 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 9de14371c061b5dcc6283f07f8df848ddb4b8227
python tools/check_file_lengths.py
git diff --check
```
