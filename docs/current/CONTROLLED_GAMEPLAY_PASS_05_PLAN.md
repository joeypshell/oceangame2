# Controlled Gameplay Pass 05 Plan

Date: 2026-07-07

Issue: #150 `Plan Controlled Gameplay Pass 05 around timed salvage interaction`

Status: Completed as of 2026-07-08. See `docs/current/CONTROLLED_GAMEPLAY_PASS_05_CLOSEOUT.md`.

## Decision

Controlled Gameplay Pass 05 should add one authored timed salvage interaction to the default `production_slice_01` loop.

The target interaction is `timed_salvage`: a valuable salvage pickup that requires the player to stay near it for a short duration before it enters held cargo. The recommended first authored target is `salvage_deep_right_cache` because it is already a valuable `expanded_route_choice` payoff in the deeper route. Making that cache take time adds pressure and payoff without changing the map scale.

The source data should remain authoritative. Runtime behavior, validation, smoke tests, capture, visual review, and Web verification should all flow from the same salvage metadata.

## Target Experience

- The player swims to the deeper valuable cache.
- If cargo has room, the timed interaction starts automatically when the player remains within the existing salvage interaction radius.
- Existing instant salvage remains instant unless source metadata opts into timed behavior.
- Timed progress is short enough for a prototype review, likely around 2 to 3 seconds.
- Progress appears compactly in the existing status overlay, such as `Salvaging valuable cache 65%`.
- Moving out of range cancels progress back to zero for this first pass.
- Oxygen keeps draining while the player holds position away from extraction.
- Completing the timed interaction moves the pickup into held cargo using current tier-derived score semantics.
- Banking at extraction, cargo capacity, run completion, route outcome, and oxygen bonus stay unchanged.
- Hazard hits, oxygen failure, and reset clear any active timed progress. Completed-but-unbanked timed salvage is restored through the existing held-salvage restoration path.

## Meaningful-Change Filter

This pass is worth doing because it creates a first moment-to-moment in-cave verb beyond instant pickup.

- Curiosity: a valuable cache can now feel different from ordinary salvage.
- Pressure: the player spends oxygen while holding position.
- Payoff: the higher-value deep route has a clearer cost.
- Route choice: the safe route stays quick; the deep route asks for time plus return discipline.
- Remembered place: one authored cache becomes a specific interaction location, not just another marker.

This is still intentionally small. It should not become an economy, upgrade, inventory, enemy, procedural, or full-map expansion pass.

## Planned Issue Batch

Recommended implementation order:

1. #150 Plan Controlled Gameplay Pass 05 around timed salvage interaction.
2. #151 Add salvage interaction metadata schema to map spec and validator.
3. #159 Split or guard `main.gd` before further gameplay expansion if runtime work would grow it substantially.
4. #152 Implement timed salvage interaction runtime.
5. #153 Author one timed valuable salvage target in `production_slice_01`.
6. #154 Add deterministic timed-salvage smoke coverage.
7. #155 Add focused timed-salvage review capture.
8. #156 Review and accept Pass 05 timed-salvage visual baseline.
9. #157 Verify public Web preview after Pass 05 timed-salvage pass.
10. #158 Add Pass 05 closeout and next-step evaluation.

If #159 finds the current `main.gd` delegation is already good enough, it can close with verification instead of forcing a refactor.

## Source-Of-Truth Boundaries

Add source schema before runtime behavior depends on it.

Recommended salvage metadata shape:

```json
{
  "id": "salvage_deep_right_cache",
  "type": "salvage",
  "kind": "relic",
  "tier": "valuable",
  "interaction": "timed_salvage",
  "interaction_seconds": 2.5
}
```

Rules for the first pass:

- Missing `interaction` means existing instant salvage.
- Supported values should be narrowly limited to `instant` and `timed_salvage`.
- `interaction_seconds` should be positive, bounded, and only required or meaningful for timed salvage.
- Metadata belongs on playable `salvage` entities only.
- Validator errors should name the entity id and invalid field/value.
- The map authoring issue should mark exactly one valuable salvage target in `maps/production_slice_01.greybox.json`.
- No terrain, collision, spawn, extraction, hazard, route, or camera topology should be changed for this pass unless a separate issue explicitly justifies it.

## Runtime/UI Boundaries

Runtime work should preserve current loop semantics:

- Existing instant salvage collection remains unchanged.
- Held cargo capacity remains 2 pickups.
- Tier-derived score remains `common = 100` and `valuable = 300`.
- Held score banks only at extraction.
- Completion-only oxygen bonus remains runtime-derived, not source-authored.
- Result panel and route outcome text remain current behavior.
- Hazard warning and hazard oxygen penalty remain current behavior.

Implementation should prefer a small helper or focused state boundary if `main.gd` would otherwise grow. Suggested runtime state is one active timed salvage id plus progress seconds, reset whenever the player leaves range, cargo is full, the run ends, reset happens, hazard restoration happens, or oxygen failure happens.

The overlay should stay compact. Do not add an inventory screen, tool wheel, upgrade panel, modal tutorial, or new broad HUD system.

## Validation/Smoke Plan

Validation:

- Update `docs/MAP_SPEC.md`.
- Update `tools/validate_greybox_map.py`.
- Validate all existing maps continue to pass without interaction metadata.
- Validate `production_slice_01` passes after exactly one timed valuable target is authored.
- Add negative validation coverage for unsupported interaction values and invalid timing values where practical.

Smoke coverage:

- Add one deterministic timed-salvage smoke flag.
- Verify reaching the authored timed target starts progress.
- Verify leaving range cancels progress.
- Verify completed timed salvage enters held cargo with the existing valuable score.
- Verify cargo-full behavior blocks starting or completing extra salvage as expected.
- Verify oxygen continues to drain during the timed interaction.
- Verify hazard hit and oxygen failure clear active progress and restore completed-but-unbanked timed salvage.
- Preserve existing route, cargo, oxygen, hazard, result, and player-facing smoke flags.

Useful existing regression smokes to keep in the verification set:

- `--smoke-salvage-loop`
- `--smoke-cargo-capacity`
- `--smoke-hazard-pressure`
- `--smoke-oxygen-pressure`
- `--smoke-route-outcome-result`
- `--smoke-safe-deep-route-choice`

## Visual/Capture Plan

The visual pass should show the timed interaction without replacing broader baselines too early.

- Add a focused timed-salvage capture command only after runtime behavior exists.
- Recommended output path: `visual_captures/timed_salvage/production_slice_01_timed_salvage.png`.
- Capture should frame the player, the target cache, nearby terrain, oxygen/status overlay, and progress text.
- Normal `production_slice_01` captures should be compared for drift before accepting any baseline change.
- Use the baseline review issue to decide whether the new timed-salvage visual state is accepted, deferred, or needs a focused follow-up.
- Do not regenerate broad art, terrain, props, or the whole scene for this pass.

## Deferred Work

Keep these out of Pass 05:

- Economy, upgrades, inventory screens, persistent saves, and loadouts.
- Enemies or moving hazard behavior.
- Procedural maps or full-map expansion.
- Multi-tool systems, cutting systems, scanning systems, or hauling systems.
- Broad visual replacement or terrain art overhaul.
- Slice-03 polish issues #52 and #53 unless the selected goal changes back to slice-03 presentation.
- Larger-map route design until the timed interaction has passed schema, runtime, smoke, capture, visual review, and Web verification.

## Exit Criteria

Pass 05 is done when:

- Source docs and validation support one timed salvage metadata path.
- Exactly one valuable target in `production_slice_01` uses the timed interaction.
- Runtime behavior preserves instant salvage, cargo, banking, oxygen, hazard reset, route outcome, and result semantics.
- Deterministic smoke coverage proves collect, cancel, oxygen pressure, cargo, hazard/reset restoration, and banking.
- A focused capture shows the interaction clearly.
- Visual impact is reviewed and either accepted or deferred with focused follow-up.
- Public Web preview is verified for the deployed timed-salvage pass.
- Closeout records what changed, what stayed out of scope, and whether the next pass should deepen interaction, improve hazards, or start cautious map-scale work.
