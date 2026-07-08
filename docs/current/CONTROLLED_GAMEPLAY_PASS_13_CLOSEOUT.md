# Controlled Gameplay Pass 13 Closeout

Date: 2026-07-08

Issue: #245 `Add Pass 13 closeout and next-step evaluation`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_13_PLAN.md`

## Decision

Controlled Gameplay Pass 13 is complete.

The pass turned the existing lower-loop/deep-cache chain into one source-authored expedition objective on the default `production_slice_01` slice. The selected objective, `deep_cache_route_objective`, is complete only when the player banks both `salvage_lower_loop` and `salvage_deep_right_cache` during the run.

This adds a clearer retry target and route-commitment read without adding a quest log, inventory, economy, enemies, procedural generation, save files, full-map productionization, or broad art replacement.

## What Landed

- #236 planned the pass around one route commitment objective.
- #237 documented the selected route chain, source/runtime boundaries, and deferred non-goals.
- #238 added first-class `route_objectives` metadata validation to `docs/MAP_SPEC.md` and `tools/validate_greybox_map.py`.
- #239 authored `deep_cache_route_objective` through `tools/create_production_slice_map.py`.
- #240 added compact runtime overlay/result feedback through `scripts/main/route_commitment_feedback.gd`.
- #241 added deterministic smoke coverage with `--smoke-pass-13-route-commitment` and CI coverage.
- #242 added focused capture support with `--capture-pass-13-route-commitment` and the review artifact `visual_captures/pass_13_route_commitment/production_slice_01_route_commitment.png`.
- #243 reviewed visual impact and recorded that no accepted production-slice baseline changes were needed.
- #244 verified the public Web preview for deployed runtime commit `b7b19811de09678d5b3bf6c2da161109a8453682`.

## Stable Areas

The pass preserved:

- `production_slice_01` as the default preview map
- terrain topology, collision, boat spawn, extraction, and camera tests
- safe/deep route metadata and route outcome behavior
- timed salvage at `salvage_deep_right_cache`
- cargo capacity, salvage scoring, oxygen bonus, banking, and retry semantics
- hazard pressure, hazard reset, and oxygen failure cleanup
- Pass 12 oxygen/rest pocket behavior
- production slices 02-04 as reference slices
- accepted visual baselines for production slices 01-04

## Verification

Representative verification completed across the pass:

```powershell
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-13-route-commitment
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-safe-deep-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-timed-salvage
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-cargo-capacity
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-12-oxygen-rest-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-13-route-commitment
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha b7b19811de09678d5b3bf6c2da161109a8453682
python tools/check_file_lengths.py
git diff --check
```

GitHub Actions status:

- Godot Smoke covers the Pass 13 route-commitment smoke after #241.
- Godot Web Export succeeded for deployed runtime commit `b7b19811de09678d5b3bf6c2da161109a8453682`.
- Visual baseline review confirmed no accepted baseline changes were needed.

## Remaining Goal Gaps

The prototype is still intentionally narrow:

- the route objective is source-authored and tracked, but there is not yet a clear start-of-run objective cue before the player makes progress
- route scale is still being proven one small source-authored beat at a time
- there is no economy, upgrades, inventory screen, enemy behavior, save system, procedural generation, or full-map productionization
- `scripts/main/main.gd`, `scripts/world/greybox_world.gd`, and `docs/current/PROJECT_CONTEXT.md` remain file-length refactor debt

## Recommendation

Next work should make the selected objective clearer before the dive rather than adding more map scale.

Recommended Pass 14 direction:

```text
Plan one compact start-of-run objective cue at the boat/extraction area using the existing `route_objectives` metadata, then protect it with smoke, focused capture, visual review, and Web verification.
```

Keep this as a controlled pass. Do not add a quest log, objective selection screen, economy, upgrades, inventory, enemies, saves, procedural generation, broad art replacement, or full-map productionization. Keep #52/#53 deferred unless slice-03 presentation becomes the selected goal.

## Current Issue State

After #245 closes, the Pass 13 queue is complete. Issues #52 and #53 remain open as deferred optional slice-03 polish. The next issue batch should start with a focused Pass 14 plan before source/runtime implementation.
