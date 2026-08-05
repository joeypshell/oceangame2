# Game Spec

Date: 2026-08-05

## Working Title

OceanGame

## Product Identity

OceanGame is a side-view underwater expedition-raising game.

The player is a researcher-diver operating from a surface boat above a large,
remembered ocean cave system. They prepare equipment, explore under oxygen and
daylight pressure, study wildlife, recover useful resources, confront or avoid
danger, and return to the boat to care, research, build, and plan.

The emotional center is one bonded active creature whose individual growth is
shaped by meaningful shared expeditions.

The signature promise is:

> Every dive writes the creature you are raising; every night lets you decide
> what those shared experiences become.

## Player Fantasy

The player should feel like an increasingly capable ocean researcher who knows
the geography, understands its wildlife, develops practical equipment, and
builds a history with distinct creature companions.

Progress is not only reaching a deeper room or earning a larger number. It is:

- recognizing a place and understanding what lives there
- preparing the right equipment and companion for an expedition
- surviving an event that changes the partnership
- watching an individual creature develop because of what happened
- using that development to interact with the ocean differently
- returning to the boat with a reason to care about tomorrow

## Target Core Loop

```text
notice a creature, habitat, threat, resource, or mystery
-> choose equipment and one active companion
-> dive through remembered geography under oxygen and daylight pressure
-> explore, observe, gather, fight, evade, rescue, or protect
-> create meaningful shared experiences
-> return to the canonical boat and commit the expedition
-> care, research, build, and consolidate one creature memory at night
-> begin the next day with a visibly changed partnership
```

One day supports multiple oxygen sorties. Open surface water refills oxygen;
only the canonical boat banks cargo, commits discoveries and creature state,
supports care/projects, and ends the day.

## Product Pillars

### Living Partnership

- One active companion is present and readable during a dive.
- Species define possibilities; individual history defines development.
- Meaningful events create memories; repetition does not create major growth.
- Night consolidation turns one understood memory into a visible adaptation.
- Personality affects expression without making critical controls unreliable.

### Remembered Expedition World

- Geography is contiguous, source-authored, and learnable.
- Equipment opens predictable hard access through current, darkness, pressure,
  wreck, and later capability gates.
- Companions change what the pair can accomplish within reachable regions.
- Habitats, threats, resources, mysteries, and adaptation opportunities are
  planned together.
- Fast travel and shortcut networks do not erase the journey.

### Preparation And Pressure

- Oxygen is the tactical sortie budget.
- Daylight is the strategic expedition budget.
- Health, cargo, tools, weapons, currents, and hostile behavior create route
  decisions.
- The player may evade, observe, distract, rescue, disable, fight, sample, or
  harvest according to the species and encounter contract.
- Failure is readable and deterministic rather than a hidden permanent penalty.

### Meaningful Nights

Night is a compact consequence and preparation phase, not a survival tax.

It supports:

- creature memory consolidation and recovery
- practical research and ecological understanding
- blueprint and material projects for diver equipment
- expedition review and next-day planning
- visible anticipation for what changes tomorrow

There is no Emergency Week and no Food/Water/Power overnight consumption loop.

## Progression Systems

### Diver Equipment

Knowledge plus guaranteed materials plus an appropriate component creates a
tool, suit capability, or weapon. Equipment owns direct player verbs and hard
geographic access.

Examples include fins, light, pressure protection, cutter, scanner, rebreather,
Current Stabilizer, and Shock Prod. Existing equipment remains foundation, but
future projects must serve creature, habitat, threat, or region goals rather
than extend a recipe-and-gate treadmill.

### Companion Development

```text
meaningful shared event -> individual memory -> night consolidation
-> permanent adaptation -> visible next-day payoff
```

Companion adaptation is not bought with score and is not unlocked by generic
experience points. Later adaptations may require a thematically related care
item or biological catalyst, but the item cannot replace the lived memory.

### Research And Ecology

The scanner should identify real organisms, anatomy, behavior, habitats,
environmental relationships, and artifacts. Research should improve decisions,
not award unrelated blueprints from abstract targets.

Some passive, defensive, or hostile wildlife may provide bounded biological
resources for equipment or care. Required resources use guaranteed authored
habitats, low counts, and non-circular dependencies.

### Stable And Individual History

The first proof has one individual. A later compact boat habitat may hold a
small stable with one active companion selected per expedition.

The game should preserve individual names/callsigns, temperament, memories,
adaptations, and important history. Large storage catalogs, breeding, fusion,
and disposable duplicates are not current goals.

## Exploration And Map Progression

The map is planned on two connected axes:

1. **Diver access:** equipment determines where the diver can travel or survive.
2. **Companion opportunity:** individual adaptations determine what the pair can
   understand, stabilize, protect, or accomplish there.

A paired challenge may occasionally require both, but a companion cannot
silently substitute for the equipment that opens a mandatory region.

Detailed rules:

- `docs/MAP_SPEC.md`
- `docs/planning/CAPABILITY_RESOURCE_PROGRESSION_MATRIX.md`
- `docs/planning/CREATURE_MAP_PROGRESSION_SPEC.md`

## Combat Direction

Combat remains real-time inside the side-view expedition world.

- The diver controls movement, weapons, positioning, and retreat.
- The active companion provides readable warning, distraction, interruption,
  defense, sensing, or support according to its development.
- Enemies and defensive wildlife use learnable behaviors and territories.
- Fighting costs time, oxygen, health, position, cargo opportunity, or
  preparation.
- Killing everything is not the automatic best answer.
- Some enemies or wildlife may provide progression resources when the source
  contract makes the acquisition understandable and non-circular.

The first creature proof adds one protection action, not party combat,
tournaments, elemental charts, or a broad arsenal.

## First Direction Proof

The first companion is a rescued juvenile bioelectric Spark Ray.

It records two meaningful memories:

- `held_the_flow` can become **Anchor Fins**, supporting one difficult
  interaction inside current without bypassing propulsion-fin access.
- `stood_ground` can become **Guardian Pulse**, supporting one contextual
  hostile interruption and knockback without replacing the Shock Prod.

The player chooses one at night. The next morning changes the creature's body,
behavior, and immediate expedition possibilities.

Detailed contract:
`docs/planning/EXPEDITION_ADAPTATION_DIRECTION.md`.

## Current Runtime Foundation

The repository currently implements:

- one contiguous source-authored production cave plus regression slices
- direct swimming, oxygen, daylight, repeated sorties, health, and cargo
- canonical-boat banking, night transition, materials, blueprints, and projects
- fins, scanner, cutter, light, pressure suit, rebreather, stabilizer, and Shock
  Prod progression
- current, darkness, pressure, wreck, hostile, research, and interior journeys
- one territorial eel and bounded biological resources
- deterministic validators, progression audit, smokes, captures, baselines, and
  public Web deployment

The repository does not yet implement:

- a general creature/species model
- persistent individual companions or a stable
- follow, context, memory, or adaptation runtime
- creature-focused night care or consolidation
- scalable creature art, animation, audio, behavior, or combat architecture

Current runtime truth is documented in `docs/current/PROJECT_CONTEXT.md` and
`docs/current/ARCHITECTURE.md`. Target direction is documented in
`docs/planning/OCEANGAME_LIVING_EXPEDITION_ROADMAP.md`.

## Source And Validation Rules

- JSON/generators own geography, habitats, encounter sites, rescue sites,
  memory opportunities, and payoff relationships.
- Runtime and versioned profile owners hold mutable individual state.
- Do not hand-author gameplay placement in Godot scenes.
- Validate reachability, player footprint, equipment prerequisites, companion
  relationships, non-circular progression, failure, and exact-once state.
- Use focused captures and exact Web checkpoints for final presentation review.
- Do not regenerate whole scenes to revise one creature or adaptation asset.

## Current Non-Goals

- procedural geography
- fast travel or shortcut networks
- Emergency Week or overnight survival-resource taxes
- giant creature roster or storage UI
- turn-based three-creature party combat
- breeding, fusion, genes, eggs, or inheritance in the first proof
- feeding chores, hidden loyalty, lifespan, forced retirement, or creature death
- generalized ecosystem simulation
- broad economy, inventory grid, or unrestricted crafting tree
- vehicles, final art/audio, broad accessibility, balance, and save hardening
  before their selected milestones

## Product Success Question

The next proof succeeds when the player can answer yes:

> Did this creature feel like an individual shaped by what happened during our
> expedition, and did seeing its adaptation make me want to begin another day?

If not, add no second species. Correct the relationship and loop first.
