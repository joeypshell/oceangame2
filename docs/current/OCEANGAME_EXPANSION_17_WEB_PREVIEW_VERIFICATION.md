# OceanGame Expansion 17 Web Preview Verification

Date: 2026-08-02

Issue: #1184 `Verify Expansion 17 owner-HOLD clarity corrections`

## Result

**PASS for the corrected exact deployment, browser initialization, responsive
framing, mobile controls, and isolated Expansion 17 checkpoint.**

- exact SHA: `075a450d8751fae73ba796a6fdb001a9ce4e5281`
- build version: `075a450`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Smoke run 30756224775](https://github.com/joeypshell/oceangame2/actions/runs/30756224775):
  source/map validation, core runtime, and regional journey jobs passed
- [Progression Audit run 30756224768](https://github.com/joeypshell/oceangame2/actions/runs/30756224768):
  focused fixtures and source-derived progression graph passed
- [Godot Web Export run 30756224777](https://github.com/joeypshell/oceangame2/actions/runs/30756224777):
  export browser check and GitHub Pages deployment passed

Public URLs:

- root: `https://joeypshell.github.io/oceangame2/`
- fresh isolated review:
  `https://joeypshell.github.io/oceangame2/?review=075a450d8751fae73ba796a6fdb001a9ce4e5281`
- focused Expansion 17 checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=075a450d8751fae73ba796a6fdb001a9ce4e5281&checkpoint=expansion_17_start`
- explicit slice fallback:
  `https://joeypshell.github.io/oceangame2/?review=075a450d8751fae73ba796a6fdb001a9ce4e5281&map=production_slice_01`

## Owner-HOLD Corrections

This verification supersedes the pre-HOLD player path recorded for
`9de1437`:

- #1181 moved desktop active-tool use from `Q` to physical/logical `Space`;
  mobile `USE` retains the same action
- #1182 replaced generic relay presentation with named current-scoured and
  pressure-crushed coordinate transponders
- #1183 made the two-half comparison an automatic exact-once night payoff,
  removing the separate triangulation command

No score, material, recipe, capability, terrain, transition, teleport, or
reward changed.

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
- framing mean difference is `1.34`, below the maximum `18`
- no failed requests, page errors, browser-console failures, Godot
  `SCRIPT ERROR`, or Godot `ERROR:` occurred

Chromium emitted only the accepted WebGL `ReadPixels` performance warnings.

## Expansion 17 Checkpoint

A separate public Playwright probe opened `expansion_17_start` at desktop
1280x720 and touch-emulated iPhone landscape 844x390. Both reported:

```text
Review checkpoint active: id=expansion_17_start persistence=false propulsion_fins=true.
Web map active: map=production_level_01 review=true.
```

Desktop `N` and the rendered mobile `DAY` touch control opened the same night
planning state. Visual inspection confirmed:

- the recorder causally explains the two coordinate halves
- both named transponder leads are visible, ready, and distinguishable
- Western Chasm names the Stabilizer route and west half
- Abyssal Shelf names the Pressure-suit route and east half
- cargo, gear, active tools, movement, and command controls remain readable

The checkpoint does not read or mutate the normal durable profile.

## Stable Areas

No deployment drift was found in map selection, terrain, collision-facing
edges, camera framing, player, boat, routes, desktop/wide presentation,
landscape-mobile canvas placement, touch alignment, or isolated-profile
behavior. The regenerated normal full-level images are pixel-identical to the
accepted baseline, and slices 01-04 remain clean.

## Owner Re-Test

Issue #1167 remains open for the real GO/HOLD decision:

1. Open the focused checkpoint URL and enter night with `N` or `DAY`.
2. Confirm the recorder's two-coordinate-half explanation gives both leads a
   reason to exist.
3. Pin either lead, start the day, and travel to its named transponder.
4. Select Scanner, face the artifact, and hold `Space/USE` or mobile `USE`.
5. Return the pending coordinate half to the boat and confirm the other
   transponder is named.
6. Repeat the remaining route; entering night should automatically report
   recovered transfer-hub coordinates without another command.
7. Decide whether the two-place investigation now feels connected enough to
   justify another expedition.

This technical PASS does not declare the player journey GO and does not select
Expansion 18.

## Verification

```powershell
gh run view 30756224775 --repo joeypshell/oceangame2
gh run view 30756224768 --repo joeypshell/oceangame2
gh run view 30756224777 --repo joeypshell/oceangame2
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 075a450d8751fae73ba796a6fdb001a9ce4e5281
python tools/check_file_lengths.py
git diff --check
```
