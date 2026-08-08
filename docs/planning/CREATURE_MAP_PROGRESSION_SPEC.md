# Creature Map Progression Spec

Date: 2026-08-08

Status: Active source/planning contract. Living Expeditions 01-03 implement two
rescues, one compact habitat, Spark Ray memory/payoff relationships, and Mica's
source-linked jellyfish migration observation and Drift Lens payoff. Living
Expedition 04 selects one existing-eel relationship as its next source proof.

## Purpose

Plan diver equipment, creature habitats, rescue encounters, shared memories,
adaptations, threats, and payoffs as one source-derived progression graph.

The map should remain a remembered physical place. Creatures add relationships,
behavior, and situational possibilities inside that place; they do not become
keys that replace traversal equipment or teleport the player past geography.

## Progression Layers

### Geography

Stable terrain, collision, landmarks, routes, and region identity remain
source-authored. Daily conditions may vary optional opportunities, not topology
or required progression.

### Diver Access

Equipment owns predictable hard access and survival:

- fins for major current traversal
- light for readable darkness
- pressure protection for deep access
- cutter and later tools for physical barriers
- weapons and health preparation for direct threat response

### Creature Opportunity

An active companion may change what can be accomplished after the diver can
reach or survive a region:

- carry the diver through already-accessible open water when species anatomy and
  committed bond permit riding
- stabilize a scan, cut, sample, rescue, or defense under pressure
- detect or interpret a real organism, behavior, or environmental clue
- warn, distract, interrupt, protect, or support retreat
- enable a species-specific, optional ecological payoff

### Paired Challenges

A later challenge may require both equipment and one companion adaptation only
when:

- both requirements are promised before the challenge
- neither prerequisite depends on the challenge's own reward
- the progression graph proves a reachable acquisition path
- the payoff is more than another generic material or score cache
- the companion performs a living behavior rather than opening a matching lock

## Source-Owned Records

Future schema work should select the smallest records needed for:

- species and habitat definitions
- rescue or trust encounter sites
- memory opportunities
- ecological observations
- companion-context interactions
- mounted-action contexts and reviewed mount/dismount clearance where required
- adaptation payoffs
- guard/threat relationships
- review cameras and provenance

Each record should use stable ids and explicit relationships. Do not encode
mutable individual memories, active selection, bond, condition, adaptation, or
cooldowns in map JSON.

## Habitat Contract

A habitat should identify:

- `habitat_id` and species relationship
- bounded authored region or candidate cells
- required equipment access, if any
- day/condition eligibility for optional appearances
- behavior or observation promise
- guaranteed versus optional role
- related resource, rescue, memory, or mystery payoff

Required species progression cannot depend on an unlucky daily candidate. A
guaranteed rescue or memory opportunity must exist under every supported seed.

## Rescue Contract

A rescue site should identify:

- the individual or species being introduced
- the physical condition creating the situation
- the diver verb used to help
- prerequisite knowledge or equipment
- completion and failure behavior
- canonical-boat commitment
- the next-sortie companionship and riding promise

The creature cannot appear as an abstract pickup, score reward, blueprint, or
automatic scanner result.

## Memory Opportunity Contract

A memory opportunity should identify:

- one stable `memory_opportunity_id`
- eligible species or individual
- associated region, zone, hostile, interaction, or objective
- meaningful completion condition
- optional prerequisite capability or prior memory
- exact-once award behavior
- night presentation label
- one or more adaptation options it can support
- the later payoff that demonstrates the choice

Standing in a volume, repeating an input, or farming a weak target is not a
meaningful completion condition.

## Equipment And Companion Matrix

| Region pressure | Diver requirement | Companion opportunity | Invalid shortcut |
| --- | --- | --- | --- |
| strong current | propulsion fins for required crossing | mounted travel uses the same access; Anchor Fins braces one interaction | companion crossing or carrying the diver through a fins-gated route without fins |
| darkness | dive light for safe readable travel | luminous or sonar behavior reveals ecology | companion replacing the light gate |
| pressure | pressure equipment for safe entry | sensing or protection changes exploitation | companion granting pressure immunity |
| hostile territory | weapon, health, or viable evade route | warning, distraction, interruption, defense | mandatory companion obtained behind that hostile |
| sealed wreck | cutter or named tool | small-space sensing or defensive support | creature acting as a generic cutter key |

## First Spark Ray Proof

Use existing `production_level_01` geography. Do not expand terrain for the
proof.

Source authoring should add only:

1. One physically motivated rescue site connected to the retained Transfer Hub
   result or another reviewed post-foundation clue.
2. One existing-topology route that can review follow, safe mount/dismount,
   mounted movement, and `glide_surge` without creating a shortcut.
3. One current-based `held_the_flow` opportunity inside a route already
   accessible with the correct diver equipment.
4. One territorial-threat `stood_ground` opportunity using the existing eel
   behavior without making the eel a companion or required drop.
5. One short next-day payoff for Anchor Fins and one for Guardian Pulse.
6. Focused review cameras for rescue, follow, mounted play, both memories, night
   choice, and both independent/mounted adaptation payoffs.

The proof should not change accepted terrain topology or populate the entire map
with creatures.

## Progression Graph Requirements

Extend the source-derived audit to answer:

- Is the rescue reachable with guaranteed prior capabilities?
- Can the individual commit at the canonical boat exactly once?
- Does riding unlock only after commitment, and can the rider footprint complete
  the reviewed route without clipping or bypassing a gate?
- Can every required mounted state dismount safely or return a clear denial?
- Is each memory opportunity reachable after rescue?
- Does each memory require a real event and avoid duplicate farming?
- Is every adaptation offered only from an earned memory?
- Does each payoff remain reachable without bypassing its equipment gate?
- Is any hostile, resource, adaptation, or equipment dependency circular?
- Can failure, full cargo, reload, or daily variation make progression
  impossible?

The generated progression report should distinguish current implemented nodes
from proposed creature nodes until runtime support lands.

## Map Review Requirements

Before accepting source changes:

- render the generated JSON preview
- validate bounds, non-solid placement, player footprint, and reachability
- validate the contracted rider footprint and reviewed mount/dismount clearances
- audit the merged progression graph
- verify terrain/render/collision parity
- run existing full-level route regressions
- capture only the affected rescue, memory, and payoff views
- compare all existing accepted baselines before accepting intentional changes
- verify the exact Web checkpoint on desktop and landscape mobile

## Drift Guards

- Do not hand-place creature progression in Godot scenes.
- Do not add a habitat without a behavior, mystery, resource, rescue, or payoff
  role.
- Do not use mounted speed, size, or collision to bypass a diver capability gate.
- Do not use a companion ability as an unexplained colored lock.
- Do not add random required spawns.
- Keep Kite and Mica as the complete roster during Living Expedition 03; do not
  add a third species before the ecological field-role owner gate.
- Do not change terrain merely to make the creature system easier to stage.
- Keep #52/#53 deferred unless slice-03 presentation is deliberately selected.
