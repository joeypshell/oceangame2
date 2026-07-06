# Player Sprite Web Preview Verification

Date: 2026-07-06

Issue: #79 `Verify public web preview after player sprite pass`

## Result

The public GitHub Pages preview was verified after the player sprite pass. The deployed preview renders the cave terrain and the committed player sprite, and the browser check did not report missing texture or asset-packaging errors.

Verified public URL:

```text
https://joeypshell.github.io/oceangame2/?check=6b5a5a9
```

## Deployed Build

The latest relevant `Godot Web Export` deployment was workflow run `28798745133`:

- Commit: `6b5a5a9523e27c20f5a7f9e4b2ce3fc63466dcf5`
- Commit title: `Implement controlled player sprite`
- Build job: success
- Deploy job: success
- Deploy completed: 2026-07-06T14:26:46Z

The later #78 acceptance commit changed docs, captures, and baselines, so it did not trigger the path-filtered Web export workflow. That is acceptable for this check because #78 did not change exported runtime code or player assets.

## Browser Check

Command:

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT = "tmp\web-preview-player-sprite-check.png"
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs "https://joeypshell.github.io/oceangame2/?check=6b5a5a9"
```

Observed result:

- Canvas rendered at `1280x720`.
- No failed requests.
- No missing `res://assets/...` texture warnings.
- No Godot errors or TileSet creation errors.
- Only browser/WebGL software-rendering and `ReadPixels` performance warnings were reported.

Screenshot evidence was saved locally at:

```text
tmp/web-preview-player-sprite-check.png
```

The screenshot shows the deployed build hash `6b5a5a9`, rendered cave terrain, the boat entry area, and the player diver sprite visible in the water.

## Decision

No checker change is needed for this issue. The existing public preview check already catches the asset-packaging failure mode that previously caused blue fallback previews, and the player sprite asset loaded in the deployed build without missing-texture warnings.
