# OceanGame Expansion 05 Web Preview Verification

Date: 2026-07-10

Issue: #757 `Verify Web preview and close OceanGame Expansion 05`

## Result

PASS. The public GitHub Pages preview serves the completed Expansion 05 runtime at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- Git commit: `f381361fc7ef1ada8ba87468159610409aced102`
- Build version: `f381361`
- Godot Web Export run: `29085923630`, success
- Build web export job: success
- Deploy GitHub Pages preview job: success
- Godot Smoke run: `29085923650`, success

The later visual-decision merge `976b27088b6aece4ae826df5f7d8311b9704a418` changed only documentation and correctly did not trigger a replacement runtime deployment.

## Browser Evidence

The public verifier reported:

- external `build_info.json` matched the full expected runtime commit
- primary canvas initialized at 1280x720
- wide canvas initialized at 1920x1080
- framing thumbnail mean difference `1.28`, below the maximum `18`
- no failed network requests
- no `SCRIPT ERROR`, `ERROR:`, missing texture, missing resource, or TileSet failure
- Godot 4.7 initialized with WebGL 2 in Chromium

The public default slice retained coherent terrain, boat, diver, and compact HUD framing at both viewports. The verification did not mutate maps, captures, or accepted baselines.

Chromium emitted repeated `ReadPixels` GPU-stall performance warnings. They did not affect initialization, requests, runtime behavior, or framing and are not Godot failures.

## Commands

```powershell
gh run view 29085923630 --repo joeypshell/oceangame2
gh run view 29085923650 --repo joeypshell/oceangame2
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha f381361fc7ef1ada8ba87468159610409aced102
```

The Web workflow also passed its pre-deploy local HTTP browser check before uploading the export and Pages bundle.
