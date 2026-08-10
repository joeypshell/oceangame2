# Game Spec

Date: 2026-08-08

## Working Title

OceanGame

## Product Identity

OceanGame is a side-view underwater expedition-raising game.

The player is a researcher-diver operating from a surface boat above a large,
remembered ocean cave system. They prepare equipment, explore under oxygen and
daylight pressure, study wildlife, recover useful resources, confront or avoid
danger, and return to the boat to care, research, build, and plan.

The emotional center is one bonded active creature whose individual growth is
shaped by meaningful shared expeditions. Depending on species anatomy and learned
adaptations, that individual may support the diver independently or become a
directly controlled mount.

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
-> command, support, or ride the companion while exploring, observing,
   gathering, fighting, evading, rescuing, or protecting
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
- The companion can remain independent or transfer movement/action control while
  mounted when its anatomy and bond support that role.
- A small tactical-pause command palette makes deliberate real-time coordination
  readable without turning expeditions into party battles.
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

Species define credible affordances such as carrying, sensing, shielding,
healing, bracing, or discharging. Experience and night choices specialize those
affordances so two individuals of the same species may play differently without
becoming anatomically arbitrary.

### Research And Ecology

The scanner should identify real organisms, anatomy, behavior, habitats,
environmental relationships, and artifacts. Research should improve decisions,
not award unrelated blueprints from abstract targets.

Some passive, defensive, or hostile wildlife may provide bounded biological
resources for equipment or care. Required resources use guaranteed authored
habitats, low counts, and non-circular dependencies.

### Stable And Individual History

The implemented stable has Kite the Spark Ray and Mica the Veil Cuttle in one
compact boat habitat, with exactly one active companion selected per launched
expedition. Mica's first ecological field proof is complete. The selected next
encounter proved Guardian-Pulse Kite's non-damaging eel interruption. The owner
rejected Mica's eel prediction as non-useful, so Drift Lens remains focused on
moving ecology and is not an active eel solution.

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

Combat and exploration remain real-time inside the shared side-view world.

- One active companion may support independently, fight beside the diver, or be
  ridden and directly controlled according to species and learned skills.
- Unmounted, the diver owns movement, tools, weapons, positioning, and retreat;
  deliberate companion actions use a bounded tactical-pause command palette.
- Mounted, movement and the action hotbar transfer to the creature until the
  player dismounts; diver tools are unavailable in that mode.
- The active companion provides readable movement, warning, distraction,
  interruption, defense, sensing, support, or direct creature actions according
  to its development.
- Enemies and defensive wildlife use learnable behaviors and territories.
- Fighting costs time, oxygen, health, position, cargo opportunity, or
  preparation.
- Killing everything is not the automatic best answer.
- Some enemies or wildlife may provide progression resources when the source
  contract makes the acquisition understandable and non-circular.

The design borrows build experimentation, role synergy, and field utility from
monster collectors such as Monster Sanctuary without adopting three-creature
turn-based combat, elemental charts, a giant initial roster, or generic battle
arenas. Detailed direction:
`docs/planning/REAL_TIME_CREATURE_PARTNERSHIP_DIRECTION.md`.

## First Direction Proof

The first companion is a rescued juvenile bioelectric Spark Ray. Day 1 rescues
and commits the individual at the canonical boat. Its first subsequently launched
sortie proves follow, a dedicated toggle `B/BOND` command palette, seamless
mount/dismount, direct mounted movement, and one non-damaging Glide Surge.

It records two meaningful memories:

- `held_the_flow` can become **Anchor Fins**, adding independent and mounted
  current bracing without bypassing propulsion-fin access.
- `stood_ground` can become **Guardian Pulse**, adding one deliberately aimed
  independent or mounted hostile interruption and knockback without replacing
  the Shock Prod.

The player chooses one at night. Day 3 changes the creature's body, independent
behavior, mounted action set, and immediate expedition possibilities.

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
- one persistent Spark Ray individual with rescue, follow, BOND tactical pause,
  committed-bond riding, two exact-once memories, night consolidation, and two
  mutually exclusive independent/mounted adaptations
- one persistent Veil Cuttle individual with physical rescue, compact shared
  boat habitat, next-sortie active selection, independent follow, and a
  deliberate Reveal Trace handoff to the Scanner
- one exact-once Mica ecological observation, night-consolidated Drift Lens
  adaptation, and deliberate Read Drift field skill for authored jellyfish
  patrols
- deterministic validators, progression audit, smokes, captures, baselines, and
  public Web deployment

The repository does not yet implement:

- an owner-approved second companion approach to the territorial eel; the
  attempted Mica prediction was deliberately retired
- generalized species runtime beyond the focused Spark Ray and Veil Cuttle
  owners
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
- more than one active expedition companion at a time
- a third species or broad stable-management surface before Living Expedition
  04 closes its owner-HOLD corrections
- breeding, fusion, genes, eggs, or inheritance
- feeding chores, hidden loyalty, lifespan, forced retirement, or creature death
- generalized ecosystem simulation
- broad economy, inventory grid, or unrestricted crafting tree
- vehicles, final art/audio, broad accessibility, balance, and save hardening
  before their selected milestones

## Current Proof Outcome

Living Expedition 04 received an owner HOLD. Guardian Pulse creates a useful
non-damaging opening, ordinary evade remains viable, and Shock Prod alone owns
defeat and harvest. Mica's prediction did not create a useful decision and is
retired from this eel while her moving-ecology Read Drift role remains intact.
Finish the bounded BOND timing correction and closeout before expanding the
enemy set, wildlife systems, or roster.
