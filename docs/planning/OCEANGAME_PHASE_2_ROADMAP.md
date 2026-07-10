# OceanGame Phase 2 Roadmap

Date: 2026-07-09

Status: Expansion 02 is complete with a GO. Expansion 03 is selected for the next issue batch; Expansions 04-09 remain directional until the preceding closeout selects them.

## Decision

`oceangame2` is the production foundation for the larger OceanGame, not a temporary prototype to discard and not a code port of the original repository.

The finished Simple Diver Game and OceanGame Expansion 01 already prove authored maps, controlled rendering, oxygen/cargo pressure, connected routes, focused interactions, limited upgrades, a profile-backed scanner, durable discovery, deterministic validation, captures, and Web deployment.

Phase 2 builds the longer game loop on that foundation:

```text
morning promise -> choose a route -> make multiple oxygen sorties
-> bank at the boat -> learn and gather -> end the day
-> review/build/prepare -> return tomorrow with a changed capability
```

## North Star

The player should repeatedly:

1. See a useful, dangerous, or mysterious place they cannot fully exploit.
2. Survey what blocks it and learn what capability is missing.
3. Gather guaranteed base materials plus a meaningful special component.
4. Complete a compact project at night.
5. Return through remembered geography with the new tool, suit upgrade, or weapon.
6. Reach a new payoff and discover the next promise.
7. Bring the result back to the boat before oxygen, daylight, health, or cargo pressure wins.

Every expedition day should leave at least one reason to start another:

- a known project close to completion
- a forecasted or seeded opportunity
- an unresolved signal or creature behavior
- a remembered capability gate
- a new weapon/tool option
- a deeper mystery revealed by the last payoff

## Locked Design Decisions

### Day And Night

- Daylight is the strategic expedition budget.
- Oxygen remains the tactical sortie budget.
- Open surface water refills oxygen; it does not bank cargo.
- The boat banks cargo, commits discoveries, supports preparation, and ends the day.
- One day supports multiple sorties.
- Night is a compact debrief, research, project, and preparation phase.
- Emergency Week is rejected. Do not add Food, Water, or Power as overnight survival taxes.

### Progression Triangle

Meaningful upgrades should combine:

```text
knowledge + base materials + special component = changed capability
```

- Knowledge comes from scans, survey, recovered plans, and practical research.
- Base materials such as titanium/scrap, fiber, glass/mineral, and conductive material use controlled candidate placement.
- Special components come from authored wrecks, environments, passive wildlife, or hostile creatures.
- The reward must change a verb, route, threat response, information surface, or reachable payoff. Pure percentage upgrades remain secondary.

### Stable Geography And Controlled Variation

- Geography, collision, landmarks, gates, habitats, and important promises remain source-authored and learnable.
- Daily seeds may select among authored resource, wildlife, patrol, visibility, current, and rare-signal candidates.
- Required progression cannot depend on arbitrary coordinates or an unlucky seed.
- Validators must prove guaranteed prerequisites, legal placement, reachability, and non-circular dependencies.
- Do not add a shortcut, pylon, elevator, or fast-travel network. Upgrades may make a known route possible, safer, or faster, but the player still travels through the world.

### Enemies, Weapons, And Wildlife Resources

- The ocean eventually contains passive wildlife, defensive wildlife, territorial enemies, predators, and study-only creatures.
- Valid responses include evade, distract, disable, fight, sample, and harvest according to the species contract.
- Health is separate from oxygen.
- The first weapon must be craftable without defeating an enemy that requires that weapon.
- Some weapon and suit upgrades may require biological materials from wildlife or enemies.
- Mandatory biological materials use guaranteed authored habitat candidates and low required counts.
- Fighting remains an expedition cost through health, oxygen, daylight, position, cargo, and weapon limits; killing everything should not be the automatic best choice.
- No full ecosystem simulation is required to prove the first resource and combat loops.

## Planning Horizons

### Committed

OceanGame Expansion 02's issue-level batch #685-#694 is complete. Expansion 03 is the only selected next batch and should be planned before implementation.

### Directional

Expansions 04-09 have GitHub milestones, goals, boundaries, and exit criteria. Create their issue batches only after the prior closeout confirms the next dependency is ready.

### Vision

Vehicles, broader crafting, large regional content production, final art/audio, accessibility, controller support, balance, save hardening, and release production remain vision-level work. Do not create detailed issue inventories for them yet.

## Design Reference Principles

Borrow structures, not names, content, art, recipes, or story:

- Subnautica: exploration reveals blueprint knowledge, equipment changes safe depth/access, and remembered signals pull the player back into the world.
- Subnautica 2: scans and samples should produce practical adaptation or project value, and tool-gated interactions need consistent visual language.
- Terraria: preserve the explore -> material -> tool -> new material/place cycle and traversal-changing equipment. Do not import the shortcut network, destructible-world scope, boss treadmill, or item volume.
- Stardew Valley: use a finite readable day, voluntary safe end, overnight payoff, compact projects, and tomorrow anticipation. Do not import farming chores, opaque luck, energy exhaustion, social schedules, or tool deprivation.

These references support OceanGame's own side-view expedition identity; none replaces the source-authored map, validation, and controlled visual pipeline.

## Milestone Roadmap

### Expansion 02: Expedition Day Foundation

Goal: make daylight and multiple sorties the organizing loop.

Prove:

- visible deterministic daylight
- open-surface oxygen refill distinct from boat banking
- at least two sorties in one day
- voluntary end day and explicit nightfall consequence
- compact night debrief and next-day transition
- no survival-resource consumption

Exit question: does the player understand why to surface, why to return to the boat, and why to begin another day?

### Expansion 03: Seeded Materials And First Tool Project

Goal: make gathering support one concrete capability project.

Prove:

- a minimal typed-material contract
- authored candidate pools with deterministic seed selection and guaranteed prerequisites
- one blueprint/project requiring knowledge, common materials, and one special component
- one active tool that changes a remembered interaction
- night project progress without an inventory grid or broad crafting tree

Exit question: does finding material create anticipation for a specific return rather than feel like generic currency?

### Expansion 04: Capability-Gated Map Progression

Goal: prove that the world is planned around diver capabilities.

Prove:

- one gate shown before its capability is available
- one clear blocker language shared by source, runtime, and UI
- one completed upgrade that opens the remembered place
- one meaningful payoff behind the gate
- a return route that still matters after the upgrade
- no shortcut or fast-travel system

Exit question: did the upgrade change the player's relationship with a place they remember?

### Expansion 05: Practical Research Foundation

Goal: make scanner knowledge useful to planning, projects, resource discovery, and danger.

Prove:

- resource research names habitat and upgrade relevance
- environment research explains one capability gate
- creature research reveals a behavior, risk, material, or countermeasure
- samples and scans feed projects without becoming a checklist field guide
- partial information creates curiosity rather than exact-route instructions

Exit question: does research make the player smarter and change the next expedition decision?

### Expansion 06: Combat Foundation

Goal: prove one readable underwater combat encounter.

Prove:

- health distinct from oxygen
- one source-authored hostile enemy and territory
- one first weapon built from non-enemy prerequisites
- readable warning, attack, hit, recovery, defeat, and retreat states
- deterministic failure and unbanked-cargo restoration
- viable evade and fight choices

Exit question: does combat add route pressure and preparation without taking over the salvage/exploration game?

### Expansion 07: Biological Resources And Weapon Progression

Goal: connect wildlife and enemies to useful progression.

Prove:

- at least one passive/nonlethal biological resource
- at least one hostile-creature material
- explicit sample, defeat, and harvest rules
- guaranteed replenishment and no mandatory grind
- one weapon or suit project using a thematically related biological component
- no circular dependency between enemy difficulty and required weapon

Exit question: do creatures feel like part of the ocean's ecology and technology rather than disposable loot containers?

### Expansion 08: Daily Conditions And Enemy Ecology

Goal: make tomorrow meaningfully different without erasing place memory.

Prove:

- readable next-day condition or opportunity forecast
- deterministic variation among authored material and encounter candidates
- controlled visibility/current or rare-signal variation
- a small set of passive, territorial, and hostile creature roles
- unchanged terrain topology and guaranteed progression paths

Exit question: does the forecast create a reason to plan another day while the map remains learnable?

### Expansion 09: Regional World Growth

Goal: expand into a coherent authored ocean made of memorable regions.

Each selected region needs:

- a landmark and visual identity
- an initial safe orientation route
- a capability promise or gate
- characteristic material opportunities
- wildlife/enemy identity
- one practical research thread
- one mystery or deeper lead
- a reason to return after first completion

Grow through JSON generators, validators, previews, parity, focused captures, and Web review. Do not productionize the whole sketch in one pass.

Exit question: can several regions support a durable expedition campaign without losing map authority or readability?

## Original OceanGame Convergence

Treat the original [joeypshell/OceanGame](https://github.com/joeypshell/OceanGame) repository as a design and behavior library.

### Reuse

- researcher-diver fantasy and practical discovery
- daylight with multiple oxygen sorties
- surface oxygen versus boat offload distinction
- stable geography with variable daily opportunity
- upgrades that open remembered places
- region identity, mystery, and learnable creature behavior

### Adapt

- `DiveSession`, progression, survival/day, condition, spawn-selection, and predator state concepts into focused current owners
- original resource and upgrade ideas into the new progression matrix
- original map/landmark ideas through the current JSON generator pipeline
- original behavior expectations into deterministic smokes rather than copied tests or scene coupling
- profile/save concepts into versioned minimal state with migration rules

### Reference

- visual assets, HUD studies, region names, vehicles, creature concepts, and tuning values
- use only after provenance, visual-fit, and current architecture review

### Reject

- Emergency Week and overnight Food/Water/Power survival consumption
- a direct code or scene port
- scene-owned gameplay placement and enormous scene files
- crowded always-visible HUDs
- arbitrary procedural geography
- broad inventory/crafting before projects prove useful
- shortcut or fast-travel networks that bypass expedition geography

## Execution Rules

- Close each milestone with GO, HOLD, or a smaller corrective pass before selecting the next.
- Keep approximately ten actionable issues only for the committed milestone.
- Preserve #52/#53 as deferred slice-03 polish unless slice-03 presentation becomes the selected goal.
- Source contract and validation precede map/entity authoring; authoring precedes runtime; smoke precedes visual acceptance; Web verification closes the pass.
- Do not expand `main.gd` or `greybox_world.gd` when a focused owner exists.
- Use the file-length policy as an agent-efficiency signal, not a reason to split cohesive runtime code into harmful abstractions.
- Every milestone must create curiosity, pressure, payoff, remembered-place progress, meaningful route choice, or a reason to begin another expedition day.
