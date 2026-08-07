# File Length Reduction Plan

Date: 2026-07-07

Planning-only note. Do not move code or change gameplay behavior in this pass.

The 500-line direction is a default target and growth guard for agent readability, not a runtime or architectural requirement. Do not split a cohesive owner merely to reach the number when that would fragment mutable state, increase coupling, obscure Godot lifecycle ordering, or create pass-through wrappers.

## 1. Current Confirmed Oversized Files

The 2026-07-09 audit reports two oversized human-authored files with different policy status:

- `scripts/main/main.gd`: 2040 lines, actionable temporary debt in the gameplay/application orchestration shell.
- `scripts/world/greybox_world.gd`: 984 lines, a documented cohesive-owner exception for map and top-level node state.
- `scripts/companion/companion_control_runtime.gd`: a documented cohesive-owner exception for tightly coupled command, riding, and transient hotbar state; keep it growth guarded and split only when a stable owner boundary is proven.

`docs/current/TOOLING.md` is now a compact index with focused child docs, and `docs/current/PROJECT_CONTEXT.md` is under 500 lines. Neither remains allowlist debt.

Near-limit files also need growth guards: `capture_controller.gd` is 500 lines, several smoke helpers are 491-497 lines, and expansion checks must use new domain files.
- `maps/full_cave_sketch_01.greybox.json`: 3035 lines, generated/source map data.
- `maps/production_slice_01.greybox.json`: 2703 lines, generated/source map data.
- `maps/production_slice_03.greybox.json`: 2218 lines, generated/source map data.
- `maps/production_slice_02.greybox.json`: 2124 lines, generated/source map data.
- `maps/cave_salvage_organic_01.greybox.json`: 1748 lines, generated/source map data.
- `maps/cave_tileset_test_01.greybox.json`: 1700 lines, generated/source map data.
- `maps/production_slice_04.greybox.json`: 1713 lines, generated/source map data.

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

Status: capture, smoke, progression, profile, expedition, and survey responsibilities now have focused helpers, but `main.gd` remains oversized. Continue extracting only when selected work exposes a complete ownership boundary; new territorial-fauna behavior belongs in a focused controller rather than this shell.

## 4. Cohesive-Owner Policy For `scripts/world/greybox_world.gd`

Goal: keep `greybox_world.gd` as world coordination. It should load validated map data, own top-level node roots, expose stable runtime query methods, and delegate rendering/query details.

Already extracted responsibilities include terrain, collision, debug, background, prop, extraction, route-marker, visibility, asset lookup, world-query, and survey-target helpers.

Further extraction is optional and must improve ownership. Good candidates own a complete responsibility with explicit inputs/outputs; bad candidates require back-references into world arrays, duplicate node state, or turn public methods into chains of pass-through wrappers.

Preserve the public method names used by `main.gd`, one clear owner for mutable map/node state, JSON semantics, collision derivation, spawn/extraction behavior, and parity reports. Remaining above 500 lines is acceptable while those constraints make the coordinator safer and easier to reason about than another split.

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

1. Continue responsibility-driven extraction from `scripts/main/main.gd` when selected work benefits from a clearer owner.
2. Keep `scripts/world/greybox_world.gd` as a growth-guarded cohesive-owner exception unless a stable boundary demonstrably reduces coupling.
3. Keep new domain files under 500 lines unless they independently justify the same documented exception.
4. Remove temporary-debt entries when decomposition improves ownership; re-evaluate cohesive-owner exceptions during architecture audits rather than treating their line count alone as debt.

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
