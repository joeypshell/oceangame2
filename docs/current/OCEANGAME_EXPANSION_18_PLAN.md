# OceanGame Expansion 18 Plan

Date: 2026-08-02

Status: Active milestone #44. Issues #1192-#1201 are the frozen implementation,
verification, and player-closeout batch.

## Decision

Select **Transfer Hub Interior Expedition** as OceanGame Expansion 18.

The recovered wreck-network coordinates should lead to one small,
source-authored destination beyond the mapped cave. The player still swims
through `production_level_01` to a physical entrance, explicitly enters one
exceptional loaded interior, recovers a tangible navigation core, returns
through the same entrance, and carries the result to the canonical boat.

This is not normal connector travel, fast travel, or a world-map menu. It is
one earned interior whose entry and return remain part of the same pressured
sortie.

## Current Evidence

- Expansion 17 ends at `wreck_network_triangulation_discovery` with the
  source-owned promise `Destination: transfer hub beyond mapped cave`.
- `production_level_01` already carries seven regional journeys, 35 authored
  zones, ten survey targets, and 49 review cameras across the complete supplied
  topology. Another in-map marker chain would add density without a new kind of
  payoff.
- The historical connector runtime proves source-authored map loading, but its
  legacy contract resets oxygen, held salvage, score, and destination-local
  state. That behavior is not sufficient for a real interior expedition.
- Owner feedback rejected teleport-like normal traversal, abstract scanner
  targets, unexplained commands, and rewards unrelated to the physical world.
  It allows exceptional wreck/cave interiors while expecting most geography to
  remain one contiguous map.
- Expansion 17 GO established that the corrected two-place mystery is worth
  following. Expansion 18 should pay it off with a place and a physical return,
  not another promise-only scan.

## Candidate Comparison

| Candidate | Value | Decision |
| --- | --- | --- |
| One exceptional Transfer Hub interior with continuous sortie state | Pays off the exact coordinates, adds a new place, preserves route pressure, and proves a rare interior boundary | **Selected** |
| Extend `production_level_01` with a contiguous Transfer Hub approach | Avoids loading, but expands topology and accepted full-level baselines while weakening the explicit `beyond mapped cave` promise | Defer until broader regional growth is selected |
| Add another equipment recipe and gate inside the existing cave | Reuses mature systems, but repeats the recipe -> gate -> scan cadence and does not pay off the coordinates | Reject for this pass |
| Add a second enemy or biological resource route | Could deepen combat/ecology, but is disconnected from the completed wreck-network investigation | Keep directional |

## Goal

Turn the recovered coordinates into one earned destination-and-return journey
that feels spatially new while preserving the boat, daylight, oxygen, cargo,
and remembered-route loop.

## Target Experience

1. After the Expansion 17 night result, the next-day plan names a physical
   Transfer Hub entrance in an existing boundary region.
2. The player prepares cargo space, follows remembered full-level geography,
   and reaches the entrance under normal daylight and oxygen pressure.
3. Before triangulation, the entrance may be visible but cannot be used. After
   triangulation, `E/ACT` opens only this exceptional interior transition.
4. Entry preserves the live expedition. It does not refill oxygen, bank cargo,
   restore health, advance time, or create a new boat.
5. Inside the compact hub, the player uses the existing Salvage Cutter with
   `Space/USE` to free one clearly presented navigation core from its cradle.
   No scanner action or unexplained analysis command is required.
6. The core requires one free cargo slot. Full cargo blocks recovery without
   deleting or auto-collecting it.
7. The player returns through the same physical doorway, emerges at the same
   exterior entrance, and still must swim to the canonical boat.
8. Boat offload commits the core exactly once and reports a broad recovered
   route result. It grants no score purchase, recipe, or surprise capability.

## Meaningful-Change Filter

The pass is meaningful only if it proves all three changes:

- **place:** an earned destination has a distinct entrance, interior identity,
  and return path rather than another marker in familiar water
- **pressure:** oxygen, daylight, health, and carried cargo remain continuous
  across entry and return
- **payoff:** the player physically recovers and returns one navigation core,
  making the coordinates causally useful

If the implementation resets the sortie, enters from a menu, deposits the core
inside the hub, or ends at another generic scan, it fails the plan.

## Geography And Transition Boundaries

- Keep `production_level_01` as the default map and normal contiguous world.
- Add one source-authored exterior entrance marker through the production-level
  generator path. Do not hand-edit generated JSON or Godot scene geometry.
- Do not alter existing terrain topology unless route/footprint review proves a
  tiny entrance-facing adjustment is necessary and separately documented.
- Add one newly generated destination map, provisionally
  `transfer_hub_interior_01`, with one entry and one paired return marker.
- Do not reuse production slices 01-04 as campaign destinations. They remain
  regression/provenance fixtures.
- `E/ACT` remains reserved for this explicit entrance. `Space/USE` remains the
  active-tool action. No new command is added.
- No connector network, destination list, map menu, shortcut, or boat-to-hub
  transition belongs to this pass.

## Source-Of-Truth Boundaries

Source data should own:

- exterior entrance and paired interior return identities
- destination map path, entry ids, labels, prerequisite discovery, and intent
- interior terrain, collision, camera tests, landmark, core cradle, and core
- source relationships from triangulation to entrance, operation, boat commit,
  and result discovery
- review questions and provenance

Runtime/profile state must not be authored in map JSON. A contract issue should
decide the smallest schema extension and preserve existing legacy connector
fixtures unchanged.

## Runtime And State Boundaries

The existing world-connector proof may be reused, but its reset semantics must
not silently become the Expansion 18 contract. A focused transition-state owner
should preserve only what a round trip requires instead of adding more mutable
transition fields to `main.gd`.

Preserve across entry and return:

- oxygen remaining and active sortie state
- daylight remaining, day number, sortie count, and selected expedition plan
- player health and current durable capabilities
- held salvage, score, materials, biological cargo, and cargo capacity
- pending discovery/core state
- origin/interior consumed-entity state needed to prevent duplication

Reset or rederive per loaded leg:

- player/camera placement from the paired entry id
- transient tool progress, warning text, overlap state, and local presentation
- local hazard presentation and other safely source-derived visuals

Only the canonical boat may offload, commit discoveries, refill as a boat,
enter night, or complete the expedition. Oxygen or health failure inside the
hub uses the normal failed-expedition lock and Retry returns to the canonical
boat with all unbanked origin/interior state restored. No free interior roaming
after failure is allowed.

## Planned Issue Batch

Milestone #44 freezes this dependency order:

1. Lock Expansion 18 source, transition, cargo, failure, and profile contract.
2. Add exceptional-interior schema, paired-entrance, and progression validation.
3. Author the exterior entrance and `transfer_hub_interior_01` through source
   generators, including preview and reachability review.
4. Implement focused continuous-sortie transition and round-trip state.
5. Implement cutter-released navigation-core recovery and boat commitment.
6. Add deterministic full journey, full-cargo, failure, reload, and regression
   smoke coverage.
7. Add focused desktop/mobile captures and source/render/collision review.
8. Review and accept only intentional Transfer Hub visual differences.
9. Verify the exact public Web build and isolated review checkpoint.
10. Run the owner journey and close with GO or a bounded HOLD.

The concrete issue range is #1192-#1201. Do not add Expansion 19 or deferred
slice-polish work to this milestone.

## Validation Plan

- Validate both maps, paired connector references, prerequisite discovery,
  player footprint, entry/return reachability, and canonical-boat path.
- Audit the cross-map progression graph for one non-circular route from
  triangulation through core commitment.
- Add a deterministic journey that records oxygen/daylight/cargo before entry,
  inside the hub, after return, and at boat commitment.
- Prove full cargo leaves the core present, release is deliberate, duplicate
  collection/commit cannot occur, and legacy slice connectors retain their
  historical behavior.
- Prove hazard, oxygen, health, Retry, and profile reload semantics without
  granting the core or respawning consumed cargo incorrectly.
- Run the integrated release suite once after source, runtime, and focused smoke
  are assembled.

## Visual And Web Plan

- Give the exterior entrance, interior hub, core cradle, and navigation core
  specific physical identities. Do not use abstract scan circles.
- Reuse the approved terrain palette and named assets where appropriate; create
  only individually reviewed hub-specific assets needed for legibility.
- Capture desktop and iPhone-landscape entrance, arrival, core-blocked,
  core-recovered, return, and boat-result states.
- Compare all existing full-level and slice baselines before accepting any
  entrance-area change. Do not replace unrelated baselines.
- Establish a named interior baseline only after source/render/collision and
  in-engine review agree.
- Verify exact-SHA public initialization, responsive framing, mobile `ACT` and
  `USE`, both map loads, paired return, and the focused checkpoint.

## Deferred Work

- No second interior, connector network, fast travel, world map, vehicle, or
  broad regional expansion.
- No new recipe, capability, material family, enemy, weapon, economy, inventory
  screen, survival tax, procedural geography, or broad HUD/art replacement.
- No detailed Expansion 19 direction or issue batch.
- #52/#53 remain deferred optional slice-03 presentation polish.

## Exit Criteria

Expansion 18 is ready for owner review when the exact public candidate proves
one source-authored entrance and interior, continuous expedition pressure,
deliberate core recovery, paired return, canonical-boat commitment, failure
restoration, regression stability, and clear desktop/mobile presentation.

Owner exit question:

> Did the recovered coordinates lead to a place worth reaching, and did
> entering, recovering the navigation core, and carrying it back through the
> ocean feel like one earned expedition rather than a teleport or reset?
