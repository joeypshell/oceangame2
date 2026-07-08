# Controlled Gameplay Pass 09 Closeout

Date: 2026-07-08

Issue: #199 `Add Pass 09 closeout and next-step evaluation`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_09_PLAN.md`

## Decision

Controlled Gameplay Pass 09 is complete.

The pass deepened the Pass 08 southwest return pocket into a small authored route decision using existing map metadata, salvage value, compact feedback, deterministic smoke, focused capture, visual baseline review, and public Web verification.

## What Landed

- #191 planned the pass around a southwest pocket route decision.
- #192 documented the route-decision source convention: `validation_route: "southwest_pocket_decision"` and `route_choice_id: "southwest_pocket_detour"`.
- #193 upgraded `salvage_southwest_return_cache` through the generator/source path into a `valuable` payoff tagged to the pocket decision.
- #194 added compact runtime feedback: `Southwest pocket payoff +300`.
- #195 added deterministic smoke coverage with `--smoke-pass-09-southwest-pocket-decision`.
- #196 added focused capture support with `--capture-pass-09-southwest-pocket-decision`.
- #197 reviewed and accepted the intentional visual difference: the existing valuable salvage gold cue on the southwest pocket payoff.
- #198 verified the public Web preview for deployed runtime commit `211ca05ffe3dfef3f13f08359307ef7b5780cf55`.

## Stable Areas

The pass preserved:

- `production_slice_01` as the default preview map
- terrain topology, collision, boat spawn, and extraction behavior
- safe/deep route metadata and route outcome behavior
- timed salvage at `salvage_deep_right_cache`
- Pass 07 hazard pressure around `hazard_right_branch`
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
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-09-southwest-pocket-decision
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-pass-08-route-extension
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-safe-deep-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-timed-salvage
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 10 --capture-pass-09-southwest-pocket-decision
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 211ca05ffe3dfef3f13f08359307ef7b5780cf55
python tools/check_file_lengths.py
git diff --check
```

GitHub Actions status:

- Godot Web Export for deployed Pass 09 runtime: success.
- Godot Web Export for the previous Pass 09 runtime/smoke commit: success.
- Local focused smoke, capture, baseline, and Web preview verification passed.

## Remaining Goal Gaps

The prototype is still intentionally narrow:

- the southwest pocket decision is a stronger payoff/readability beat, not a new interaction system
- the player only sees the pocket's special meaning clearly at collection/result time
- route scale is still being proven one source-authored beat at a time
- there is no economy, inventory, upgrades, enemies, save system, procedural generation, or full-map productionization
- `scripts/main/main.gd`, `scripts/world/greybox_world.gd`, and `docs/current/PROJECT_CONTEXT.md` remain file-length refactor debt

## Recommendation

Next pass should add one more in-run decision using existing systems before expanding map scale.

Recommended Pass 10 direction:

```text
Make return/banking pressure or pre-pickup route readability matter in production_slice_01 without adding a broad new system.
```

Good candidates:

- a small return/banking decision that uses the current two-item cargo limit
- a pre-pickup cue or compact prompt that helps the player read optional detours before collecting them
- deterministic smoke/capture coverage for the chosen decision

Avoid starting full-map productionization, economy, upgrades, enemies, inventory, save files, procedural generation, or broad art replacement. Keep #52/#53 deferred unless slice-03 presentation becomes the selected goal.

## Current Issue State

After #199 closes, the Pass 09 queue is complete. Only #52 and #53 should remain open as deferred optional slice-03 polish unless new Pass 10 issues are created.
