# Game Spec

## Working Title

OceanGame

## Purpose

`oceangame2` is the production foundation for a side-view ocean expedition
game. The project uses a compact playable scope to prove the larger OceanGame
loop without treating the current work as disposable.

The game combines authored exploration, oxygen and daylight pressure,
materials and blueprints, night projects, practical research, capability-gated
returns, limited combat, and reasons to begin another expedition day.

## Player Fantasy

The player is a researcher-diver operating from a surface boat above a
dangerous cave network. They learn the water, investigate signals and wildlife,
recover useful materials, build equipment, and return through remembered
places with capabilities that change what can be reached or survived.

## Core Loop

```text
see a promise -> choose and prepare -> dive under daylight
-> manage oxygen, health, cargo, tools, and route pressure
-> return to the boat -> bank cargo and commit discoveries
-> end the day -> review, build, and plan -> return changed
```

One day supports multiple oxygen sorties. Open surface water refills oxygen;
only the canonical boat banks cargo, commits discoveries, supports night
projects, and ends the day.

## Current Playable Foundation

- One contiguous source-authored production cave:
  `maps/production_level_01.greybox.json`.
- A canonical top-water boat, direct continuous swimming, and no normal
  teleport, prompted connector, or fast-travel route.
- Oxygen as the tactical sortie budget and daylight as the strategic day
  budget.
- Held cargo, boat-only offload, typed materials, deterministic authored
  candidate pools, and compact night projects.
- Durable blueprint knowledge and equipment including propulsion fins,
  scanner, cutter, dive light, pressure suit, Current Stabilizer, and Shock
  Prod progression.
- Remembered current, darkness, pressure, wreck, and tool interactions whose
  prerequisites are validated as one progression graph.
- Practical scanner findings, pending boat commitment, daily opportunities,
  one territorial enemy, separate health, and bounded biological resources.
- Desktop, landscape-mobile, local Godot, deterministic smoke, focused capture,
  accepted baseline, and public Web review workflows.

Production slices 01-04 remain regression and provenance fixtures. They are not
the normal world or separate campaign areas.

## Current Committed Direction

Expansions 01-14 are complete with player GO. Expansion 15 milestone #41
tracks #1095-#1104 for one bounded **Expedition Planning And Choice** pass:

- derive available plans from existing source-authored regional journeys and
  daily conditions
- present exactly two meaningful choices in the focused night review state
- let the player pin one plan for the following day
- show compact active guidance without an exact map marker or route line
- preserve all underlying discovery, project, capability, objective, and map
  owners

Detailed direction:

- `docs/current/OCEANGAME_EXPANSION_15_PLAN.md`
- `docs/planning/OCEANGAME_PHASE_2_ROADMAP.md`
- `docs/planning/CAPABILITY_RESOURCE_PROGRESSION_MATRIX.md`

## Design Principles

- Stable geography should become more legible and useful as the player learns
  it; progression should not erase travel with shortcuts.
- Meaningful equipment combines knowledge, guaranteed base materials, and an
  appropriate special component.
- Upgrades should change a verb, route, threat response, information surface,
  or reachable payoff. Pure percentages are secondary.
- Required progression cannot depend on an unlucky daily seed, inaccessible
  material, or circular enemy/tool dependency.
- Scanner results should identify the world or create practical knowledge, not
  award unrelated blueprints from abstract markers.
- Fighting should cost time, oxygen, health, position, or preparation; killing
  everything is not the automatic best route.
- Every expedition day should leave a project, opportunity, unresolved signal,
  remembered gate, or mystery worth returning for.

## Source And Validation Rules

- JSON and generator helpers own terrain, collision-facing topology, entities,
  gates, landmarks, habitats, resource candidates, encounter candidates,
  journeys, and planning relationships.
- Runtime derives presentation and mutable state from source; it does not
  invent progression dependencies.
- Map changes update the generator/source path first, then regenerate, validate,
  audit reachability/parity, and verify final Godot/Web rendering.
- Visual revisions target named assets or renderer rules and compare focused
  captures before baseline acceptance.

## Current Non-Goals

- Procedural geography.
- Emergency Week or Food/Water/Power overnight survival taxes.
- Broad economy, crafting tree, or inventory grid.
- Shortcut or fast-travel networks.
- Full ecosystem simulation.
- Vehicles, large-scale production content, final art/audio, broad
  accessibility/input work, balance, and save hardening before their own
  selected milestones.

Exceptional interiors, additional regions, durable oxygen-route progression,
and broader wildlife remain directional. They are not part of Expansion 15.
