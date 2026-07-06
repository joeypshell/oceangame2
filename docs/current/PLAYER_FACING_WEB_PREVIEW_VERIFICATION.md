# Player-Facing Fix Web Preview Verification

Date: 2026-07-06

Issue: #99 `Verify public Web preview after player-facing fix`

Public preview:

```text
https://joeypshell.github.io/oceangame2/
```

Verified deployed runtime commit:

```text
d32e0713765d6bdc7fa65570fe5543a8dd015f6e
```

The later backlog refresh commit `2bb1fe5` changed docs only and did not trigger the path-filtered Web export workflow. The deployed runtime commit above is the #98 player-facing fix, which changed the player runtime script.

## GitHub Actions

Workflow:

```text
Godot Web Export
```

Run:

```text
https://github.com/joeypshell/oceangame2/actions/runs/28813121705
```

Result:

```text
success
```

The run built and deployed commit `d32e0713765d6bdc7fa65570fe5543a8dd015f6e`.

## Browser Check

Command:

```powershell
$env:NODE_PATH = "C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules;C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\node_modules\.pnpm\node_modules"
& "C:\Users\pirat\.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe" tools/check_web_preview.cjs "https://joeypshell.github.io/oceangame2/" --expected-sha d32e071
```

Result:

- `build_info.json` matched `d32e0713765d6bdc7fa65570fe5543a8dd015f6e`.
- Canvas rendered at `1280x720`.
- No failed requests were reported.
- No missing texture/resource warnings were reported.
- No Godot `SCRIPT ERROR` or Godot `ERROR:` lines were reported.
- Chromium emitted WebGL `ReadPixels` performance warnings only; those are expected checker-environment warnings and not project resource failures.

Screenshot:

```text
exports/web-preview-check.png
```

## Decision

The public Web preview is verified for the #98 player-facing runtime fix. No packaging or deployment follow-up is needed for this fix.
