# OceanGame Expansion 12 Plan

Date: 2026-07-14

Status: Complete with player GO in #941 after focused corrections #951-#953.
See `docs/current/OCEANGAME_EXPANSION_12_CLOSEOUT.md`.

Locked implementation contract:
`docs/current/OCEANGAME_EXPANSION_12_SOURCE_STATE_CONTRACT.md` (#932).

## Decision

OceanGame Expansion 12 is **Abyssal Pressure Return**.

The committed deep-harmonic discovery will reveal one durable
`pressure_suit_1` project. The player will combine guaranteed titanium, rubber,
and insulating gel, build the suit at night, and return through the existing
contiguous cave to the lower-central abyssal basin.

The basin remains physically present before the suit. A source-authored
pressure zone at its shaft gives a brief readable warning and sharply increases
oxygen drain, making a full target-and-boat journey non-viable even with the
optional session `O2 tank +15`. The pressure suit restores normal oxygen drain
inside that zone. It does not add an invisible wall, teleport, prompted
crossing, health damage, or new terrain.

## Evidence And Alternatives

The proposal follows current source and runtime evidence:

- `signal_reef_deep_harmonic_discovery` ends with `signal descends into deeper
  water` and has no outgoing progression edge.
- The existing lower-central shaft and basin around `x=79..119, y=126..155`
  are open, collision-active, boat-reachable geography with no authored
  progression journey yet.
- A candidate target near `x=96, y=150` has an ideal collision-aware round trip
  of about 56 seconds at the current 200 px/s swim speed. The base 90-second
  tank therefore has about 34 seconds of ideal headroom before interactions or
  mistakes. A simple tank increase would not honestly gate this place.
- Existing titanium, rubber, and insulating gel sources are guaranteed and
  validated. Gel replenishes through the established nonlethal source.
- `SortieState` already owns oxygen and failure; durable projects and
  capabilities already belong to `ExpansionProfileState` and
  `MaterialProjectRuntime`.

Alternatives considered:

- **Durable oxygen-capacity upgrade:** rejected for this milestone because the
  existing basin is already round-trip reachable on the base tank. Making it a
  gate would require global oxygen retuning or an artificially long stationary
  interaction. The optional score-funded `O2 tank +15` remains secondary
  preparation, not mandatory progression.
- **Another existing-tool regional payoff:** deferred because it would leave
  the deep-harmonic lead unresolved and add content without proving the next
  environmental capability.
- **Exceptional interior or loaded destination:** deferred because the current
  world still has unused contiguous geography and normal progression should
  not become connector travel.

Pressure protection is preferred because it resolves the accepted clue, uses
an existing memorable depth transition, creates a recipe-built capability, and
opens a real place without redrawing the map.

## Target Experience

1. Returning the deep-harmonic chart to the boat reveals a pressure-suit
   project and points broadly toward the central deep shaft.
2. The compact project tracker shows Ti2, Rubber1, and Gel1 with separate held
   and banked counts.
3. The player gathers or revisits guaranteed sources and builds the project
   only during night debrief.
4. Before the suit, the player can reach and briefly enter the pressure
   threshold. Clear feedback and accelerated oxygen drain make retreat the
   sensible response; `O2 tank +15` cannot bypass the full journey.
5. After the suit, the same terrain remains continuously swimmable and oxygen
   drains normally through the pressure zone.
6. The player reaches one source-authored abyssal landmark, completes one timed
   survey, and carries the pending result back to the canonical boat.
7. The committed result names the abyssal finding and gives one broad later
   promise without creating the following milestone.

## Meaningful-Change Filter

The milestone must create:

- curiosity: the harmonic clue points toward a visible deeper-water threshold
- preparation: exact ingredients and night construction matter
- remembered-place progress: the player returns through known continuous
  geography to the central shaft
- changed capability: one formerly non-viable pressure region becomes usable
- route pressure: oxygen, daylight, cargo, and the boat return still matter
- payoff: the basin contains a concrete survey result worth returning

A timer increase, warning-only zone, HUD line, or isolated survey does not meet
the milestone by itself.

## Capability And Recipe Contract

Proposed stable ids:

- project: `pressure_suit_1_project`
- capability: `pressure_suit_1`
- knowledge: `signal_reef_deep_harmonic_discovery`
- recipe: `titanium_scrap: 2`, `rubber_sheet: 1`, `insulating_gel: 1`
- route: `deep_harmonic_abyssal_basin_route`
- pressure zone: `abyssal_basin_pressure_zone`
- landmark: `abyssal_basin_landmark`
- survey: `abyssal_basin_harmonic_source_survey`
- discovery: `abyssal_basin_harmonic_source_discovery`

The source-contract issue may refine labels and exact rectangles, but it should
keep one knowledge-to-project-to-zone-to-payoff chain. The project consumes
banked profile materials atomically at night and persists across reload.

The existing `oxygen_tank_1` remains an optional session purchase for this
proposal. It is not a project prerequisite, does not unlock the pressure zone,
and must not make the unprotected basin survey and boat return viable. Score
never substitutes for pressure-suit ingredients.

## Source-Of-Truth Boundaries

- `maps/full_cave_sketch_01.greybox.json` remains topology and provenance.
- A focused production-level source helper owns the project, route, pressure
  zone, landmark, survey, camera records, and boat-commit metadata.
- Generated `maps/production_level_01.greybox.json` and SVG remain outputs.
- Use the existing central shaft and bottom chamber. Do not redraw terrain,
  stitch slices, or import crop seals to force the interaction.
- The pressure threshold must be reachable and safely retreatable before the
  suit. The target and return must be reachable after the suit.
- Validators must prove guaranteed recipe inputs, non-circular ownership, one
  unavoidable pressure crossing to the target, and canonical-boat return.
- Slices 01-04 remain unchanged regression and provenance fixtures.

## Runtime And State Boundaries

- `ExpansionProfileState` and `MaterialProjectRuntime` own the durable project,
  material transaction, capability, and reload behavior.
- A focused pressure-zone controller owns source-zone exposure, warning/grace
  state, and the unprotected oxygen-drain multiplier. Do not grow `main.gd`.
- `SortieState` remains the only mutable oxygen and oxygen-failure owner. The
  pressure controller supplies a drain modifier; it does not store oxygen.
- Pressure does not damage health in this pass. Eel combat remains the explicit
  health-damage lane.
- Existing session progression continues to own optional oxygen and cargo
  purchases. Neither can satisfy the pressure capability requirement.
- Existing survey, pending-discovery, failure cleanup, and canonical-boat
  commitment owners should be reused.
- Keep feedback compact and contextual. Do not add an inventory screen,
  permanent recipe panel, depth gauge system, or broad HUD redesign.

## Implementation Issue Batch

Frozen implementation order:

1. #932 locks the Expansion 12 pressure-return source and state contract.
2. #933 adds pressure-route, project, and progression validation.
3. #934 authors the pressure project, zone, basin landmark, survey, and payoff through
   the production-level source path without topology changes.
4. #935 adds durable pressure-suit project/profile ownership while preserving the
   optional session oxygen purchase as a distinct secondary benefit.
5. #936 implements focused pressure-zone oxygen behavior and integrates the abyssal
   survey, compact feedback, pending state, and boat payoff.
6. #937 adds deterministic fresh-profile pressure-return journey coverage and runs the
   full release suite once at this integration boundary.
7. #938 adds focused desktop/mobile captures for the warning, recipe, protected
   crossing, basin survey, and pending boat return.
8. #939 reviews and accepts only intentional full-level visual differences.
9. #940 verifies the exact merged SHA on the public Web preview.
10. #941 deploys the release candidate, runs the player playtest gate, and closes out
    the milestone after GO or a focused correction.

## Validation And Review Plan

- regenerate the production level and prove repeatability
- validate map schema, pressure-zone crossing, material guarantees, progression
  graph, player-footprint reachability, returnability, and render/collision parity
- prove pre-suit approach and retreat are possible
- prove base oxygen and `O2 tank +15` cannot complete the unprotected target
  and boat return under the deterministic route contract
- prove the pressure suit restores normal zone drain with a useful return margin
- prove night construction is exact-once and survives profile reload
- prove hazard, oxygen failure, combat defeat, day transition, and reset clear
  only unbanked pressure/survey state
- run the full release suite once after the integrated journey is ready
- capture only affected full-level views, compare before baseline acceptance,
  and verify exact public build metadata after merge

## Non-Goals

- no global pressure simulation, health damage, decompression, depth physics,
  suit durability, or multiple pressure tiers
- no terrain expansion, loaded destination, teleport, normal connector travel,
  map menu, or prompted standard gate
- no base-oxygen reduction or global oxygen rebalance
- no retirement or persistence migration of `oxygen_tank_1` in this milestone
- no new material catalog, crafting grid, inventory screen, or broad economy
- no second enemy, weapon tier, vehicle, broad regional population, or art pass
- no slice-03 polish; #52/#53 remain deferred

## Exit Criteria

Expansion 12 reaches its player playtest gate when the deep-harmonic result reveals one
clear pressure-suit recipe, the source-authored pressure threshold is readable
and cannot be bypassed by the session oxygen purchase, the durable suit makes
the unchanged abyssal basin viable, one finding returns to the canonical boat,
and source/progression/smoke/visual/Web evidence passes without unrelated drift.

Exit question: **Did the deep-harmonic clue, pressure warning, material hunt,
and night-built suit make the abyssal basin feel like a dangerous place the
player learned to reach, with a payoff worth carrying back to the boat?**
