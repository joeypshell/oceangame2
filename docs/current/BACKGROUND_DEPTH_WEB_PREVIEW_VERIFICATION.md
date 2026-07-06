# Background Depth Web Preview Verification

Date: 2026-07-06

Issue: #92 `Verify public web preview after background depth pass`

## Result

The public GitHub Pages preview was verified after the Controlled Visual Revision 04 background-depth pass. The deployed preview renders the updated background-depth asset, terrain, approved sprites, boat, and default production-slice scene without missing texture or stale-deploy errors.

Verified public URL:

```text
https://joeypshell.github.io/oceangame2/
```

## Deployed Build

The relevant `Godot Web Export` deployment was workflow run `28810106572`:

- Commit: `29e5518f8befc202f96319fb34d59b961b87c884`
- Commit title: `Implement background depth art pass`
- Build job: success
- Deploy job: success
- Deploy completed: 2026-07-06T17:24:01Z

The later #91 baseline-acceptance commit `80c41462ed87b9e4b50cc7e88f3521dbfb538986` changed docs and accepted baseline artifacts only, so it did not trigger the Web Export workflow's runtime path filters. The exported runtime asset/script change is from #90.

## Browser Check

Command:

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT = "tmp\web-preview-background-depth-check.png"
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs "https://joeypshell.github.io/oceangame2/" --expected-sha 29e5518f8befc202f96319fb34d59b961b87c884
```

Observed result:

- External `build_info.json` matched `29e5518f8befc202f96319fb34d59b961b87c884`.
- Canvas rendered at `1280x720`.
- No failed requests.
- No missing `res://assets/...` texture warnings.
- No Godot errors or TileSet creation errors.
- Only browser/WebGL software-rendering and `ReadPixels` performance warnings were reported.

Screenshot evidence was saved locally at:

```text
tmp/web-preview-background-depth-check.png
```

## Decision

No follow-up is needed for public Web deployment of the background-depth pass. The Pages preview is serving the expected background-depth runtime commit and the browser checker confirmed asset packaging, canvas initialization, and build metadata.
