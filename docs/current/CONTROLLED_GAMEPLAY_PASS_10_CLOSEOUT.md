# Controlled Gameplay Pass 10 Closeout

Date: 2026-07-08

Issue: #209 `Add Pass 10 closeout and next-step evaluation`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_10_PLAN.md`

## Decision

Controlled Gameplay Pass 10 is complete.

The pass added one source-authored return/banking pressure beat in the default `production_slice_01` slice. The selected target, `salvage_return_branch`, now uses existing cargo capacity, oxygen, boat extraction, compact feedback, deterministic smoke, focused capture, visual baseline review, and public Web verification to make the return decision readable without adding a new broad system.

## What Landed

- #201 planned the pass around return/banking pressure.
- #202 documented the selected source route segment and metadata convention.
- #203 authored `return_pressure_to_boat` and `salvage_return_branch` metadata through `tools/create_production_slice_map.py`.
- #204 added compact runtime feedback: `Cargo full - bank at boat`.
- #205 added deterministic smoke coverage with `--smoke-pass-10-return-pressure`.
- #206 added focused capture support with `--capture-pass-10-return-pressure`.
- #207 reviewed and accepted the intentional visual difference: the subtle `return_pressure_to_boat` route/review marker.
- #208 verified the public Web preview for deployed runtime commit `977ad13808e63cf3630d67e945de1a3e66aa7f3f`.

## Stable Areas

The pass preserved:

- `production_slice_01` as the default preview map
- terrain topology, collision, boat spawn, and extraction behavior
- safe/deep route metadata and route outcome behavior
- timed salvage at `salvage_deep_right_cache`
- hazard pressure around `hazard_right_branch`
- southwest pocket payoff behavior at `salvage_southwest_return_cache`
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
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-10-return-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-cargo-capacity
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-timed-salvage
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-safe-deep-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-pass-10-return-pressure
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 977ad13808e63cf3630d67e945de1a3e66aa7f3f
python tools/check_file_lengths.py
git diff --check
```

GitHub Actions status:

- Godot Smoke covered the new Pass 10 return-pressure smoke after #205.
- Godot Web Export succeeded for deployed runtime commit `977ad13808e63cf3630d67e945de1a3e66aa7f3f`.
- Local source, smoke, capture, baseline, and Web preview verification passed.

## Remaining Goal Gaps

The prototype is still intentionally narrow:

- the return-pressure beat is one readable cargo/banking prompt, not an economy or inventory system
- pre-pickup route readability is still limited
- route scale is still being proven one source-authored beat at a time
- there is no economy, upgrades, enemies, save system, procedural generation, or full-map productionization
- `scripts/main/main.gd`, `scripts/world/greybox_world.gd`, and `docs/current/PROJECT_CONTEXT.md` remain file-length refactor debt

## Recommendation

Next work should stay small and meaningful before adding map scale.

Recommended Pass 11 direction:

```text
Add one pre-pickup readability or route-commitment beat using existing metadata, overlay feedback, smoke, and focused capture.
```

Good candidates:

- a compact cue before entering an optional detour
- clearer feedback before committing to a valuable pickup route
- one small source-authored marker that helps the player read risk before collecting

Avoid full-map productionization, economy, upgrades, enemies, inventory, save files, procedural generation, or broad art replacement. Keep #52/#53 deferred unless slice-03 presentation becomes the selected goal.

## Current Issue State

After #209 closes, the Pass 10 queue is complete. Issues #210 and #211 are closed follow-up hygiene for the repo drift skill docs and Pass 10 script UID sidecars. The active next batch is Pass 11 pre-pickup route readability; issues #52 and #53 remain open as deferred optional slice-03 polish unless slice-03 presentation becomes the selected goal.
