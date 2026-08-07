# Real-Time Creature Partnership Direction

Status: selected product direction. Living Expeditions 01 and 02 implement the
focused Spark Ray command/riding proof plus a bounded two-individual stable and
Veil Cuttle sensing role; broader ecology and combat direction remains planned.

## Decision

OceanGame keeps real-time exploration and combat in the shared side-view world.
One bonded companion joins each expedition. Species anatomy defines credible
field roles, while the individual's meaningful experiences and selected
adaptations determine how those roles develop.

The player may fight with diver equipment while the companion supports, command
the companion as an independent partner, or directly ride a capable companion.
Who leads is part of the expedition build rather than a fixed rule.

## Reference Lessons

Monster Sanctuary is useful because its creatures support build experimentation,
team synergy, distinct roles, and exploration abilities. OceanGame adapts those
strengths into a continuous underwater expedition:

- action-order synergy becomes real-time setup and payoff
- party builds become diver, equipment, companion, memory, and region builds
- large skill trees become a small set of visible lived adaptations
- party selection becomes choosing one individual whose role changes the dive
- field abilities become physical ecological behaviors inside remembered places

OceanGame does not adopt three-creature turn-based battles, elemental charts,
large launch rosters, generic encounter arenas, or interchangeable combat pets.
The differentiator is embodied partnership: what the pair lives through changes
the same creature's body, controls, and future possibilities.

References:

- https://monster-sanctuary.com/
- https://monster-sanctuary.com/press/sheet.php?p=monster_sanctuary

## Field Roles

One creature may support more than one role when its body and learned skills make
that credible:

| Role | Player experience |
| --- | --- |
| Independent partner | Diver swims and uses tools; companion follows, warns, positions, and performs deliberate commands. |
| Guardian or support | Companion heals, shields, interrupts, senses, retrieves, or manipulates a local condition while the diver acts. |
| Mounted partner | Movement authority and the active-action hotbar transfer to the creature until the player dismounts. |

Critical companion actions are deliberate and reliable. Temperament may change
posture, timing, spacing, and expression, but cannot silently refuse a valid
command or make progression random.

## Companion Command

`companion_command` is the dedicated toggle `B/BOND` action. It does not reuse `Q`,
`E/ACT`, the diver tool cycle, or `Space/USE`.

Pressing `BOND` opens a numbered palette, slows the complete simulation to 20
percent, and presents at most three contextual commands. Desktop `1`-`3`
activates the matching row; `B` or `Esc` closes. World movement, enemies,
cooldowns, oxygen, and daylight use the same scaled time so the palette cannot
desynchronize systems. Activating or closing restores normal speed.

The mobile test surface presents a contextual toggle `BOND` control during an
active dive without crowding `TOOL` or `USE`; touch selection and activation are
sequential, never a held chord.

## Mounted Control

Riding is a control-mode change, not a passive speed upgrade:

- mounting requires a committed active individual, proximity, and valid rider
  clearance
- dismounting requires valid diver clearance and gives clear denial feedback
- mounted movement uses the companion controller and existing world collision
- the bottom hotbar shows creature actions only while mounted
- `Tab/TOOL` selects and `Space/USE` activates the mounted creature action
- dismounting immediately restores the diver tool hotbar and movement owner
- oxygen, daylight, diver health, route choice, cargo, and failure remain active
- lighting, pressure, current, collision, and equipment gates remain authoritative

A hostile hit while mounted uses existing diver damage and failure semantics. A
major first-proof hit separates the pair and forces a readable dismount; it does
not add creature health, injury, death, or hidden loyalty loss.

## Growth And Combat

Real-time combat should create coordinated windows rather than passive bonus
damage. Diver tools may expose, mark, distract, interrupt, or protect; companion
actions may answer with movement, defense, control, rescue, or damage according
to the individual's build. Enemy intent, target, range, action, hit or miss,
knockback, recovery, and cooldown must remain readable.

Small familiarity gains may later improve handling, but major growth comes from
exact-once meaningful memories and deliberate night consolidation. Repetition or
button spam cannot create major adaptations.

## First Spark Ray Proof

The three-day review path is:

1. Day 1: rescue one juvenile Spark Ray and commit the individual at the boat.
2. The next launched sortie: prove follow, command, mount/dismount, direct
   movement, and one non-damaging `glide_surge` action.
3. Earn either `held_the_flow` or `stood_ground` through a complete shared event.
4. Night 2: consolidate one earned memory into one mutually exclusive adaptation.
5. Day 3: prove the visible independent and mounted payoff.

Anchor Fins adds current bracing without replacing propulsion-fin access.
Guardian Pulse adds one deliberately aimed interruption and knockback without
replacing the Shock Prod. The proof changes no terrain topology.

## Deferred

- turn-based or party combat
- more than one active companion
- a third species or broad stable-management UI before the selected Mica
  ecological field-role proof
- broad weapon, ability, or combat-framework replacement
- creature health, permanent injury, death, breeding, fusion, or lineage
- general ecosystem simulation

## Success Question

Does commanding and riding the same visibly adapting individual create enough
attachment, build curiosity, and mechanical difference to make the player want
another expedition?
