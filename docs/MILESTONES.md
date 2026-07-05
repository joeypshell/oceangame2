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

As of 2026-07-05, the first production slice has validated enough of the workflow to continue with focused slice production rather than restarting or attempting the whole full-map sketch at once.

What `production_slice_01` is meant to test:

- a bounded slice from the supplied full sketch can become JSON source data
- `boat_spawn` can serve as the production-style top-water entry and extraction model
- terrain rendering and collision can stay tied to the JSON map source
- the simple salvage, hazard, extraction, and reset loop works in a non-rectangular cave slice
- targeted visual changes can be made by editing named assets or source data instead of regenerating the scene

Current constraints:

- Keep map work slice-sized until the pipeline is accepted on `production_slice_01`.
- Preserve `maps/full_cave_sketch_01.greybox.json` as a topology draft and planning source.
- Treat `maps/production_slice_01.greybox.json` as the first production-slice source.
- Keep icons from the supplied sketch out of terrain conversion unless they are reauthored as JSON entities.
- Keep gameplay pressure minimal until terrain readability, entity visuals, and source/render validation are stable.

Next issue batch:

- [#31](https://github.com/joeypshell/oceangame2/issues/31) promote the production slice to the default preview
- [#32](https://github.com/joeypshell/oceangame2/issues/32) add a source-render-collision review artifact
- [#33](https://github.com/joeypshell/oceangame2/issues/33) clean production-slice topology artifacts in source data
- [#34](https://github.com/joeypshell/oceangame2/issues/34) replace placeholder salvage and hazard markers with readable props
- [#35](https://github.com/joeypshell/oceangame2/issues/35) add boat-spawn visual and top-water entry framing
- [#36](https://github.com/joeypshell/oceangame2/issues/36) add an accepted production-slice visual baseline workflow
- [#37](https://github.com/joeypshell/oceangame2/issues/37) clarify entity marker meanings in debug review mode
- [#38](https://github.com/joeypshell/oceangame2/issues/38) tune production-slice camera framing and capture set
- [#39](https://github.com/joeypshell/oceangame2/issues/39) prototype one scoped expedition pressure mechanic
- [#40](https://github.com/joeypshell/oceangame2/issues/40) select and author a second production slice after slice 01 is accepted
