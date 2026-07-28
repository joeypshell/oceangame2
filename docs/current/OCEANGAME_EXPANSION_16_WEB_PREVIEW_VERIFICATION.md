# OceanGame Expansion 16 Web Preview Verification

Date: 2026-07-28

Issue: #1132 `Verify the exact Expansion 16 public Web candidate`

## Result

**PASS for exact deployment, browser initialization, responsive framing, and
the isolated Expansion 16 checkpoint.** The verified candidate is:

- exact SHA: `cacef6ae74d163e71eab3ad921b74f62d176f37e`
- build version: `cacef6a`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Smoke run 30335287485](https://github.com/joeypshell/oceangame2/actions/runs/30335287485):
  success across source/map validation, core runtime, and regional journey jobs
- [Progression Audit run 30335287475](https://github.com/joeypshell/oceangame2/actions/runs/30335287475):
  success
- [Godot Web Export run 30335489941](https://github.com/joeypshell/oceangame2/actions/runs/30335489941):
  success, including the export browser check and GitHub Pages deployment

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=cacef6ae74d163e71eab3ad921b74f62d176f37e`
- focused Expansion 16 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=cacef6ae74d163e71eab3ad921b74f62d176f37e&checkpoint=expansion_16_start`

The accepted visual-review merge touched documentation and baseline evidence,
so the path-filtered Web workflow was dispatched manually on current `main`.

## Public Browser Evidence

The independent public checker confirmed:

- public `build_info.json` reports the exact full candidate SHA
- root continuing play, fresh isolated review, the retained Expansion 14
  checkpoint, and explicit slice-01 fallback all initialize
- root and map-unspecified review load `production_level_01`
- explicit slice fallback loads `production_slice_01`
- desktop canvas: 1280x720
- wide canvas: 1920x1080
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` with zero visual-viewport offset
- mobile touch differences are `8.60` for move-down, `4.91` for oxygen,
  `5.60` for build/project, and `5.10` for use, all above the required `2`
- framing mean difference is `1.31`, below the maximum `18`
- no failed requests, browser-console errors, Godot `SCRIPT ERROR`, or Godot
  `ERROR:` occurred

Chromium emitted only the accepted software-WebGL and `ReadPixels`
performance warnings.

## Expansion 16 Checkpoint

A separate Playwright probe opened the focused checkpoint at desktop 1280x720
and iPhone-landscape 844x390. Both runs reported:

```text
Review checkpoint active: id=expansion_16_start persistence=false propulsion_fins=true.
Web map active: map=production_level_01 review=true.
```

Both canvases initialized at the expected dimensions with zero failed requests
and zero script/resource errors. Visual inspection found no new checkpoint
overlap: desktop HUD/tools remain clear, and mobile movement, action buttons,
and the bottom hotbar remain visible and reachable.

The checkpoint starts at the canonical boat with prior required tools and
discoveries complete, the exact Ti1 + Rubber1 + Coil1 + Gel1 recipe banked,
and the closed-circuit rebreather, far-west recorder, and discovery unresolved.
It does not read or mutate the normal durable profile.

## Stable Areas

This verification found no deployment drift in:

- default full-level and explicit slice-01 map selection
- terrain, collision-facing edges, camera framing, player, or boat entry
- existing desktop/wide layout
- iPhone-landscape canvas position, touch alignment, and controls
- ordinary root profile and fresh isolated-review separation

No gameplay, map source, topology, asset, workflow, accepted baseline, or
generated capture changed in this issue.

## Owner Review Path

Issue #1133 remains open for the real GO/HOLD decision. From the focused URL:

1. Scout the far-west wreck threshold without the rebreather; confirm the
   oxygen warning makes retreat necessary but understandable.
2. Return to the boat, enter night, and build the closed-circuit rebreather
   from Ti1 + Rubber1 + Coil1 + Gel1.
3. Start the next day and follow the same continuous west route; confirm the
   confined-wreck oxygen pressure is now manageable.
4. At the recorder, select Cutter with `Tab/TOOL`, use it with `Q/USE`, then
   select Scanner and hold `Q/USE` through the survey.
5. Return to the canonical boat and confirm the pending discovery commits once.
6. Decide whether the scout, recipe, return, tool sequence, and boat payoff make
   this remembered place worth revisiting.

This technical PASS does not declare the player journey GO.

## Verification

```powershell
gh run view 30335287485 --repo joeypshell/oceangame2
gh run view 30335287475 --repo joeypshell/oceangame2
gh run view 30335489941 --repo joeypshell/oceangame2
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha cacef6ae74d163e71eab3ad921b74f62d176f37e
python tools/check_file_lengths.py
git diff --check
```
