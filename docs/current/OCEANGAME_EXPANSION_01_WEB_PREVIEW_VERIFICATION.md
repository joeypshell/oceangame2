# OceanGame Expansion 01 Web Preview Verification

Date: 2026-07-09

Issue: #671 `Verify public Web preview and close OceanGame Expansion 01`

Public preview: `https://joeypshell.github.io/oceangame2/`

## Result

The public GitHub Pages preview serves the intended Expansion 01 commit and initializes cleanly in Chromium.

Expected and deployed commit:

```text
3d6a922408fb3261da2065b3c0beeafc224e56ee
```

External `build_info.json` reported:

```json
{
  "version": "3d6a922",
  "git_sha": "3d6a922408fb3261da2065b3c0beeafc224e56ee",
  "git_ref": "main",
  "dirty": false,
  "generated_utc": "2026-07-09T20:40:29-05:00"
}
```

## GitHub Actions

- [Godot Web Export run 29062882430](https://github.com/joeypshell/oceangame2/actions/runs/29062882430): success, including export, in-workflow Chromium verification, artifact upload, and Pages deploy.
- [Godot Smoke run 29062882389](https://github.com/joeypshell/oceangame2/actions/runs/29062882389): success, including the integrated anomaly-survey journey.

Both runs used the deployed SHA above. The Web run emitted one action-runtime Node 20 deprecation annotation; it did not affect the project build, browser check, or deployment.

## Browser Verification

Command:

```powershell
$env:NODE_PATH = 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules'
& 'C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe' tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 3d6a922408fb3261da2065b3c0beeafc224e56ee
```

Observed:

- external metadata matched the full expected SHA
- the Godot canvas initialized at 1280x720 and 1920x1080 CSS viewports
- framing thumbnail mean difference was 1.26 with maximum 18
- no failed requests, missing resources, Godot `SCRIPT ERROR`, or Godot `ERROR:` lines appeared
- only Chromium WebGL `ReadPixels` performance warnings appeared
- a separate browser inspection showed the default slice-01 cave terrain, surface boat, diver, salvage, HUD, and `Build 3d6a922`

## Decision

Expansion 01 public deployment is verified. The preview does not reproduce the historical blue-water fallback or missing-terrain failure, and no deployment blocker remains.
