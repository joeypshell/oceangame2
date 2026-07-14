# OceanGame Expansion 10 Web Preview Verification

Date: 2026-07-13

Issue: #888 `Verify the public Web preview for Expansion 10`

## Result

**PASS.** The public GitHub Pages preview serves the reviewed Expansion 10
source state at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- runtime/export SHA: `4a85c93dfb7a0fe9fa092bfc2bf0f846a5cf81c3`
- build version: `4a85c93`
- [Godot Web Export run 29298272854](https://github.com/joeypshell/oceangame2/actions/runs/29298272854): success
- [Godot Smoke run 29298272861](https://github.com/joeypshell/oceangame2/actions/runs/29298272861): success
- [Progression Audit run 29298272872](https://github.com/joeypshell/oceangame2/actions/runs/29298272872): success
- external `build_info.json`: exact full-SHA match
- isolated review URL:
  `https://joeypshell.github.io/oceangame2/?review=4a85c93dfb7a0fe9fa092bfc2bf0f846a5cf81c3`

The later baseline-acceptance merge `84e1ebb` changed only documentation and
review PNGs, so it correctly did not trigger a replacement Web export. Its
accepted images were generated from the deployed `4a85c93` source state.

## Browser Evidence

`tools/check_web_preview.cjs` verified:

- the root and map-unspecified fresh review load `production_level_01`
- the explicit review fallback still loads `production_slice_01`
- primary canvas: 1280x720 CSS pixels
- wide canvas: 1920x1080 CSS pixels
- iPhone-landscape canvas: 2532x1170 intrinsic at 844x390 CSS, positioned at `(0, 0)`
- mobile visual viewport: 844x390 with zero offset
- touch probes: move-down `8.60`, oxygen `4.91`, project `5.80`, attack `5.09`, all above the required `2`
- framing mean difference `1.36`, below the maximum `18`
- no failed requests, missing resources, `SCRIPT ERROR`, or Godot `ERROR:` output

An independent fresh-profile browser load reported the expected isolated state
with propulsion fins unowned and the full-level default. Public input probes
held each control for 0.9 seconds from an independent fresh load:

| Input | Changed sampled pixels | Idle pixels | Result |
| --- | ---: | ---: | --- |
| Right arrow | 35,943 | 10 | horizontal arrow movement passes |
| Down arrow | 2,011 | 10 | vertical arrow movement passes |
| `D` | 36,032 | 10 | horizontal WASD movement passes |
| `S` | 1,179 | 10 | vertical WASD movement passes |

All four input probes recorded zero page errors and zero failed requests.

Chromium emitted only software-WebGL fallback and `ReadPixels` performance
warnings. They did not affect initialization, framing, input, or requests.

## Journey Evidence

The exact deployed SHA's Godot Smoke run exercised the integrated journey with
active collision:

- fresh profile is blocked at the authored current before propulsion fins
- the fins blueprint uses the authored titanium-two plus rubber-one recipe and a night project
- the lower-right regional current is crossed by swimming, with no `E`, connector, or teleport
- the Signal Reef scanner survey becomes pending away from the boat and commits on return
- the regional round trip measures 9,362 pixels; the full setup and journey measures 33,388 pixels
- minimum oxygen is 37.8 seconds and day-two daylight remains 226.3 seconds
- the committed result identifies the Signal Reef chart and the next deeper-harmonic lead

This proves the deployed source has the reviewed route contract. Whether that
journey is clear, memorable, and worth another expedition remains the player
GO/HOLD question in #889.

## Commands

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 4a85c93dfb7a0fe9fa092bfc2bf0f846a5cf81c3
python tools/check_file_lengths.py
git diff --check
```
