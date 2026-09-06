# Creature System Spec

Date: 2026-09-06

Status: Active source/planning contract. LE01-06 implement Kite, Mica, and Marl,
the schema-v3 three-individual habitat with one active companion, Kite/Mica
adaptations, Marl's rescue/excavation, and Kite's remembered Signal Reef nursery.
LE04's rejected Mica eel prediction stays retired. LE07 selects Marl's first
memory and Root Claws in `docs/current/LIVING_EXPEDITION_07_PLAN.md`; that growth
and Ground Pin are planned, not current runtime behavior.

## Purpose

Define the smallest creature system that can make OceanGame an expedition-
raising game without discarding the diver, equipment, map, pressure, and night
foundation.

This contract separates species possibility, individual history, live behavior,
and persistent development so future implementations do not turn companions
into tools, quest rewards, or unvalidated state inside `main.gd`.

The provisional roster, species-review template, and regional ecology-cluster
direction live in `docs/planning/MONSTER_SPECIES_DESIGN_BIBLE.md`. That planning
document distinguishes the three implemented species from future concepts.
LE05's owner GO approved Marl's base proof, not a fourth species or every
directional adaptation.

## Foundational Rules

- The implemented catalog/habitat supports exactly three named individuals.
  Rescue commitment determines availability; each sortie has one active slot.
- The current eel proof retains Guardian-Pulse Kite as its sole useful companion
  response. Mica's rejected eel prediction is retired while her moving-ecology
  role remains intact; the proof adds no individual or habitat growth.
- Acquisition begins through observation, aid, rescue, or trust, not an abstract
  capture device.
- Species provide a body plan, instincts, possible memories, adaptations, and
  ecological role, including whether riding is physically credible.
- Individuals provide identity, temperament, lived memories, selected
  adaptation, condition, and relationship history.
- Major growth comes from meaningful shared events plus night consolidation,
  never generic experience points.
- The player chooses critical adaptations; randomness cannot decide required
  progression.
- Companions may support independently or become directly controlled mounts, but
  do not replace equipment gates, survival ownership, or deliberate player agency.

## Species And Individual State

A species definition provides immutable data such as:

- `species_id`
- display name and short ecological description
- base visual and animation set
- movement and follow envelope
- allowed independent/mounted roles, rider footprint, and base creature actions
- temperament options
- eligible memory kinds
- adaptation branches and compatibility
- field, sensing, protection, or combat roles
- habitat and encounter tags

A versioned individual record should own only persistent mutable state such as:

- `individual_id`
- `species_id`
- stable callsign or display name
- temperament id or deterministic seed
- rescue/availability state
- active-companion selection
- earned memory ids
- selected adaptation ids
- bounded condition or recovery state when implemented
- legacy/release state only after a later milestone selects it

Position, target, follow velocity, control mode, mounted state, palette selection,
cooldowns, animation state, and in-progress encounters are live runtime state,
not profile data. Riding availability is derived from committed rescue and active
selection; it is not a separately purchased profile capability.

## Acquisition And Bond

The first companion is rescued from a physical, source-authored situation. The
player should understand what happened to it and why it chooses to remain at the
boat.

The proof does not add:

- capture probability
- creature currency or purchase
- egg rarity tables
- feeding chores
- hidden loyalty failure
- breeding or fusion
- permanent death

Bond is expressed first through reliable behavior, proximity, visible response,
shared memories, and the night scene. A numeric bond meter is not required to
prove attachment.

The first canonical-boat return commits the rescued Spark Ray. Riding becomes
available on the next launched sortie, normally Day 2 in the first-proof review
path. The trust payoff is not granted inside the rescue encounter.

## Active Companion Behavior

The active companion should:

- enter the water with the diver and remain visually identifiable
- follow through normal collision-active geography
- choose readable near, catch-up, separated, and recovery states
- avoid jitter, oscillation, silent disappearance, and routine teleporting
- recover deterministically when normal map geometry separates the pair
- react visibly to memory opportunities and danger
- never fail a critical command because of hidden temperament or loyalty

The companion is not a diver hotbar item. `companion_command` is the dedicated
toggle `B/BOND` action. Its open palette pauses the complete gameplay simulation
and presents no more than three numbered valid commands. Desktop
`1`-`3` activates the matching row and `B` or `Esc` closes; touch uses sequential
`BOND`, `TOOL`, and `USE`. The system does not reuse `Q` or `E/ACT`.

The first-proof independent palette may show recall, mount, and the selected
adaptation action. It must communicate invalid target, range, clearance, or
cooldown states rather than silently ignoring input. Temperament changes
expression, not command validity.

## Independent And Mounted Modes

Unmounted:

- the diver owns movement, `Tab/TOOL`, and `Space/USE`
- the companion follows and uses deliberate palette commands
- significant offensive or protection actions do not fire as hidden autonomous
  damage

Mounted:

- movement authority transfers to the creature controller
- the bottom hotbar projects creature actions only
- `Tab/TOOL` selects and `Space/USE` activates the selected creature action
- diver tools remain unavailable until dismount
- the camera, world collision, oxygen, daylight, diver health, route gates, and
  failure owners remain authoritative
- dismount requires safe diver clearance and returns immediate denial feedback
  when blocked

A major hostile hit while mounted applies existing diver damage and knockback,
forces readable separation, and returns control to the diver. The first proof
adds no creature health, permanent injury, death, or hidden loyalty penalty.

## Experience And Memory

A meaningful experience is an authored condition with a real outcome, not time
spent near a volume.

An experience may qualify when the pair:

- completes a difficult interaction inside environmental pressure
- survives or resolves a full hostile behavior cycle
- discovers a species behavior through an appropriate observation
- rescues or aids another organism
- protects one another during a consequential route decision
- returns a significant biological or ecological finding to the boat

Each memory requires:

- one stable lower_snake_case id
- one source-authored opportunity or encounter relationship
- one explicit runtime completion condition
- one individual eligibility rule
- one exact-once award rule
- one short in-world acknowledgement
- one night-facing explanation of why it matters

Repeating a trivial action, idling in a hazard, attacking a harmless target, or
reloading a checkpoint cannot grind memories.

## Night Consolidation

Returning to the canonical boat secures eligible memories. The night phase may
offer only memories actually earned by the active individual.

For each option, show:

- the event being remembered
- the adaptation name
- the visible physical change
- the exploration, sensing, protection, or combat effect
- any tradeoff or mutual exclusion

The player confirms one adaptation deliberately. The next morning must make the
change visually and mechanically obvious within a short sortie.

The first proof has no score payment or generic recipe for adaptation. Later
adaptations may use a thematically related care item or biological catalyst,
but an item cannot substitute for its required memory.

## Familiarity And Use-Based Growth

The intended feel is that creatures become good at what they actually do. The
system must avoid repetitive use grinding.

If familiarity is added later:

- it provides small bounded handling or expression changes
- meaningful context matters more than raw action count
- gains use diminishing returns or per-day caps
- major adaptations still require discrete memories
- all progression remains visible and explainable

The proof does not need a familiarity meter.

## Field And Combat Roles

Companions may eventually provide:

- direct mounted movement and creature actions when anatomy permits
- sensing and ecological interpretation
- interaction stability in difficult conditions
- warning and threat-reading behavior
- distraction, interruption, defense, or support
- specialized collection or nonlethal creature handling

While unmounted, the diver retains:

- movement and survival responsibility
- equipment access gates
- active tool and weapon control
- cargo and return decisions
- direct retreat and route choice

Combat remains real-time in the shared side-view world. A creature's credible
body plan defines possible roles; experience and selected adaptations specialize
how that individual performs them. One individual may therefore act as a mount,
guardian, hunter, sensor, healer, or utility partner without every species
learning every role.

The design adapts monster-collector build experimentation and synergy through
real-time setup/payoff windows. It does not add turn-based battles, multiple
active party members, elemental charts, generic battle arenas, or a general
combat rewrite. See
`docs/planning/REAL_TIME_CREATURE_PARTNERSHIP_DIRECTION.md`.

## Failure And Persistence

- Unbanked rescue or memory progress follows an explicit sortie-failure rule.
- A committed individual cannot duplicate, reroll, or disappear on Retry.
- Night consolidation is exact-once and reload-safe.
- Adaptations persist through day transition and profile reload.
- Review checkpoints isolate profile mutation.
- Schema changes require migration fixtures before normal profiles load them.

The first proof should favor restoring a pre-sortie individual state after
failure. It must not punish experimentation with hidden permanent injury or
death.

## First Proof: Spark Ray

The first individual is a curious, cautious juvenile bioelectric ray with two
possible memories and one selected adaptation:

| Memory | Adaptation | Visible change | Mechanical payoff |
| --- | --- | --- | --- |
| `held_the_flow` | Anchor Fins | broader fin tips, low stable posture in either mode | independent or mounted bracing for one difficult current interaction without bypassing fins access |
| `stood_ground` | Guardian Pulse | bright conductive stripe and aimed charge cue | deliberate independent or mounted hostile interruption and knockback without replacing the Shock Prod |

The proof includes one base independent/mounted visual plus one individually
reviewed variant for each adaptation. Before adaptation, committed riding provides
direct movement and one non-damaging `glide_surge`. The two branches are mutually
exclusive for this individual.

## Selected Encounter Proof

Living Expedition 04 reuses the existing eel for Guardian-Pulse Kite's temporary
non-damaging opening without changing health or exposing a harvest. The owner
rejected Mica's eel prediction; generic hostile reading remains dormant and
source-gated while Drift Lens still reads authored moving ecology. The Shock
Prod remains the direct-damage owner, and only defeat exposes the electrocyte.

Anchor-Fins Kite receives no invented combat action. The proof adds no new
memory, adaptation, individual, hostile, resource, or hard-access capability.
Detailed boundaries live in `docs/current/LIVING_EXPEDITION_04_PLAN.md`.

LE07 plans a separate Marl growth proof: a physical refuge dig under existing
eel pressure earns `guarded_the_nest`, canonical-boat return secures it, and
deliberate night consolidation offers Root Claws or deferral. Only that Marl
branch is offered; Vein Whiskers stays directional. Planned Ground Pin provides
a short grounded, non-damaging hold rather than Kite's recoil, with hostile
state/health still owned by the existing controller. See
[LE07 plan](../current/LIVING_EXPEDITION_07_PLAN.md). None of this is live yet.

## Validation Surface

Deterministic checks should prove:

- rescue and commitment occur once
- follow and separation recovery work through the selected route
- riding unlocks only after canonical-boat commitment
- command tactical pause freezes hostile phases, movement, cooldowns, oxygen,
  daylight, hazards, and companion motion consistently while input remains live
- mount/dismount, rider clearance, movement authority, and hotbar ownership switch
  cleanly on desktop and landscape mobile
- `glide_surge` moves visibly, cools down, causes no damage, and bypasses no gate
- only meaningful conditions award each memory
- duplicate exposure and reload cannot duplicate memories
- only earned options appear at night
- one adaptation applies and persists
- equipment gates remain authoritative
- Guardian Pulse targets, interrupts, knocks back, cools down, and does not
  silently kill or grant rewards
- failure and Retry preserve the contract
- existing tool, eel, day, map, and profile regressions remain stable

Player review must judge attachment, clarity, personality, adaptation payoff,
mounted feel, build curiosity, and desire to begin another day. Automation cannot
close those questions.

## Deferred Systems

- a fourth species or broad stable management without a later reviewed plan;
  LE07 keeps the current three-individual roster and one active companion
- free-form naming UI
- feeding, care schedules, bond meters, and personality conflicts
- eggs, breeding, fusion, genes, and inherited techniques
- release, retirement, lifespan, death, and legacy
- party or turn-based combat, tournaments, or broad creature-versus-creature
  systems
- generalized ecosystem simulation
- final creature art, animation, audio, balance, and accessibility
