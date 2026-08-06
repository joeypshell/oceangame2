# Tooling

This is the compact index for current project commands. Keep detailed command blocks in the smaller files under `docs/current/tooling/` so current-state docs stay agent-friendly.

## Quick Index

- [Local Run](tooling/local_run.md): Godot editor/run helpers, map selection flags, Command Prompt wrappers, and local Godot path checks.
- [Validation And Map Source Tools](tooling/validation.md): map validation, runtime/source parity, asset manifest checks, file-length audit, SVG previews, and production-slice source regeneration.
- [Smoke Checks](tooling/smokes.md): whitespace checks, Godot import/startup, route, scoring, hazard, oxygen, cargo, result, player-facing, and movement-feel smokes.
- [Captures](tooling/captures.md): non-headless screenshot/camera captures, focused review captures, production-slice captures, debug captures, and capture completeness checks.
- [Web Export](tooling/web_export.md): local build metadata, local Web export, HTTP serving, Chromium preview checks, GitHub Actions export, and Pages notes.
- [Baselines And Review Sheets](tooling/baselines.md): production-slice baseline accept/compare commands and source/render/collision review sheets.
- [Asset Generation](tooling/asset_generation.md): terrain tileset, props, player sprite, terrain-kit processing, and generated-file warnings.
- [Agent Skills](tooling/agent_skills.md): project-local Codex skills for repo drift evaluation and issue-resolution workflows.
- [Living Expedition 01 Evidence](tooling/living_expedition_01.md): pre-rescue checkpoint, three-day journey smoke, and generated desktop/mobile review captures.
- [Living Expedition 02 Evidence](tooling/living_expedition_02.md): two-partner checkpoint, deterministic species-selection journey, and focused source/progression checks.

## Critical Warnings

- Do not commit generated/cache/build files: `.godot/`, `.import/`, `*.import`, `builds/`, `exports/`, local editor state, secrets, or platform export artifacts.
- Godot Web exports must be served over HTTP. Do not open `exports/web/index.html` directly.
- Do not use `--headless` for screenshot capture on the current local setup; headless uses Godot's dummy renderer here, so the viewport texture is unavailable.
- Treat `SCRIPT ERROR` or `ERROR:` lines as failures even when a Godot command exits `0`.
- For map/terrain work, update source data or renderer first, then validate and capture from the source-driven output.

## Common Starting Points

Open the project:

```powershell
.\tools\open_godot_project.ps1
```

Run the current default preview:

```powershell
.\tools\open_godot_project.ps1 -Run
```

Run the standard documentation/worktree checks:

```bash
python tools/check_file_lengths.py
git diff --check
```
