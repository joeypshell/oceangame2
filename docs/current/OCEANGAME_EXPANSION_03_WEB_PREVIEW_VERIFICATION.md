# OceanGame Expansion 03 Web Preview Verification

Date: 2026-07-10

Issue: #715 `Verify Web preview and close OceanGame Expansion 03`

## Result

PASS. The public GitHub Pages preview serves the completed Expansion 03 runtime at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- Git commit: `9322863ac25486a2a869d5e7f154cc58dbb70183`
- Build version: `9322863`
- Godot Web Export run: `29075848082`
- Build web export job: success
- Deploy GitHub Pages preview job: success
- Godot Smoke run: `29075848135`, success

## Browser Evidence

The public verifier reported:

- external `build_info.json` matched the full expected commit
- primary canvas initialized at 1280x720
- wide canvas initialized at 1920x1080
- framing thumbnail mean difference `1.31`, below the maximum `18`
- no failed network requests
- no `SCRIPT ERROR`, `ERROR:`, missing texture, missing resource, or TileSet failure
- Godot 4.7 initialized with WebGL 2 in Chromium

The default slice retained coherent cave, boat, diver, and compact HUD framing at both viewports. The deployment check does not mutate maps, captures, or accepted baselines.

Chromium emitted repeated `ReadPixels` GPU-stall performance warnings. The verifier does not classify those browser/platform warnings as Godot runtime failures, and they did not affect initialization, requests, or framing.

GitHub also warned that several pinned actions still target Node.js 20 and were forced onto Node.js 24. Both workflow jobs completed successfully; updating those action versions is maintenance work, not an Expansion 03 blocker.

## Commands

```powershell
gh run watch 29075848082 --repo joeypshell/oceangame2 --exit-status
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 9322863ac25486a2a869d5e7f154cc58dbb70183
```

The same workflow run passed its pre-deploy local HTTP browser check before uploading the Web artifact and Pages bundle.
