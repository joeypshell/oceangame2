# OceanGame Expansion 12 Web Preview Verification

Date: 2026-07-15

Issue: #940 `Verify the exact Expansion 12 public Web release candidate`

## Player-Hold Correction Deployment

**PASS for technical deployment. Player GO remains open in #941.** Feedback on
the original release candidate identified two bounded scanner-flow defects:

- [#951](https://github.com/joeypshell/oceangame2/issues/951) made `Q/SCAN`
  explicitly activate a nearby survey. Proximity alone no longer advances it,
  and leaving range disarms the interaction.
- [#952](https://github.com/joeypshell/oceangame2/issues/952) keeps scanner
  guidance and progress visible at full cargo and explains that a pending
  result must be returned to the surface boat before another scan.

Corrected deployment:

- exact SHA: `d864a9ed744bbeb2e72e4b1d72bc1112069fdad6`
- build version: `d864a9e`
- [PR #954](https://github.com/joeypshell/oceangame2/pull/954): explicit
  scanner activation
- [PR #955](https://github.com/joeypshell/oceangame2/pull/955): full-cargo and
  pending-return feedback
- [Godot Web Export run 29461275873](https://github.com/joeypshell/oceangame2/actions/runs/29461275873): success, including Pages deploy
- [Godot Smoke run 29461276679](https://github.com/joeypshell/oceangame2/actions/runs/29461276679): success
- [Progression Audit run 29461275882](https://github.com/joeypshell/oceangame2/actions/runs/29461275882): success
- fresh correction review URL:
  `https://joeypshell.github.io/oceangame2/?review=d864a9ed744bbeb2e72e4b1d72bc1112069fdad6`

The focused anomaly-survey journey reports
`explicit_q=true full_cargo_scan=true pending_boat_guidance=true`. It verifies
that no progress occurs before `Q/SCAN`, a survey can start and complete while
cargo remains full, and a second target gives explicit boat-return guidance
while one result is pending. The existing one-pending-result and exact-once
boat-commit rules remain unchanged.

Fresh ignored review captures at desktop and mobile sizes verified the 50%
abyssal survey state and the visible text `Abyssal chart pending | Return to
surface boat before another scan`. No map source, accepted baseline, or
generated capture was committed.

The public Web checker matched the exact corrected SHA, initialized the root,
fresh-review, and slice-fallback URLs, passed desktop/wide/mobile framing and
touch probes, and reported no failed requests, missing assets, `SCRIPT ERROR`,
or Godot `ERROR:` output. A separate live browser inspection showed build
`d864a9e`, the isolated fresh profile, and the contiguous full level with a
clean console.

These checks prove the corrected runtime is deployed. They do not replace the
player journey in #941, which remains the only Expansion 12 GO/HOLD gate.

## Original Release Result

**PASS.** The public GitHub Pages preview serves the reviewed Expansion 12
release candidate at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- exact SHA: `84fb81fbdaac2d6e9a3066f68fc1393470d496e8`
- build version: `84fb81f`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Web Export run 29425789679](https://github.com/joeypshell/oceangame2/actions/runs/29425789679): success, including Pages deploy
- fresh review URL:
  `https://joeypshell.github.io/oceangame2/?review=84fb81fbdaac2d6e9a3066f68fc1393470d496e8`

The accepted-baseline merge changed only path-filtered visual baseline and
documentation files, so it did not start a Web export automatically. The
existing workflow was manually dispatched on `main` and built the exact SHA
above without changing workflow configuration.

## Browser Evidence

`tools/check_web_preview.cjs` verified:

- root and fresh-review URLs load `production_level_01`
- explicit review fallback loads `production_slice_01`
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at `(0, 0)`
- mobile visual viewport: 844x390 with zero offset
- touch probes: move-down `8.60`, oxygen `4.91`, project `5.60`, attack `4.93`; all exceed the required `2`
- framing mean difference: `1.29`, below the maximum `18`
- no failed requests, missing assets, `SCRIPT ERROR`, or Godot `ERROR:` output

The fresh-review marker reports `persistence=false` and
`propulsion_fins=false`. A separate live in-app browser inspection showed the
full-level map, fresh-profile HUD, player, boat, terrain, and salvage rendering
at the exact build version. The live browser console contained no warnings or
errors.

Chromium emitted only the allowed software-WebGL fallback and `ReadPixels`
performance warnings during the automated checker. They did not affect
initialization, input, framing, or requests.

## Journey Evidence

The exact release candidate includes the deterministic
`--smoke-expansion-12-abyssal-pressure-return` journey. It proves:

- the unprotected 127.8-second route demand exceeds both base oxygen and the optional session tank
- the pressure suit reduces protected demand to 59.1 seconds with a 29.2-second return margin
- pressure warning and grace behavior remain retreatable before the suit
- the exact `Ti2 + Rubber1 + Gel1` project builds at night and persists
- the protected crossing, timed abyssal survey, hazard/reset cleanup, pending boat return, and exact-once discovery commitment pass

The browser checks prove that this same SHA initializes publicly and that its
desktop and mobile input surfaces remain usable. They do not substitute for
the focused player-experience review in #941, which is the only place this
milestone may receive GO or a bounded correction.

## Commands

```powershell
gh workflow run godot-web-export.yml --repo joeypshell/oceangame2 --ref main
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 84fb81fbdaac2d6e9a3066f68fc1393470d496e8
python tools/check_file_lengths.py
git diff --check
```
