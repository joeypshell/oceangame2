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

As of 2026-07-06, the project has validated the focused production-slice workflow across four different slice roles. See `docs/current/PRODUCTION_SLICE_INDEX.md` for the current slice status table and `docs/current/POST_SLICE_WORKFLOW_DECISION.md` for the phase decision.

The project should now move from "prove focused slice production" to "prove controlled visual revision."

What the production-slice workflow has proven:

- bounded regions from the supplied full sketch can become JSON source data
- terrain rendering and collision can stay tied to authored source maps
- both `boat_spawn` and in-water `spawn + base` entry/extraction models are reviewable
- route smoke, camera captures, source/render/collision review, and visual baselines can be repeated across different topology roles
- targeted visual changes can now be compared against accepted baselines instead of relying on memory or one-off screenshots

Current constraints:

- Keep `production_slice_01` as the default preview map unless a separate default-preview decision changes it.
- Preserve `maps/full_cave_sketch_01.greybox.json` as a topology draft and planning source.
- Keep icons from the supplied sketch out of terrain conversion unless they are reauthored as JSON entities.
- Do not attempt whole-map productionization yet; keep map work slice-sized and source-derived.
- Keep gameplay pressure minimal until controlled visual revision passes prove that assets and renderer changes can be made without damaging unrelated visuals.
- Keep #52 and #53 as optional slice-03 post-baseline polish unless a future accepted-baseline replacement intentionally needs them.

Current next implementation issue:

- [#70](https://github.com/joeypshell/oceangame2/issues/70) implement the controlled sprite prop pass for salvage and hazards

Recently completed planning/tooling setup:

- [#67](https://github.com/joeypshell/oceangame2/issues/67) refreshed the roadmap after accepted production slices
- [#68](https://github.com/joeypshell/oceangame2/issues/68) added an aggregate production-slice baseline comparison command
- [#69](https://github.com/joeypshell/oceangame2/issues/69) planned the first controlled visual revision target
