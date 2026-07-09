# Simple Diver Game 09 Expansion Experience Contract

Date: 2026-07-09

Issue: #646
Milestone: Simple Diver Game 09 `2D Subnautica Expansion Planning`

## Decision

The first 2D Subnautica-like expansion slice should be one **anomaly survey expedition** built from the release candidate's final-dive signal.

The player should recognize a route from the small game, prepare one bounded capability, push through one new environmental constraint, investigate one source-authored anomaly, and return to the boat with a discovery that changes the next expedition state.

This is the smallest coherent step from a complete salvage game toward a larger exploration game. It adds curiosity, remembered-place progress, and capability-based route planning without requiring a procedural ocean, broad inventory, crafting tree, base building, combat, or ecosystem simulation.

## Expanded Player Fantasy

The player is a working diver becoming an ocean explorer. Salvage still pays for expeditions, but the deeper reason to dive is to understand signals, places, and environmental clues that cannot be resolved in one trip.

The boat remains safety, preparation, and return context. The cave network remains authored and legible. Expansion should make the player think:

- I know where that route goes now.
- I saw something there that I could not fully investigate.
- One preparation choice may let me push farther next time.
- I need enough oxygen and cargo room to get home with the result.

## First Expansion Slice: Anomaly Survey

The existing release journey ends with `lower_left_final_dive_signal`. The first expansion slice turns that cue into a playable follow-up:

1. **Lead:** the completed small-game journey exposes an anomaly/survey objective.
2. **Prepare:** at the boat, the player selects or unlocks one bounded capability required to investigate it.
3. **Revisit:** the player travels through at least one familiar route or connector, making prior knowledge useful.
4. **Commit:** one environmental pressure or soft capability gate creates a clear go/defer/return decision.
5. **Investigate:** the player completes one source-authored survey or sample interaction at the destination.
6. **Return:** oxygen, cargo, hazards, and route memory still govern the trip home.
7. **Resolve:** banking the result records one persistent discovery and presents one next lead.

The exact destination map, state lifetime, capability, interaction, and fauna/hazard candidate are decided by #647-#650. They must fit this sequence rather than creating separate unrelated systems.

## Core Loop

```text
review lead -> prepare one capability -> revisit known water -> cross one pressure point
-> investigate anomaly -> choose whether to take extra salvage -> return and bank
-> retain one discovery -> receive next lead
```

The release-candidate salvage loop remains nested inside this larger loop. Discovery does not replace oxygen, cargo, salvage payoff, hazards, banking, failure, or retry.

## Experience Pillars

### Curiosity

- A named signal/anomaly has a visible source, destination, or clue.
- The player sees enough before arrival to form a question, not merely a checklist task.

### Expedition Pressure

- Preparation and route commitment affect oxygen/return margin.
- The survey competes with optional salvage or safety; it is not a free cutscene trigger.

### Payoff

- The destination has a distinct interaction and compact result.
- Returning records a discovery or capability-relevant outcome, not only score text.

### Remembered Places

- At least one familiar route or landmark gains new relevance.
- The next objective refers to a place the player has seen or can recognize.

### Meaningful Route Choice

- The player can defer, prepare, or take a safer/longer approach where source topology supports it.
- A capability may improve access or confidence, but the first slice should avoid a confusing hard-lock maze.

### Reason To Repeat

- One expedition reveals the lead; a later expedition resolves it.
- Failure preserves enough understanding to make the retry feel informed rather than repeated from zero.

## In Scope For The First Slice

- one bounded authored destination or route extension chosen through the map strategy
- one source-authored anomaly/survey objective
- one compact survey/sample-style interaction
- one bounded capability or preparation requirement
- one explicit persistent discovery outcome, subject to the state contract
- existing oxygen, cargo, salvage, hazards, connectors, progression, result, failure, and retry semantics
- deterministic smoke, focused capture, baseline comparison, and public Web verification

## Out Of Scope

- procedural generation or a seamless full ocean
- productionizing the entire supplied full-map sketch
- base building or major vehicle gameplay
- inventory grids, freeform loadouts, recipe trees, or broad crafting
- broad economy simulation or dozens of resources
- combat, weapons, loot tables, spawning ecosystems, or full enemy AI
- save-heavy sandbox simulation or multiple profiles in the first implementation slice
- dialogue trees, quest journal, mission board, or cinematic story system
- multiple broad biomes
- broad visual or audio replacement

## Meaningful-Change Filter

A future implementation issue belongs in the first expansion batch only if it answers yes to all applicable questions:

1. Does it advance the anomaly survey sequence?
2. Does it create curiosity, pressure, payoff, remembered-place progress, route choice, or a reason to repeat?
3. Is its source/runtime/state owner explicit?
4. Can it be validated deterministically and reviewed without replacing unrelated baselines?
5. Is it the smallest version that proves the player-facing decision?

Tooling or refactor issues may proceed only when they are direct prerequisites for one of those changes. Generic frameworks, speculative schemas, and unrelated polish fail the filter.

## Release-Candidate Boundaries

- `production_slice_01` remains the default preview until a separate reviewed decision changes it.
- The existing complete release journey remains runnable and smoke-covered throughout expansion work.
- Maps remain source/generator-owned JSON with reachability and parity checks.
- The boat, diver, terrain, collision, accepted assets, and baselines remain stable unless a scoped implementation issue intentionally changes one.
- #52/#53 remain deferred because slice-03 presentation is not selected by this contract.

## Experience Exit Criteria

The first expansion slice succeeds when a player can:

- understand the anomaly lead from the existing final-dive result
- make one preparation or capability decision
- use knowledge of a remembered route
- reach and complete one distinct investigation under expedition pressure
- return and see one durable discovery outcome
- understand what the outcome makes interesting next

It fails the contract if the work mainly adds menus, data structures, map area, or enemies without making that expedition sequence more meaningful.

## Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
