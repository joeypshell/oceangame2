# Post-Slice Workflow Decision

Date: 2026-07-06

Issue: #67 `Refresh roadmap after accepted production slices`

## Decision

The focused production-slice workflow is repeatable enough to move into a controlled visual-revision phase.

This does not mean the full sketch should be productionized as one large map. It means the project now has enough protected reference slices to test targeted visual changes against multiple map shapes without resetting unrelated visuals.

## Evidence

- `production_slice_01` remains the default first-area preview with top-water `boat_spawn` entry/extraction.
- `production_slice_02`, `production_slice_03`, and `production_slice_04` are validated reference slices for different topology roles.
- All four production slices have generated JSON source, SVG preview, source/render/collision review sheets, route-smoke coverage, normal/debug captures, and accepted visual baselines.
- `docs/current/PRODUCTION_SLICE_INDEX.md` is the compact status source for slice roles, launch commands, smoke flags, captures, review sheets, and baselines.
- `Godot Smoke` runs the route smokes for all four production slices.

## Current Phase

Move from "prove focused slice production" to "prove controlled visual revision."

The next useful test is one small visual revision that:

- names its affected assets or renderer code
- names what stays untouched
- compares against accepted production-slice baselines
- avoids map topology changes
- avoids whole-scene regeneration
- preserves `production_slice_01` as the default preview unless a separate default-preview decision changes it

## Constraints

- Maps remain the source of truth for terrain, collision, entity placement, routes, and extraction.
- Do not promote another slice to the default preview as part of unrelated work.
- Do not attempt the whole full-map sketch as production content yet.
- Keep #52 and #53 as optional slice-03 post-baseline polish unless a future accepted-baseline replacement intentionally needs them.
- New visual work should target one controlled asset, renderer rule, or presentation layer at a time.

## Next Recommended Work

1. Add an aggregate accepted-baseline comparison command so all protected slices can be reviewed with one command.
2. Plan the first controlled visual-revision target before changing art or runtime visuals.
3. Implement that target as a separate scoped issue after the expected screenshot differences are documented.
