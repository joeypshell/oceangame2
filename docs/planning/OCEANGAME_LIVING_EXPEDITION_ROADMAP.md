# OceanGame Living Expedition Roadmap

Date: 2026-08-10

Status: Active product roadmap. The completed diver-expedition work remains the
runtime foundation; this roadmap owns future product direction.

## Product Decision

OceanGame is becoming a side-view underwater expedition-raising game.

The player remains a researcher-diver operating from a surface boat, exploring
one remembered ocean world under oxygen, daylight, health, cargo, and route
pressure. The new emotional center is a bonded active creature whose individual
development is shaped by meaningful expeditions and deliberate night choices.
Exploration and combat remain real-time. Depending on species anatomy and learned
skills, the individual may support independently, fight beside the diver, or
become a directly controlled mount.

The signature promise is:

> Every dive writes the creature you are raising; every night lets you decide
> what those shared experiences become.

The existing equipment, map, day, night, resource, combat, validation, capture,
and Web systems are retained where they serve this promise. They are foundation,
not the complete game loop.

## Why The Direction Changed

The completed foundation proved that the project can deliver stable authored
geography, deterministic progression, controlled assets, pressure, tools,
combat, and exact Web review. Player feedback also identified a product-level
problem: repeated clue, recipe, gate, scan, and return chains felt generic and
did not create enough emotional attachment or anticipation for another day.

Adding more destinations, scanner targets, recipes, or score rewards would
extend that cadence without fixing it. The next phase must prove attachment,
individual development, and expressive choice before expanding content.

## Target Loop

```text
notice a creature, habitat, threat, or mystery
-> choose equipment and one active companion
-> dive through remembered geography
-> command, support, or ride the companion through a meaningful shared event
-> return discoveries, resources, and creature memories to the boat
-> care, research, build, and consolidate one memory at night
-> see a visible behavioral adaptation next morning
-> revisit the ocean with a changed partnership
```

Every day should leave at least one personal reason to return:

- a companion memory awaiting consolidation
- an adaptation whose payoff has not yet been tested
- a creature behavior or habitat relationship not yet understood
- a rescued individual recovering at the boat
- a region that needs a different companion specialty
- a threat the current pair is not prepared to handle

## Foundation Classification

### Retain

- contiguous source-authored geography and remembered routes
- oxygen sorties inside a finite daylight day
- canonical-boat banking, commitment, care, and night transition
- blueprints, materials, and night projects for diver equipment
- health, active tools, weapons, hazards, and readable failure
- deterministic map/progression validation, smokes, captures, and Web review

### Adapt

- scanner research toward real species, habitats, behavior, and anatomy
- biological resources toward bounded ecological and progression roles
- combat toward diver-and-companion tactical cooperation
- controls toward one readable independent/mounted partnership rather than a
  passive pet or interchangeable party roster
- night debrief toward care, memory consolidation, research, and preparation
- map progression toward equipment access plus companion opportunities
- profile state toward a small set of persistent individuals

### Stop Extending As The Main Loop

- consecutive clue -> recipe -> gate -> generic scan chains
- abstract markers that award unrelated progression
- score as the primary meaning of exploration
- one-off equipment that exists only for one matching barrier
- generic salvage as the main reason to cross the map
- HUD instructions substituting for environmental motivation

### Reject

- Emergency Week or Food/Water/Power survival taxes
- fast travel or shortcut networks that erase remembered geography
- giant creature catalogs before individual attachment works
- random mutation, generic XP grinding, or repeated exposure farming
- turn-based party combat, elemental charts, and generic encounter arenas
- full ecosystem simulation, breeding, fusion, or forced creature death now

## Planning Horizons

### Completed

**Living Expedition 01: Spark Ray Adaptation Proof** is implemented and closed
with owner GO. It proves one physical rescue, persistent individual identity,
follow, tactical-pause commands, riding, two meaningful memories, night
consolidation, mutually exclusive visible adaptations, equipment-gate safety,
and deterministic journey/Web evidence.

**Living Expedition 02: Small Stable And Species Identity** is implemented and
closed with owner GO. It proves schema-v2 migration, a compact two-individual
boat habitat, one active next-sortie selection, Mica's independent sensing role,
Kite's retained mounted role, optional Reveal Trace evidence, equipment-gate
safety, and deterministic journey/visual/Web evidence.

**Living Expedition 03: Field Roles And Ecological Discovery** is implemented
and closed with owner GO on corrected exact-Web runtime `0e92dd7`. It proves one
Mica-revealed jellyfish migration, held Scanner identification, exact-once boat
commitment, deliberate night consolidation, and next-sortie Drift Lens without
changing topology, hard access, hazard authority, or rewards.

**Living Expedition 04: Companion-Shaped Wildlife Encounter** is technically
complete and closed on owner HOLD. Guardian-Pulse Kite remains a useful eel
opening, Mica's non-useful eel prediction is retired, and BOND now pauses the
whole simulation during command selection.

**Living Expedition 05: Silt Hound Excavation Proof** is implemented and closed
with owner GO on corrected exact-Web runtime `7792a08`. It proves one third
individual, schema-v3 migration, compact habitat selection, and one deliberately
commanded physical excavation that exposes an existing typed material through
normal cargo and boat-banking owners. Correction #1362 repaired the focused
checkpoint before the accepted retest.

### Committed

No next milestone is committed. The next audit must select one bounded proof
from the directional horizon without automatically adding a fourth species.

### Directional

Only milestone-level goals are selected beyond the committed proof:

1. **Living Expedition 06: Regional Creature Journeys**
   Add memorable regions whose equipment access, species ecology, mysteries,
   and return reasons are planned together through the JSON map pipeline.
2. **Later: Growth, Release, And Habitat Legacy**
   Test voluntary retirement or release, one bounded legacy trait, and visible
   habitat consequences only after enough individuals have reviewed history for
   the choice to carry emotional weight, without forced death or a simulation
   rewrite.

These directions do not receive detailed issue inventories until a later audit
selects one bounded proof after Living Expedition 05's closeout.

### Vision

Long-term possibilities include a larger stable, lineage systems, richer boat
habitats, deeper combat, more region production, final art/audio, accessibility,
controller support, balance, and save hardening. They remain intentionally
unticketed.

## Latest Completed Milestone Batch

Living Expedition 05 completed one dependency-ordered batch: contract, schema
and progression validation, profile migration and three-row habitat,
source-first rescue/deposit authoring, Silt Hound follow/presentation,
deliberate Excavate runtime, integrated journey, deterministic evidence,
focused visual decision, corrected exact-Web checkpoint, and owner GO.
`docs/current/LIVING_EXPEDITION_05_CLOSEOUT.md` records the verdict.

## Prior Completed Milestone Batch

Living Expedition 02 completed one bounded issue batch in this order:

1. Lock source, state, habitat, selection, and failure contracts.
2. Extend catalog/schema validation and migrate profile state to a bounded
   two-individual collection.
3. Implement the compact boat habitat and next-sortie active selection.
4. Author one Veil Cuttle rescue, habitat, optional trace, and review camera.
5. Implement Veil Cuttle presentation, follow identity, and Reveal Trace.
6. Integrate species-specific sortie instantiation, commands, guidance, failure,
   and reload while preserving all Kite behavior and access gates.
7. Add deterministic journey, migration, selection, isolation, and progression
   audit coverage.
8. Add focused desktop/mobile captures and record the visual decision.
9. Verify the exact public Web build and named checkpoint.
10. Run the owner closeout and record GO, HOLD, or bounded corrections.

Do not combine the compact habitat with a third species, broad stable UI,
Mica adaptation tree, turn-based or broad combat framework, map expansion, or
accepted-baseline sweep.

## Map And Progression Rules

- Equipment owns predictable hard geographic access.
- Companions change what the pair can accomplish within reachable regions.
- A paired challenge must justify both requirements and remain non-circular.
- Habitats, rescue sites, memory opportunities, and payoffs are source-authored.
- Mutable individual state belongs to a focused versioned profile owner.
- Random daily selection may vary optional opportunities, never required
  rescue, memory, or progression prerequisites.
- The progression graph must include creature relationships before source
  authoring lands.

Detailed contract:
`docs/planning/CREATURE_MAP_PROGRESSION_SPEC.md`.

## Creature-System Rules

- One active companion is the emotional and mechanical center of a dive.
- Species define possibilities; individual history defines the selected build.
- A capable individual may alternate between independent and mounted play during
  the same dive; mounted control is a role, not an equipment-gate bypass.
- Significant companion actions are deliberate through toggle `B/BOND` and a
  bounded numbered tactical-pause palette, not hidden autonomous damage.
- Meaningful events create memories; repetition does not create major growth.
- The player chooses permanent adaptations with predictable consequences.
- Temperament affects expression, not critical command reliability.
- Creatures remain living participants rather than inventory, currency, or
  equipment slots.

Detailed contract: `docs/planning/CREATURE_SYSTEM_SPEC.md`.
Control/combat decision:
`docs/planning/REAL_TIME_CREATURE_PARTNERSHIP_DIRECTION.md`.

## Execution Rules

- Keep current-runtime truth separate from target-game plans.
- Historical Phase 2 docs remain implementation records, not active direction.
- Use one focused issue batch and close with GO, HOLD, or bounded correction.
- Living Expeditions 01-03 and 05 received GO; Living Expedition 04 closed on
  HOLD. Keep Kite, Mica, and Marl as the complete current roster until a later
  reviewed plan selects another species.
- Do not use automation to claim fun, attachment, or replay motivation.
- Keep #52/#53 deferred unless slice-03 presentation becomes the selected goal.
- Preserve the 500-line agent-efficiency target without harmful runtime splits.

## Living Expedition 04 Outcome

The answer to the original companion-choice question was HOLD: Mica's prediction
did not produce a useful eel decision. Her ecology role and Kite's opening are
preserved, BOND timing is corrected, exact Web evidence is green, and the
bounded experiment is closed. No later milestone is selected by that closeout.
