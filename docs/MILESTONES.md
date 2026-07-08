# Milestones

## Milestone 0: Planning Lock

Done when:

- Game spec exists.
- Art bible exists.
- Map spec exists.
- Asset manifest exists.
- Visual workflow exists.

## Milestone 1: Greybox Map

Done when:

- A small map exists in Godot or chosen map format.
- Player can move around it.
- Dock, salvage, hazards, and blockers are represented by placeholders.
- A greybox baseline screenshot is saved.

## Milestone 2: First Art Pass

Done when:

- The basic terrain tile kit exists.
- The greybox map is visually replaced without changing layout.
- The map remains readable at gameplay zoom.
- A first art baseline screenshot is saved.

## Milestone 3: Playable Salvage Loop

Done when:

- Salvage can be collected.
- Hazards can damage or end the run.
- Returning to the base or extraction point banks score.
- Restart works.
- UI shows the core state.

## Milestone 4: Controlled Visual Revision Test

Done when:

- One specific visual issue is selected.
- Only the relevant asset or setting is changed.
- A before/after screenshot comparison confirms unrelated visuals stayed stable.

## Milestone 5: Expansion Decision

Done when:

- The visual workflow has either passed or failed clearly.
- The team decides whether to expand this prototype, revise the art pipeline, or restart with a better visual constraint.

## Current Roadmap Decision

As of 2026-07-08, Controlled Gameplay Pass 13 is complete. See `docs/current/CONTROLLED_GAMEPLAY_PASS_13_CLOSEOUT.md` for the latest closeout decision and `docs/current/PRODUCTION_SLICE_INDEX.md` for the current slice status table.

The project can now plan one small start-of-run objective cue using existing route-objective metadata, still through small source-driven passes rather than whole-map productionization.

What the current prototype has proven:

- bounded regions from the supplied full sketch can become JSON source data
- terrain rendering and collision can stay tied to authored source maps
- both `boat_spawn` and in-water `spawn + base` entry/extraction models are reviewable
- route smoke, camera captures, source/render/collision review, and visual baselines can be repeated across different topology roles
- targeted visual changes can now be compared against accepted baselines instead of relying on memory or one-off screenshots
- the default slice now supports source-authored safe/deep route metadata, oxygen pressure, cargo pressure, hazard warning/penalty behavior, route outcome text, and deterministic smoke coverage
- the default slice now has one authored timed valuable salvage target with source metadata, in-world affordance, progress/cancel/complete feedback, deterministic smoke coverage, focused capture, accepted visual impact, and public Web verification
- the default slice now has one authored hazard/navigation pressure marker, route-specific warning feedback, deterministic route-pressure smoke, focused capture, accepted visual impact, and public Web verification
- the default slice now has one tiny source-authored route extension with a southwest pocket route-decision payoff, deterministic smoke coverage, focused capture, accepted visual impact, and public Web verification
- the default slice now has one source-authored return/banking pressure beat at `salvage_return_branch`, compact full-cargo banking feedback, deterministic smoke coverage, focused capture, accepted visual impact, and public Web verification
- the default slice now has one source-authored pre-pickup route cue at `southwest_pocket_pre_pickup_cue`, compact `Optional pocket ahead` feedback, deterministic smoke coverage, focused capture, accepted visual impact, and public Web verification
- the default slice now has one source-authored oxygen/rest pocket at `lower_loop_oxygen_rest_pocket`, compact `Rest pocket +oxygen` feedback, deterministic smoke coverage, focused capture, accepted visual impact, and public Web verification
- the default slice now has one source-authored route commitment objective at `deep_cache_route_objective`, compact objective progress/result feedback, deterministic smoke coverage, focused capture, visual review with no baseline acceptance needed, and public Web verification

Current constraints:

- Keep `production_slice_01` as the default preview map unless a separate default-preview decision changes it.
- Preserve `maps/full_cave_sketch_01.greybox.json` as a topology draft and planning source.
- Keep icons from the supplied sketch out of terrain conversion unless they are reauthored as JSON entities.
- Do not attempt whole-map productionization yet; expand route scale only as one small source-authored connector, extension, return-loop, or objective-readability pass at a time.
- Keep #52 and #53 as optional slice-03 camera/topology polish unless slice-03 presentation becomes the selected goal.

Current next direction:

- Plan a focused Controlled Gameplay Pass 14 around one compact start-of-run objective cue at the boat/extraction area using existing `route_objectives` metadata, smoke, focused capture, visual review, and Web verification.

Recently completed current-state work:

- #129-#148 completed Controlled Gameplay Pass 04.
- #146 accepted the Pass 04 route-pressure visual baseline.
- #147 verified the public Web preview for the Pass 04 route-pressure runtime.
- #148 recorded the Pass 04 closeout and next-step evaluation.
- #150-#159 completed Controlled Gameplay Pass 05 and main-file guard work.
- #160-#169 completed Controlled Gameplay Pass 06 timed-salvage readability, visual review, Web verification, and closeout.
- #170-#179 completed Controlled Gameplay Pass 07 hazard/navigation pressure, visual review, Web verification, and closeout.
- #180-#190 completed Controlled Gameplay Pass 08 cautious route-scale expansion, visual review, Web verification, and closeout.
- #191-#199 completed Controlled Gameplay Pass 09 southwest pocket route-decision payoff, smoke/capture coverage, visual review, Web verification, and closeout.
- #201-#209 completed Controlled Gameplay Pass 10 return/banking pressure, smoke/capture coverage, visual review, Web verification, and closeout.
- #213-#222 completed Controlled Gameplay Pass 11 pre-pickup route readability, source metadata, smoke/capture coverage, visual review, Web verification, and closeout.
- #224-#233 completed Controlled Gameplay Pass 12 oxygen/rest route pressure, source metadata, smoke/capture coverage, visual review, Web verification, and closeout.
- #236-#245 completed Controlled Gameplay Pass 13 route commitment objective, source metadata, runtime feedback, smoke/capture coverage, visual review, Web verification, and closeout.
