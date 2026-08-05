# OceanGame Living Expedition Roadmap

Date: 2026-08-05

Status: Active product roadmap. The completed diver-expedition work remains the
runtime foundation; this roadmap owns future product direction.

## Product Decision

OceanGame is becoming a side-view underwater expedition-raising game.

The player remains a researcher-diver operating from a surface boat, exploring
one remembered ocean world under oxygen, daylight, health, cargo, and route
pressure. The new emotional center is a bonded active creature whose individual
development is shaped by meaningful expeditions and deliberate night choices.

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
-> survive a meaningful shared event
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
- broad turn-based party combat as the first creature implementation
- full ecosystem simulation, breeding, fusion, or forced creature death now

## Planning Horizons

### Committed

**Living Expedition 01: Spark Ray Adaptation Proof** receives one issue-level
implementation batch after this roadmap lands.

It must prove:

- one physical rescue and stable individual identity
- one active companion with readable follow and context behavior
- two meaningful memories earned through real expedition events
- one deliberate night consolidation choice
- one visible adaptation on the following day
- one exploration branch and one protection branch
- no bypass of existing diver-equipment access gates
- deterministic persistence, failure, capture, and Web evidence
- an owner verdict on attachment and another-day motivation

### Directional

Only milestone-level goals are selected beyond the first proof:

1. **Living Expedition 02: Small Stable And Species Identity**
   Add two contrasting species, a compact boat habitat, one active selection,
   clear individual records, and reasons to care about inactive companions.
2. **Living Expedition 03: Field Roles And Ecological Discovery**
   Make species perception and behavior reveal real habitats, organisms,
   resources, and mysteries without turning creatures into keys.
3. **Living Expedition 04: Duo Combat And Wildlife Consequences**
   Expand real-time diver-and-companion tactics, enemy behavior, nonlethal
   responses, and bounded wildlife resources.
4. **Living Expedition 05: Growth, Release, And Habitat Legacy**
   Test voluntary retirement or release, one bounded legacy trait, and visible
   habitat consequences without forced death or a simulation rewrite.
5. **Living Expedition 06: Regional Creature Journeys**
   Add memorable regions whose equipment access, species ecology, mysteries,
   and return reasons are planned together through the JSON map pipeline.

These milestones do not receive detailed issue inventories until the preceding
player gate closes.

### Vision

Long-term possibilities include a larger stable, lineage systems, richer boat
habitats, deeper combat, more region production, final art/audio, accessibility,
controller support, balance, and save hardening. They remain intentionally
unticketed.

## Committed Milestone Batch

Freeze approximately ten issues for Living Expedition 01 in this order:

1. Lock companion experience, controls, source, state, and failure contracts.
2. Add species, rescue, memory, adaptation, and payoff schema validation.
3. Add versioned individual companion state and profile migration.
4. Implement deterministic Spark Ray follow, separation, and context behavior.
5. Author one rescue and two memory opportunities through the map source path.
6. Implement exact-once memory qualification and night consolidation.
7. Implement Anchor Fins exploration adaptation and visual change.
8. Implement Guardian Pulse protection adaptation and visual change.
9. Add deterministic journey smoke, review checkpoint, and focused captures.
10. Verify the exact public Web build and run the three-day owner closeout.

Do not combine the two adaptations with a second creature, roster UI, broad
combat framework, map expansion, or accepted-baseline sweep.

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
- Meaningful events create memories; repetition does not create major growth.
- The player chooses permanent adaptations with predictable consequences.
- Temperament affects expression, not critical command reliability.
- Creatures remain living participants rather than inventory, currency, or
  equipment slots.

Detailed contract: `docs/planning/CREATURE_SYSTEM_SPEC.md`.

## Execution Rules

- Keep current-runtime truth separate from target-game plans.
- Historical Phase 2 docs remain implementation records, not active direction.
- Use one focused issue batch and close with GO, HOLD, or bounded correction.
- Do not add species until the Spark Ray proof answers its attachment question.
- Do not use automation to claim fun, attachment, or replay motivation.
- Keep #52/#53 deferred unless slice-03 presentation becomes the selected goal.
- Preserve the 500-line agent-efficiency target without harmful runtime splits.

## Living Expedition 01 Exit Question

> Did the Spark Ray feel like an individual shaped by what happened during the
> expedition, and did seeing its adaptation make the player want to begin
> another day to discover what the partnership could become?

If the result feels like another tool, gate key, passive follower, checklist,
or skill-tree token, HOLD before creating a second species.
