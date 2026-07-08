# Controlled Gameplay Pass 07 Pressure Rules

Date: 2026-07-08

Issue: #172 `Document Pass 07 hazard/navigation pressure rules`

Related docs:

- `docs/current/CONTROLLED_GAMEPLAY_PASS_07_PLAN.md`
- `docs/current/CONTROLLED_GAMEPLAY_PASS_07_SEGMENT_DECISION.md`
- `docs/current/ARCHITECTURE.md`
- `docs/MAP_SPEC.md`

## Decision

Use the existing hazard runtime and map schema for the first Pass 07 hazard/navigation pressure pattern.

No new hazard behavior, damage type, combat state, or Godot scene-local geometry is required for this rules pass. The selected pattern should be authored from source data and validated through the normal production-slice map pipeline.

Selected pressure pattern:

```text
lower_loop_to_deep_cache_pressure
from: salvage_lower_loop
primary hazard: hazard_right_branch
payoff: salvage_deep_right_cache
```

## Source Rules

The existing hazard schema is sufficient:

- `type: "hazard"`
- `kind`: one of the currently valid hazard styles
- source-authored tile position from the map generator

If #173 needs a durable anchor for review captures or smokes, prefer an existing marker-zone style annotation such as:

```text
lower_loop_to_deep_cache_pressure
```

That marker is allowed to support tooling and review selection only. It must not change terrain, collision, collection, scoring, or hazard semantics by itself.

Map/source changes must start from:

- `tools/create_production_slice_map.py`
- `maps/production_slice_01.greybox.json`
- `references/greybox/production_slice_01.svg`

Do not hand-edit Godot scene geometry, collision, camera position, or runtime nodes to create the pressure pattern.

## Warning Rules

Current warning behavior remains the Pass 07 baseline:

- Warning radius: `HAZARD_WARNING_RADIUS`, currently 80 px.
- Contact radius: `HAZARD_CONTACT_RADIUS`, currently 30 px.
- Warning appears only when the player is inside warning radius and outside contact radius.
- Generic hazards use compact overlay text: `Hazard nearby - keep clear`.
- The selected Pass 07 route hazard, `hazard_right_branch`, uses `Hazard ahead - keep clear` so the lower-loop to deep-cache route reads as intentional navigation pressure.
- Warning should not move the player, drop salvage, alter score, alter cargo, or mutate map state.

For the selected segment, the expected warning case is a player moving from `salvage_lower_loop` toward `salvage_deep_right_cache` and entering warning range around `hazard_right_branch` before touching it.

## Contact Rules

Current hazard contact behavior remains the Pass 07 baseline:

- Contact occurs inside `HAZARD_CONTACT_RADIUS`, currently 30 px.
- Contact applies `HAZARD_OXYGEN_PENALTY_SECONDS`, currently 12 seconds.
- Contact clears the active hazard warning.
- Contact resets active timed-salvage progress.
- Contact bumps the player back to the current spawn/boat entry.
- Contact briefly marks the player with existing hazard feedback.
- Contact status reports the oxygen penalty, and if held cargo was dropped it reports that held cargo was dropped.

If the oxygen penalty does not deplete oxygen, the run continues after the reset with reduced oxygen. If the penalty depletes oxygen, the existing oxygen-failure path runs instead and the result panel reports expedition failure.

## Salvage And Cargo Rules

Existing cargo and banking semantics must stay stable:

- Banked salvage and banked score remain banked after hazard contact.
- Held but unbanked salvage is restored to the map on hazard contact.
- Held cargo count, held cargo ids, and held cargo score clear after hazard contact.
- A completed timed-salvage target that has entered held cargo is still unbanked until returned to extraction, so hazard contact restores it to the map.
- Active partial timed-salvage progress clears on hazard contact, but the target remains available because it was not collected.
- Cargo capacity continues to block over-collection without deleting a target.
- Banking at the boat/extraction remains unchanged.

## Timed Salvage Rules

`salvage_deep_right_cache` stays the timed payoff for the selected pressure route.

Pass 07 must preserve current timed-salvage behavior:

- The player must remain near the target for the authored duration.
- Moving away cancels progress.
- Oxygen keeps draining during the interaction when away from extraction.
- Hazard contact or oxygen failure clears active progress.
- Completion moves the target into held cargo only if capacity allows.

The hazard pattern should increase route pressure around the timed payoff, not introduce a separate tool, inventory, economy, or combat system.

## Oxygen And Failure Rules

Oxygen remains the main pressure resource:

- Oxygen drains while away from extraction.
- Oxygen refills at extraction.
- Hazard contact subtracts the existing hazard penalty.
- Oxygen depletion restores held cargo to the map, clears held state, returns the player to spawn, and puts the run in failed/retry state.
- Oxygen failure clears active timed-salvage progress.
- Result-panel route outcome, oxygen bonus, session best, and retry semantics remain unchanged.

## Route Outcome Rules

Safe/deep route metadata and result text must remain stable:

- `salvage_entry_shaft` remains the short safe target.
- `salvage_lower_loop` and `salvage_deep_right_cache` remain deeper route targets.
- The selected pressure pattern should sharpen the deep-route choice, not reclassify existing route metadata.
- Existing route outcome smoke and capture should still pass after implementation work.

## Implementation Boundaries

#173 may add a source-driven marker or small source-authored hazard placement adjustment if review proves it necessary. It should avoid terrain topology changes.

#174 may tune compact warning/contact feedback only if the selected pattern is not readable with the existing overlay. It should not add a new HUD system.

#175 should harden smoke coverage around the selected hazard id and segment id rather than relying only on the first hazard in the map.

#176 should frame the selected route segment, player, hazard warning, and relevant salvage context for review without accepting baselines.

## Verification Expectations

Future implementation issues should preserve or add coverage for:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
--smoke-hazard-pressure
--smoke-pass-07-hazard-route-pressure
--smoke-oxygen-pressure
--smoke-timed-salvage
--smoke-safe-deep-route-choice
--smoke-route-outcome-result
```

Pass 07 route-pressure smoke should report at least:

- segment id
- hazard id
- warning state
- oxygen before and after contact
- held cargo state
- banked score state
- reset/restoration state
