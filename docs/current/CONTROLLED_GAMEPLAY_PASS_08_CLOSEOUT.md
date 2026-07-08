# Controlled Gameplay Pass 08 Closeout

Date: 2026-07-08

Issue: #190 `Add Pass 08 closeout and next-step evaluation`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_08_PLAN.md`

## Decision

Controlled Gameplay Pass 08 is complete.

The pass proved that `production_slice_01` can grow by one tiny source-authored route segment without switching the default map, hand-editing Godot geometry, or destabilizing the existing timed-salvage and hazard-pressure beats.

## What Landed

- #180 planned the pass around cautious route-scale expansion.
- #181 selected `southwest_return_pocket_extension` near the lower-loop return pocket.
- #182 documented source rules for route-scale edits.
- #183 added the source marker through `tools/create_production_slice_map.py`.
- #184 opened one small connected alcove through the generator/source path.
- #185 added one common salvage cue, `salvage_southwest_return_cache`.
- #186 added deterministic smoke coverage with `--smoke-pass-08-route-extension`.
- #187 added focused capture support with `--capture-pass-08-route-extension`.
- #188 reviewed and accepted the intentional visual baseline differences.
- #189 verified the public Web preview for deployed runtime commit `722837d2d35b4c904f90a475c1251f533d2468ec`.

## Stable Areas

The pass preserved:

- `production_slice_01` as the default preview map
- boat spawn, extraction, and return-to-boat behavior
- safe/deep route metadata and route outcome text
- timed salvage at `salvage_deep_right_cache`
- Pass 07 `hazard_right_branch` pressure route
- cargo capacity, scoring, oxygen, reset, and banking semantics
- production slices 02-04 as reference slices
- broad terrain, player, boat, prop, and background art direction

## Verification

Representative verification completed across the pass:

```powershell
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-08-route-extension
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-safe-deep-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-timed-salvage
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-pressure
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 722837d2d35b4c904f90a475c1251f533d2468ec
python tools/check_file_lengths.py
git diff --check
```

GitHub Actions status:

- Godot Web Export for deployed Pass 08 runtime: success.
- Godot Smoke for deployed Pass 08 runtime: success.
- Godot Smoke for visual-baseline acceptance commit: success.

## Remaining Goal Gaps

The prototype is still deliberately narrow:

- route scale is proven one segment at a time, not across the full sketch
- the new route-extension payoff is still a simple common salvage cue
- there is no economy, inventory, upgrade, enemy, save, or procedural system
- the larger supplied full-map sketch remains a topology/planning source, not a production map
- `scripts/main/main.gd`, `scripts/world/greybox_world.gd`, and `docs/current/PROJECT_CONTEXT.md` remain file-length refactor debt

## Recommendation

Next pass should deepen the new route, not add another connector yet.

Recommended Pass 09 direction:

```text
Make the southwest return pocket matter as one small authored route decision using existing systems.
```

Good candidates:

- add route metadata/result language for the pocket without broad UI changes
- tune one source-authored payoff or return cue so the detour has a clearer reason to exist
- add deterministic smoke/capture coverage for that decision

Avoid starting full-map productionization, economy, upgrades, enemies, inventory, save files, or broad art replacement. Keep #52/#53 deferred unless slice-03 presentation becomes the selected goal.

## Current Issue State

After #190 closes, the Pass 08 queue is complete. Only #52 and #53 should remain open as deferred optional slice-03 polish unless new Pass 09 issues are created.
