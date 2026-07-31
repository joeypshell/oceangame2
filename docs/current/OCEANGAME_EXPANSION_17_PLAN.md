# OceanGame Expansion 17 Plan

Date: 2026-07-31

Status: Selected by planning gate #1156. No implementation milestone or issue
batch exists yet.

## Decision

OceanGame Expansion 17 is **Wreck Network Triangulation**.

The committed far-west deeper-wreck discovery will decode two parallel wreck
network leads in distinct, underused parts of the existing contiguous
`production_level_01`. Each lead ends at a recognizable physical relay
artifact and asks the player to reuse a different combination of capabilities
already earned in Expansions 10-16. Each scan becomes durable only after return
to the canonical boat. Once both fragments are committed, one explicit night
analysis triangulates the network and reveals the next broad destination
promise.

This pass adds no new recipe or capability. Its purpose is to test whether the
existing equipment, planner, map memory, boat return, and night phase can form
a coherent multi-site investigation instead of another isolated upgrade gate.

## Evidence

- The executable progression graph passes with 100 nodes, 386 edges, and 31
  stages. It currently ends at `far_west_deeper_wreck_discovery`.
- The source-authored endpoint says `Next lead: deeper wreck network
  unresolved`, but does not yet define a destination or interaction.
- Existing gameplay records are concentrated around the opening route,
  upper-right pocket, southeast chain, Northwest relay, and far-west wreck.
  Large western/lower chambers remain available without terrain expansion.
- Expansion 15 already owns source-derived lead choice and day-scoped pinning.
  Expansion 17 can prove that choice against two main-progression leads rather
  than a progression lead versus an optional material opportunity.
- Earlier owner HOLD feedback rejected abstract scan circles, unrelated scan
  rewards, automatic tool use, and listless progression. Progression-bearing
  scans must use believable physical artifacts and produce a clear next reason
  to travel.
- Expansions 11-16 repeatedly proved one discovery -> one project -> one return.
  Repeating that shape again would add content without testing a stronger loop.

## Candidate Evaluation

| Candidate | Value | Decision |
| --- | --- | --- |
| Wreck network triangulation | Turns the current signal into two route choices, reuses the earned toolkit, and creates a multi-return investigation plus night payoff | **Selected** |
| Exceptional loaded wreck interior | Could provide a memorable destination, but introduces transition, destination-map, return-state, and new-topology risk before the network destination is earned | Deferred |
| Second predator/resource/weapon tier | Adds action and future biological progression, but does not naturally answer the current wreck signal or improve the weak connective loop | Deferred |
| Credits/economy conversion | Could give generic salvage another use, but would blur score, materials, knowledge, and project ownership without resolving the network mystery | Deferred |

The selected candidate is the smallest one that changes the structure of an
expedition while preserving current geography and owners.

## Target Experience

1. Returning the far-west recorder to the boat leaves the wreck network
   unresolved.
2. At night, the recovered record decodes two broad, distinguishable relay
   leads. The player may pin either one for the next day.
3. The next day, compact guidance supports the selected route without drawing
   an exact path or disabling the unselected lead.
4. Each route crosses familiar geography and asks for a different combination
   of already-owned movement, survival, or active-tool capabilities.
5. Each destination is a visible wreck artifact, not a generic scan ring. The
   player deliberately faces it and holds the scanner through readable progress.
6. Each fragment remains pending until the canonical boat, where it commits
   exactly once and updates the remaining network objective.
7. After both fragments are committed, the night debrief offers one explicit
   network-analysis action. It spends no score or materials.
8. Analysis commits one triangulated-network discovery and reveals a broad
   destination promise for a later expansion.

The player may optimize both fragments into one day if daylight and route
execution permit it. The design should encourage another day through distance,
choice, and return pressure, not an arbitrary one-fragment-per-day lock.

## Meaningful-Change Filter

Expansion 17 fails if it only:

- places two mechanically identical circles in empty water
- repeats a new blueprint, recipe, and capability before every artifact
- makes lead selection a hidden interaction lock
- grants fragments on proximity or scan completion without boat return
- awards only score, cargo, or an unexplained item
- makes the final analysis automatic or visually indistinguishable from normal
  night text
- adds an interior transition, teleport, terrain expansion, or exact route line
  to make the investigation feel larger

The two routes must differ in place, preparation, and remembered capability
use. Their combined result must be clearer and more motivating than either
fragment alone.

## Source-Of-Truth Boundaries

Future authoring should extend:

```text
tools/create_production_level_01_map.py
tools/production_level_01_expansion_17.py
maps/production_level_01.greybox.json
```

The focused helper should own:

- two physical, non-collision wreck-artifact presentations
- two survey targets and broad source-authored lead labels
- distinct route/capability relationships using existing capabilities
- the aggregate two-fragment triangulation relationship
- boat commit ids, review cameras, questions, and provenance

Exact coordinates belong to the source contract after open-water, player
footprint, route-time, and camera review. No terrain change is expected.
Generated JSON must not be hand-edited.

Prefer existing `regional_journeys`, `survey_targets`, and expedition-lead
metadata. Add one small normalized investigation relationship only if those
records cannot express the two-required-fragment aggregate without duplicated
truth. Source data must never author selected lead, pending progress, completed
fragments, night analysis state, or UI visibility.

## Runtime And State Boundaries

| Owner | Responsibility |
| --- | --- |
| `ExpansionProfileState` | committed fragment discovery ids and final triangulation discovery |
| `ExpeditionDiscoveryState` | one pending fragment and canonical-boat commit semantics |
| `ExpeditionLeadResolver` | source/state-derived eligibility and readiness of the two leads |
| `ExpeditionPlanState` | day-scoped selected guidance id only |
| focused investigation resolver | derive fragment set, remaining leads, and night-analysis readiness |
| scanner owners | deliberate forward-cone acquisition, progress, cancellation, and physical target presentation |
| night debrief/presentation | explicit analysis command and compact result presentation |
| map source | immutable artifact, route, relationship, label, and commit metadata |

Use the existing completed-discovery profile model if it can represent all
three new ids safely. Add no second quest log, arbitrary inventory object,
currency, or mutable map-owned progress. Do not grow `main.gd` with the
aggregate rules.

## Validation And Smoke Plan

Source and progression validation must prove:

- `far_west_deeper_wreck_discovery` is the sole investigation prerequisite
- both fragments are physical, reachable, non-solid, and directly returnable
  to the canonical boat
- each lead has distinct source labels and a different prior-capability shape
- all required capabilities are available before either fragment
- no fragment requires the final triangulation discovery or the other fragment
- final triangulation requires both committed fragments and has no material or
  score substitute
- selection changes guidance only, never target validity

The deterministic journey smoke should cover lead resolution, alternate
selection, scan cancellation, pending failure cleanup, exact-once boat commits,
one-fragment incomplete state, two-fragment night readiness, explicit analysis,
profile reload, final result text, and prior Expansion 15/16 regressions.

Run the integrated release suite once after source, runtime, smoke, and capture
work are assembled, not after each small implementation issue.

## Visual And Web Plan

Focused desktop and iPhone-landscape captures should show:

- two distinct night leads and alternate pinning
- each physical artifact in recognizable regional context
- held scanner acquisition/progress at both artifacts
- one-fragment boat result and remaining lead
- two-fragment night analysis readiness and committed result

No accepted terrain or slice baseline should change. Compare full-level and
HUD baselines before accepting intentional artifact, guidance, debrief, or
result differences. Verify the exact public Web SHA in root, fresh-review,
focused checkpoint, desktop, wide, and mobile modes.

## Recommended Issue Batch

After this plan merges, create one milestone with this dependency order:

1. Lock the Expansion 17 source/state/investigation contract.
2. Add focused schema and progression-graph validation.
3. Author two physical relay artifacts and lead relationships in source.
4. Implement fragment-set and night-analysis state/runtime ownership.
5. Integrate planner guidance, scanning, boat commits, and result feedback.
6. Add deterministic multi-site journey smoke and CI coverage.
7. Add focused desktop/mobile review captures.
8. Review and accept only intentional visual differences.
9. Verify the exact public Web candidate and isolated checkpoint.
10. Run the owner journey and close with GO or a bounded HOLD.

The future audit assigns issue numbers and freezes the batch. Do not create
those implementation issues from planning gate #1156.

## Deferred Work

- #52/#53 remain optional slice-03 presentation polish.
- The triangulated destination may justify one exceptional interior later, but
  this milestone does not create or load it.
- New enemies, creature resources, weapons, materials, capabilities, economy,
  inventory, map topology, vehicles, and broad HUD work remain outside scope.
- Expansion 18 is not selected by the triangulation result.

## Exit Criteria

Expansion 17 is complete only when:

1. two believable physical artifacts create distinct route choices
2. existing capabilities feel useful as a toolkit rather than obsolete keys
3. lead selection guides but does not lock interaction
4. each fragment survives only through canonical-boat commitment
5. both fragments enable one explicit, readable night analysis
6. the combined discovery produces a motivating next promise without points,
   a surprise upgrade, or a loaded-map transition
7. source validation, progression audit, deterministic smoke, visual review,
   exact Web verification, and owner review agree
8. the owner answers GO to:

> Did following two physical wreck-network leads, returning each fragment, and
> triangulating them at night make the existing ocean feel like a connected
> mystery worth planning another expedition around?
