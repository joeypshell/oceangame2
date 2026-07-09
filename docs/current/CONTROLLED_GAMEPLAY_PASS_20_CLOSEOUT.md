# Controlled Gameplay Pass 20 Closeout

Date: 2026-07-09

Issue: #409 `Add Pass 20 closeout and next-step evaluation`
Milestone: Simple Diver Game 04 `Progression And Economy Slice`

## Result

Controlled Gameplay Pass 20 is complete.

The default slice now has a third tiny session progression choice: bank salvage, earn session wallet, then buy `Light +range` at extraction for a modestly longer and brighter player light cone during the current app session.

## Implemented Behavior

- Added one session-only light upgrade, `dive_light_1`.
- Purchase is available only at extraction and costs `900` wallet.
- Fresh app launch starts with base light state.
- Retry/reset preserves the purchased light upgrade during the current app session.
- The upgrade changes only the existing player `LightCone` visual:
  - base range scale `1.0`, alpha `0.38`
  - upgraded range scale `1.25`, alpha `0.48`
- Overlay/result feedback stays compact:
  - `L: Light +range (900)`
  - `Light +range upgraded`
  - `Light +range`
  - `Light base`

## Source And Runtime Decisions

- No map source data changed.
- `production_slice_01` topology, collision, spawn, extraction, route objectives, salvage placement, hazards, and camera tests stayed unchanged.
- The light upgrade is runtime/session progression state, not map metadata.
- No persistent save data, store scene, inventory screen, loadout system, darkness damage, enemies, or visibility gate was added.

## Validation

- `--smoke-pass-20-light-upgrade` covers base light state, insufficient funds, purchase spend, upgraded light settings, retry persistence, and independence from oxygen/cargo upgrades.
- Existing Pass 18 and Pass 19 progression smokes remain part of the CI smoke lane.
- PR #415 and PR #416 completed the smoke/capture implementation path.
- PR #418 `Godot Smoke` passed before merge.

## Visual And Web Review

- Focused review capture:
  - `visual_captures/pass_20_light_upgrade/production_slice_01_pass_20_light_upgrade.png`
- Visual baseline decision:
  - `docs/current/PASS_20_LIGHT_UPGRADE_VISUAL_BASELINE_DECISION.md`
  - No production-slice baseline changes were accepted.
- Public Web preview verification:
  - `docs/current/PASS_20_LIGHT_UPGRADE_WEB_PREVIEW_VERIFICATION.md`
  - Deployed runtime/export commit `a86a4f7064cd9d8ca15caa4ad4543603a848ed55` matched public `build_info.json`.
  - Browser preview initialized with no missing-resource, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages.

## Stable Areas

- Terrain topology and collision remain source-driven.
- Accepted production-slice baselines remain unchanged.
- Boat, extraction, player body, salvage props, hazard props, route/objective cues, oxygen-rest feedback, cargo behavior, oxygen behavior, primary objective completion, timed salvage, and pry salvage stayed stable outside the new light-upgrade feedback/effect.
- #52 and #53 remain deferred optional slice-03 polish.

## Remaining Gaps

- Session progression is still in-memory only.
- There is no upgrade menu, save file, broad economy, inventory/loadout system, or multiple light tier system.
- The light upgrade improves route confidence but does not create source-authored dark areas or new route gates.

## Recommended Next Direction

Pass 20 completes the small Milestone 04 progression trio: oxygen capacity, cargo capacity, and light confidence.

The next meaningful batch should move to Milestone 05 world-slice expansion only if it creates a clearer playable route loop, remembered-place progress, or pressure/payoff decision. Keep #52/#53 deferred unless slice-03 presentation becomes the selected Milestone 05 target.
