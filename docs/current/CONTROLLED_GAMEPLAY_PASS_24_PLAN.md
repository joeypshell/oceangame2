# Controlled Gameplay Pass 24 Plan

Date: 2026-07-09

Issue: #542 `Plan Controlled Gameplay Pass 24 around lower-left relay follow-through`

Milestone: Simple Diver Game 06 `Objective And Run Structure`

## Decision

Pass 24 should make the Pass 23 result prompt pay off with one source-authored lower-left relay follow-through objective.

Target flow:

```text
Next dive: Investigate lower-left relay -> reach lower-left relay/destination context -> compact follow-through feedback
```

This remains a narrow objective-structure pass. It should not become a quest log, mission selector, save system, inventory/loadout system, broad connector expansion, enemy pass, economy pass, procedural system, or full productionization of the sketch map.

## Target Experience

After completing the primary deep-cache objective, the result panel now suggests investigating the lower-left relay. On a later run, the player should be able to follow that lead through the existing lower-left connector into the already-authored relay/destination context and get one compact confirmation that the lead was meaningful.

Desired feel:

- the Pass 23 prompt points to an actual remembered place
- reaching the lower-left relay has a small objective payoff beyond travel
- the existing connector and destination cache feel more intentional
- current score, cargo, oxygen, upgrade, connector, hazard, reset, and primary-objective rules remain stable

## Meaningful-Change Filter

Pass 24 is worth doing only if it improves objective/run structure:

- curiosity: the next-dive lead has a visible follow-through moment
- payoff: the lower-left relay produces a compact confirmation or result beat
- remembered-place progress: `lower-left relay` becomes a recognizable objective location
- reason to retry: the completed run points to a concrete next expedition action

It is not worth doing if it only adds bookkeeping metadata, another permanent label, broad travel state, or a new connector with no moment-to-moment payoff.

## Planned Issue Batch

1. #542 Plan Controlled Gameplay Pass 24 around lower-left relay follow-through.
2. #543 Document Pass 24 relay follow-through objective source contract.
3. #544 Add Pass 24 relay follow-through validation.
4. #545 Author one Pass 24 lower-left relay follow-through objective in source.
5. #546 Implement compact Pass 24 relay follow-through runtime feedback.
6. #547 Add deterministic Pass 24 relay follow-through smoke coverage.
7. #548 Add focused Pass 24 relay follow-through review capture.
8. #549 Review Pass 24 visual impact and baseline decision.
9. #550 Verify public Web preview after Pass 24 relay follow-through.
10. #551 Add Pass 24 closeout and next-step evaluation.

## Source-Of-Truth Boundaries

The follow-through objective must be source-authored. The likely source path is:

```text
tools/create_production_slice_04_map.py
maps/production_slice_04.greybox.json
docs/MAP_SPEC.md
tools/validate_greybox_map.py
```

The objective should tie back to the Pass 23 prompt context:

- prompt target in `production_slice_01`: `lower_left_loop_connector`
- destination map: `production_slice_04`
- destination entry: `relay_sub_entry`
- existing destination payoff: `slice_04_destination_cache`

Omitted metadata must preserve current behavior. No terrain, collision, spawn, extraction, camera-test, salvage, hazard, connector, or destination topology should change unless the source-authoring issue explicitly justifies it.

## Runtime And UI Boundaries

Runtime should read the source metadata and show one compact objective cue/result line at the planned follow-through moment.

Stable behavior:

- Pass 23 result prompt remains success-only for the primary deep-cache objective
- connector travel and destination-local reset semantics remain unchanged
- cargo, oxygen, hazard, banking, session wallet/upgrades, and salvage rules remain unchanged
- maps without Pass 24 metadata preserve current behavior

Do not add:

- quest journal or mission picker
- persistent save flags
- inventory or loadout UI
- new economy rules
- broad objective framework
- new connector topology
- new art requirement

## Validation And Smoke Plan

Validation should catch malformed follow-through metadata before runtime:

- duplicate objective ids
- unsupported trigger or completion values
- dangling target, entry, connector, or payoff references
- non-short or malformed label text
- out-of-bounds or unreachable target context

Smoke should verify:

- objective feedback is hidden before the selected follow-through condition
- feedback appears when the lower-left relay follow-through condition is met
- source ids, labels, target context, and result text match metadata
- maps without metadata preserve existing behavior
- existing connector, primary objective, cargo, oxygen, hazard, and route smokes remain stable

Expected new smoke flag:

```text
--smoke-pass-24-relay-follow-through
```

## Visual And Capture Plan

Add one focused capture after runtime work:

```text
--capture-pass-24-relay-follow-through
```

The capture should frame the relay follow-through feedback clearly enough for review. It should live under a focused `visual_captures/` subdirectory and must not replace or accept production-slice baselines.

Visual review should compare normal production-slice baselines and accept no unrelated terrain, player, boat/base, prop, camera, map, or overlay drift.

## Deferred Work

Keep these out of Pass 24:

- enemies, combat, health, or broad moving-hazard expansion
- procedural generation or full-map productionization
- inventory/loadouts, save-heavy mission progress, quest log, or objective picker
- economy expansion beyond current session wallet/upgrades
- persistent multi-area expedition state
- new connector topology or another destination slice
- broad audio, music, ambience, or art replacement
- slice-03 presentation cleanup

#52 and #53 remain deferred optional slice-03 polish unless slice-03 presentation becomes the selected goal.

## Exit Criteria

Pass 24 is complete when:

- the source contract is documented
- validation supports the narrow metadata
- one follow-through objective is source-authored
- runtime shows compact feedback at the planned relay moment
- deterministic smoke covers the objective and fallback boundaries
- focused capture exists for review
- visual/Web verification is recorded
- closeout records what changed, what stayed stable, and the next recommended step
