# Simple Diver Game 09 Expansion Planning

Date: 2026-07-09

Issues: #643-#652
Milestone: Simple Diver Game 09 `2D Subnautica Expansion Planning`

## Decision

Use Milestone 09 to decide the first bounded expansion beyond the release-candidate small diver game before adding runtime, map, or asset scope.

Simple Diver Game 08 is the stable foundation. Its source-authored maps, complete release journey, validation runner, captures, accepted baselines, local launch path, and public Web preview remain intact while this planning lane answers what should grow next and what must stay deferred.

## Player-Facing North Star

The first expansion should make the ocean feel more worth exploring across repeat expeditions. It must add at least one of:

- curiosity about a newly reachable or newly understood place
- pressure that changes route or return planning
- a payoff that makes discovery or preparation matter
- remembered-place progress across expeditions
- a meaningful route choice created by capability, state, or risk

An issue that only adds bookkeeping, generic framework code, or more validation evidence does not qualify unless it directly unblocks the selected player-facing outcome.

## Decision Questions

Milestone 09 must settle:

1. Which release-candidate systems are safe to preserve, extend, refactor, or retire?
2. What is the first coherent 2D Subnautica-like experience slice?
3. How should connected authored areas grow while JSON remains the map source of truth?
4. Which state is dive-local, session-local, profile-persistent, or world-persistent?
5. What is the smallest useful tool/resource model without inventory or crafting sprawl?
6. What bounded fauna or hazard behavior can deepen a route without becoming combat AI?
7. Which architecture and validation gates must be in place before implementation grows?
8. What single implementation milestone should follow planning?

## Planned Issue Order

1. #643 establish this expansion decision pass.
2. #644 reconcile completed milestone state and post-RC handoff drift.
3. #645 audit release-candidate systems for reuse and growth risk.
4. #646 define the expanded experience and scope contract.
5. #647 define connected-world and map growth strategy.
6. #648 define persistence and expedition state boundaries.
7. #649 define bounded tools, inventory, crafting, and resource scope.
8. #650 define fauna, hazard, and ecosystem scope.
9. #651 define architecture and validation gates.
10. #652 synthesize the decisions and create the first implementation batch.

Issues #647-#651 may refine separate contracts after #646, but #652 must reconcile any conflicts before implementation issues are created.

## Source-Of-Truth Boundaries

- JSON map data and its generators remain authoritative for topology, collision, entities, routes, and connectors.
- Godot scenes and screenshots are runtime/rendering consumers, not alternate topology sources.
- Future map work must update source or generator first, then regenerate previews and validate reachability/parity before capture review.
- Approved assets remain named, individually replaceable files governed by the art bible and manifest.
- Existing accepted baselines stay fixed unless a later implementation issue documents and reviews an intentional visual change.
- The release-candidate validation runner remains the regression floor while additional focused checks are planned.

## Planning-Only Boundary

Issues #643-#652 may change documentation, GitHub issue/milestone state, and planning metadata only. They must not:

- change gameplay behavior or command-line flags
- edit map JSON, generators, terrain, collision, or scene geometry
- generate or accept captures/baselines
- replace visual or audio assets
- add save, inventory, crafting, fauna, enemy, procedural, or world-streaming runtime systems

Implementation begins only after #652 selects one bounded outcome and records an ordered issue batch.

## Non-Goals

- procedural ocean or full-map productionization
- base building or major vehicle systems
- inventory grids, loadout sprawl, or recipe trees
- broad economy simulation
- combat systems, loot tables, or full ecosystem AI
- save-heavy sandbox progression
- multiple broad biomes or broad art/audio replacement
- reopening release-candidate hardening without a reproduced blocker

## Deferred Work

- #52 and #53 remain optional slice-03 camera/topology polish. Milestone 09 does not select slice-03 presentation.
- Existing file-length debt is evidence for #645/#651, not permission for an unrelated refactor in this planning lane.
- Any user or playtest defect discovered during planning should become a separate scoped blocker issue rather than expanding these contracts.

## Exit Criteria

Milestone 09 is complete when:

- the experience, world, state, tool/resource, fauna/hazard, and architecture contracts agree
- one first expansion implementation milestone has a concrete player-facing outcome
- its issue batch is independently actionable and dependency ordered
- source-of-truth, reset/failure, validation, capture, baseline, and Web boundaries are explicit
- broad speculative systems remain deferred
- current handoff docs and GitHub milestone state point to the same next queue

## Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
