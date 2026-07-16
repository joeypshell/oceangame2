# OceanGame Expansion 13 Web Preview Verification

Date: 2026-07-16

Issue: #968 `Verify the exact Expansion 13 public Web release candidate`

## Result

**PASS for technical deployment. Player GO remains open in #969.** The public
GitHub Pages preview serves the reviewed Expansion 13 candidate at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- exact SHA: `a9d143131b2a27009b7f57e49cab979016fa52ee`
- build version: `a9d1431`
- `git_ref`: `main`
- `dirty`: `false`
- [Godot Web Export run 29541554518](https://github.com/joeypshell/oceangame2/actions/runs/29541554518): success, including Pages deploy
- [Godot Smoke run 29541470293](https://github.com/joeypshell/oceangame2/actions/runs/29541470293): success
- [Progression Audit run 29541470317](https://github.com/joeypshell/oceangame2/actions/runs/29541470317): success
- fresh player-review URL:
  `https://joeypshell.github.io/oceangame2/?review=a9d143131b2a27009b7f57e49cab979016fa52ee`

The visual-baseline merge changed only paths outside the Web Export trigger,
so the workflow was manually dispatched on `main`. Its artifact embeds the
exact merge SHA above rather than an older successful deployment.

## Browser Evidence

`tools/check_web_preview.cjs` verified:

- root and fresh-review URLs load `production_level_01`
- explicit review fallback loads `production_slice_01`
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at `(0, 0)`
- mobile visual viewport: 844x390 with zero offset
- touch probes: move-down `8.60`, oxygen `4.91`, project `5.60`, attack `4.93`; all exceed the required `2`
- framing mean difference: `1.28`, below the maximum `18`
- no failed requests, missing assets, `SCRIPT ERROR`, or Godot `ERROR:` output

The fresh-review marker reports `persistence=false` and
`propulsion_fins=false`. Independent clean-tab inspection showed build
`a9d1431`, the full-level map, boat, diver, terrain, HUD, and isolated review
state rendering normally. Its console contained only Godot startup and map
markers, with no warning or error entries.

The automated Chromium run emitted only the allowed software-WebGL fallback
and `ReadPixels` performance warnings. They did not affect initialization,
input, framing, requests, or the independent browser view.

## Journey Boundary

The exact candidate includes the deterministic Southeast Wreck journey that
crosses the existing pressure route, completes cutter and explicit scanner
steps, preserves base-tank viability, returns recorder cargo and the pending
finding to the canonical boat, and reloads durable state exactly once.

These checks prove that candidate initializes publicly on desktop and mobile.
They do not replace the real player journey in #969, which remains the only
Expansion 13 GO/HOLD gate.

## Commands

```powershell
gh workflow run godot-web-export.yml --repo joeypshell/oceangame2 --ref main
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha a9d143131b2a27009b7f57e49cab979016fa52ee
python tools/check_file_lengths.py
git diff --check
```
