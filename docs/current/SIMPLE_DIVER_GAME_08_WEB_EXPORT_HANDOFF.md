# Simple Diver Game 08 Web Export Handoff

Date: 2026-07-09

Issue: #628

## Decision

The public GitHub Pages preview and Web export workflow are valid for the Simple Diver Game 08 release-candidate handoff. The latest deployed runtime/export build is from the last main-branch change that touched Web-export-relevant paths, not from later documentation-only merges.

## Current Deployed Build

- Workflow: `Godot Web Export`
- Run: `29054709626`
- Trigger: push to `main`
- Display title: `Add release journey smoke (#636)`
- Deployed SHA: `a529d0d62ee52c4ec5cc498ecdb4636dad723fca`
- Public URL: `https://joeypshell.github.io/oceangame2/`
- Pages status: enabled, public, HTTPS enforced, workflow source

Later documentation-only commits did not trigger `Godot Web Export` because the workflow path filter is limited to project/runtime/export inputs. That is expected for docs-only release-candidate notes.

## Workflow Audit

The workflow still performs the required release-candidate handoff steps:

- Writes `build_info.json` from `GITHUB_SHA`.
- Generates the Web export preset.
- Exports to `exports/web/index.html`.
- Copies external `build_info.json` beside the export.
- Serves the export over HTTP.
- Runs `tools/check_web_preview.cjs` against the served build with the expected SHA.
- Uploads the `web-preview-check` artifact.
- Uploads the `oceangame2-web-export` artifact.
- Deploys the same export to GitHub Pages when Pages is enabled.

## Public Preview Verification

Command:

```powershell
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha a529d0d62ee52c4ec5cc498ecdb4636dad723fca
```

Result:

- `build_info.json` loaded from the public preview.
- `git_sha` matched `a529d0d62ee52c4ec5cc498ecdb4636dad723fca`.
- Primary canvas initialized at `1280x720`.
- Wide canvas initialized at `1920x1080`.
- Framing thumbnail mean difference was `1.27`, below the max threshold of `18`.
- No failed network requests were reported.
- No Godot `SCRIPT ERROR`, `ERROR:`, missing texture, or failed resource warnings were reported.

Chromium emitted local software WebGL and `ReadPixels` performance warnings during the automated check. These are not project/runtime failures and are not matched by the checker failure patterns.

## Handoff Notes

- Use the deployed `build_info.json` SHA when comparing public Web preview against a local checkout.
- A docs-only merge can make `main` newer than the public export without indicating a stale runtime deploy.
- For a fresh runtime/map/script/assets change, expect `Godot Web Export` to run and deploy a new Pages build.
- Do not accept visual baselines from the Web preview unless the relevant visual review issue explicitly calls for it.

## Not Changed

No gameplay, maps, assets, captures, baselines, or workflow files changed in this audit.
