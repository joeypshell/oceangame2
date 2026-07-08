# Controlled Gameplay Pass 11 Closeout

Date: 2026-07-08

Issue: #222 `Add Pass 11 closeout and next-step evaluation`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_11_PLAN.md`

## Decision

Controlled Gameplay Pass 11 is complete.

The pass added one source-authored pre-pickup route-readability cue in the default `production_slice_01` slice. The selected marker, `southwest_pocket_pre_pickup_cue`, now shows compact `Optional pocket ahead` feedback before the player collects `salvage_southwest_return_cache`.

This makes the southwest pocket feel intentional before the payoff fires, while preserving the existing instant salvage, cargo, oxygen, hazard, route outcome, banking, reset, visual baseline, and public Web preview workflows.

## What Landed

- #213 corrected stale current-state issue text after the Pass 10 follow-ups.
- #214 planned Pass 11 around one pre-pickup route-readability cue.
- #215 documented the selected source marker, target, condition, and route context.
- #216 authored `southwest_pocket_pre_pickup_cue` through `tools/create_production_slice_map.py`.
- #217 added compact runtime feedback through `scripts/main/pre_pickup_route_cue_feedback.gd`.
- #218 added deterministic smoke coverage with `--smoke-pass-11-pre-pickup-route-cue`.
- #219 added focused capture support with `--capture-pass-11-pre-pickup-route-cue`.
- #220 reviewed and accepted the intentional visual difference: the subtle Pass 11 cue marker.
- #221 verified the public Web preview for deployed runtime commit `4231d5fa8760840452acb9cdb3581f4199c74b95`.

## Stable Areas

The pass preserved:

- `production_slice_01` as the default preview map
- terrain topology, collision, boat spawn, extraction, and camera tests
- safe/deep route metadata and route outcome behavior
- timed salvage at `salvage_deep_right_cache`
- hazard pressure around `hazard_right_branch`
- southwest pocket payoff behavior after collection
- return-pressure behavior at `salvage_return_branch`
- cargo capacity, scoring, oxygen, hazard reset, banking, and retry semantics
- production slices 02-04 as reference slices
- broad terrain, player, boat, prop, and background art direction

## Verification

Representative verification completed across the pass:

```powershell
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-11-pre-pickup-route-cue
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-09-southwest-pocket-decision
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-10-return-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-safe-deep-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-11-pre-pickup-route-cue
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 4231d5fa8760840452acb9cdb3581f4199c74b95
python tools/check_file_lengths.py
git diff --check
```

GitHub Actions status:

- Godot Smoke covers the Pass 11 cue smoke after #218.
- Godot Web Export succeeded for deployed runtime commit `4231d5fa8760840452acb9cdb3581f4199c74b95`.
- Local source, smoke, capture, baseline, and Web preview verification passed.

## Remaining Goal Gaps

The prototype is still intentionally narrow:

- the pre-pickup cue is a readability beat, not a broad tutorial or HUD system
- route scale is still being proven one source-authored beat at a time
- there is no economy, upgrades, enemies, inventory screen, save system, procedural generation, or full-map productionization
- `scripts/main/main.gd`, `scripts/world/greybox_world.gd`, and `docs/current/PROJECT_CONTEXT.md` remain file-length refactor debt

## Recommendation

Next work should add one small gameplay-meaningful expedition decision before map-scale expansion.

Recommended Pass 12 direction:

```text
Plan one source-authored oxygen/rest or route-pressure opportunity that uses existing oxygen, map metadata, compact feedback, smoke, focused capture, visual review, and Web verification.
```

Keep this as one controlled pass. Do not expand into economy, upgrades, enemies, inventory, save files, procedural generation, full-map productionization, or broad art replacement. Keep #52/#53 deferred unless slice-03 presentation becomes the selected goal.

## Current Issue State

After #222 closes, the Pass 11 queue is complete. Issues #52 and #53 remain open as deferred optional slice-03 polish. The next issue batch should start with a focused Pass 12 plan before source/runtime implementation.
