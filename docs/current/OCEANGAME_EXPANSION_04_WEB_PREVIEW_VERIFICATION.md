# OceanGame Expansion 04 Web Preview Verification

Date: 2026-07-10

Issue: #735 `Verify Web preview and close OceanGame Expansion 04`

## Result

PASS. The public GitHub Pages preview serves the completed Expansion 04 runtime at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- Git commit: `679c16eccad0d87e7f47d50ce2a7737fbd9e050c`
- Build version: `679c16e`
- Godot Web Export run: `29081121678`
- Build web export job: success
- Deploy GitHub Pages preview job: success
- Godot Smoke run: `29081121697`, success

## Browser Evidence

The public verifier reported:

- external `build_info.json` matched the full expected commit
- primary canvas initialized at 1280x720
- wide canvas initialized at 1920x1080
- framing thumbnail mean difference `1.29`, below the maximum `18`
- no failed network requests
- no `SCRIPT ERROR`, `ERROR:`, missing texture, missing resource, or TileSet failure
- Godot 4.7 initialized with WebGL 2 in Chromium

The default slice retained coherent cave, boat, diver, and compact HUD framing at both viewports. The deployment check did not mutate maps, captures, or accepted baselines.

Chromium emitted repeated `ReadPixels` GPU-stall performance warnings. They did not affect initialization, requests, or framing and are not Godot runtime failures.

GitHub also warned that pinned actions targeting Node.js 20 were forced onto Node.js 24. Both workflows completed successfully; action-version maintenance is not an Expansion 04 blocker.

## Commands

```powershell
gh run view 29081121678 --repo joeypshell/oceangame2
gh run view 29081121697 --repo joeypshell/oceangame2
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 679c16eccad0d87e7f47d50ce2a7737fbd9e050c
```

The Web workflow also passed its pre-deploy local HTTP browser check before uploading the export and Pages bundle.
