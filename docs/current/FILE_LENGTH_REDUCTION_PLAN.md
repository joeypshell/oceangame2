# File Length Reduction Plan

Date: 2026-07-07

Planning-only note. Do not move code or change gameplay behavior in this pass.

## 1. Current Confirmed Oversized Files

The 2026-07-09 audit reports two remaining temporary human-authored exceptions:

- `scripts/main/main.gd`: 2175 lines, gameplay/application orchestration shell.
- `scripts/world/greybox_world.gd`: 1088 lines, world/source coordinator.

`docs/current/TOOLING.md` is now a compact index with focused child docs, and `docs/current/PROJECT_CONTEXT.md` is under 500 lines. Neither remains allowlist debt.

Near-limit files also need growth guards: `capture_controller.gd` is 500 lines, several smoke helpers are 491-497 lines, and expansion checks must use new domain files.
- `maps/full_cave_sketch_01.greybox.json`: 3035 lines, generated/source map data.
- `maps/production_slice_01.greybox.json`: 2433 lines, generated/source map data.
- `maps/production_slice_03.greybox.json`: 2218 lines, generated/source map data.
- `maps/production_slice_02.greybox.json`: 2087 lines, generated/source map data.
- `maps/cave_salvage_organic_01.greybox.json`: 1748 lines, generated/source map data.
- `maps/cave_tileset_test_01.greybox.json`: 1700 lines, generated/source map data.
- `maps/production_slice_04.greybox.json`: 1642 lines, generated/source map data.

## 2. Temporary Exceptions For Generated Data Files

Keep `maps/*.greybox.json` temporarily allowlisted. These files are source data for the prototype maps and are validated by map-specific tooling instead of the human-authored file-length target.

Do not split generated map JSON by hand. If map data becomes hard to review, create a separate source-format/generator issue that preserves source-of-truth validation, map parity, reachability checks, and rendered review sheets.

Human-authored Markdown is no longer temporarily allowlisted. Keep current handoff docs concise and replace/archive stale detail instead of crossing 500 lines again.

## 3. Proposed Split Of `scripts/main/main.gd`

Goal: keep `main.gd` as orchestration only. It should create/load the world, create the player, connect compact controllers, and dispatch high-level modes.

Recommended extraction boundaries:

- Map/cmdline mode resolution: move map path selection, capture/smoke flag parsing, automated-review detection, and map-selector eligibility into a small mode resolver.
- Capture controller: move screenshot, camera-test capture, player-readability, background-depth, feedback-overlay, and route-outcome capture helpers.
- Review/result overlay: move review panel, map selector UI, status text, oxygen feedback label, result panel, score breakdown text, route outcome text, and build label formatting.
- Expedition/run state: move salvage banking, held cargo, oxygen timer, hazard penalty/reset, session best score, completion/failure state, and reset semantics.
- Smoke checks: split deterministic smoke flows into multiple domain files, such as salvage/cargo/scoring, hazards/oxygen, route choice/pathing, player facing/movement, and map selector.

Keep the first split narrow: extract mode resolution without changing runtime semantics. Then extract one domain at a time with smoke coverage after each move.

Status: capture and smoke responsibilities have focused helpers, but `main.gd` remains oversized. The next expansion gate is a no-behavior extraction of progression transaction/presentation wrappers before scanner/profile growth; see `SIMPLE_DIVER_GAME_09_ARCHITECTURE_VALIDATION_GATES.md`.

## 4. Proposed Split Of `scripts/world/greybox_world.gd`

Goal: keep `greybox_world.gd` as world coordination. It should load validated map data, own top-level node roots, expose stable runtime query methods, and delegate rendering/query details.

Recommended extraction boundaries:

- Terrain rendering: move cave terrain TileMapLayer creation, cave TileSet construction, solid-cell expansion, atlas mask selection, terrain variants, and source-grid TileSet helpers.
- Entity/prop rendering: move background art, zones, boat/relay visuals, salvage/hazard props, debug markers, and local polygon/shape helpers.
- World query/path/reachability helpers: move open-path search, position/cell conversion, collision/runtime parity cell extraction, extraction checks, hazard lookup, and salvage center reporting where practical.
- Texture loading/asset lookup: move PNG loading, packaged texture fallback, prop texture cache, and asset lookup helpers if this reduces coupling after prop rendering is extracted.

Preserve the public method names used by `main.gd` until call sites are intentionally updated. Do not change JSON map semantics, collision derivation, spawn/extraction behavior, or parity reports during these splits.

Status: terrain, collision, debug, background, prop, extraction, route-marker, visibility, and asset lookup helpers have been extracted. The next expansion gate is a no-behavior world query/path helper extraction before survey/fauna queries.

## 5. Completed Split Of `docs/current/TOOLING.md`

Goal: make `TOOLING.md` a short index under 500 lines and move dense command/reference sections into focused docs under `docs/current/tooling/`.

Suggested files:

- `docs/current/tooling/local_godot.md`: editor launch, map launch flags, `.cmd` wrappers, map selector notes.
- `docs/current/tooling/map_pipeline.md`: validators, renderers, map regeneration, parity, source/render/collision review sheets.
- `docs/current/tooling/smokes.md`: Godot smoke command list and short descriptions.
- `docs/current/tooling/captures_and_baselines.md`: capture commands, visual baselines, baseline comparison/acceptance.
- `docs/current/tooling/web_preview.md`: local web export, Pages verification, build metadata.
- `docs/current/tooling/assets.md`: asset manifest, terrain atlas coverage, sprite generation, local asset processing.

`TOOLING.md` is now a compact table of contents plus common commands. Keep it that way and avoid duplicating long command blocks between the index and child docs.

## 6. Recommended Remaining Order

1. Extract progression transaction/presentation wrappers from `scripts/main/main.gd` before scanner/profile integration.
2. Extract world query/path/reachability helpers from `scripts/world/greybox_world.gd` before survey/fauna query growth.
3. Continue domain-driven extractions only when a selected feature needs the ownership boundary.
4. Remove each temporary allowlist entry after its owner file is under 500 lines.

## 7. Verification Commands After Each Split

Run the narrow checks for the touched area plus the shared audit:

```bash
python tools/check_file_lengths.py
python tools/check_asset_manifest.py
python tools/check_map_parity.py
git diff --check
```

For `main.gd` splits, also run the relevant Godot smoke flags for the extracted domain. At minimum after each behavioral split:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-salvage-loop
```

For `greybox_world.gd` splits, also run:

```bash
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
```

For `TOOLING.md` or `PROJECT_CONTEXT.md` splits, run:

```bash
python tools/check_file_lengths.py
git diff --check
```

Highest-risk split: extracting expedition/run state from `scripts/main/main.gd`, because it touches oxygen, hazard reset, held cargo, banking, result-panel state, and session-best behavior at once. Keep that issue smaller than it looks: move state ownership first, then clean call sites only after smoke coverage passes.
