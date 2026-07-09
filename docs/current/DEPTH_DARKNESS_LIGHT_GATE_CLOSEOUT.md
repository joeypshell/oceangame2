# Depth Darkness Light Gate Closeout

Date: 2026-07-09

Issues: #462-#470
Milestone: Simple Diver Game 07 `Presentation And Game Feel`

## Decision

The first darkness/light gate pass is complete.

The default slice now has one source-authored visual-only dark pocket on the deep-cache route. The player can enter it before buying `Light +range`, but the area reads darker. Buying `dive_light_1` makes that same pocket easier to read by reducing the local darkness overlay while preserving movement, collision, oxygen, cargo, objective, salvage, scoring, and hazard semantics.

Darkness should remain visual-only for now. A later hard gate should require a separate design issue with a specific player-facing reason.

## Implemented Work

- #462 added visibility-zone metadata validation.
- #463 authored `deep_cache_dark_pocket` through the production-slice source/generator path.
- #464 rendered the visual-only darkness zone in runtime.
- #465 connected `dive_light_1` to improved readability in that zone.
- #466 added deterministic `--smoke-darkness-light-gate` coverage and CI wiring.
- #467 added focused before/after captures:
  - `visual_captures/darkness_light_gate/production_slice_01_darkness_light_before_light.png`
  - `visual_captures/darkness_light_gate/production_slice_01_darkness_light_after_light.png`
- #468 recorded the visual baseline decision:
  - `docs/current/DEPTH_DARKNESS_LIGHT_GATE_VISUAL_BASELINE_DECISION.md`
- #469 verified the public Web preview:
  - `docs/current/DEPTH_DARKNESS_LIGHT_GATE_WEB_PREVIEW_VERIFICATION.md`

## Source And Runtime Boundaries

- The zone is source-authored marker metadata, not hand-placed scene geometry.
- The first implementation is not a hard lock, fog-of-war system, damage zone, enemy/stealth system, or inventory/loadout feature.
- `production_slice_01` remains the default preview map.
- #52 and #53 remain deferred optional slice-03 polish.

## Validation

Key commands run during the pass:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
python tools/manage_production_slice_baseline.py compare-all
python tools/manage_production_slice_baseline.py check-clean --all-slices
node tools/check_web_preview.cjs https://joeypshell.github.io/oceangame2/ --expected-sha eb09665b6dd7c6a1c5120a300e7af037dbbf1cd4
```

Runtime/smoke coverage includes:

- `--smoke-darkness-light-gate`
- `--smoke-pass-20-light-upgrade`
- `--smoke-production-slice-route`
- `--smoke-player-facing`
- GitHub `Godot Smoke` on PRs that changed runtime/capture code

Closeout checks:

```powershell
python tools/check_file_lengths.py
git diff --check
```

## Visual Decision

No production-slice accepted baseline changes were needed.

Normal production-slice captures for slices 01-04 remain clean against accepted baselines. The darkness/light before/after captures are focused review artifacts only.

## Remaining Gaps

- The dark pocket is one local readability treatment, not a broad lighting art pass.
- There is no darkness damage, hard route lock, scan/reveal mechanic, or multi-zone darkness tuning.
- The light upgrade is still session-only and in-memory.
- The project still needs a selected next presentation/game-feel micro-pass rather than another automatic expansion step.

## Recommended Next Direction

Use #471 to plan the next small Presentation And Game Feel micro-pass.

Prefer a player-facing polish step that improves moment-to-moment feel in the existing default slice, such as compact audio/feedback planning, pickup/banking feel, hazard readability, or terrain/prop readability. Avoid full enemies, broad inventory/loadouts, procedural generation, save systems, broad economy work, another connector just because the first one works, and full-map productionization.
