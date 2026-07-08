# Controlled Gameplay Pass 07 Closeout

Date: 2026-07-08

Issues: #170-#179
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_07_PLAN.md`

## Result

Controlled Gameplay Pass 07 is complete. The default `production_slice_01` slice now has one source-authored hazard/navigation pressure beat on the lower-loop route toward the timed deep-cache payoff.

The pass stayed inside the source-of-truth workflow:

- the selected segment was documented before implementation
- the route-pressure marker was authored in the production-slice generator
- no terrain topology, collision, spawn, extraction, or camera-test geometry changed
- hazard behavior reused the existing warning/contact/reset semantics
- the selected hazard gained compact route-specific feedback without adding combat, health, enemies, tools, inventory, economy, procedural maps, or broad art replacement
- deterministic smoke, focused capture, normal baseline review, and public Web verification all completed before closeout

## What Landed

- #170 planned Pass 07 around one authored hazard/navigation pressure pattern.
- #171 selected `lower_loop_to_deep_cache_pressure` from `salvage_lower_loop` through `hazard_right_branch` toward `salvage_deep_right_cache`.
- #172 documented warning, contact, salvage, cargo, timed-salvage, oxygen, and route-outcome rules.
- #173 added the source-driven `lower_loop_to_deep_cache_pressure` marker and regenerated the JSON/SVG source outputs.
- #174 tuned the selected route hazard prompt to `Hazard ahead - keep clear` while keeping generic hazards unchanged.
- #175 added deterministic `--smoke-pass-07-hazard-route-pressure` coverage.
- #176 added focused `--capture-pass-07-hazard-pressure` review capture output.
- #177 accepted only the intentional production-slice-01 marker visual impact after comparison review.
- #178 verified the public Web preview. The behavior-changing runtime work deployed at `1b90187a55c9d0c0baa11a46f35288b5d81c02ce`; the final source-state build metadata later advanced to `99d5fff60e388f9c58ab26a797f617366cfbb509` after adding the missing Godot `.uid` sidecar for the Pass 07 smoke helper.
- #179 recorded this closeout and next-step evaluation.

## Current Prototype State

The default slice now supports:

- source-authored safe/deep route metadata
- one valuable timed salvage target, `salvage_deep_right_cache`
- cargo capacity pressure and banking
- oxygen drain, refill, failure, completion bonus, and route outcome result text
- generic hazard warning and oxygen-penalty reset behavior
- one authored route-pressure marker, `lower_loop_to_deep_cache_pressure`
- route-specific hazard warning text for `hazard_right_branch`
- deterministic smokes for safe/deep route choice, timed salvage, generic hazard pressure, and the Pass 07 route-pressure segment
- focused review captures for route outcome, timed salvage, and Pass 07 hazard pressure
- accepted normal visual baseline impact and public Web deployment metadata checks

## Stable Areas

Pass 07 did not intentionally change:

- terrain topology or collision
- player movement, collision shape, facing, or camera behavior
- boat spawn, extraction, or map selection behavior
- salvage scoring, cargo capacity, banking, or result-panel semantics
- timed-salvage duration, cancel rule, completion rule, or affordance art
- production slices 02-04
- broad terrain, prop, player, boat, or background art

## Verification

Local verification included:

```powershell
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
--smoke-pass-07-hazard-route-pressure
--smoke-hazard-pressure
--smoke-oxygen-pressure
--smoke-timed-salvage
--smoke-safe-deep-route-choice
--smoke-route-outcome-result
--capture-pass-07-hazard-pressure
--capture-production-slice-map
--capture-production-slice-debug-map
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 99d5fff60e388f9c58ab26a797f617366cfbb509
python tools/check_file_lengths.py
git diff --check
```

GitHub verification:

- Godot Web Export run `28916261068`: success for deployed runtime commit `1b90187`.
- Godot Smoke run `28916261027`: success for deployed runtime commit `1b90187`.
- Godot Smoke run `28916414980`: success for accepted visual-baseline commit `b62ab12`.
- Godot Web Export run `28916764273`: success for final `.uid` sidecar source-state commit `99d5fff`.
- Godot Smoke run `28916764245`: success for final `.uid` sidecar source-state commit `99d5fff`.

## Remaining Goal Gaps

- the default playable space is still one focused slice
- the hazard pattern is one authored route beat, not a broader navigation language
- timed salvage is one authored interaction, not a general tool system
- score exists, but there is no economy, upgrades, inventory, or persistent progression
- art is readable prototype art, not final production art
- `scripts/main/main.gd`, `scripts/world/greybox_world.gd`, and `docs/current/PROJECT_CONTEXT.md` remain file-length allowlist debt
- #52 and #53 remain deferred optional slice-03 polish unless slice-03 presentation becomes the selected goal

## Recommended Next Direction

Recommended next pass: begin cautious route-scale expansion from the source workflow.

The next pass should add one small playable route extension, connector, or return-loop beat that proves the production-slice workflow can grow without losing validation, visual consistency, or authored-route readability. This should not mean full-map productionization yet.

Keep the pass small:

- preserve `production_slice_01` as the default preview map until a separate default-preview decision changes it
- start with a planning/segment-selection issue before changing map data
- update generator/source data first, then regenerate JSON/SVG and validate reachability/parity
- keep camera captures and baselines controlled
- preserve the existing timed-salvage and hazard-pressure behaviors
- avoid economy, upgrades, inventory, enemies, procedural generation, save files, broad art replacement, or full-sketch conversion
- keep #52 and #53 deferred unless slice-03 presentation becomes the selected goal

If route-scale expansion proves too large for one pass, split it into a planning issue plus one tiny source-authored connector pass before adding new gameplay behavior.
