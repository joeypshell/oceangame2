# Controlled Gameplay Pass 23 Plan

Date: 2026-07-09

Issue: #523 `Plan Controlled Gameplay Pass 23 around a next-dive objective prompt`

Milestone: Simple Diver Game 06 `Objective And Run Structure`

## Decision

Pass 23 should add one source-authored next-dive objective prompt to the default `production_slice_01` run.

Target prompt:

```text
Next dive: Investigate lower-left relay
```

The prompt should appear in the run result flow after the player completes the current primary `Deep cache` objective. It should point the next attempt toward the already-authored lower-left connector and destination payoff work without turning Pass 23 into a quest log, save system, objective picker, new connector, or full multi-area expedition.

## Target Experience

The player starts with the existing `Objective: Deep cache 0/2` cue, commits to the deep-cache route, banks the required salvage, and returns to the boat. The result panel should then give one compact next-run direction instead of ending as a pure score report.

Desired feel:

- the first run has a clearer after-action beat
- the player sees a reason to try another expedition
- the lower-left connector becomes more legible as the next authored lead
- all current score, cargo, oxygen, upgrade, connector, hazard, and reset rules remain stable

## Meaningful-Change Filter

Pass 23 is worth doing only if it improves run structure:

- curiosity: the result points to an authored place the player has not necessarily used
- payoff: the connector/destination payoff becomes easier to discover
- remembered-place progress: `lower-left relay` should refer to an existing in-map place
- reason to retry: completion now suggests a next dive instead of only ending the run

It is not worth doing if it only adds another permanent overlay label, broad text system, or bookkeeping-only metadata.

## Planned Issue Batch

1. #522 Reconcile current-state pass numbering before Milestone 06 objective work.
2. #523 Plan Controlled Gameplay Pass 23 around a next-dive objective prompt.
3. #524 Document Pass 23 next-dive objective prompt source contract.
4. #525 Add validation for Pass 23 next-dive objective prompt metadata.
5. #526 Author one Pass 23 next-dive objective prompt in `production_slice_01` source.
6. #527 Implement compact Pass 23 next-dive objective runtime feedback.
7. #528 Add deterministic smoke coverage for Pass 23 next-dive objective prompt.
8. #529 Add focused Pass 23 next-dive objective review capture.
9. #530 Review Pass 23 visual impact and verify public Web preview.
10. #531 Add Pass 23 closeout and next-step evaluation.

## Source-Of-Truth Boundaries

The prompt must be source-authored. The likely source path is:

```text
tools/create_production_slice_map.py
maps/production_slice_01.greybox.json
docs/MAP_SPEC.md
tools/validate_greybox_map.py
```

Expected source shape should stay narrow and support one prompt, likely tied to:

- a unique lower_snake_case prompt id
- a short display label
- `deep_cache_route_objective`
- completed-run result timing
- optional next target context such as `lower_left_loop_connector`

Omitted metadata must preserve current behavior. No terrain, collision, spawn, extraction, camera-test, salvage, hazard, connector, or destination topology should change.

## Runtime And UI Boundaries

Runtime should read the prompt metadata and add one compact result-panel or status/result line after the selected trigger.

Stable behavior:

- primary objective completion remains `deep_cache_route_objective`
- failed runs do not show stale completion prompts
- partial banking still banks cargo without completing the run
- oxygen failure, hazard reset, normal reset, banking, upgrades, connector travel, and session wallet behavior stay unchanged

Do not add:

- quest journal
- mission selector
- persistent save flags
- inventory or loadout UI
- new economy rules
- broad objective framework
- new map connector
- new art requirement

## Validation And Smoke Plan

Validation should catch malformed prompt metadata before runtime:

- duplicate prompt ids
- unsupported trigger values
- dangling objective or target references
- non-short or malformed label text
- more than one prompt in the first Pass 23 scope

Smoke should verify:

- prompt hidden before primary objective completion
- prompt visible after banking the selected primary objective and returning
- prompt text/id/target context match source metadata
- failed or reset runs do not leave stale next-dive text
- existing primary objective, cargo, oxygen, hazard, connector, and route smokes remain stable

Expected new smoke flag:

```text
--smoke-pass-23-next-dive-objective
```

## Visual And Capture Plan

Add one focused capture after the runtime work:

```text
--capture-pass-23-next-dive-objective
```

The capture should frame the result panel or compact prompt state clearly enough for review. It should live under a focused `visual_captures/` subdirectory and must not replace or accept production-slice baselines.

Visual review should compare normal production-slice baselines and accept no unrelated terrain, player, boat, prop, camera, or overlay drift.

## Deferred Work

Keep these out of Pass 23:

- enemies, combat, health, or broad moving-hazard expansion
- procedural generation or full-map productionization
- inventory/loadouts, save-heavy mission progress, quest log, or objective picker
- economy expansion beyond current session wallet/upgrades
- new connector topology or another destination payoff
- broad audio, music, ambience, or art replacement
- slice-03 presentation cleanup

#52 and #53 remain deferred optional slice-03 polish unless slice-03 presentation becomes the selected goal.

## Exit Criteria

Pass 23 is complete when:

- the source contract is documented
- validation supports the narrow metadata
- one prompt is source-authored in `production_slice_01`
- runtime shows the compact next-dive prompt at the planned result moment
- deterministic smoke covers the prompt and reset/failure boundaries
- focused capture exists for review
- visual/Web verification is recorded
- closeout records what changed, what stayed stable, and the next recommended step
