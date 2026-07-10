# OceanGame Expansion 02: Expedition Day Foundation

Date: 2026-07-09

Issues: #685-#694

Milestone: OceanGame Expansion 02 `Expedition Day Foundation`

## Decision

Make daylight and multiple oxygen sorties the organizing loop before adding typed materials, tool projects, capability-gated map expansion, combat, or broader daily variation.

```text
start at boat -> dive -> surface for oxygen -> continue or return
-> bank at boat -> launch another sortie -> end day
-> compact debrief -> next morning
```

This milestone replaces the old Emergency Week direction. Night consumes no Food, Water, Power, or similar survival resource.

## Target Experience

- A new day begins at the canonical slice-01 boat with a visible daylight budget.
- The first tuning target is 300 seconds, exposed as one runtime constant with deterministic smoke override.
- Daylight continues underwater, at open surface, at the active boat, and across source-authored connectors. It pauses only with the game pause state and after transition into the night/debrief state.
- Oxygen remains a separate 90-second tactical budget plus existing upgrades.
- Reaching authored open surface refills oxygen at the existing normal refill rate; it does not bank cargo, commit discovery, purchase upgrades, or end the day.
- Returning to the canonical boat banks cargo and commits eligible discovery, but does not automatically end the day.
- The player may leave the boat for another sortie while daylight remains.
- A separate boat-only command voluntarily ends the day.
- Approaching-night feedback warns at deterministic thresholds before zero.
- Nightfall away from the boat ends the active sortie as a forced recovery: held/unbanked cargo and pending discovery are cleared through existing failure semantics, already banked day results remain, and the debrief identifies the forced return.
- The night debrief summarizes the day and starts the next morning. It contains no project, forecast, crafting, or survival-need controls yet.

The 300-second target is an initial review value, not hidden scaling. Closeout may tune it only from integrated route, capture, and player-experience evidence.

## State Boundaries

### Sortie State

- current oxygen
- held/unbanked cargo
- local salvage and interaction progress
- pending discovery
- local hazard/failure state
- current connected-map leg

### Expedition-Day State

- day number
- daylight remaining and phase
- completed sortie count
- cargo/value banked during the day
- discoveries committed during the day
- voluntary or forced end reason
- debrief-ready result

### Profile State

- schema version
- unlocked durable capabilities
- committed discoveries

Existing session wallet and current session upgrades do not become profile-persistent in this milestone. Arbitrary map entities, depletion, oxygen, cargo, daylight, and in-progress interactions are not saved as profile state.

## Source-Of-Truth Boundaries

- Existing JSON maps, boat rectangles, connectors, collision, and terrain remain authoritative.
- Open surface must be resolved from source/runtime world semantics, not camera position or guessed screen coordinates.
- If explicit surface metadata is required, update `docs/MAP_SPEC.md`, validator coverage, and generators before runtime use.
- Do not change terrain topology unless implementation reproduces a separate source-level blocker.
- Keep slice 01 as the default boat hub and preserve the Expansion 01 slice-01/04/02 anomaly journey.

## Runtime And UI Boundaries

- Use focused day/sortie/debrief owners; `main.gd` and `greybox_world.gd` must not grow.
- Keep the daylight indicator compact and stable beside the existing oxygen/cargo/objective hierarchy.
- Show distinct feedback for open-surface oxygen, boat offload, voluntary end day, approaching night, forced recovery, and next morning.
- Do not add a management screen, inventory grid, project tree, forecast system, material taxonomy, health, weapon, enemy, or new map destination.

## Issue Order

1. #685 locks this experience, timing, failure, state, source, visual, and exit contract.
2. #686 defines focused sortie/day/profile ownership.
3. #687 implements deterministic daylight runtime.
4. #688 separates open-surface oxygen from boat banking.
5. #689 implements at least two sorties in one day.
6. #690 adds compact daylight and end-day presentation.
7. #691 adds the night debrief and next-day transition shell.
8. #692 adds integrated deterministic smoke and CI/release coverage.
9. #693 adds focused captures and a controlled visual decision.
10. #694 verifies the public Web build and records GO/HOLD closeout.

Dependencies are recorded on the issues. Runtime follows state ownership; lifecycle follows timer and surface/boat semantics; presentation follows behavior; smoke precedes capture; Web verification closes the milestone.

## Validation Plan

The integrated smoke must prove:

- one daylight start and deterministic countdown
- unchanged oxygen behavior before the new surface rule is invoked
- open-surface refill without banking or commit
- boat banking without automatic day end
- at least two sorties with one shared daylight budget
- connector preservation of day state
- voluntary end day from the boat
- forced nightfall recovery away from the boat
- correct unbanked cleanup and preservation of banked/profile state
- debrief summary and clean next-day reset
- unchanged complete anomaly-survey journey

Keep the release validation runner green and add the new smoke without removing existing gates.

## Visual And Web Plan

- Capture one active-day dive with daylight and oxygen readable together.
- Capture open-surface refill without boat banking.
- Capture the canonical boat/end-day affordance.
- Capture the night debrief or next-morning result.
- Compare affected baselines before accepting anything.
- Reject unrelated terrain, collision, player, boat, camera, prop, connector, anomaly, or HUD drift.
- Verify public build metadata, both supported viewports, failed requests, and Godot errors before closeout.

## Deferred Work

- typed materials, candidate selection, projects, tools, and crafting
- capability-gated map changes
- broader practical research
- health, enemies, weapons, combat, and biological resources
- daily conditions and forecasts
- additional regions or map topology
- Emergency Week and Food/Water/Power survival consumption, which are rejected rather than deferred
- shortcut or fast-travel networks, which are rejected
- #52/#53 slice-03 presentation polish

## Exit Criteria

- A player can explain the difference between oxygen, daylight, open surface, and boat return.
- One day supports at least two meaningful sorties.
- Banked results survive while forced nightfall loses only unbanked work.
- Night cleanly resolves the day without a survival tax or fake future systems.
- Existing release and anomaly journeys remain deterministic.
- Focused captures communicate the loop without unrelated drift.
- The public Web preview serves the intended closeout commit cleanly.
- Closeout answers: does the survey journey work well enough under daylight and multiple sorties for seeded materials and one tool project to become the next progression layer?
