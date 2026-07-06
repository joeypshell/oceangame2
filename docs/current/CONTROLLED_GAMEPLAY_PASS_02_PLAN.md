# Controlled Gameplay Pass 02 Plan

Date: 2026-07-06

Issue: #110 `Plan Controlled Gameplay Pass 02 route choice and expedition pressure`

## Decision

Controlled Gameplay Pass 02 will make the default prototype loop express one clear route-choice question:

Should the player take the safer nearby salvage and return, or push farther for a more valuable pickup under oxygen pressure?

This is still a small prototype pass. It should prove route choice, expedition pressure, and payoff readability without adding a full economy, inventory, upgrade system, health model, enemies, or new map-production workflow.

## Single Target

Use `production_slice_01` to demonstrate one source-authored risk/reward salvage route.

The intended loop is:

1. Start from the top-water boat entry.
2. See or discover ordinary salvage on the safer route.
3. Notice a distinct high-value salvage pickup on a slightly more demanding route.
4. Choose whether to push for it while oxygen drains.
5. Return to extraction and bank the run.

The pass should make the route choice legible enough to evaluate locally and through deterministic validation.

## Affected Areas

- `docs/current/PROJECT_CONTEXT.md`
- `docs/MAP_SPEC.md`
- `tools/validate_greybox_map.py`
- `scripts/main/main.gd`
- `scripts/world/greybox_world.gd`
- `maps/production_slice_01.greybox.json`
- `tools/create_production_slice_map.py` if the production-slice source must be regenerated from the generator
- `references/greybox/production_slice_01.svg` if source data changes
- production-slice captures and accepted baselines only during the later review issue

## Untouched Areas

- Production slices 02-04 unless validation tooling requires read-only checks across all maps.
- Full-map sketch topology and slice-selection bounds.
- Terrain/collision generation semantics.
- Player movement constants and player collision shape.
- Player, boat, terrain, background, and existing common salvage/hazard sprite art, except for a narrowly scoped high-value salvage marker or variant.
- Camera framing except as part of a later explicit baseline review.
- Public Web preview verification until the final deployment issue.

## Expected Behavior Changes

- Map data can distinguish at least common/default salvage from one higher-value target.
- The high-value target has a readable prototype visual distinction.
- A deterministic route-choice probe can confirm the authored target is reachable, collectible, and returnable.
- Oxygen pressure can be tuned against the accepted movement baseline so the deeper route creates mild pressure without becoming a hard fail-state maze.

## Unacceptable Drift

- Hand-tuning Godot scene geometry instead of updating source data or generator output.
- Regenerating broad visual scenes or replacing unrelated approved assets.
- Changing slice-01 topology beyond the one scoped risk/reward placement unless a follow-up issue explicitly chooses that.
- Folding baseline acceptance or Web preview verification into implementation issues.
- Adding economy, upgrades, inventory UI, enemies, health, stamina, or long-term progression.
- Making #52/#53 active blockers; they remain deferred slice-03 polish.

## Follow-Up Issues

- #111 `Add deterministic route-choice review probe`
- #112 `Tune oxygen pressure thresholds and warning timing`
- #113 `Record oxygen pressure baseline decision`
- #114 `Add salvage value tiers to map schema and validation`
- #115 `Render high-value salvage with distinct prototype marker`
- #116 `Author one risk-reward salvage placement in production slice 01`
- #117 `Validate risk-reward route collection and return`
- #118 `Review and accept route-payoff visual baselines`
- #119 `Verify public Web preview after route-payoff pass`

## Verification Plan

The implementation chain should use targeted checks as each issue lands:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py
python tools/check_asset_manifest.py
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

If visuals change, #118 should run the established capture and baseline-review workflow before accepting any updated baseline.

If runtime-visible changes deploy, #119 should verify public Pages metadata and browser initialization before closing the route/payoff pass.
