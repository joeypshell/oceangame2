# OceanGame Expansion 02 Web Preview Verification

Date: 2026-07-09

Issue: #694 `Verify public Web preview and close OceanGame Expansion 02`

## Result

PASS. The public GitHub Pages preview serves the completed Expansion 02 runtime at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- Git commit: `a2dab3c930785aa753495e29c4dbcf24ec06c0be`
- Build version: `a2dab3c`
- GitHub Actions run: `29070476832`
- Build web export job: success
- Deploy GitHub Pages preview job: success

## Browser Evidence

The public verifier reported:

- external `build_info.json` matched the full expected commit
- primary canvas initialized at 1280x720
- wide canvas initialized at 1920x1080
- framing thumbnail mean difference `1.30`, below the maximum `18`
- no failed network requests
- no `SCRIPT ERROR`, `ERROR:`, missing texture, missing resource, or TileSet failure
- Godot 4.7 initialized with WebGL 2 in Chromium

The public screenshot shows the source-rendered cave terrain, boat, diver scene, and compact `Day 1 | 04:54 | Dive 0 | Boat N End` line without overlap. No screenshot or generated Web output is committed by this verification.

Chromium emitted software-WebGL deprecation and `ReadPixels` performance warnings. The verifier does not classify those platform warnings as Godot/runtime failures, and they did not affect initialization, requests, framing, or rendered content.

## Commands

```powershell
gh run watch 29070476832 --repo joeypshell/oceangame2 --exit-status
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha a2dab3c930785aa753495e29c4dbcf24ec06c0be
```

The same workflow run passed its pre-deploy local HTTP browser check before uploading the Web artifact and Pages bundle.
