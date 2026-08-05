# OceanGame Expansion 01 Closeout

Date: 2026-07-09

Roadmap status: historical GO closeout. Its territorial-eel next-step
recommendation was superseded by the completed Phase 2 foundation. Active
direction now lives in
`docs/planning/OCEANGAME_LIVING_EXPEDITION_ROADMAP.md`.

Issues: #662-#671
Milestone: OceanGame Expansion 01 `Anomaly Survey Foundation`

## Decision

GO. OceanGame Expansion 01 is complete and the milestone may close after #671 merges.

The bounded post-release journey now works end to end:

```text
final-dive lead -> scanner unlock -> slice 01 -> slice 04 -> slice 02
-> timed anomaly survey -> risky return -> canonical boat commit
-> durable discovery -> next lead
```

No reproduced runtime, map, validation, visual, CI, or Web blocker remains.

## What Landed

- #662 locked the experience, affordability, state, source, validation, visual, and exit contracts.
- #663/#664 reduced coordinator growth by extracting progression and world-query responsibilities.
- #665 made non-salvage survey metadata first-class and validator-backed.
- #666 added minimal profile capability/discovery state and one cross-map pending-discovery owner.
- #667 authored the bidirectional slice-04/slice-02 route and one slice-02 anomaly through generators without terrain drift.
- #668 implemented the 300-wallet scanner unlock, timed survey, failure cleanup, return, and exact-once commit.
- #669 added the integrated `--smoke-anomaly-survey-journey` CI/release gate.
- #670 added focused survey/commit captures and rejected unrelated baseline drift.
- #671 verified the deployed Pages build and records this GO closeout.

## Source And State Result

- Map JSON remains the source of truth for connector and survey placement/metadata.
- Existing terrain and collision topology did not change.
- Scanner capability and completed discovery are the only durable profile additions.
- Wallet and existing upgrades remain session-only.
- Pending discovery is the only new cross-map expedition payload.
- Reset, hazard, and oxygen failure clear uncommitted work; committed discovery survives.
- Survey creates no cargo or direct score and preserves instant/timed/pry salvage behavior.

## Validation Result

- Complete release-candidate runner: pass.
- GitHub Headless smoke, including the integrated anomaly journey: pass.
- Generator/schema/reachability/parity checks: pass.
- Scanner gating, exact 300-wallet payment, idempotence, progress/cancel, oxygen drain, no-cargo completion, failure cleanup, connector preservation, commit, and profile reload: pass.
- `main.gd`: 2040 lines, below its pre-expansion 2043-line count.
- `greybox_world.gd`: 984 lines, unchanged from its pre-survey count.
- New source owners remain below 500 lines.

## Visual And Web Result

- Focused 50% survey and boat-commit captures are accepted as review evidence.
- No production-slice accepted baseline was replaced.
- All final production-slice comparison sheets had black difference panels.
- Broad local captures with unrelated HUD/black-terrain drift were rejected and removed.
- Public Pages serves `3d6a922408fb3261da2065b3c0beeafc224e56ee`.
- Both supported browser viewports initialized with no failed requests, missing resources, or Godot errors.

Detailed evidence:

- `docs/current/OCEANGAME_EXPANSION_01_VISUAL_BASELINE_DECISION.md`
- `docs/current/OCEANGAME_EXPANSION_01_WEB_PREVIEW_VERIFICATION.md`

## Next Direction

GO to a bounded Phase B territorial-eel encounter, beginning with a plan and source/runtime contract before implementation.

The selected encounter remains:

```text
idle -> warning -> fixed lunge -> return -> cooldown
```

Keep it tied to the authored slice-02 anomaly approach and preserve the completed survey journey as the regression floor. Do not add combat, health, loot, pursuit/pathfinding, spawning, ecosystem simulation, inventory/loadouts, broad economy, more destinations, or full-map productionization.

The next issue batch should separate planning, source schema/validation, source authoring, runtime, deterministic smoke, focused capture, visual decision, Web verification, and closeout. Reproduce and scope any blocker rather than expanding the batch around it.

## Deferred

- #52/#53 remain optional slice-03 presentation polish.
- Additional anomalies, tools, fauna types, resources, connectors, and destinations remain deferred.
- Procedural generation, crafting/inventory, persistent wallet/economy, base building, vehicles, combat/ecosystem AI, broad biomes, broad art/audio replacement, and save-heavy sandbox progression remain out of scope.
