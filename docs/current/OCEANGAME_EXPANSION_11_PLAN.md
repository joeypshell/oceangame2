# OceanGame Expansion 11 Plan

Date: 2026-07-14

Status: Committed after player GO on planning issue #903.

GitHub milestone: [#37 OceanGame Expansion 11: Deep-Harmonic Light
Return](https://github.com/joeypshell/oceangame2/milestone/37)

Frozen issue batch: #905-#914

## Decision

OceanGame Expansion 11 is **Deep-Harmonic Light Return**.

The committed Signal Reef discovery will become the knowledge prerequisite for
one durable `dive_light_1` project. The player will combine guaranteed base
materials with one insulating-gel sample, build the light at night, and return
through the existing east-current journey to resolve one source-authored dark
harmonic survey in the lower-right region.

This replaces the current 900-score session purchase for `dive_light_1`. The
same capability id and light/readability effect remain, but durable profile and
material-project state become the only ownership source. Score will not
substitute for ingredients.

## Evidence And Alternatives

The leading direction fits the accepted handoff:

- `lower_right_signal_reef_discovery` currently ends at a broad `deeper harmonic
  below reef` lead with no outgoing progression edge.
- `dive_light_1` already improves source-authored darkness readability, but it
  is an in-memory session-wallet upgrade. The progression framework identifies
  direct-score upgrades as migration debt.
- titanium, conductive coil, and insulating gel already have guaranteed,
  validated sources before this project. The gel comes from the nonlethal glow
  anemone sample and fits the capability thematically.
- the full level contains continuous lower-right geography, so the payoff can
  deepen a remembered journey without a teleport or map-scale expansion.

Alternatives considered:

- A durable oxygen upgrade would improve range but the accepted Signal Reef
  route currently returns with useful oxygen margin. Making oxygen the next gate
  would require less-readable tuning pressure or more geography before it gives
  the current lead a concrete payoff.
- Another regional payoff using only cutter or shock prod could add content, but
  it would not resolve the dead-end harmonic clue or the score-owned light debt.

The light return is preferred because knowledge, ingredients, night preparation,
a changed capability, and a remembered place form one legible chain.

## Target Experience

1. Returning the Signal Reef chart to the boat reveals a concrete dive-light
   project rather than only a generic next-lead sentence.
2. The project tracker shows one exact recipe: titanium scrap 1, conductive coil
   1, and insulating gel 1. Banked and held counts remain distinct.
3. The player gathers or revisits the guaranteed sources and builds the project
   only during night debrief.
4. Before the upgrade, the player may scout the dark harmonic pocket, but the
   route is difficult to read and the survey reports that a stronger light is
   required. Darkness does not create invisible collision.
5. After the upgrade, the same water and terrain remain, readability improves,
   and the player can complete one timed harmonic survey.
6. The finding remains pending until the player returns to the canonical boat.
   The committed result names the discovery and points broadly toward a later
   deep-water problem without implementing pressure progression now.

## Meaningful-Change Filter

The milestone must create:

- knowledge payoff: Signal Reef unlocks a practical project
- preparation: exact materials and night construction matter
- remembered-place progress: the player returns through the east-current route
- changed capability: darkness becomes readable and one interaction becomes usable
- return pressure: the harmonic result commits only at the boat
- tomorrow motivation: the result reveals the next broad deep-water promise

A brighter cone alone, another score purchase, or an isolated HUD line does not
satisfy the milestone.

## Capability And Recipe Contract

Accepted stable ids:

- project: `dive_light_1_project`
- capability: `dive_light_1`
- knowledge: `lower_right_signal_reef_discovery`
- recipe: `titanium_scrap: 1`, `conductive_coil: 1`, `insulating_gel: 1`
- dark route: `signal_reef_deep_harmonic_dark_zone`
- survey: `signal_reef_deep_harmonic_survey`
- discovery: `signal_reef_deep_harmonic_discovery`

The source contract issue may refine display labels but should keep these ids
unless direct source evidence requires a correction.

The project consumes banked profile materials atomically at night. Existing
fresh profiles must not receive the light automatically. Existing profiles have
no persisted session-light state to migrate; they can follow the new project
chain. Completed durable capability state remains idempotent across reloads.

## Source-Of-Truth Boundaries

- `maps/full_cave_sketch_01.greybox.json` remains topology/provenance source.
- Focused production-level source helpers own the project, dark-zone, survey,
  route context, camera records, and boat-commit metadata.
- Generated `maps/production_level_01.greybox.json` and SVG remain outputs.
- Select an existing open-water lower-right pocket during source-contract work.
  Do not redraw terrain merely to force the planned interaction.
- Validators must prove every recipe input and the knowledge source are
  guaranteed before the project, the target is reachable and returnable, and
  the light requirement creates no circular dependency.
- Slices 01-04 remain regression/provenance fixtures and receive no topology edits.

## Runtime And State Boundaries

- `ExpansionProfileState` and `MaterialProjectRuntime` own the durable project,
  material transaction, capability, reload, and compact project guidance.
- Existing player/world light-profile APIs and visibility-zone rendering remain
  the visual effect owners.
- `SessionProgression` keeps oxygen and cargo purchases but stops owning
  `dive_light_1`; `config/progression_contract.json` and generated constants must
  expose only one light owner.
- The survey reuses timed progress, pending expedition discovery, failure
  cleanup, and canonical-boat commit owners.
- Keep overlay feedback compact and contextual. Do not add an inventory screen,
  permanent recipe panel, or broad HUD redesign.
- Do not grow `main.gd`; use the existing focused project, progression, survey,
  and presentation owners.

## Planned Issue Batch

Dependency order:

1. #905 locks the source/state and legacy-light migration contract.
2. #906 adds progression/schema validation for the durable light chain.
3. #907 authors the project, dark route, survey, and payoff through the full-level
   source generator without topology changes.
4. #908 moves `dive_light_1` ownership from session wallet to durable project/profile
   state and preserves the existing visual effect.
5. #909 integrates the light-gated survey, compact guidance, pending state, and boat
   commitment through existing owners.
6. #910 adds deterministic fresh-profile journey and regression coverage.
7. #911 adds focused desktop/mobile captures for recipe, pre-light denial, improved
   readability, and pending return.
8. #912 reviews and accepts only intentional full-level visual differences.
9. #913 verifies the exact merged SHA on the public Web preview.
10. #914 runs the player GO/HOLD gate and closes out the milestone.

## Validation And Review Plan

- regenerate the production level and prove repeatability
- validate map schema, material sources, biological resource source, visibility
  zones, surveys, progression graph, reachability, and source/render parity
- prove the pre-light survey is unavailable without deleting or hiding it
- prove recipe inputs remain guaranteed under every supported day selection
- prove the night transaction is exact-once and survives reload
- prove existing darkness rendering uses durable capability state
- prove hazard, oxygen, combat, cargo, failure, and day transitions clear only
  unbanked/pending state
- run the full release suite once after the integrated journey is ready
- capture only affected full-level views, compare before baseline acceptance,
  and verify exact public build metadata after merge

## Non-Goals

- no pressure suit, pressure damage, or new hard movement gate
- no terrain expansion, new loaded map, teleport, connector, or map menu
- no global fog or broad lighting rewrite
- no score substitute for recipe ingredients
- no second light tier, battery/charge meter, tool loadout, or inventory screen
- no broad material catalog, regional population, creature roster, or art replacement
- no changes to oxygen/cargo upgrade ownership in this milestone
- no slice-03 polish; #52/#53 remain deferred

## Exit Criteria

Expansion 11 reaches its player gate when the Signal Reef discovery unlocks one
clear recipe, the durable light changes a remembered dark return and enables one
useful harmonic survey, the result commits only after the boat journey, all
source/progression/visual/Web evidence passes, and unrelated full-level or slice
surfaces do not drift.

Exit question: **Did the Signal Reef clue, material hunt, and night-built light
make returning to the dark lower-right route feel like a capability earned for a
place the player remembered, with a payoff worth bringing back to the boat?**
