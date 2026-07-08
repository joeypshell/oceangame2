# Controlled Gameplay Pass 05 Closeout

Date: 2026-07-08

Issues: #150-#159
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_05_PLAN.md`

## Result

Controlled Gameplay Pass 05 is complete. The default `production_slice_01` loop now has one authored timed salvage interaction without expanding into economy, upgrades, enemies, procedural maps, save files, inventory screens, multi-tool systems, broad art replacement, or map-scale expansion.

The pass stayed inside the source-of-truth workflow:

- timed salvage metadata is authored in generated map JSON
- schema rules live in `docs/MAP_SPEC.md` and `tools/validate_greybox_map.py`
- runtime behavior reads salvage metadata instead of scene-local hand edits
- deterministic smoke coverage exercises collection, cancel, cargo, banking, hazard reset, and oxygen reset behavior
- focused capture and baseline review checked visual impact without accepting terrain/player/boat/prop/camera drift
- public Web preview was verified against deployed build metadata

## What Landed

- #150 planned Pass 05 around one timed salvage interaction.
- #151 added salvage interaction metadata to the map spec and validator.
- #152 implemented `timed_salvage` runtime behavior.
- #153 authored `salvage_deep_right_cache` as the timed valuable target in `production_slice_01`.
- #154 added deterministic `--smoke-timed-salvage` coverage and CI wiring.
- #155 added `--capture-timed-salvage` focused review capture.
- #156 reviewed visual impact and accepted only the focused timed-salvage state.
- #157 verified the public Web preview for deployed commit `0a412bf82d0cf329bd9ea4e8ad032bfa5b2c66c9`.
- #158 recorded this closeout.
- #159 reduced `main.gd` growth risk by extracting capture and smoke helpers, plus file-length audit tooling.

## Current Prototype State

The default slice now supports:

- source-authored safe/deep route metadata
- route outcome result text
- cargo capacity pressure and banking
- oxygen drain, refill, failure, and completion bonus
- hazard warning and oxygen penalty/reset
- one valuable timed salvage target with compact progress text
- deterministic smokes for timed salvage, route choice, cargo, oxygen, hazards, scoring, route outcome, player facing, movement feel, and slice routes
- focused capture for timed-salvage review
- public Web deployment metadata checks

The timed target is:

```text
id: salvage_deep_right_cache
interaction: timed_salvage
interaction_seconds: 2.5
interaction_label: deep cache
```

Moving out of range cancels timed progress back to zero. Completed timed salvage enters held cargo only if cargo has room; cargo-full checks do not delete the target.

## Verification

Local verification:

```powershell
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
python tools/check_file_lengths.py
git diff --check
```

Godot local smokes:

```powershell
--smoke-salvage-loop
--smoke-cargo-capacity
--smoke-oxygen-pressure
--smoke-hazard-pressure
--smoke-route-outcome-result
--smoke-safe-deep-route-choice
--smoke-timed-salvage
```

GitHub verification:

- Godot Smoke run `28911760512`: success.
- Godot Web Export run `28911760531`: success.
- Public preview matched build SHA `0a412bf82d0cf329bd9ea4e8ad032bfa5b2c66c9`.

## Remaining Goal Gaps

The prototype still has meaningful gaps before it feels like a fuller OceanGame-style salvage loop:

- the default playable space is still one focused slice
- timed salvage is one authored interaction, not a full tool system
- hazards are still pressure/reset markers, not encounter patterns
- score exists, but there is no economy, upgrades, inventory, or persistent progression
- art is readable prototype art, not final production art
- `scripts/main/main.gd` and `scripts/world/greybox_world.gd` remain temporary file-length refactor debt

## Recommended Next Direction

The next pass should build on the timed-salvage result with another small meaningful pressure point before map-scale expansion.

Recommended options, in order:

1. Improve the timed interaction into a clearer tool-like moment with better in-world affordance and cancellation feedback.
2. Add one authored hazard/navigation pressure pattern that creates a route timing decision without enemies or broad systems.
3. Only after one more interaction/pressure pass, evaluate cautious route-scale expansion.

Keep #52 and #53 deferred unless slice-03 presentation becomes the selected goal.
