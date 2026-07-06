# Boat Spawn Web Preview Verification

Date: 2026-07-06

Issue: #87 `Verify public web preview after boat entry art pass`

## Result

The public GitHub Pages preview was verified after the Controlled Visual Revision 03 boat entry art pass. The deployed preview renders the updated boat entry sprite, terrain, player, and default production-slice scene without missing texture or stale-deploy errors.

Verified public URL:

```text
https://joeypshell.github.io/oceangame2/
```

## Deployed Build

The relevant `Godot Web Export` deployment was workflow run `28805176318`:

- Commit: `4e5dc8f90bc745e8fb241400358128519c181f8d`
- Commit title: `Implement controlled boat spawn art pass`
- Build job: success
- Deploy job: success
- Deploy completed: 2026-07-06T16:03:50Z

The later #86 baseline-acceptance commit changed docs and accepted baseline artifacts, so it did not need a new Web export. The exported runtime asset/script change is from #85.

## Browser Check

Command:

```powershell
$env:NODE_PATH = "$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT = "tmp\web-preview-boat-entry-check.png"
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs "https://joeypshell.github.io/oceangame2/" --expected-sha 4e5dc8f90bc745e8fb241400358128519c181f8d
```

Observed result:

- External `build_info.json` matched `4e5dc8f90bc745e8fb241400358128519c181f8d`.
- Canvas rendered at `1280x720`.
- No failed requests.
- No missing `res://assets/...` texture warnings.
- No Godot errors or TileSet creation errors.
- Only browser/WebGL software-rendering and `ReadPixels` performance warnings were reported.

Screenshot evidence was saved locally at:

```text
tmp/web-preview-boat-entry-check.png
```

The screenshot shows build `4e5dc8f`, cave terrain, the player sprite, and the updated top-water boat entry visual in the default production-slice preview.

## Decision

No follow-up is needed for public Web deployment of the boat entry art pass. The Pages preview is serving the expected boat-art runtime commit and the browser checker confirmed asset packaging, canvas initialization, and build metadata.
