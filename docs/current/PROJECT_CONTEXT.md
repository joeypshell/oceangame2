# Project Context

Last updated: 2026-08-02

This file is the compact handoff for new Codex or ChatGPT Project sessions. It captures the useful context from the initial planning and implementation chat without preserving the whole conversation.

## Current Goal

`oceangame2` has a GO release candidate and sixteen completed bounded Phase 2 expansions. Expansion 17 Wreck Network Triangulation is implemented and technically verified after bounded owner-HOLD corrections #1181-#1184; #1167 remains open for the short player GO/HOLD re-test. OceanGame Expansion 01 proved:

- authored map data as the source of truth
- generated-but-controlled terrain art
- repeatable screenshots and browser preview
- fixing one visual issue without resetting unrelated visuals
- expedition pressure through oxygen, cargo, hazards, routes, and objectives
- tool-like salvage interactions and limited progression
- one scanner-backed, source-authored discovery journey with exact return/commit state

Expansion 02 added a visible daylight budget, source-derived open-surface oxygen refill, repeated sorties, boat return, explicit night resolution, next-day reset, integrated smoke, focused visual review, and verified Web deployment.

Expansion 03 added deterministic authored material candidates, typed cargo and canonical-boat commitment, one exact-once night cutter project, a durable capability, and one remembered sealed-wreck return/payoff.

Expansion 04 added one visible source-authored current pocket, an exact durable stabilizer project/capability, unchanged remembered geography, and a valuable cargo-and-boat payoff. The pass closed with GO.

Expansion 05 added one stabilizer-gated mineral survey, an exact boat-committed finding, and a source-derived next-day deep-cache coil habitat lead without increasing yield or adding exact-route handholding. The pass closed with GO.

Expansion 06 added separate player health, one source-authored territorial eel, a viable unarmed evade route, and one durable shock-prod project built from non-enemy materials. Defeating the eel clears its territory only for the current day and grants no automatic reward. The pass closed with GO.

Expansion 07 added bounded passive/eel biological materials and one shock-prod capacitor step. Corrective review work established behavioral eel guarding, deliberate blueprint-plus-ingredient fins progression, passive same-map east-current traversal, scanner-before-weapon ordering, and isolated fresh-profile review. It closed at `73a3667` with an explicitly authorized technical GO.

Expansion 08 added one odd/even-day southwest jellyfish bloom, a night-ahead forecast, one optional bonus coil trace, and one condition-bound migration patrol. Source validation, deterministic journey coverage, focused visual review, the integrated release suite, and exact-SHA Web verification passed at `f2dc68d`. The authorized technical GO does not claim automation proved fun, clarity, map learnability, or another-day motivation.

Expansion 09 generated the complete `full_cave_sketch_01` topology as `production_level_01`, transformed the proven slice-01 gameplay overlay, validated continuous collision-active swimming and direct boat return, and passed player review. #864 recorded GO; #865 promoted the full level through PR #877 and exact-SHA Web verification at `e825c88`. `production_level_01` is now the normal default while slices 01-04 remain unchanged regression/provenance fixtures. The earlier #852 teleport/relay-terminal direction remains superseded, and connector travel, stabilizer entry requirements, and pressure progression remain deferred.

Expansion 10 completed through #889 plus player-gate correction #900. Propulsion fins now open one passive east-current route through continuous geography to Signal Reef, where a scanner-backed pending discovery commits only at the canonical boat. The correction preserves `production_level_01` through the real night/build/next-day transition. Exact-SHA Web verification passed at `c576d13`, and the player gave GO. The pass adds no teleport, prompted current crossing, pressure capability, broad map population, or second traversal capability.

Expansion 11 is complete with player GO through #914 plus corrections #925/#927. Signal Reef knowledge now reveals a durable Ti1/Coil1/Gel1 night-built light for one remembered dark-harmonic return. The old 900-score light purchase and 300-wallet scanner shortcut are retired; scanner ownership instead uses a guaranteed post-fins blueprint and Ti1/Coil1 night project, while the nearby valuable cache remains optional score. Final exact-SHA Web verification passed at `eb940b7`.

Expansion 12 is complete with player GO through #941 plus player-HOLD corrections #951-#953. The deep-harmonic clue now reveals a durable Ti2/Rubber1/Gel1 night-built pressure suit for one scoutable lower-central pressure threshold and protected abyssal survey. Explicit held `Space/SCAN` activation, full-cargo scanner feedback, pending boat-return guidance, deterministic journey coverage, and exact-SHA Web verification pass at runtime `d864a9e`.

Expansion 13 Southeast Wreck Return is complete with owner GO. After two bounded HOLD corrections, #1000-#1009 established deliberate shared tool controls, matching mobile presentation, named material sprites, and failure-safe sealed-wreck navigation data through canonical-boat commitment. Bounded audio interlude #1020-#1023 added first-material pickup ownership, individually generated semantic cues, deterministic lifecycle/asset coverage, and exact-SHA Web verification. The owner reviewed runtime `ede39d1`, reported the corrected experience was fine, and closed the player gate through #969.

Expansion 14 Archive Current Return is complete with owner GO at exact Web runtime `1f148eb`. Bounded correction #1069-#1077 plus replay fixes #1087/#1088 establish readable eel health/recoil/cadence and directional hit/miss feedback, continuous held scanner use, reward-free ordinary identification, visible Northwest Wreck Relay identity, separate passive-equipment presentation, and movement lock after oxygen failure. The archive, Ti2/Coil1 Current Stabilizer, passive current, relay core, survey pending state, cargo/failure behavior, canonical-boat commitment, contiguous map, and checkpoint boundary remain unchanged.

Expansion 15 Expedition Planning And Choice is complete with owner GO on exact Web runtime `23f4172`. It presents the unresolved Northwest Wreck Relay as main progression and the forecasted Southwest jellyfish bloom as an optional resource run, stores one session/day-scoped selection, and carries compact guidance through the following day's sorties. Corrections #1117/#1119 hardened build feedback and made the choices directly comparable without changing profile schema, topology, rewards, or progression ownership.

Expansion 16 Deeper Wreck Oxygen Return is complete through #1122-#1133 plus bounded corrections #1143-#1146/#1151/#1153. The committed relay finding now leads into the underused far-west/lower-left part of continuous `production_level_01`, where one recipe-built closed-circuit rebreather normalizes a source-authored confined-wreck x8 oxygen zone before an existing-cutter/existing-scanner payoff. The final route cue, relay beacons, pressure warning, scalable passive-gear presentation, and scaled-display HUD correction passed exact-SHA Web verification. The owner confirmed the oxygen pressure, rebreather, cutter, and corrected HUD and gave GO on runtime `05b482e`.

Expansion 17 Wreck Network Triangulation is implemented through #1158-#1166 plus owner-HOLD corrections #1181-#1184. The far-west recorder now explains that transfer-hub coordinates are split across a current-scoured western transponder and a pressure-crushed abyssal transponder. Each route reuses already-earned capabilities, each coordinate half commits only at the canonical boat, and returning both triggers one automatic, exact-once night comparison with a destination promise. Held scanner use is `Space/USE` on desktop and `USE` on mobile; there is no separate triangulation command. The pass adds no recipe, capability, terrain, transition, score reward, or broad system.

Emergency Week and Food/Water/Power overnight survival taxes are rejected. Shortcut and fast-travel networks are also rejected; remembered geography remains part of expedition pressure.

Controlled gameplay/visual passes are now a validation lane inside the roadmap, not the whole roadmap. New work should serve curiosity, pressure, payoff, remembered-place progress, meaningful route choice, or a reason to try another expedition.

## Repository

- GitHub repo: `joeypshell/oceangame2`
- Public preview: `https://joeypshell.github.io/oceangame2/`
- Engine: Godot 4.7, GDScript
- Main scene: `scenes/main/Main.tscn`
- Default preview map source: `maps/production_level_01.greybox.json`
- Original comparison map source: `maps/cave_salvage_test_01.greybox.json`
- Organic tileset stress-test map: `maps/cave_tileset_test_01.greybox.json`
- Full-map sketch topology draft: `maps/full_cave_sketch_01.greybox.json`
- Full-level production source: `maps/production_level_01.greybox.json`
- First production slice source: `maps/production_slice_01.greybox.json`
- Second production slice source: `maps/production_slice_02.greybox.json`
- Third production slice source: `maps/production_slice_03.greybox.json`
- Fourth production slice source: `maps/production_slice_04.greybox.json`
- Current terrain atlas: `assets/terrain_tiles/cave_tileset_v2.png`
- Web export workflow: `.github/workflows/godot-web-export.yml`
- Current docs index: `README.md`
- Finished foundation roadmap: `docs/current/SIMPLE_DIVER_GAME_ROADMAP.md`
- Active Phase 2 roadmap: `docs/planning/OCEANGAME_PHASE_2_ROADMAP.md`
- Completed Expansion 09 handoff: `docs/current/OCEANGAME_EXPANSION_09_CLOSEOUT.md` plus its linked plan, source contract, visual decision, and exact-SHA promotion evidence
- Completed Expansion 10 handoff: `docs/current/OCEANGAME_EXPANSION_10_CLOSEOUT.md` plus its linked plan, source contract, visual decision, Web verification, and correction #900
- Completed Expansion 11 handoff: `docs/current/OCEANGAME_EXPANSION_11_CLOSEOUT.md` plus its plan, source/state contract, visual decision, Web verification, corrections #925/#927, and player GO #914
- Completed Expansion 12 handoff: `docs/current/OCEANGAME_EXPANSION_12_CLOSEOUT.md` plus its plan, source/state contract, visual decision, Web verification, corrections #951-#953, and player GO #941
- Completed Expansion 13 handoff: `docs/current/OCEANGAME_EXPANSION_13_CLOSEOUT.md`, with correction history in `docs/current/OCEANGAME_EXPANSION_13_OWNER_HOLD_CORRECTION_PLAN.md`, `docs/current/ACTIVE_TOOL_AND_WRECK_REWARD_CONTRACT.md`, and `docs/current/OCEANGAME_EXPANSION_13_OWNER_HOLD_CORRECTION_VISUAL_WEB_VERIFICATION.md`
- Completed Expansion 14 handoff: `docs/current/OCEANGAME_EXPANSION_14_CLOSEOUT.md`, with correction history in `docs/current/OCEANGAME_EXPANSION_14_OWNER_HOLD_CORRECTION_PLAN.md`, focused visual review, and exact Web verification
- Completed Expansion 15 handoff: `docs/current/OCEANGAME_EXPANSION_15_CLOSEOUT.md`, with its plan, source/state contract, visual decision, final Web evidence, and corrections #1113/#1117/#1119
- Completed Expansion 16 handoff: `docs/current/OCEANGAME_EXPANSION_16_CLOSEOUT.md`, with its plan, source/state contract, visual decisions, exact Web evidence, and corrections #1143-#1146/#1151/#1153
- Active Expansion 17 handoff: its plan, source/state contract, visual decision, and exact Web verification under `docs/current/`; milestone #43 leaves only owner gate #1167 open after correction verification #1184
- Latest audio/Web handoff: `docs/current/FEEDBACK_AUDIO_CORRECTION_WEB_VERIFICATION.md`
- Progression framework: `docs/planning/CAPABILITY_RESOURCE_PROGRESSION_MATRIX.md`
- Architecture: `docs/current/ARCHITECTURE.md`
- Tooling: `docs/current/TOOLING.md`
- Focused player-review workflow: `docs/current/PLAYTEST_CHECKPOINTS.md`
- Production-slice status: `docs/current/PRODUCTION_SLICE_INDEX.md`
- Latest owner decision: Expansion 16 GO on exact reviewed runtime `05b482e`; Expansion 17 remains at owner HOLD pending #1167 re-test
- Latest selected direction: finish the bounded Expansion 17 player decision on exact corrected runtime `075a450`; do not select Expansion 18 first
- Latest completed expansion plan: `docs/current/OCEANGAME_EXPANSION_17_PLAN.md`, corrected after owner HOLD without changing its progression boundaries
- Latest source contract: `docs/current/OCEANGAME_EXPANSION_17_SOURCE_STATE_CONTRACT.md`
- Latest visual decision: corrected Expansion 17 focused states are accepted for review while the 14-view full-level and slice baselines remain pixel-stable
- Current expansion gates: `docs/current/SIMPLE_DIVER_GAME_09_ARCHITECTURE_VALIDATION_GATES.md`
- Release-candidate closeout: `docs/current/SIMPLE_DIVER_GAME_08_RELEASE_CANDIDATE_CLOSEOUT.md` (GO; regression foundation for Expansion 01).
- Latest Web verification: corrected Expansion 17 owner candidate `075a450`, recorded in `docs/current/OCEANGAME_EXPANSION_17_WEB_PREVIEW_VERIFICATION.md`.

Start every new coding session by reading `AGENTS.md`, this file, `README.md`, and the relevant docs under `docs/current/`.

## Visual Direction

The approved direction is a clean side-view underwater cave prototype with readable dark blue-gray cave terrain, clear blue water, sparse props, and gameplay-readable scale. The closest reference target in-repo is:

```text
references/visual/visual_direction_b_modular_cave.png
```

Important visual decisions:

- Perspective is side-view, roughly Dave-the-Diver scale and feel.
- The style should be simpler and more AI-generation-friendly than Dave the Diver.
- Seam-critical terrain must be generated/rendered as grid-aligned tiles, not stretched modules.
- Large generated modules are allowed only for background silhouettes, landmarks, and non-collision decoration.
- Do not regenerate whole scenes to fix one visual defect. Edit or replace individual named assets.
- Avoid retro SNES/pixel cave style, crowded mobile-platformer collectibles, and obvious repeated square-tile identity in final art.

## Map And Terrain Source Of Truth

Maps are data, not screenshots. The current source format is JSON greybox data rendered in Godot.

For map/terrain changes:

1. Update the machine-readable source map or renderer.
2. Regenerate previews/captures.
3. Run reachability validation.
4. Use screenshots or browser preview only as final rendering confirmation.

Do not visually interpret screenshots and hand-tune Godot polygons as topology fixes.

Current terrain renderer:

- `scripts/world/greybox_world.gd`
- Builds `CaveTerrainTileMapLayer` from solid cells in the JSON map.
- Selects 32x32 terrain atlas tiles from neighbor masks.
- Keeps collision generated from JSON terrain rectangles.
- Exposes a headless parity report so tooling can compare Godot terrain/collision cells with the JSON source.
- Hides the source grid in normal preview mode.
- Supports `--show-debug-overlay` for map debugging.

The main scene also shows a compact preview overlay with map id, build label, banked salvage score, salvage progress, held salvage capacity/score, and a scoped oxygen timer. A compact expedition result panel appears after run completion or oxygen failure with total score, salvage score, oxygen bonus, current map session-best score, salvage, optional route outcome, oxygen, and retry status. The gameplay loop includes separate player health, hazard reset/oxygen pressure, and one optional territorial-eel evade/fight encounter.

Maps may use either a legacy `spawn` entity or the newer `boat_spawn` entity. `boat_spawn` is the preferred top-water entry/extraction marker for production-style maps; the player starts at its `entry_x`/`entry_y` cell, and runtime extraction checks also accept its boat rectangle.

The greybox validator now checks entity schema as well as reachability: unique lower_snake_case entity ids, supported entity types, required salvage/hazard kinds, optional salvage `tier` values, coordinate bounds, exactly one player entry, and extraction requirements for playable salvage maps.

Current map-loading helper:

- Open the editor: `.\tools\open_godot_project.ps1`
- Run the default production level locally: `.\tools\open_godot_project.ps1 -Run`
- Run the organic comparison map locally: `.\tools\open_godot_project.ps1 -Run -OrganicMap`
- Run the original comparison map locally: `.\tools\open_godot_project.ps1 -Run -OriginalMap`
- Run the full-map sketch draft locally: `.\tools\open_godot_project.ps1 -Run -FullSketchMap`
- Run the first production slice locally: `.\tools\open_godot_project.ps1 -Run -ProductionSliceMap`
- Run the second production slice locally: `.\tools\open_godot_project.ps1 -Run -ProductionSlice2Map`
- Run the third production slice locally: `.\tools\open_godot_project.ps1 -Run -ProductionSlice3Map`
- Run the fourth production slice locally: `.\tools\open_godot_project.ps1 -Run -ProductionSlice4Map`
- From Command Prompt, use the root wrappers instead of invoking `.ps1` files directly: `run-production-slice-01.cmd`, `run-production-slice-02.cmd`, `run-production-slice-03.cmd`, or `run-production-slice-04.cmd`.
- Opening the Godot editor and pressing Play uses the default preview map unless Godot was launched with `--map-path`; the overlay should show the requested map id.
- Local/editor review runs show a small map selector in the review overlay for switching supported maps without relaunching. It is hidden for capture/smoke automation and exported builds unless explicitly enabled with `--review-map-selector`.

## Web Preview Status

The public preview was technically verified and owner-approved after the bounded Expansion 15 corrections at exact build `23f4172`:

```text
https://joeypshell.github.io/oceangame2/
```

The GitHub Pages source is configured for GitHub Actions publishing. The `Godot Web Export` workflow:

- downloads Godot 4.7 and export templates
- generates ignored `export_presets.cfg` with `tools/write_web_export_preset.py`
- writes `build_info.json` and copies it beside `exports/web/index.html` as plain external Pages metadata
- exports to ignored `exports/web/`
- serves the export and runs `tools/check_web_preview.cjs --expected-sha "${GITHUB_SHA}"` in Chromium to catch missing texture assets, stale build metadata, and viewport-size framing drift before deploy
- uploads the `oceangame2-web-export` artifact
- deploys to GitHub Pages when Pages is enabled

Important fixed pitfall: Web exports did not package dynamically loaded PNG terrain assets. The fix was:

- preload terrain textures in `scripts/world/greybox_world.gd`
- include `*.json,*.png,*.svg` in `tools/write_web_export_preset.py`
- fail the web export workflow if the browser console reports missing terrain textures or TileSet creation errors

If the browser preview ever shows only blue water, faint rectangles, markers, no cave tiles, or fallback prop art, check browser logs for missing `res://assets/...png` warnings and verify the export package includes the assets.

If the public preview looks stale, fetch `https://joeypshell.github.io/oceangame2/build_info.json` or run `tools/check_web_preview.cjs` with `--expected-sha` to compare the deployed external metadata with the expected commit. `Build local` means the editor is running a local checkout/worktree; mismatched HUD, salvage counts, or upgrade prompts usually mean the local checkout is behind or running a different map/worktree than the public `Build <sha>`.

## Current Validation Commands

Use `docs/current/TOOLING.md` and its focused pages for detailed commands. The current high-signal gates are:

```powershell
python tools/run_release_candidate_validation.py --require-godot
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-09-full-level-journey
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-current-gate
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-expansion-06-combat-foundation
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-current-gate
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha <merged-sha>
python tools/check_file_lengths.py
git diff --check
```

For map changes, run the relevant generator, SVG renderer, validator, parity check, route smoke, and focused capture in that order. Godot Web exports must be served over HTTP; never open `exports/web/index.html` directly.

## Issue Workflow

Use GitHub Issues for meaningful feature, bug, workflow, tooling, and demo work. Each issue needs acceptance criteria, relevant files, implementation notes, and verification steps.

Current issue state as of 2026-08-02:

- Closed: #662-#671 completed Expansion 01 with a GO.
- Closed: #685-#694 completed Expansion 02 with a GO.
- Closed: #706-#715 completed Expansion 03 with a GO.
- Closed: #726-#735 completed Expansion 04 with a GO; #739 resolved a narrow validator blocker found during authoring.
- Closed: #748-#757 completed Expansion 05 with a GO.
- Closed: #768-#777 completed Expansion 06 with a GO.
- Closed: #790-#799 and corrective issues through #831 complete Expansion 07 with a technical GO.
- Closed: #836 and #838-#843 completed Expansion 08 with a technical GO.
- Closed: #857-#865 plus correction #875 via PR #876 completed the contiguous full-level foundation, player GO, default promotion, and exact-SHA Web verification.
- Closed: #880-#889 plus correction #900 via PR #901 completed the east-current regional journey, player GO, and exact-SHA Web verification.
- Closed: #905-#914 plus corrections #925/#927 completed Expansion 11 with player GO and exact-SHA Web verification.
- Closed: #932-#941 plus corrections #951-#953 completed Expansion 12 with player GO and exact-SHA Web verification.
- Closed: #980 and #986-#990 delivered the first Expansion 13 HOLD correction and exact-SHA runtime `89371d6` verification.
- Closed correction batch: #1000-#1009 define, implement, validate, capture, accept, and deploy selected active-tool input, deliberate cutter activation, compact controls, readable named material sprites, and the source/runtime sealed-wreck navigation reward through exact-once boat commitment and profile compatibility.
- Closed audio interlude: #1020-#1023 fix the first material-pickup cue path, separate semantic cue assets, add deterministic lifecycle/asset coverage, and verify public runtime `ede39d1`.
- Closed: #969 records owner GO for exact reviewed runtime `ede39d1`; milestone #39 is complete.
- Closed: #1069-#1077 and #1087/#1088 resolve the Expansion 14 owner-HOLD findings and late replay gaps.
- Closed: #1040 records owner GO for exact runtime `1f148eb`; milestone #40 is complete.
- Closed: #1094-#1104 plus corrections #1113/#1117/#1119 completed Expansion 15; #1104 records owner GO for exact runtime `23f4172`, and milestone #41 is complete.
- Closed: #1122-#1133 plus corrections #1143-#1146/#1151/#1153 completed Expansion 16; #1133 records owner GO for exact runtime `05b482e`, and milestone #42 is complete.
- Closed: #1158-#1166 implemented and technically verified Expansion 17; #1181-#1184 corrected input, artifact identity, night payoff, visuals, and exact Web evidence after owner HOLD.
- Open owner gate: #1167 awaits the short corrected Expansion 17 player re-test; milestone #43 remains open and Expansion 18 is not selected.
- Closed bookkeeping: #849 was already fixed by `e825c88`; two repeat imports confirmed all three UID sidecars stable.
- Deferred: #52/#53 remain optional slice-03 presentation polish.
- Completed pass ranges and historical closeouts are indexed in `docs/MILESTONES.md`; do not duplicate that history here.

## Known Limits

- Terrain art has a first targeted polish pass, but it is still structural prototype art rather than final production art.
- `production_level_01` is the default preview map; slices 01-04 remain explicit regression/provenance fixtures.
- `cave_salvage_organic_01` is preserved as a first playable organic source-map comparison pass.
- `cave_salvage_test_01` is preserved as the original rectangular comparison map.
- `full_cave_sketch_01` is a topology-only draft conversion from a supplied full-map sketch; icons are intentionally ignored and the top-water `boat_spawn` is present for entry/extraction validation. It is the topology source for generated `production_level_01`, not the runtime production map itself.
- `docs/current/PRODUCTION_SLICE_SELECTION_CRITERIA.md` defines reusable roles and checklist criteria for choosing future focused slices from the full sketch.
- `docs/current/PRODUCTION_SLICE_INDEX.md` summarizes the current production slices, including role, source, launch command, route smoke, capture folders, source/render/collision review sheet, and accepted baseline status.
- `docs/current/POST_SLICE_WORKFLOW_DECISION.md` records the earlier focused-slice decision. Expansion 09 supersedes only its old full-sketch deferral; the slice fixtures and their source-discipline lessons remain valid.
- `docs/current/CONTROLLED_VISUAL_REVISION_01_PLAN.md` selects the first controlled visual-revision target: replace procedural salvage/hazard prop drawings with named committed sprite assets under #70.
- `docs/current/CONTROLLED_VISUAL_REVISION_02_PLAN.md` selects the next controlled visual-revision target: replace the procedural player placeholder with a named committed `player_diver_01.png` sprite while preserving collision, movement, camera behavior, map data, and gameplay logic.
- `docs/current/CONTROLLED_VISUAL_REVISION_03_PLAN.md` selects the next controlled visual-revision target: replace the procedural `boat_spawn` entry craft with a named committed `boat_spawn_01.png` sprite while preserving source-map boat entry/extraction semantics, player spawn, collision, movement, camera behavior, map data, and gameplay logic.
- `docs/current/CONTROLLED_VISUAL_REVISION_04_PLAN.md` selects the next controlled visual-revision target: improve the non-collision background/depth layer with a named `background_rocks_02.png` variant while preserving maps, terrain tiles, collision, movement, camera behavior, gameplay logic, approved foreground sprites, and accepted baselines until review.
- `docs/current/CONTROLLED_VISUAL_REVISION_05_PLAN.md` selects the next controlled visual-revision target: create a named `cave_tileset_v2.png` atlas variant while preserving map data, terrain/collision cells, route design, camera tests, accepted foreground/background assets, gameplay behavior, and default preview selection.
- `docs/current/CONTROLLED_GAMEPLAY_PASS_01_PLAN.md` selects the next controlled prototype target: tune player movement feel and readability while preserving map source data, terrain/collision, player sprite art, camera framing, salvage/hazard/oxygen semantics, and accepted visual baselines until review.
- `docs/current/MOVEMENT_FEEL_BASELINE_DECISION.md` records #104: the current movement-feel baseline is accepted for the prototype at `200 px/s` swim speed, `620 px/s^2` acceleration, and `900 px/s^2` deceleration.
- `docs/current/SALVAGE_OXYGEN_FEEDBACK_PLAN.md` selects the next controlled prototype target: improve the existing review overlay feedback for held/banked salvage, oxygen pressure, and reset/failure moments while preserving gameplay semantics.
- `docs/current/SALVAGE_OXYGEN_FEEDBACK_BASELINE_DECISION.md` records #107: the clearer salvage/oxygen overlay is accepted in normal production-slice visual baselines for slices 01-04.
- `docs/current/SALVAGE_OXYGEN_FEEDBACK_WEB_PREVIEW_VERIFICATION.md` records #108: the public Pages preview deployed the salvage/oxygen feedback runtime commit successfully, matched external build metadata, loaded without missing-resource or Godot errors, and showed the separated overlay lines in the browser screenshot.
- `docs/current/TERRAIN_TILESET_V2_BASELINE_DECISION.md` records #96: `cave_tileset_v2.png` is approved for the current prototype terrain baseline, and accepted baselines were updated for production slices 01-04.
- `docs/current/TERRAIN_TILESET_V2_WEB_PREVIEW_VERIFICATION.md` records #97: the public Pages preview deployed the terrain tileset v2 runtime commit successfully, matched external build metadata, and loaded the updated runtime without missing texture warnings.
- `assets/terrain_tiles/cave_tileset_v2.png` is the active approved runtime terrain atlas; `cave_tileset_v1.png` remains committed for comparison and rollback.
- `tools/render_terrain_atlas_coverage.py` renders `references/asset_reviews/cave_tileset_v1_coverage_review.png` and validates that atlas coordinates used by `scripts/world/greybox_world.gd` are present in the terrain manifest before terrain tileset revisions are accepted.
- `docs/current/CONTROLLED_VISUAL_REVISION_CHECKLIST.md` is the reusable checklist for future controlled visual revisions, covering planning, source-of-truth constraints, capture comparison, baseline acceptance, Web preview verification, and follow-up issues.
- `docs/current/PROP_SPRITE_BASELINE_DECISION.md` records #71: the prop sprites are approved for the current prototype, accepted baselines were updated for slices 02-04, and slice 01 baseline reconciliation was split into #75.
- `docs/current/PLAYER_SPRITE_BASELINE_DECISION.md` records #78: the player sprite is approved for the current prototype, and accepted baselines were updated for slices 01-04.
- `docs/current/PLAYER_SPRITE_WEB_PREVIEW_VERIFICATION.md` records #79: the public Pages preview deployed the player sprite runtime commit successfully, loaded terrain/player assets without missing texture warnings, and showed the player sprite in the browser screenshot.
- `docs/current/BOAT_SPAWN_ENTRY_BASELINE_DECISION.md` records #86: the boat spawn entry sprite is approved for the current prototype, and the accepted slice-01 baseline was updated for the new boat visual.
- `docs/current/BOAT_SPAWN_WEB_PREVIEW_VERIFICATION.md` records #87: the public Pages preview deployed the boat sprite runtime commit successfully, matched external build metadata, loaded assets without missing texture warnings, and showed the updated boat in the browser screenshot.
- `docs/current/BACKGROUND_DEPTH_BASELINE_DECISION.md` records #91: `background_rocks_02.png` is approved for the current prototype, and accepted baselines were updated for production slices 01-04.
- `docs/current/BACKGROUND_DEPTH_WEB_PREVIEW_VERIFICATION.md` records #92: the public Pages preview deployed the background-depth runtime commit successfully, matched external build metadata, and loaded the updated runtime without missing texture warnings.
- `docs/current/PRODUCTION_SLICE_01_VISUAL_BASELINE_RECONCILIATION.md` records #75: the former default slice's accepted baseline covers the current six-view fixture set.
- `docs/current/BACKLOG_REFRESH_2026_07_06.md` records the recommended issue order after #74.
- `docs/current/BACKLOG_REFRESH_POST_GAMEPLAY_PASS_01_2026_07_06.md` records the active recommended issue order after Controlled Gameplay Pass 01 and the salvage/oxygen feedback pass.
- `docs/current/CONTROLLED_GAMEPLAY_PASS_02_PLAN.md` selects the next controlled prototype target: one readable route-choice loop in `production_slice_01`, pairing a safer salvage route with a more valuable pickup under oxygen pressure while preserving source-of-truth map discipline.
- `docs/current/CONTROLLED_GAMEPLAY_PASS_03_PLAN.md` selects the next controlled prototype target: make the default loop feel like an expedition by adding scored salvage, cargo pressure, compact run results, retry flow, and one more authored route decision.
- `docs/current/CONTROLLED_GAMEPLAY_PASS_04_PLAN.md` selects the next controlled prototype target: make the expedition loop easier to read and more worth replaying with route metadata, safe-versus-deep validation, best-score/bonus feedback, hazard pressure, and focused visual/Web review.
- `docs/current/CONTROLLED_GAMEPLAY_PASS_04_CLOSEOUT.md` records #148: Pass 04 is complete, the next recommended pass should focus on moment-to-moment interaction before broader map scale, and the next issue batch should be concrete timed/tool-like salvage interaction work rather than a vague epic.
- `docs/current/OXYGEN_PRESSURE_BASELINE_DECISION.md` records #113/#143: the current oxygen baseline keeps a 90-second tank, starts `LOW` feedback at 40 seconds, escalates to `CRITICAL` at 15 seconds, and preserves the existing refill/depletion semantics.
- `docs/current/ROUTE_PAYOFF_VISUAL_BASELINE_DECISION.md` records #118: the tiny valuable-salvage cue on `salvage_lower_loop` is accepted in the `production_slice_01` visual baseline.
- `docs/current/EXPEDITION_LOOP_VISUAL_BASELINE_DECISION.md` records #127: the current `production_slice_01` expedition-loop captures are accepted with score/cargo/oxygen overlay text and the new `salvage_deep_right_cache` cue; generated `.import` sidecars were removed from accepted production-slice baselines.
- `docs/current/PASS_04_ROUTE_PRESSURE_VISUAL_BASELINE_DECISION.md` records #146: the current `production_slice_01` normal captures remain visually unchanged after Pass 04 route-pressure runtime/UI work, the focused route-outcome result capture covers the completed-run panel, and accepted baseline folders are clean of generated `.import` sidecars.
- `docs/current/PASS_04_ROUTE_PRESSURE_WEB_PREVIEW_VERIFICATION.md` records #147: the public Pages preview serves runtime commit `088a608`, matches external build metadata, initializes the Godot canvas, and emits no missing-resource, failed-request, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages.
- `docs/current/EXPEDITION_LOOP_WEB_PREVIEW_VERIFICATION.md` records #128: the public Pages preview serves runtime commit `510b241`, matches external build metadata, initializes the Godot canvas, and emits no missing-resource or Godot error messages.
- `docs/current/ROUTE_PAYOFF_WEB_PREVIEW_VERIFICATION.md` records #119: the public Pages preview deployed the route/payoff runtime commit successfully, matched external build metadata, initialized the Godot canvas, and emitted no missing-resource or Godot error messages.
- `references/greybox/full_cave_sketch_01_conversion_review.png` is generated by the full-sketch converter and compares source sketch, generated tiles, and overlay with conversion stats.
- `references/greybox/production_slice_01_source_render_collision_review.png` compares production-slice JSON topology, expected collision rectangles, and the Godot overview capture.
- `references/greybox/production_slice_02_source_render_collision_review.png` compares slice 02 JSON topology, expected collision rectangles, and the Godot overview capture.
- `references/greybox/production_slice_03_source_render_collision_review.png` compares slice 03 JSON topology, expected collision rectangles, and the Godot overview capture.
- `references/greybox/production_slice_04_source_render_collision_review.png` compares slice 04 JSON topology, expected collision rectangles, and the Godot overview capture.
- `production_slice_01` is the first focused slice from the full sketch's top-center entry hub; it preserves the selected topology, seals left/right/bottom crop edges, fills unreachable conversion pockets, applies targeted one-cell tip/notch cleanup in source generation, and adds authored boat spawn, salvage, hazards, route markers, and camera tests.
- `production_slice_01` marks `salvage_entry_shaft` as the short `safe_route_choice` target, `salvage_lower_loop` plus `salvage_deep_right_cache` as current `valuable` deep-route payoff targets, and `salvage_southwest_return_cache` as the `southwest_pocket_decision` detour payoff.
- `production_slice_02` is the second focused slice from the full sketch's lower-right chamber route. It is a later-game destination/connector candidate, not an alternate first area. It uses an in-water `spawn` and `base` extraction zone because the region has no natural top-water boat opening.
- `production_slice_03` is the third focused slice from the full sketch's upper-left room cluster. It is a connector/landmark room-cluster candidate with compact stacked-room navigation and an east-side in-water `spawn` plus `base` relay extraction zone.
- `production_slice_04` is the fourth focused slice from the full sketch's lower-left loop. It is a connector/return-loop candidate with curved-corridor movement and an east-side in-water `spawn` plus `base` relay extraction zone.
- `docs/current/PRODUCTION_SLICE_02_DECISION.md` records the bounds, rationale, spawn/extraction plan, and verification for the second slice.
- `docs/current/PRODUCTION_SLICE_02_VISUAL_BASELINE_DECISION.md` records the original slice-02 baseline deferral and the 2026-07-06 update accepting the current captures as the named visual baseline.
- `docs/current/PRODUCTION_SLICE_02_EVALUATION.md` records that slice 02 should stay a validated later-game reference slice, now with an accepted five-view visual baseline.
- `docs/current/PRODUCTION_SLICE_03_DECISION.md` selects the upper-left room cluster as the third focused slice candidate with starting bounds `x=0, y=8, w=76, h=82` and likely `spawn + base` relay extraction.
- `docs/current/PRODUCTION_SLICE_03_EVALUATION.md` records that slice 03 is a validated connector/landmark reference slice. Relay readability is accepted for the prototype pass, camera/source cleanup is not blocking, baseline acceptance remains separate, and slice 01 should stay the default preview for now.
- `docs/current/PRODUCTION_SLICE_03_DEFAULT_PREVIEW_DECISION.md` records that slice 03 should stay a reference slice and should not replace slice 01 as the Godot or public web default preview.
- `docs/current/PRODUCTION_SLICE_04_DECISION.md` selects the lower-left loop as the fourth focused slice candidate with bounds `x=0, y=86, w=88, h=50`, a `spawn + base` relay plan near global `(74, 104)`, and follow-up implementation issue #61.
- `docs/current/PRODUCTION_SLICE_04_DECISION.md` also records implementation status for #61 and points to #62 for the evaluation pass.
- `docs/current/PRODUCTION_SLICE_04_EVALUATION.md` records that slice 04 is a validated lower-left connector/return-loop reference slice. Source/collision, route smoke, relay readability, and capture completeness pass; baseline status remains separate under #63.
- `docs/current/PRODUCTION_SLICE_04_VISUAL_BASELINE_DECISION.md` records that current slice 04 captures are accepted as the named slice-04 visual baseline.
- `--smoke-production-slice-02-route` verifies `production_slice_02` by swimming through authored salvage with the normal movement controller and returning to the relay extraction zone.
- `--smoke-production-slice-03-route` verifies `production_slice_03` by swimming through authored salvage with the normal movement controller and returning to the relay extraction zone.
- `--smoke-production-slice-04-route` verifies `production_slice_04` by swimming through authored salvage with the normal movement controller and returning to the relay extraction zone.
- `--smoke-hazard-interaction` verifies hazard pressure in `production_slice_01` by checking a warning-only range status before contact, then confirming contact applies the 12-second oxygen penalty, resets the player, restores held salvage, and cleanly enters the failed expedition result panel if the penalty empties the tank.
- `--smoke-hazard-pressure` runs the same deterministic hazard pressure check and reports hazard id, warning distance/radii, oxygen before/after, and restored salvage id for CI diagnosis.
- `--smoke-player-facing` verifies the player direction-change path by keeping the root transform stable while flipping only the diver body and light-cone visuals.
- `--smoke-movement-feel` drives the player controller through start, stop, horizontal reversal, and diagonal movement phases, then reports measured velocities for the Controlled Gameplay Pass 01 tuning pass.
- `--smoke-route-choice` drives the player through the default slice route-choice probe by swimming from the boat entry to the authored `valuable` salvage target, collecting it, returning to extraction, and reporting the target/collection/return state.
- `--smoke-route-choice-metadata` verifies the ordered `expanded_route_choice` metadata for production slice 01 without moving the player, including route-choice IDs, strictly increasing route order, positive valuable salvage score, and source-route availability from spawn and back to extraction.
- `--smoke-expanded-route-choice` verifies the `expanded_route_choice` source metadata, swims through `salvage_lower_loop` and `salvage_deep_right_cache`, banks both valuable pickups at the boat, and reports targets, cargo, score, return, and oxygen.
- `--smoke-safe-deep-route-choice` swims one run to the short `safe_route_choice` target and a second run through the deeper `expanded_route_choice` targets, reports target ids, cargo, banked salvage, score, oxygen, and oxygen feedback for both runs, and asserts the safe route stays comfortable while the deeper route has higher payoff, lower remaining oxygen, and visible `LOW`/`CRITICAL` pressure.
- `--smoke-cargo-capacity` fills the current two-pickup cargo capacity, verifies held score is not banked before extraction, verifies an extra nearby salvage stays available and visibly uncollected while full, verifies the status says to return to extraction, banks held salvage/score at extraction, then verifies the blocked pickup can be collected after capacity frees up.
- `--smoke-salvage-feedback` collects one common pickup and one valuable pickup in separate reset runs, then verifies the status text reports each pickup's tier and score.
- `--smoke-session-best-score` completes a full collect-return run, verifies the result panel reports score and best score, verifies reset preserves the current map's best score, and verifies oxygen failure does not overwrite that best score.
- `--smoke-oxygen-bonus-score` completes a full collect-return run, verifies banked salvage score stays tier-derived, verifies the completion oxygen bonus is based on remaining oxygen, and verifies failed expeditions receive zero oxygen bonus.
- `--smoke-route-outcome-result` completes a route-tagged collect-return run, verifies the result panel reports `Route: Deep route`, resets, and verifies a generic failure result does not show stale route text.
- `--smoke-pass-09-southwest-pocket-decision` verifies the southwest pocket payoff metadata, pathing, collection feedback, held/banked score, route label, and reset cleanup.
- `--smoke-salvage-loop` also verifies the completion-only expedition result panel reports banked salvage score, oxygen bonus, best score, and salvage totals after a full collect-return run.
- `--capture-feedback-overlay` writes `visual_captures/feedback_overlay/production_slice_01_feedback_overlay.png` as the focused review capture for the salvage/oxygen feedback overlay pass.
- `--capture-route-outcome-result` writes `visual_captures/route_outcome/production_slice_01_route_outcome_result.png` after completing a deterministic route-tagged collect-return run; it is a review aid for Pass 04 result-panel readability, not baseline acceptance.
- `--capture-pass-09-southwest-pocket-decision` writes `visual_captures/southwest_pocket_decision/production_slice_01_southwest_pocket_decision.png` after collecting the pocket payoff through the normal runtime path; it is a review aid, not baseline acceptance.
- The `Godot Smoke` workflow runs the salvage loop, scoring/cargo/salvage-feedback/best-score/oxygen-bonus/route-outcome smoke, hazard-pressure smoke, all four production-slice route smokes, route-choice metadata and safe/deep route-choice smokes, Pass 08-16 focused route/objective smokes, and player-facing smoke, so CI covers the default slice, valuable salvage routes, safe-vs-deep pressure, cargo banking, primary objective completion, hazard pressure, later reference slices, and direction-change regressions.
- `production_slice_02` has five tuned camera captures: overview, relay entry, main chamber, lower terminal, and return route. Normal captures live in `visual_captures/production_slice_02/`; debug captures live in `visual_captures/production_slice_02_debug/`.
- `production_slice_03` has five authored camera captures: overview, relay entry, stacked rooms, connector, and return route. Normal captures live in `visual_captures/production_slice_03/`; debug captures live in `visual_captures/production_slice_03_debug/`.
- `production_slice_04` has five authored camera captures: overview, relay entry, lower-left loop, curved corridor, and return route. Normal captures live in `visual_captures/production_slice_04/`; debug captures live in `visual_captures/production_slice_04_debug/`.
- `tools/check_camera_captures.py` checks that a capture directory contains every PNG named by a map's authored `camera_tests`, ignoring Godot `.import` sidecars and reporting missing, extra, invalid, or stale-looking captures.
- `tools/check_production_slice_captures.py` runs the committed-capture completeness check for all production slices. The `Godot Smoke` workflow runs it without `--fail-on-stale` so CI catches missing, extra, or invalid captures without requiring a display renderer or relying on checkout mtimes.
- `tools/check_asset_manifest.py` verifies that `draft`, `approved`, and `locked` table entries in `docs/ASSET_MANIFEST.md` still point to committed files under `assets/` or `references/asset_reviews/`, while ignoring planned future assets.
- `visual_baselines/production_slice_01_accepted/` stores the accepted six-view production-slice visual baseline. Use `python tools/manage_production_slice_baseline.py compare` to render `references/asset_reviews/production_slice_01_visual_baseline_review.png` before accepting future visual changes.
- `tools/manage_production_slice_baseline.py` supports `--slice production_slice_01`, `--slice production_slice_02`, `--slice production_slice_03`, and `--slice production_slice_04` for compare/accept workflows. Use an explicit `--baseline-dir visual_captures/<slice>` only for tooling sanity checks, not as acceptance.
- `visual_baselines/production_slice_02_accepted/` stores the accepted five-view slice-02 visual baseline. Use `python tools/manage_production_slice_baseline.py --slice production_slice_02 compare` to render `references/asset_reviews/production_slice_02_visual_baseline_review.png` before accepting future slice-02 visual changes.
- `visual_baselines/production_slice_03_accepted/` stores the accepted five-view slice-03 visual baseline. Use `python tools/manage_production_slice_baseline.py --slice production_slice_03 compare` to render `references/asset_reviews/production_slice_03_visual_baseline_review.png` before accepting future slice-03 visual changes.
- `visual_baselines/production_slice_04_accepted/` stores the accepted five-view slice-04 visual baseline. Use `python tools/manage_production_slice_baseline.py --slice production_slice_04 compare` to render `references/asset_reviews/production_slice_04_visual_baseline_review.png` before accepting future slice-04 visual changes.
- Use `python tools/manage_production_slice_baseline.py compare-all` to refresh every accepted production-slice baseline/current/difference review sheet before controlled visual-revision work.
- `boat_spawn` now renders as a small top-water surface craft with a hatch/tether cue at the authored entry cell while still using the source rectangle for extraction.
- In-water `base` extraction zones now render as compact relay/sub return visuals with a spawn cue when a legacy `spawn` point sits inside the zone. The visual does not change source collision, spawn, extraction, salvage, hazard, or terrain data.
- The review overlay includes a local/editor-only map selector for supported review maps. It reloads world/player state cleanly, preserves the debug-overlay mode, and is covered by `--smoke-map-selector`.
- Collision is rectangular per terrain block; player collision is tuned smaller than the placeholder body art for production-slice clearance.
- Player movement is currently tuned to `200 px/s` swim speed, `620 px/s^2` acceleration, and `900 px/s^2` deceleration for Controlled Gameplay Pass 01.
- Player facing now keeps the `CharacterBody2D` root at normal scale and flips only the `Body` sprite plus `LightCone`, avoiding transient double-facing artifacts from mirroring the whole player node.
- `docs/current/PLAYER_FACING_WEB_PREVIEW_VERIFICATION.md` records #99: the public Pages preview deployed the #98 player-facing runtime fix successfully, matched external build metadata, initialized the Godot canvas, and emitted no missing-resource or Godot error messages.
- The salvage/oxygen overlay now separates banked salvage, held salvage, oxygen, and prompt/state lines so held-return, low oxygen, depletion, hazard reset, and run completion states are easier to read.
- Salvage has a minimal collect-return-complete-reset loop.
- Hazards now have a tiny scoped interaction: approaching one within warning range reports `Hazard nearby - keep clear`, and touching one applies a 12-second oxygen penalty, bumps the player back to spawn, briefly tints the player, and restores held/unbanked salvage to the map. If the penalty empties the tank, the normal failed expedition result panel takes over.
- The first scoped expedition pressure is a simple oxygen timer: oxygen drains away from extraction, refills at the boat/extraction area, and depletion surfaces the player while restoring held/unbanked salvage to the map.
- Current oxygen pressure timing keeps a 90-second tank, starts `LOW` feedback at 40 seconds, and escalates to `CRITICAL` at 15 seconds. The safe/deep route comparison smoke keeps the short safe route comfortable while verifying the deeper route shows `LOW` and `CRITICAL` before returning.
- `lower_loop_oxygen_rest_pocket` provides the Pass 12 limited oxygen-rest beat: compact `Rest pocket +oxygen` feedback, slow recovery up to a 45-second cap, and deterministic `--smoke-pass-12-oxygen-rest-pressure` coverage.
- The stable `deep_cache_route_objective` id now presents as `Relay trail`: bank `salvage_lower_loop` and `salvage_southwest_return_cache` to complete the opening objective without entering the eel encounter. Propulsion fins instead require the recovered lower-loop blueprint plus Ti2/Rubber1; historical pass docs retain former wording as snapshots.
- `salvage_pry_locker` provides the Pass 17 staged pry salvage beat: 3 in-range stages at 1.2 seconds each, partial-stage cancel on leaving range, completed-stage persistence during normal exploration, cargo-full blocking without deletion, and deterministic `--smoke-pry-salvage` coverage.
- Pass 18-20 historically introduced three score purchases. The live session wallet now owns only `O2 tank +15` and `Cargo +1`; `survey_scanner_1` uses a recovered blueprint plus Ti1/Coil1 night project, and `dive_light_1` uses Signal-Reef knowledge plus Ti1/Coil1/Gel1. Historical pass docs may retain the retired scanner purchase as a snapshot, but #927 and the generated progression graph supersede that wording.
- Salvage map data may include optional `tier` values. Missing tiers default conceptually to `common`; the current supported tiers are `common` and `valuable`. Runtime salvage score is tier-derived for now: `common` is worth 100 and `valuable` is worth 300, and pickup status feedback names the tier and score. Completed expeditions add a small runtime oxygen bonus of 1 point per remaining oxygen second; failed expeditions receive no oxygen bonus.
- Held salvage capacity is 2 pickups by default and 3 after the session `Cargo +1` upgrade. Full cargo blocks additional collection without hiding or banking the blocked pickup, shows a compact return-to-extraction status prompt, and returning to extraction frees capacity.
- Run completion shows a compact result panel that now orders objective/payoff text before route and score bookkeeping, then shows score, salvage score, oxygen bonus, current map session-best score, salvage banked, progression/wallet, oxygen, and retry prompt. Maps with `primary_route_objective_id` complete after the primary objective's required salvage is banked and returned to extraction; maps without it preserve all-salvage completion. Route-tagged production-slice completions summarize the strongest banked route as `Route: Deep route` or `Route: Safe route`; Pass 26 adds `Final dive signal locked` when the final-dive result is present, while failed/reset states suppress stale success text. Oxygen depletion shows the same result panel as a failed expedition with zero oxygen bonus and pauses the run until reset without overwriting session best. The panel stays hidden during normal exploration.
- Combat is intentionally narrow: one 3-health territorial eel, one short-range shock prod, separate 3-point player health, and no automatic enemy reward. The guarded cache accepts normal timed-salvage attempts; active eel contact and knockback interrupt progress until the encounter is controlled. There is still no inventory screen, broad arsenal, armor, ammo, combat economy, or general enemy ecosystem.
- Background art is still rough and secondary to proving terrain readability.
- Normal preview uses approved current-prototype sprite assets for salvage and hazard props, with procedural fallback if a sprite cannot be loaded.
- `valuable` salvage renders with a small extra gold cue over the existing salvage prop; `common` or omitted tiers keep the existing prop appearance.
- The first controlled visual-revision target landed as #70 and was reviewed under #71. It adds `assets/props/` sprites generated by `tools/generate_prop_sprites.py`, keeps map data, collision, behavior, and debug markers unchanged, updates accepted baselines for slices 02-04, and leaves slice 01 baseline reconciliation to #75. #75 later reconciled slice 01 to the current six-view default-slice baseline.
- The second controlled visual-revision target is the player placeholder. #77 added `assets/player/player_diver_01.png`, `tools/generate_player_sprite.py`, `references/asset_reviews/player_sprite_01_review.png`, and updated `scenes/player/Player.tscn` without changing the player collision shape, movement controller, camera behavior, light cone, map data, or gameplay logic. #78 accepted the sprite and refreshed accepted baselines for slices 01-04.
- The third controlled visual-revision target is the top-water boat entry visual. #85 added `assets/vehicles/boat_spawn_01.png`, `tools/generate_boat_spawn_sprite.py`, `references/asset_reviews/boat_spawn_01_review.png`, and renderer integration in `scripts/world/greybox_world.gd` without changing maps, boat entry/extraction source semantics, collision, player spawn, movement, camera behavior, or gameplay logic. #86 accepted the sprite and refreshed the accepted `production_slice_01` baseline. #87 verified the public Web preview against deployed build metadata.
- `--capture-player-readability` writes `visual_captures/player_readability/production_slice_01_player_start.png` as the close default-slice review shot for the player sprite pass.
- The source map/grid and entity review markers can be shown with `--show-debug-overlay`; dedicated production-slice debug captures are written with `--capture-production-slice-debug-map` to `visual_captures/production_slice_01_debug/`.
- Debug marker roles are: cyan source grid, white route rectangles, amber boat/extraction outlines, green entry/spawn labels, yellow salvage diamonds, and red hazard squares.
- `production_slice_01` now has six authored camera captures: overview, entry shaft, first route choice, central crossing, lower loop, and return-to-boat context. Use `--quit-after 20` when regenerating this set so every view is written.

## Recommended Next Work

Use #1167 for a short player re-test of the corrected Expansion 17 journey on exact runtime `075a450`. Do not create Expansion 18 work until that gate records GO or a new bounded HOLD. #52/#53 remain deferred rather than becoming the default next work.

Accepted constraints for next work:

- Keep the implemented held-cargo strip, selectable active tools, persistent vitals/objectives, and temporary prompts as distinct HUD responsibilities; a broad production HUD replacement remains directional.
- Keep `production_level_01` as the default preview map unless a separate reviewed decision changes it.
- Preserve `maps/full_cave_sketch_01.greybox.json` as the generated topology draft and source for a separately named `production_level_01` output.
- Preserve the complete full-sketch topology as one contiguous level. Do not stitch crop JSONs together or import their artificial edge seals.
- Keep map topology, collision, spawn, extraction, and camera tests source-driven.
- Transform the proven slice-01 gameplay overlay through shared source data; do not copy generated JSON by hand.
- Preserve the blueprint-and-material scanner project, same-map east-pocket anomaly, explicit returned cutter plan, daylight, surface oxygen, repeated sorties, boat return, night transition, seeded material ownership, canonical-boat commitment, and mandatory fins/cutter/weapon chain.
- Omit prompted connectors and map transitions from normal full-level traversal. Preserve Expansion 14's source-authored advanced stabilizer current as a passive regional boundary inside continuous water; legacy slice behavior remains a protected reference surface, not the canonical prerequisite owner.
- Keep standard capability gates inside contiguous authored geography and traversable through movement; reserve `E` connectors for explicit exceptional entrances/interiors.
- Preserve Expansion 16's far-west/lower-left journey and source-authored confined-wreck oxygen zone as a completed regression surface. Its rebreather remains route-local; the session `O2 tank +15` does not substitute for the durable project.
- Keep Expansion 17 inside existing contiguous geography with no terrain change. Its two physical transponders reuse already-earned capabilities, commit separately at the boat, and combine through one automatic exact-once night comparison; lead selection guides but never locks either target.
- Preserve the completed mineral research, fresh-day selection, and broad habitat-lead behavior as the practical-knowledge regression surface.
- Preserve separate health, the source-authored eel territory, viable unarmed evasion, non-circular shock-prod project, day-local defeat, and no-reward combat semantics.
- Night consumes no Food, Water, Power, or other survival tax.
- Keep future resource and encounter variation inside authored candidates; never reroll geography or required progression arbitrarily.
- Do not add shortcut or fast-travel networks.
- Preserve the completed biological-resource-to-equipment proof and the bounded optional daily-condition proof; do not turn either into a creature catalog, ecosystem simulation, grind, or arbitrary progression variation.
- Keep #52/#53 as optional post-baseline slice-03 improvement issues unless the selected goal shifts back to slice-03 presentation.

Keep new work small. If a task touches visual style, map topology, renderer behavior, and gameplay at once, split it into separate issues.

## Project Instructions For Future Sessions

Use this as the short project instruction text if moving context into a ChatGPT Project:

```text
This project is for oceangame2, a Godot 4.7 side-view ocean salvage visual prototype.

Prioritize visual consistency, map/source-of-truth discipline, GitHub issue workflow, and small scoped implementation passes. Before making changes, read AGENTS.md, docs/current/PROJECT_CONTEXT.md, and relevant current docs. Use GitHub issues for actionable work. Do not regenerate the whole visual scene to fix one visual issue. For terrain/map changes, update source data or renderer first, then verify with screenshots/web preview.
```

