# OceanGame Expansion 15 Web Preview Verification

Date: 2026-07-27

Issue: #1103 `Verify the exact Expansion 15 public Web candidate`

Final update: 2026-07-28

## Final Owner Candidate

The initial #1103 candidate below passed its technical gate. Owner review then
produced bounded corrections #1117 and #1119 for build-input feedback and
choice clarity. The final accepted public candidate is:

- exact SHA: `23f4172a9cb169273c129a3ccf1ceb8aeb00a06f`
- build version: `23f4172`
- [Godot Web Export run 30283772918](https://github.com/joeypshell/oceangame2/actions/runs/30283772918):
  success, including GitHub Pages deployment
- focused checkpoint:
  `https://joeypshell.github.io/oceangame2/?review=23f4172a9cb169273c129a3ccf1ceb8aeb00a06f&checkpoint=expansion_14_start`

The independent public checker matched the exact final SHA, initialized root,
fresh-review, checkpoint, and reference-slice modes, verified desktop, wide,
and iPhone-landscape framing plus touch alignment, and reported no Godot,
script, resource, request, or browser-console errors. The owner reviewed that
candidate and gave GO in #1104.

## Result

**PASS for the initial exact deployment, focused browser controls, and
responsive framing.** The originally verified #1103 candidate is:

- exact SHA: `28752d7c7cca4d0eecaac9e0b679072428abda07`
- build version: `28752d7`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Web Export run 30264984855](https://github.com/joeypshell/oceangame2/actions/runs/30264984855):
  success, including GitHub Pages deployment
- root URL: `https://joeypshell.github.io/oceangame2/`
- fresh review URL:
  `https://joeypshell.github.io/oceangame2/?review=28752d7c7cca4d0eecaac9e0b679072428abda07`
- focused checkpoint URL:
  `https://joeypshell.github.io/oceangame2/?review=28752d7c7cca4d0eecaac9e0b679072428abda07&checkpoint=expansion_14_start`

The #1102 merge changed documentation and visual-review evidence only, so the
path-filtered Web workflow was dispatched manually on current `main`.

## Public Browser Evidence

`tools/check_web_preview.cjs` confirmed:

- public `build_info.json` reports the exact full candidate SHA
- root continuing-play and fresh isolated-review launches remain distinct
- root and fresh review initialize `production_level_01`
- explicit slice fallback still initializes `production_slice_01`
- the checkpoint logs
  `Review checkpoint active: id=expansion_14_start persistence=false`
- desktop canvas: 1280x720
- wide canvas: 1920x1080
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` with zero visual-viewport offset
- mobile touch probes remain aligned: move-down `8.60`, oxygen `4.91`,
  project `5.60`, and use `5.10`, all above the required `2`
- framing mean difference is `1.32`, below the maximum `18`
- all required resources load without failed requests
- no browser console error, Godot `SCRIPT ERROR`, or Godot `ERROR:` occurs

Chromium emitted only the accepted software-WebGL and `ReadPixels`
performance warnings during automated checking. The interactive browser pass
reported no warnings or errors.

## Focused Interaction

The existing `expansion_14_start` checkpoint is the correct Expansion 15
decision boundary: it starts at the boat with an isolated profile, prior
projects complete, Ti2 + Coil1 ready, the Current Stabilizer unbuilt, and the
relay unresolved. No additional checkpoint or profile migration is needed.

Interactive verification on the deployed candidate confirmed:

1. `N/DAY` ends day 1 at the boat and opens the night planner.
2. Northwest Wreck Relay and Southwest Jellyfish Bloom both appear with
   distinct readiness and route text.
3. `Tab/TOOL` changes the highlighted choice and `E/ACT` pins it.
4. The bloom choice starts day 2 with compact southwest migration-lane
   guidance and no persistent planner panel.
5. A fresh isolated reload can pin the relay choice.
6. `P/BUILD` consumes Ti2 + Coil1, installs the Current Stabilizer, and updates
   relay readiness to `Required equipment installed`.
7. `N/DAY` starts day 2 with compact
   `Plan: Follow the archive signal northwest` guidance.

These checks exercise only isolated review state. Normal root profile state is
not reset or contaminated.

## Scope

This verification changes no gameplay, map source, topology, assets, profile
schema, accepted baselines, workflow, or generated capture. Owner experience
review and milestone closeout completed through #1104.

## Verification

```powershell
gh workflow run godot-web-export.yml --repo joeypshell/oceangame2 --ref main
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 28752d7c7cca4d0eecaac9e0b679072428abda07
python tools/check_file_lengths.py
git diff --check
```
