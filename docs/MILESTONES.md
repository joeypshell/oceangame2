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

As of 2026-07-08, Controlled Gameplay Pass 06 is complete. See `docs/current/CONTROLLED_GAMEPLAY_PASS_06_CLOSEOUT.md` for the latest closeout decision and `docs/current/PRODUCTION_SLICE_INDEX.md` for the current slice status table.

The project should now move from the readable timed-salvage interaction to one authored hazard/navigation pressure pattern before broader map-scale expansion.

What the current prototype has proven:

- bounded regions from the supplied full sketch can become JSON source data
- terrain rendering and collision can stay tied to authored source maps
- both `boat_spawn` and in-water `spawn + base` entry/extraction models are reviewable
- route smoke, camera captures, source/render/collision review, and visual baselines can be repeated across different topology roles
- targeted visual changes can now be compared against accepted baselines instead of relying on memory or one-off screenshots
- the default slice now supports source-authored safe/deep route metadata, oxygen pressure, cargo pressure, hazard warning/penalty behavior, route outcome text, and deterministic smoke coverage
- the default slice now has one authored timed valuable salvage target with source metadata, in-world affordance, progress/cancel/complete feedback, deterministic smoke coverage, focused capture, accepted visual impact, and public Web verification

Current constraints:

- Keep `production_slice_01` as the default preview map unless a separate default-preview decision changes it.
- Preserve `maps/full_cave_sketch_01.greybox.json` as a topology draft and planning source.
- Keep icons from the supplied sketch out of terrain conversion unless they are reauthored as JSON entities.
- Do not attempt whole-map productionization yet; add one authored hazard/navigation pressure pattern before expanding route scale.
- Keep #52 and #53 as optional slice-03 camera/topology polish unless slice-03 presentation becomes the selected goal.

Current next direction:

- Plan a focused Controlled Gameplay Pass 07 around one authored hazard/navigation pressure pattern in `production_slice_01`.

Recently completed current-state work:

- #129-#148 completed Controlled Gameplay Pass 04.
- #146 accepted the Pass 04 route-pressure visual baseline.
- #147 verified the public Web preview for the Pass 04 route-pressure runtime.
- #148 recorded the Pass 04 closeout and next-step evaluation.
- #150-#159 completed Controlled Gameplay Pass 05 and main-file guard work.
- #160-#169 completed Controlled Gameplay Pass 06 timed-salvage readability, visual review, Web verification, and closeout.
