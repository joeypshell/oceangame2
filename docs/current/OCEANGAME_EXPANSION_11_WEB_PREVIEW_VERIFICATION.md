# OceanGame Expansion 11 Web Preview Verification

Date: 2026-07-14

Issue: #913 `Verify the public Web preview for Expansion 11`

## Result

**PASS.** The public GitHub Pages preview serves the reviewed Expansion 11
state at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- exact SHA: `308a7f3a4de7d926d3818f911d03fac77206c9fc`
- build version: `308a7f3`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Web Export run 29350571832](https://github.com/joeypshell/oceangame2/actions/runs/29350571832): success, including Pages deploy
- [Godot Smoke run 29350571479](https://github.com/joeypshell/oceangame2/actions/runs/29350571479): success
- [Progression Audit run 29350571541](https://github.com/joeypshell/oceangame2/actions/runs/29350571541): success
- fresh review URL:
  `https://joeypshell.github.io/oceangame2/?review=308a7f3a4de7d926d3818f911d03fac77206c9fc`

## Browser Evidence

`tools/check_web_preview.cjs` verified:

- root and fresh-review URLs load `production_level_01`
- explicit review fallback loads `production_slice_01`
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at `(0, 0)`
- mobile visual viewport: 844x390 with zero offset
- touch probes: move-down `8.60`, oxygen `4.91`, project `5.60`, attack `4.93`; all exceed the required `2`
- framing mean difference: `1.27`, below the maximum `18`
- no failed requests, missing assets, `SCRIPT ERROR`, or Godot `ERROR:` output

The fresh-review console marker reports `persistence=false` and
`propulsion_fins=false`. Review mode constructs the shared capability owner as
a new in-memory profile, so the durable `dive_light_1`, completed projects,
discoveries, and other prior profile state are not inherited.

Chromium emitted only the allowed software-WebGL fallback and `ReadPixels`
performance warnings. They did not affect initialization, input, framing, or
requests.

## Journey Evidence

The exact deployed SHA's Expansion 11 smoke proves:

- Signal Reef knowledge unlocks the `Ti1 + Coil1 + Gel1` dive-light project
- cargo-capacity pressure preserves the blocked material candidate
- the project builds at night exactly once and persists across reload
- the deep-harmonic survey remains at zero before the light
- dark-zone alpha improves from `0.3600` to `0.1512` after the light
- a hazard clears unbanked survey progress and applies the 12-second oxygen penalty
- the completed survey stays pending away from the boat and commits at the canonical boat
- duplicate commitment is prevented and the committed discovery survives profile reload
- the continuous route has no connector or prompt dependency

The smoke completed on day 4 with 35.1/87.0 oxygen, 212.1 seconds of daylight,
health 3, and the result `Discovery logged: Deep harmonic chart | Next lead:
signal descends into deeper water`.

## Verifier Correction

Earlier Expansion 11 exports correctly built but failed before deployment
because the Web checker still targeted the obsolete nine-command mobile grid.
PR #923 aligned BUILD and HIT probes with the intentional eight-command layout;
it did not change runtime controls, gameplay, maps, assets, captures, baselines,
or workflows. The corrected local export and exact public deployment both
reported project `5.60` and attack `4.93`.

## Commands

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 308a7f3a4de7d926d3818f911d03fac77206c9fc
python tools/check_file_lengths.py
git diff --check
```

Whether the clue, material hunt, night-built light, and remembered dark return
form a satisfying player journey remains the GO/HOLD question in #914.
