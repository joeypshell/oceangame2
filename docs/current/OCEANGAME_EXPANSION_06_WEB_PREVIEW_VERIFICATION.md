# OceanGame Expansion 06 Web Preview Verification

Date: 2026-07-10

Issue: #777 `Verify Web preview and close OceanGame Expansion 06`

## Result

PASS. The public GitHub Pages preview serves the completed Expansion 06 runtime at:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployment:

- Git commit: `90dfd01c4437df3687067f1256d885cac80f8892`
- Build version: `90dfd01`
- Godot Web Export run: `29093205074`, success
- Build web export job: success
- Deploy GitHub Pages preview job: success
- Godot Smoke run: `29093205027`, success

The later visual-decision merge `3a2663f1ecb661b7708e17bd4f58da71947be8d7` changed only documentation and correctly did not trigger a replacement runtime deployment.

## Browser Evidence

The public verifier reported:

- external `build_info.json` matched the full expected runtime commit
- primary canvas initialized at 1280x720
- wide canvas initialized at 1920x1080
- framing thumbnail mean difference `1.31`, below the maximum `18`
- no failed network requests
- no `SCRIPT ERROR`, `ERROR:`, missing texture, missing resource, or TileSet failure
- Godot 4.7 initialized with WebGL 2 in Chromium

An independent in-app browser review observed one visible canvas with the expected intrinsic size at each viewport. Both frames showed `Build 90dfd01`, coherent source-driven terrain, boat and diver framing, and the compact day, health, shock-prod, oxygen, cargo, objective, and material lines without overlap. Browser error logs were empty.

Chromium emitted software-WebGL fallback and `ReadPixels` GPU-stall performance warnings. They did not affect initialization, requests, runtime behavior, or framing and are not Godot failures.

## Commands

```powershell
gh run view 29093205074 --repo joeypshell/oceangame2
gh run view 29093205027 --repo joeypshell/oceangame2
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 90dfd01c4437df3687067f1256d885cac80f8892
```

The Web workflow also passed its pre-deploy local HTTP browser check before uploading the export and Pages bundle.
