# OceanGame Expansion 14 Web Preview Verification

Date: 2026-07-19

Issues: #1039 `Verify the exact Expansion 14 public Web candidate`, #1057 `Verify Expansion 14 checkpoint Web review path`

## Current Checkpoint Result

**PASS for exact deployment and focused review startup. Player GO remains open
in #1040.** The current public build is:

- exact SHA: `626ab23a4d38cc44d17d7c136311a1308ea2ebd3`
- build version: `626ab23`
- [Godot Web Export run 29693647371](https://github.com/joeypshell/oceangame2/actions/runs/29693647371): success, including Pages deploy and checkpoint-aware browser verification
- checkpoint URL:
  `https://joeypshell.github.io/oceangame2/?review=626ab23a4d38cc44d17d7c136311a1308ea2ebd3&checkpoint=expansion_14_start`

The named checkpoint starts from an isolated in-memory profile after the
southeast archive commit. Earlier projects are complete, Ti2 + Coil1 is
banked, and the Current Stabilizer, advanced-current crossing, relay core, and
relay survey remain incomplete. It changes no normal save or default launch.

The independent public checker confirmed the checkpoint marker and
`production_level_01`, the empty fresh-profile path, retained slice-01
fallback, 1280x720 and 1920x1080 framing, iPhone-landscape touch alignment,
matching build metadata, no failed requests, and no Godot error output.

## Original Candidate Result

**PASS for technical deployment. Player GO remains open in #1040.** The public
GitHub Pages preview serves the post-baseline Expansion 14 candidate at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- exact SHA: `739ffd59fa37d40c9dc1d909facc5de17a3c05dd`
- build version: `739ffd5`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Web Export run 29658558080](https://github.com/joeypshell/oceangame2/actions/runs/29658558080): success, including Pages deploy
- fresh player-review URL:
  `https://joeypshell.github.io/oceangame2/?review=739ffd59fa37d40c9dc1d909facc5de17a3c05dd`

The #1038 merge changed only visual-baseline and documentation paths, so the
path-filtered workflow was manually dispatched on `main`. Its artifact and the
public metadata both identify the exact merge SHA rather than the earlier
runtime-source deployment.

## Browser Evidence

`tools/check_web_preview.cjs` independently verified the deployed Pages site:

- root and fresh-review URLs initialize `production_level_01`
- explicit review fallback initializes `production_slice_01`
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at
  `(0, 0)` over an 844x390 visual viewport with zero offset
- touch probes: move-down `8.60`, oxygen `4.91`, project `5.60`, use `5.10`;
  all exceed the required `2`
- framing mean difference: `1.37`, below the maximum `18`
- no failed requests, missing resources, `SCRIPT ERROR`, or Godot `ERROR:`
  output

Independent desktop inspection showed build `739ffd5`, the fresh isolated
profile marker, full-level boat entry, held-cargo strip, and separate active
tool panel without overlap. The exact workflow's touch-enabled mobile artifact
shows the canvas top anchored and MOVE/O2/BAG/TOOL/BUILD/DAY/RESET/ACT/USE
controls reachable without covering the cargo or tool panels.

Chromium emitted only the allowed software-WebGL fallback and `ReadPixels`
performance warnings. They did not affect initialization, input, framing, or
network checks.

## Journey Boundary

The deployed candidate contains runtime source commit
`00980855b4dfb3defd79b488592ee610f189f667`; #1038 added no gameplay, map,
asset, or workflow change after it. Focused desktop/mobile evidence from that
source confirms the blocked current, stabilizer promise, enabled crossing,
Northwest Wreck Relay and core, mixed cargo strip, 50% scanner survey, pending
boat return, and archive result.

The public query contract deliberately supports fresh profiles and map choice,
not profile-state injection or capture flags. Browser automation therefore
proves exact deployment, startup, HUD separation, and touch behavior but does
not skip directly to the relay. The live current-to-relay journey remains the
owner GO/HOLD gate in #1040.

## Verification

```powershell
gh workflow run godot-web-export.yml --repo joeypshell/oceangame2 --ref main
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 626ab23a4d38cc44d17d7c136311a1308ea2ebd3
python tools/check_file_lengths.py
git diff --check
```
