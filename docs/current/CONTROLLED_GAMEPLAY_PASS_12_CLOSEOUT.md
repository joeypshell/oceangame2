# Controlled Gameplay Pass 12 Closeout

Date: 2026-07-08

Issue: #233 `Add Pass 12 closeout and next-step evaluation`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_12_PLAN.md`

## Decision

Controlled Gameplay Pass 12 is complete.

The pass added one source-authored oxygen/rest route-pressure opportunity in the default `production_slice_01` slice. The selected marker, `lower_loop_oxygen_rest_pocket`, now gives compact `Rest pocket +oxygen` feedback and slowly recovers oxygen up to a limited cap while the player remains in the pocket.

This makes the lower-loop return corridor more readable as a remembered place and a small pressure-management decision, while preserving the existing salvage, cargo, hazard, route outcome, banking, reset, visual baseline, and public Web preview workflows.

## What Landed

- #224 planned the pass around one source-authored oxygen/rest route-pressure opportunity.
- #225 documented the selected source marker, route context, cap, refill rate, and source/runtime boundaries.
- #226 added first-class oxygen-rest metadata validation to `docs/MAP_SPEC.md` and `tools/validate_greybox_map.py`.
- #227 authored `lower_loop_oxygen_rest_pocket` through `tools/create_production_slice_map.py`.
- #228 added compact runtime feedback through `scripts/main/oxygen_rest_pocket_feedback.gd`.
- #229 added deterministic smoke coverage with `--smoke-pass-12-oxygen-rest-pressure`.
- #230 added focused capture support with `--capture-pass-12-oxygen-rest-pressure`.
- #231 reviewed and accepted the intentional visual difference: the subtle Pass 12 rest-pocket marker.
- #232 verified the public Web preview for deployed runtime commit `fbcf63dcfc54e7d6481618d74fd67709da097ddb`.

## Stable Areas

The pass preserved:

- `production_slice_01` as the default preview map
- terrain topology, collision, boat spawn, extraction, and camera tests
- safe/deep route metadata and route outcome behavior
- timed salvage at `salvage_deep_right_cache`
- hazard pressure around `hazard_right_branch`
- southwest pocket payoff and pre-pickup cue behavior
- return-pressure behavior at `salvage_return_branch`
- cargo capacity, scoring, hazard reset, banking, and retry semantics
- production slices 02-04 as reference slices
- broad terrain, player, boat, prop, and background art direction

## Verification

Representative verification completed across the pass:

```powershell
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-12-oxygen-rest-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-safe-deep-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-timed-salvage
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-12-oxygen-rest-pressure
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha fbcf63dcfc54e7d6481618d74fd67709da097ddb
python tools/check_file_lengths.py
git diff --check
```

GitHub Actions status:

- Godot Smoke covers the Pass 12 oxygen-rest smoke after #229.
- Godot Web Export succeeded for deployed runtime commit `fbcf63dcfc54e7d6481618d74fd67709da097ddb`.
- Local source, smoke, capture, baseline, and Web preview verification passed.

## Remaining Goal Gaps

The prototype is still intentionally narrow:

- the rest pocket is one limited pressure-management beat, not a general oxygen-station network
- route scale is still being proven one source-authored beat at a time
- there is no economy, upgrades, enemies, inventory screen, save system, procedural generation, or full-map productionization
- `scripts/main/main.gd`, `scripts/world/greybox_world.gd`, and `docs/current/PROJECT_CONTEXT.md` remain file-length refactor debt

## Recommendation

Next work should turn the accumulated route beats into one clearer reason to attempt a run again before adding more map scale.

Recommended Pass 13 direction:

```text
Plan one source-authored expedition objective or retry target on production_slice_01 using existing salvage, route metadata, oxygen pressure, overlay/result text, smoke, focused capture, visual review, and Web verification.
```

Keep this as one controlled pass. A good target would name or evaluate one existing route chain without adding economy, upgrades, enemies, inventory, save files, procedural generation, full-map productionization, or broad art replacement. Keep #52/#53 deferred unless slice-03 presentation becomes the selected goal.

## Current Issue State

After #233 closes, the Pass 12 queue is complete. Issues #52 and #53 remain open as deferred optional slice-03 polish. The next issue batch should start with a focused Pass 13 plan before source/runtime implementation.
