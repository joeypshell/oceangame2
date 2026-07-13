# OceanGame Expansion 08 Web Preview Verification

Date: 2026-07-13

Issue: #843 `Verify Web preview and technically close Expansion 08`

## Result

**PASS.** The public GitHub Pages preview serves the completed Expansion 08 runtime at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- Runtime and visual-decision commit: `f2dc68d32464fb06731bfc4b6ef49476d29a3ad2`
- Build version: `f2dc68d`
- Godot Web Export run: [29228826346](https://github.com/joeypshell/oceangame2/actions/runs/29228826346), success
- External `build_info.json`: exact full-SHA match
- Isolated review URL: `https://joeypshell.github.io/oceangame2/?review=f2dc68d32464fb06731bfc4b6ef49476d29a3ad2`

The later closeout merge changes documentation only and does not require a replacement runtime deployment.

## Automated Browser Evidence

`tools/check_web_preview.cjs` verified both the public root and fresh review URL:

- Godot 4.7 initialized with WebGL 2
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- mobile canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at `(0, 0)`
- mobile visual viewport: 844x390 with zero offset
- all four touch-control alignment probes exceeded the required two-pixel separation
- framing comparison mean difference `1.39`, below the maximum `18`
- no failed requests, script errors, missing textures, missing resources, or TileSet failures
- fresh isolated review-profile marker present

Chromium reported only software-WebGL fallback and `ReadPixels` performance warnings. They did not affect initialization, requests, framing, or the condition journey and are not Godot failures.

## Condition Path Evidence

An independent in-app browser run at 1280x720 exercised the deployed condition transition:

1. Day 1 loaded with the exact `f2dc68d` build label and fresh isolated profile.
2. `N` at the boat opened Night 1 with `Tomorrow: Southwest jellyfish bloom` before the day-start command.
3. `N` started Day 2 with `Southwest bloom: jellyfish + coil trace` in the active overlay.
4. Browser warning/error logs remained empty during this path.

This confirms the deployed transition and presentation operate technically. It does not prove that a player understands or values the forecast.

## Commands

```powershell
python tools/run_release_candidate_validation.py --require-godot
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha f2dc68d32464fb06731bfc4b6ef49476d29a3ad2
python tools/check_file_lengths.py
git diff --check
```
