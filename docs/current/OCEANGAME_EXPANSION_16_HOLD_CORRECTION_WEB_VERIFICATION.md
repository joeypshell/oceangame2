# Expansion 16 Owner-HOLD Correction Web Verification

Date: 2026-07-28

Issue: #1146

## Result

**PASS for exact deployment, browser initialization, responsive framing, and
the isolated Expansion 16 checkpoint.** The verified correction candidate is:

- exact SHA: `8fd86674b0de8664944b6f9a4731fa1fcb49ec2b`
- build version: `8fd8667`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Smoke run 30415676731](https://github.com/joeypshell/oceangame2/actions/runs/30415676731):
  exact-SHA source/map, core runtime, and regional journey jobs passed
- [Progression Audit run 30415038053](https://github.com/joeypshell/oceangame2/actions/runs/30415038053):
  exact-SHA progression fixtures and source graph passed
- [Godot Web Export run 30415131648](https://github.com/joeypshell/oceangame2/actions/runs/30415131648):
  exact-SHA export browser check and GitHub Pages deployment passed

The visual-acceptance merge changed only documentation and baseline evidence,
so the path-filtered Web and Godot Smoke workflows were dispatched manually on
current `main`. The existing Progression Audit ran automatically on the merge.

## Public URLs

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=8fd86674b0de8664944b6f9a4731fa1fcb49ec2b`
- focused Expansion 16 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=8fd86674b0de8664944b6f9a4731fa1fcb49ec2b&checkpoint=expansion_16_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=8fd86674b0de8664944b6f9a4731fa1fcb49ec2b&map=production_slice_01`

## Public Browser Evidence

The repository checker confirmed:

- root continuing play, fresh isolated review, retained checkpoint fallback,
  and explicit slice-01 fallback initialize without failed requests
- root/review load `production_level_01`; explicit fallback loads
  `production_slice_01`
- desktop canvas: 1280x720
- wide canvas: 1920x1080
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` with zero visual-viewport offset
- touch differences are `8.60` move-down, `4.91` oxygen, `5.60` build, and
  `5.10` use, all above the required `2`
- framing mean difference is `3.55`, below the maximum `18`
- no failed requests, browser-console errors, Godot `SCRIPT ERROR`, or Godot
  `ERROR:` occurred

Chromium emitted only accepted WebGL `ReadPixels` performance warnings.

## Expansion 16 Checkpoint

A separate browser probe opened `expansion_16_start` at desktop 1280x720 and
touch-emulated iPhone landscape 844x390. Both runs reported:

```text
Review checkpoint active: id=expansion_16_start persistence=false propulsion_fins=true.
Web map active: map=production_level_01 review=true.
```

The desktop frame shows the source-owned
`Far-west wreck | Follow cyan relay beacons west` cue and the fixed five-cell
`GEAR` surface. The mobile frame keeps the compact cargo/gear surface, bottom
active-tool hotbar, movement control, and command controls within the playable
canvas without overlap. The accepted focused warning/protected captures and
exact-SHA Expansion 16 journey smoke cover the amber threshold,
`Confined wreck air | Oxygen x8`, and active-rebreather states reached later
in the route.

## Stable Areas

No deployment drift was found in default full-level selection, explicit
slice-01 fallback, terrain, collision-facing edges, camera framing, player,
boat entry, desktop/wide presentation, landscape-mobile canvas placement,
touch alignment, or isolated-profile behavior.

No gameplay, map source, topology, asset, workflow, accepted baseline, or
generated capture changed in this issue.

## Owner Re-Test

Issue #1133 remains open for the real GO/HOLD decision:

1. Open the focused checkpoint URL above.
2. Follow the source-owned far-west cue and cyan relay beacons.
3. At the amber threshold, confirm the unprotected x8 oxygen warning is clear.
4. Return to the boat, enter night, and build the rebreather from the banked
   Ti1 + Rubber1 + Coil1 + Gel1 recipe.
5. Repeat the route; confirm `Rebreather active` and the highlighted
   rebreather gear state make the protection legible.
6. Cut, scan, and return the recorder discovery to the canonical boat.
7. Decide whether the scout, recipe, return, tool sequence, and payoff make
   the remembered wreck worth revisiting.

This technical PASS does not declare player GO or select Expansion 17.
#52/#53 remain deferred optional slice-03 polish.

## Verification

```powershell
gh run view 30415676731 --repo joeypshell/oceangame2
gh run view 30415038053 --repo joeypshell/oceangame2
gh run view 30415131648 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 8fd86674b0de8664944b6f9a4731fa1fcb49ec2b
python tools/check_file_lengths.py
git diff --check
```
