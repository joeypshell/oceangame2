# Controlled Gameplay Pass 06 Plan

Date: 2026-07-08

Issue: #160 `Plan Controlled Gameplay Pass 06 around timed-salvage readability`

## Decision

Controlled Gameplay Pass 06 should make the existing timed salvage interaction read as a deliberate in-cave action, not just a pickup with delayed overlay text.

The pass should keep the same authored target:

```text
salvage_deep_right_cache
```

The pass should not add a new map, economy, upgrade, inventory, enemy, procedural, save, or multi-tool system. It should deepen the first timed interaction enough that future route and map work has a clearer gameplay language to reuse.

## Target Experience

- The player can tell the deep cache is different before committing to it.
- While the player stays in range, progress is visible without hiding oxygen, cargo, score, or terrain.
- Leaving range gives compact cancellation feedback so the lost progress feels intentional.
- Completion gives compact payoff feedback before the salvage becomes held cargo.
- Cargo-full, hazard hit, oxygen failure, and reset preserve the Pass 05 semantics.
- The player should understand that the deep route asks for time, oxygen, and a clean return.

## Meaningful-Change Filter

This pass is worth doing if it creates at least one of:

- clearer curiosity: the target looks special before collection
- clearer pressure: the player sees the cost of holding position
- clearer payoff: completion reads as finishing an action, not merely touching a pickup
- clearer remembered-place progress: the deep cache becomes a recognizable authored moment
- clearer replay reason: the player can decide whether the timed cache is worth the route risk

If a proposed change does not improve those reads, keep it out of this pass.

## Planned Issue Batch

Recommended implementation order:

1. #160 Plan Controlled Gameplay Pass 06 around timed-salvage readability.
2. #161 Document Pass 06 timed-salvage feedback state rules.
3. #162 Add in-world timed-salvage affordance marker.
4. #163 Improve timed-salvage progress feedback readability.
5. #164 Add timed-salvage cancel and completion feedback.
6. #165 Add deterministic timed-salvage feedback smoke coverage.
7. #166 Add focused Pass 06 timed-salvage feedback capture.
8. #167 Review and accept Pass 06 timed-salvage visual impact.
9. #168 Verify public Web preview after Pass 06 timed-salvage feedback pass.
10. #169 Add Pass 06 closeout and next-step evaluation.

## Source-Of-Truth Boundaries

Do not add source fields unless runtime or capture work proves they are necessary.

For this pass, the existing metadata should remain enough:

```json
{
  "interaction": "timed_salvage",
  "interaction_seconds": 2.5,
  "interaction_label": "deep cache"
}
```

The timed-salvage target remains normal salvage for reachability, cargo, score, banking, hazard reset, oxygen failure, route metadata, and visual baseline comparisons.

No terrain topology, collision, spawn, extraction, camera test, route marker, or broad map source change should happen in this pass.

## Runtime/UI Boundaries

Runtime work should stay narrow:

- Instant salvage remains instant.
- The timed target keeps cancel-to-zero behavior when the player leaves range.
- Cargo capacity remains two held pickups.
- Cargo-full does not collect or delete the timed target.
- Oxygen drains normally while away from extraction.
- Hazard hit and oxygen failure clear active progress and preserve existing held-salvage restoration semantics.
- Banking at extraction remains unchanged.

UI and visual feedback should use existing lightweight patterns:

- compact status text
- a small in-world marker or progress affordance
- short-lived cancel/complete notes

Do not add an inventory screen, tool wheel, modal tutorial, new HUD framework, sound system, or broad visual replacement.

## Feedback State Rules

Pass 06 feedback should use the existing `interaction_label` as the player-facing target name. For the current target, that label is `deep cache`.

- Available: before interaction starts, the target should have a small in-world cue that reads as special but does not imply collection has begun. Suggested overlay copy is none; this state should be readable from the world marker.
- Progress: while the player is in range and cargo has room, progress should increase and display compactly, for example `Salvaging deep cache 42%`. Oxygen continues draining normally.
- Canceled: when the player leaves range before completion, progress returns to zero and a brief status note should communicate interruption, for example `Salvage interrupted`. The target stays in the world.
- Completed: when progress reaches 100%, the pickup enters held cargo and a brief status note should communicate completion/payoff, for example `Deep cache secured +300`.
- Cargo-full: when cargo is full, timed salvage should not start or complete. The target remains in the world and feedback should say the cargo is full without deleting or hiding the target.
- Hazard reset: hazard contact clears active timed progress and feedback, then follows the existing hazard oxygen-penalty/restoration path.
- Oxygen failure/reset: oxygen failure clears active timed progress and feedback, restores held salvage as before, and leaves uncollected timed targets available.

These are runtime/UI states, not terrain, topology, collision, or map-source states. Source metadata remains the current `interaction`, `interaction_seconds`, and `interaction_label` fields unless a later issue proves a new field is necessary.

## Validation/Smoke Plan

Preserve existing validation and smoke coverage:

- `python tools/validate_greybox_map.py maps/production_slice_01.greybox.json`
- `--smoke-timed-salvage`
- `--smoke-salvage-loop`
- `--smoke-cargo-capacity`
- `--smoke-oxygen-pressure`
- `--smoke-hazard-pressure`
- `--smoke-route-outcome-result`
- `--smoke-safe-deep-route-choice`

Pass 06 should extend timed-salvage smoke coverage only after the new feedback states exist. Smoke output should remain deterministic and report the target id, interaction seconds, progress/cancel/complete state, held cargo, banked score, cargo-blocked status, and oxygen.

## Visual/Capture Plan

The visual pass should remain focused:

- update or add a focused timed-salvage feedback capture
- frame the target, player, in-world affordance/progress state, and overlay
- compare normal production-slice captures before accepting any baseline change
- accept only intentional timed-salvage feedback differences
- never commit `.import` sidecars

Normal terrain, boat, player, hazard, props, background, camera, topology, and collision should remain stable unless a separate issue explicitly selects them.

## Deferred Work

Keep these out of Pass 06:

- economy, upgrades, inventory screens, persistent saves, loadouts
- enemies, moving hazards, or broad encounter systems
- procedural maps or full-map productionization
- multi-tool systems, cutting systems, scanning systems, or hauling systems
- broad visual replacement or terrain art overhaul
- slice-03 polish issues #52 and #53 unless the selected goal changes back to slice-03 presentation

## Exit Criteria

Pass 06 is done when:

- feedback state rules are documented
- the timed target has a clear in-world affordance
- progress, cancel, complete, and cargo-full feedback are readable
- deterministic smoke coverage protects the new feedback states
- a focused capture shows the feedback clearly
- normal baseline views are reviewed for drift
- public Web preview is verified for the deployed pass
- closeout recommends whether Pass 07 should deepen interaction, add hazard/navigation pressure, or start cautious map-scale expansion
