# Finished Simple Diver Game Roadmap

Last updated: 2026-07-09

## Decision

`oceangame2` should aim first at a finished small diver game, not an endless sequence of prototype micro-passes and not the full 2D Subnautica-like OceanGame yet.

The current controlled-pass workflow remains useful, but it is now a validation lane. Each new issue batch should serve the roadmap below: curiosity, pressure, payoff, remembered-place progress, meaningful route choice, or a reason to try another expedition.

## Finished Simple Diver Game Target

The finished simple diver game is a compact handcrafted side-view ocean salvage game:

- start from a boat or small surface base
- choose or accept a simple dive objective
- navigate readable underwater cave routes
- manage oxygen, cargo, hazards, and return pressure
- use a small set of tool-like interactions
- bring salvage home for score, payout, or progression
- unlock a few deeper routes or capabilities
- finish with a final authored dive objective

It should feel like a complete small game before any larger OceanGame expansion begins.

## Boundary Before The Larger OceanGame

In scope for the simple diver game:

- handcrafted maps and route loops
- one diver, boat/base extraction, oxygen, cargo, salvage, hazards, and objectives
- limited progression through a few upgrades or unlocks
- a small tool set that changes interaction and route planning
- polished enough presentation to sell the mood and readability
- Web preview and repeatable capture/smoke validation

Out of scope until after this roadmap:

- procedural ocean generation
- large seamless world production
- base building
- vehicles as major gameplay systems
- complex crafting or inventory grids
- large economy simulation
- full ecosystem/enemy AI
- save-heavy open-ended sandbox progression
- multiple broad biomes

## Experience Pillars

- Expedition tension: leaving safety should create a clear risk of overcommitting.
- Salvage interaction: at least some valuables require more than instant pickup.
- Readable routes: the player should understand safer paths, deeper paths, shortcuts, and return loops.
- Remembered places: dives should reveal places the player recognizes and wants to revisit.
- Small progression: upgrades or unlocks should change what the player can attempt without bloating scope.
- Controlled production: source maps, validation, smokes, captures, and baselines stay part of every pass.

## Milestone Roadmap

### 01. Prototype Stabilization And Roadmap Alignment

Purpose: finish or close the remaining prototype tail and align docs/issues to this roadmap.

Exit criteria:

- roadmap docs and GitHub milestones match
- active non-deferred issues are assigned to the first roadmap milestone
- `production_slice_01` remains stable as the default preview
- Pass 15 objective-follow-through work is complete
- smoke/capture/Web-preview workflow is still green

### 02. Core Diver Loop Vertical Slice

Purpose: turn the current prototype into one clearly playable dive.

Exit criteria:

- one authored objective can be completed from boat to return
- oxygen, cargo, hazard, salvage, and result feedback are readable together
- at least one safe route and one risky/deeper route create a meaningful choice
- the dive has a clear start, middle, return, and completion

### 03. Salvage Tools And Interaction Set

Purpose: add a small set of tool-like interactions that make salvage and route planning more interesting.

Exit criteria:

- timed salvage is stable and readable
- at least one additional interaction exists, such as pry, cut, scan, or clear obstruction
- tool interactions are source-authored and smoke-covered
- no inventory/loadout sprawl is introduced

### 04. Progression And Economy Slice

Purpose: give repeat dives a reason to matter.

Exit criteria:

- salvage payout or score supports simple progression decisions
- a few upgrades or unlocks exist, such as oxygen, cargo, light, or tool access
- progression changes reachable goals without requiring a full economy sim
- failure and retry remain understandable

### 05. World Slice Expansion

Purpose: grow from one default slice into a small connected game space.

Exit criteria:

- multiple authored areas or route loops connect through source data
- each area has a distinct role, such as entry, lower loop, shortcut, deep cache, or return route
- map validation proves intended routes, salvage, hazards, and extraction paths are reachable
- slice-03 and other reference slices are either integrated intentionally or kept deferred

### 06. Objective And Run Structure

Purpose: make the game feel directed without becoming quest-heavy.

Exit criteria:

- dive objectives are source-authored and visible at the right moments
- at least one multi-step objective spans route choice and return pressure
- run result text explains payoff, failure, and next attempt clearly
- objectives support the final small-game arc

### 07. Presentation And Game Feel Pass

Purpose: raise readability and mood enough for a finished small game.

Exit criteria:

- player, boat/base, salvage, hazards, terrain, background, and UI read coherently
- movement and direction changes feel stable
- key sounds or visual feedback are planned or implemented if selected
- accepted visual baselines cover the important review views

### 08. Simple Diver Game Release Candidate

Purpose: lock the small game, verify it, and stop expanding scope.

Exit criteria:

- the small game has a complete beginning-to-end progression arc
- core smokes, map validation, parity checks, captures, and Web preview are green
- docs explain how to run, verify, and continue the project
- known deferred work is separated from release-blocking work

### 09. 2D Subnautica Expansion Planning

Purpose: decide what changes when the project graduates beyond the simple diver game.

Exit criteria:

- the small diver game is playable enough to serve as a foundation
- expansion requirements are written separately from current implementation tasks
- broad systems are planned before issues are created

## How To Use Controlled Passes Now

Controlled gameplay and visual passes should continue only when they serve one of the roadmap milestones. A pass should name its milestone and answer what player-facing value it creates.

Good pass targets:

- one new route choice
- one clearer objective step
- one new salvage/tool interaction
- one hazard or return-pressure improvement
- one source-authored map connector
- one focused readability or baseline decision

Avoid pass targets that only add bookkeeping, labels, or isolated polish unless they unblock roadmap work.

## Current Next Direction

Pass 24 is complete and gives the default slice one deterministic moving hazard as a route-timing beat, not an enemy/combat system. #448 adds the first small visual-only diver swim/idle animation slice.

Use `docs/current/DEPTH_DARKNESS_LIGHT_GATE_CONTRACT.md` for the next light/progression presentation step: one visual-only deep-route darkness zone improved by `dive_light_1`, without changing movement, collision, oxygen, cargo, objective, or salvage semantics. Do not add another connector merely because the first one works, and do not jump to procedural generation, full inventory/loadout systems, save files, broad economy work, full enemy AI, or full-map productionization.

## Deferred Work

- #52 and #53 remain optional slice-03 polish unless slice-03 becomes part of Milestone 05.
- Full-map productionization remains deferred until the core loop and progression goals need it.
- Broad economy, upgrades, inventory, enemies, procedural generation, and save systems remain outside the simple diver game until their milestone is selected.
