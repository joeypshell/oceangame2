# OceanGame Expansion 07 Web Preview Verification

Date: 2026-07-10

Issue: #798 `Verify exact-SHA Web preview for Expansion 07`

## Result

**PASS.** The public GitHub Pages preview serves the completed Expansion 07 technical runtime at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- Runtime commit: `2a958f4747f677d5edfe7a52b8dfa224871637dc`
- Build version: `2a958f4`
- Godot Web Export run: `29100729376`, success
- Build web export job: success
- Deploy GitHub Pages preview job: success
- Godot Smoke run: `29100729246`, success

The later visual-decision merge `fb4d9027c80fd80ddfaab39a494c8259d7e4da8d` changed documentation only and correctly did not trigger a replacement runtime deployment.

## Browser Evidence

The public verifier reported:

- external `build_info.json` matched the full expected runtime commit
- primary canvas initialized at 1280x720
- wide canvas initialized at 1920x1080
- framing thumbnail mean difference `1.34`, below the maximum `18`
- no failed network requests
- no `SCRIPT ERROR`, `ERROR:`, missing texture, missing resource, or TileSet failure
- Godot 4.7 initialized with WebGL 2 in Chromium

An independent in-app browser inspection observed one initialized `oceangame2` canvas with intrinsic 1920x1080 size displayed at 1280x720. Browser error logs were empty.

Chromium emitted software-WebGL fallback and `ReadPixels` GPU-stall performance warnings. They did not affect initialization, requests, runtime behavior, or framing and are not Godot failures.

## Commands

```powershell
gh run view 29100729376 --repo joeypshell/oceangame2
gh run view 29100729246 --repo joeypshell/oceangame2
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 2a958f4747f677d5edfe7a52b8dfa224871637dc
python tools/check_file_lengths.py
git diff --check
```

The Web workflow also passed its pre-deploy local HTTP browser check before uploading the export and Pages bundle. Player-experience review and milestone closeout remain scoped to #799.
