# Expedition Loop Web Preview Verification

Date: 2026-07-06

## Result

The public GitHub Pages preview is serving the latest runtime-affecting expedition-loop commit and initializes cleanly in Chromium.

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

Expected runtime commit:

```text
510b241bde80673066f2e89bd73f0efd3f088a6b
```

Public build metadata:

```json
{
  "version": "510b241",
  "git_sha": "510b241bde80673066f2e89bd73f0efd3f088a6b",
  "git_ref": "main",
  "dirty": false
}
```

The repository head at verification time was `dff9183`, but that commit only accepted visual captures and docs. It did not touch Web-export-triggering runtime paths, so the deployed runtime commit remained `510b241`, which includes the expanded expedition-loop gameplay changes.

## Browser Check

Command:

```powershell
$env:NODE_PATH="$env:TEMP\oceangame2-web-preview-check\node_modules"
$env:WEB_PREVIEW_SCREENSHOT='web-preview-public-expedition-loop.png'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 510b241bde80673066f2e89bd73f0efd3f088a6b
```

Result:

- `build_info.json` matched the expected SHA.
- Godot canvas initialized at `1280x720`.
- Browser screenshot showed `production_slice_01` with the expedition-loop overlay: score, salvage banked `0/6`, held `0/2`, and oxygen `90s`.
- No missing-resource, failed-request, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages were reported.
- Chromium emitted WebGL/software-rendering performance warnings only; these are not preview failures.
