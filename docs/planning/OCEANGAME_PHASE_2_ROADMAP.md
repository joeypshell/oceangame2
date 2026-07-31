# OceanGame Phase 2 Roadmap

Date: 2026-07-31

Status: Expansions 01-16 are complete with player GO. Expansion 16 Deeper Wreck
Oxygen Return closed on exact reviewed runtime `05b482e`. No Expansion 17
direction or implementation milestone is selected.

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
- The main explorable world is contiguous authored geography by default. Separate loaded maps are exceptions for explicit interiors or exceptional destinations, not the normal capability-gate chain.
- Expansion 09 established the complete full-sketch topology as one production level before any exceptional destination transition. The optional current stabilizer is not an entry requirement for that level.
- Standard currents are passive traversal gates: blocked by flow before the capability, crossed through normal swimming after it. `E`/ACT is reserved for explicit entrances and interactions.
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

No new implementation milestone. The next audit must evaluate project
direction before selecting and batching Expansion 17.

### Proposed

No Expansion 17 direction is selected.

### Directional

Other regional identities and exceptional interiors remain directional. Broad
oxygen or pressure simulation and later equipment tiers remain uncommitted.

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

Status: Complete with GO.

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

Status: Complete with GO.

Goal: make gathering support one concrete capability project.

Prove:

- a minimal typed-material contract
- authored candidate pools with deterministic seed selection and guaranteed prerequisites
- one blueprint/project requiring knowledge, common materials, and one special component
- one active tool that changes a remembered interaction
- night project progress without an inventory grid or broad crafting tree

Exit question: does finding material create anticipation for a specific return rather than feel like generic currency?

### Expansion 04: Capability-Gated Map Progression

Status: Complete with GO.

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

Status: Complete with GO.

Goal: make one scanner finding useful to next-day resource planning.

Prove:

- one resource clue appears behind a remembered capability gate
- the scanner creates one pending finding that commits only at the boat
- committed research changes a fresh-day material selection and exposes a broad habitat lead
- practical knowledge changes route planning without increasing yield
- partial information creates curiosity rather than exact-route instructions

Exit question: does research make the player smarter and change the next expedition decision?

### Expansion 06: Combat Foundation

Status: Complete with GO.

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

Status: Complete with technical GO. See `docs/current/OCEANGAME_EXPANSION_07_CLOSEOUT.md`; the decision proves technical readiness and does not claim automation proved player experience.

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

Status: Complete with technical GO. See `docs/current/OCEANGAME_EXPANSION_08_CLOSEOUT.md`; the decision proves technical readiness and does not claim automation proved the player-facing exit question.

Goal: make tomorrow meaningfully different without erasing place memory.

Prove:

- readable next-day condition or opportunity forecast
- deterministic variation among authored material and encounter candidates
- controlled visibility/current or rare-signal variation
- a small set of passive, territorial, and hostile creature roles
- unchanged terrain topology and guaranteed progression paths

Exit question: does the forecast create a reason to plan another day while the map remains learnable?

### Expansion 09: Contiguous Full-Level Foundation

Status: Complete with player GO. See `docs/current/OCEANGAME_EXPANSION_09_CLOSEOUT.md`.

Goal: promote the entire supplied cave topology into one coherent production level before adding teleport or connector-based world expansion.

Prove:

- a separately named full-level JSON generated from `full_cave_sketch_01`
- one continuous water space from the top boat through representative upper-left, lower-left, and lower-right areas and back
- source-owned transformation of the proven slice-01 gameplay overlay into full-map coordinates
- no stitched crop JSON, imported crop-edge seals, teleport, prompted connector, map menu, or stabilizer entry gate
- sealed unintended outer-boundary openings while preserving the authored top-water boat entry
- player-footprint clearance, entity reachability, direct return, render/collision parity, camera bounds, and practical runtime performance
- candidate-only local and Web review followed by explicit player GO and default promotion
- unchanged production slices 01-04 as regression and provenance fixtures

Later milestones may author regional identities, capability gates, wildlife, research, and exceptional interiors inside or beyond the contiguous world. The current stabilizer and new pressure progression remain deferred until separately selected.

Exit question: can the player launch at the boat, swim through the full authored cave, understand where they are, and return without a teleport while map authority and runtime readability remain trustworthy? **GO recorded at #864/#865.**

### Expansion 10: East-Current Regional Journey

Status: Complete with player GO. See
`docs/current/OCEANGAME_EXPANSION_10_CLOSEOUT.md` and closed
[milestone #36](https://github.com/joeypshell/oceangame2/milestone/36).

Goal: make the existing east current the readable entrance to one meaningful
lower-right place, using the established fins, scanner, and boat-return loop.

Prove:

- the current promises a larger route before fins are available
- the existing blueprint/material/night project unlocks passive crossing
- continuous collision-active swimming reaches a recognizable lower-right landmark
- one scanner-backed result remains pending until canonical-boat return
- the committed payoff gives a broad reason to begin another expedition
- direct full-level progression auditing catches circular or unreachable dependencies
- focused desktop/mobile captures, Web verification, and player GO/HOLD close the pass

No teleport, prompted current crossing, stabilizer entry, pressure capability,
broad map population, or second new traversal capability belongs in this milestone.

Exit question: did building fins turn the east current into the entrance to a
place the player remembers, and did the lower-right payoff make the return journey
and another expedition feel worthwhile? **GO recorded at #889 after correction
#900.**

### Expansion 11: Deep-Harmonic Light Return

Status: Complete with player GO. See
`docs/current/OCEANGAME_EXPANSION_11_CLOSEOUT.md` and closed
[milestone #37](https://github.com/joeypshell/oceangame2/milestone/37).

Goal: replace the score-owned session light with one durable knowledge/material
project and use it to resolve a remembered dark harmonic survey beyond Signal
Reef without changing topology.

Prove:

- Signal Reef knowledge unlocks one exact light recipe
- guaranteed base materials plus a nonlethal biological component support it
- night construction creates one durable capability owner
- existing darkness readability improves and one survey requires the light
- movement remains continuous, with no invisible wall or prompted crossing
- the result remains pending until canonical-boat return
- source, progression, smoke, visual, mobile, and Web evidence remain controlled

Non-goals include pressure progression, terrain expansion, global lighting,
batteries, inventory, a second light tier, broad region population, and changes
to oxygen/cargo upgrades.

Exit question: did the Signal Reef clue, material hunt, and night-built light
make returning to the dark lower-right route feel like a capability earned for a
place the player remembered, with a payoff worth bringing back to the boat?
**GO recorded at #914 after corrections #925/#927.**

### Expansion 12: Abyssal Pressure Return

Status: Complete with player GO in #941 after corrections #951-#953. See
`docs/current/OCEANGAME_EXPANSION_12_CLOSEOUT.md`.

Goal: turn the committed deep-harmonic clue into one durable pressure-suit
project and one return through existing continuous geography to the
lower-central abyssal basin.

Prove:

- exact Ti2/Rubber1/Gel1 night construction and one durable capability owner
- a source-authored pressure threshold that is briefly scoutable before the suit
- accelerated unprotected oxygen drain that the optional `O2 tank +15` cannot bypass
- normal zone drain and useful return margin after the pressure suit
- one basin landmark, timed finding, pending state, and canonical-boat commitment
- unchanged terrain, collision, slices, session upgrades, health, and normal travel

Non-goals include global pressure simulation, health damage, terrain expansion,
loaded destinations, oxygen rebalance, new materials, inventory, enemies,
vehicles, and broad art replacement.

Exit question: did the deep-harmonic clue, pressure warning, material hunt, and
night-built suit make the abyssal basin feel like a dangerous place the player
learned to reach, with a payoff worth carrying back to the boat?
**GO recorded at #941 after corrections #951-#953.**

### Expansion 13: Southeast Wreck Return

Status: Complete with player GO. #960-#968 delivered the original journey;
#980/#982-#990 and #1000-#1009 resolved two bounded HOLD reviews; #1020-#1023
resolved the audio interlude. The owner reviewed exact runtime `ede39d1` and
reported the corrected experience was fine. See
`docs/current/OCEANGAME_EXPANSION_13_CLOSEOUT.md`.

Goal: turn the empty farthest southeast chamber into one memorable wreck
journey that pays off the existing pressure suit, cutter, and scanner while
making oxygen preparation useful without making score mandatory.

Prove:

- one source-authored wreck landmark in unchanged contiguous geography
- a route that crosses the existing pressure zone and returns to the boat
- one cutter-opened recorder explicitly exposing one scanner survey
- base oxygen remains technically viable but tight; optional `O2 tank +15`
  provides a useful margin without becoming a source prerequisite
- cargo-full, failure, reload, pending finding, and exact-once boat commitment
  retain their established owners and semantics
- focused source, progression, smoke, visual, mobile, and Web evidence

Non-goals include a new oxygen upgrade, recipe, material, capability, terrain
expansion, interior transition, teleport, connector, global oxygen/pressure
rebalance, enemy, vehicle, inventory, or broad art pass.

Exit question: did the distant wreck turn prior upgrades and the far southeast
route into a tense, memorable expedition whose discovery felt worth bringing
back to the boat?
**GO recorded at #969 after the bounded corrections and exact-runtime owner replay.**

### Expansion 14: Archive Current Return

Status: Complete with owner GO in #1040. Milestone #40 includes base issues
#1031-#1039, checkpoint work #1056/#1057, bounded corrections
#1061/#1063/#1065 and #1069-#1077, replay fixes #1087/#1088, and exact public
runtime `1f148eb`. At that closeout, no later expansion had been selected.

Goal: turn the committed southeast archive's unresolved wreck-network lead into
the existing Ti2/Coil1 Current Stabilizer project and one return through a
source-authored advanced current to a Northwest Wreck Relay in the underused
upper-left sector of continuous `production_level_01`.

Prove:

- archive knowledge, guaranteed base materials, and one exact night build form
  a non-circular capability chain
- the current visibly blocks normal inward swimming before the stabilizer and
  permits ordinary two-way swimming after it, without `E` or a transition
- the route, landmark, valuable relay core, survey, and canonical-boat result
  are source-authored and represented in the executable progression graph
- existing failure, cargo-full, pending discovery, reload, and exact-once
  profile semantics remain stable
- one bounded held-cargo strip clarifies current-sortie risk while active tools,
  vitals/objectives, and contextual prompts retain separate responsibilities
- focused source, smoke, visual, mobile, player, and exact-SHA Web evidence
  agree before closeout

Non-goals include terrain expansion, connector travel, teleport, a new
capability or material, score-gated progression, broad economy/inventory/HUD
work, another enemy, vehicle, or slice-03 polish.

Exit question: did the archive clue, night-built stabilizer, visible current,
and Northwest Wreck Relay feel like one place the player earned access to, with
a payoff clear enough to motivate and complete another expedition?
**GO recorded at #1040 after bounded corrections and exact-runtime owner
replay.**

### Expansion 15: Expedition Planning And Choice

Status: Complete with owner GO in #1104. Milestone #41 includes planning
#1094, issues #1095-#1104, and bounded corrections #1113/#1117/#1119. The
exact reviewed runtime is `23f4172`.

It proves two source-derived night choices, session/day-scoped selection,
shared desktop/mobile controls, and distinct next-day guidance without markers,
automatic navigation, profile mutation, or reward ownership. **GO recorded at
#1104 after bounded corrections and exact-runtime owner replay.**

### Expansion 16: Deeper Wreck Oxygen Return

Status: Complete with owner GO through #1133. Milestone #42 includes planning
#1122, issues #1124-#1133, and bounded corrections #1143-#1146/#1151/#1153.
The exact reviewed runtime is `05b482e`.

Goal: turn the committed Northwest relay signal into one prepared far-west
wreck return through existing continuous geography.

Prove:

- a Ti1/Rubber1/Coil1/Gel1 night project grounded in relay knowledge
- one durable closed-circuit rebreather capability
- a visible route-local oxygen-pressure zone that is scoutable before the build
- deterministic evidence that the session tank cannot substitute for the build
- existing cutter and held scanner use at one recognizable wreck
- pending failure cleanup and exact-once canonical-boat discovery commitment
- no terrain, connector, teleport, new material, enemy, or global oxygen change

Exit question: did the relay clue, material project, and rebreather turn the
far-west wreck into a place the player could first scout and later complete
safely, with a discovery worth returning to the boat?

**GO recorded at #1133 after bounded discoverability and HUD corrections.**

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

- Close each milestone with GO, HOLD, or a smaller corrective pass before selecting the next. A technical GO must preserve any unresolved human experience question explicitly.
- Keep approximately ten actionable issues only for the committed milestone.
- Preserve #52/#53 as deferred slice-03 polish unless slice-03 presentation becomes the selected goal.
- Source contract and validation precede map/entity authoring; authoring precedes runtime; smoke precedes visual acceptance; Web verification closes the pass.
- Do not expand `main.gd` or `greybox_world.gd` when a focused owner exists.
- Use the file-length policy as an agent-efficiency signal, not a reason to split cohesive runtime code into harmful abstractions.
- Every milestone must create curiosity, pressure, payoff, remembered-place progress, meaningful route choice, or a reason to begin another expedition day.
