# Controlled Gameplay Pass 06 Closeout

Date: 2026-07-08

Issues: #160-#169
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_06_PLAN.md`

## Result

Controlled Gameplay Pass 06 is complete. The existing `salvage_deep_right_cache` timed salvage target now reads more clearly as a deliberate in-cave action without adding economy, upgrades, inventory, enemies, procedural maps, save files, broad art replacement, or map-scale expansion.

The pass stayed inside the source-of-truth workflow:

- no terrain topology, collision, spawn, extraction, route marker, or map source changes were made
- the timed interaction still reads existing salvage metadata from `production_slice_01`
- runtime feedback remains compact in the existing overlay
- the in-world affordance is rendered from the timed-salvage entity metadata
- deterministic smoke coverage protects progress, cancel, complete, cargo-full, hazard, and oxygen-reset states
- focused capture, normal baseline review, and public Web verification checked visual impact before closeout

## What Landed

- #160 planned Pass 06 around timed-salvage readability.
- #161 documented feedback state rules.
- #162 added a small in-world timed-salvage affordance marker.
- #163 improved progress feedback with compact percent and bar text.
- #164 added explicit cancel and completion feedback.
- #165 hardened deterministic timed-salvage smoke output.
- #166 regenerated the focused timed-salvage feedback capture.
- #167 accepted the intentional normal lower-loop visual-baseline change.
- #168 verified the public Web preview for deployed runtime commit `2608fc166af07738dc764143365f1a833890b675`.
- #169 recorded this closeout and next-step evaluation.

## Current Prototype State

The default slice now supports:

- source-authored safe/deep route metadata
- route outcome result text
- cargo capacity pressure and banking
- oxygen drain, refill, failure, and completion bonus
- hazard warning and oxygen penalty/reset
- one valuable timed salvage target with an in-world affordance, progress feedback, cancel feedback, completion feedback, smoke coverage, focused capture, and accepted normal-baseline impact
- public Web deployment metadata checks

The timed target remains:

```text
id: salvage_deep_right_cache
interaction: timed_salvage
interaction_seconds: 2.5
interaction_label: deep cache
```

Moving out of range cancels progress back to zero. Cargo-full blocks the timed interaction without collecting or deleting the target.

## Verification

Local verification included:

```powershell
--smoke-timed-salvage
--smoke-salvage-loop
--smoke-cargo-capacity
--smoke-oxygen-pressure
--smoke-hazard-pressure
--smoke-safe-deep-route-choice
--capture-timed-salvage
--capture-route-outcome-result
--capture-production-slice-map
--capture-production-slice-debug-map
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_production_slice_captures.py --fail-on-stale
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha 2608fc1
python tools/check_file_lengths.py
git diff --check
```

GitHub verification:

- Godot Web Export run `28913642138`: success for deployed runtime commit `2608fc1`.
- Godot Smoke run `28913642135`: success for deployed runtime commit `2608fc1`.
- Godot Smoke run `28913735363`: success for focused capture commit `c726441`.
- Godot Smoke run `28913871682`: success for accepted visual-baseline commit `92a9bde`.
- Godot Smoke run `28914103343`: success for Web verification screenshot commit `f6ec3d5`.

## Remaining Goal Gaps

- the default playable space is still one focused slice
- timed salvage is one authored interaction, not a general tool system
- hazards are still warning/reset pressure markers, not authored navigation patterns
- score exists, but there is no economy, upgrades, inventory, or persistent progression
- art is readable prototype art, not final production art
- `scripts/main/main.gd`, `scripts/world/greybox_world.gd`, and `docs/current/PROJECT_CONTEXT.md` remain file-length allowlist debt

## Recommended Next Direction

Recommended next pass: add one authored hazard/navigation pressure pattern in `production_slice_01` that creates a route timing decision without enemies or broad systems.

Keep the pass small:

- preserve `production_slice_01` as the default preview map
- preserve the source-of-truth map workflow
- do not start whole-map productionization yet
- do not expand into economy, upgrades, inventory, enemies, procedural generation, or save files
- keep #52 and #53 deferred unless slice-03 presentation becomes the selected goal

After one authored hazard/navigation pressure pattern, reassess whether the prototype is ready for cautious route-scale expansion.
