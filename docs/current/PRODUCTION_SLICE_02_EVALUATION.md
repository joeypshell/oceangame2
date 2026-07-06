# Production Slice 02 Evaluation

Date: 2026-07-05

Issue: #48 `Evaluate production slice 02 against workflow goals`

## Summary Decision

Keep `production_slice_02` as a validated later-game reference slice and move on to slice 03 planning.

Do not promote slice 02 to the default first preview map, and do not spend another source-cleanup or visual-polish pass on it right now. Its main value is that it proves the workflow can handle a non-surface, later-game chamber route using `spawn + base` instead of `boat_spawn`.

## What Slice 02 Tests That Slice 01 Does Not

- In-water relay entry and extraction instead of a top-water boat.
- A later-game destination/connector role rather than a first-area onboarding role.
- A broad lower-right chamber with a lower terminal passage and return route.
- Relay/base readability in normal captures while keeping debug overlays distinct.
- Reuse of the full-sketch-to-focused-slice workflow on a second, different region.

## Source-Of-Truth Review

Status: pass.

- Source data lives in `maps/production_slice_02.greybox.json`.
- The map is generated from `tools/create_production_slice_02_map.py`, not hand-tuned in the Godot scene.
- Source icons from the sketch are ignored; salvage, hazards, route markers, spawn, base, and camera tests are reauthored as JSON.
- `references/greybox/production_slice_02_source_render_collision_review.png` compares authored source topology, expected collision rectangles, and Godot rendered overview.

Remaining note: if the full sketch source changes, regenerate slice 02 from the generator rather than editing runtime terrain by eye.

## Validation Review

Status: pass.

Current verification:

```powershell
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
python tools/check_map_parity.py maps/production_slice_02.greybox.json
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02_debug
```

Results:

- Reachability passes from entry `(8, 34)`.
- Runtime terrain/collision parity passes with 2507 terrain cells and 231 collision rectangles.
- Normal capture folder has all five expected camera views.
- Debug capture folder has all five expected camera views.
- Route smoke passed in #45 by swimming to all five salvage points and returning to relay extraction.

## Capture And Readability Review

Status: good enough for a reference slice; not accepted as a visual baseline yet.

The tuned five-view capture set covers:

- overview
- relay entry
- main chamber
- lower terminal
- return route

The relay extraction zone now reads as an intentional in-water relay/sub return point instead of a generic rectangle. Debug captures still show source grid, route boxes, amber extraction outline, green spawn marker, yellow salvage markers, and red hazard markers distinctly.

Remaining baseline note: `visual_baselines/production_slice_01_accepted/` is still the only accepted production-slice baseline. Slice 02 can be accepted later, but the baseline accept/compare workflow is still slice-01-oriented and should be extended intentionally before using slice 02 as a locked comparison target.

## Route-Pressure Review

Status: pass for the current prototype scope.

Slice 02 has a more destination-like shape than slice 01:

- The relay entry creates a safe return point without pretending this is a surface-access area.
- The main chamber provides broad movement space and object spread.
- The lower terminal tests deeper-route commitment and return clarity.
- Hazards are placed at choke or pressure points rather than as dense clutter.

This is enough to validate later-game route review, but not enough to justify adding economy, enemies, doors, or larger-map progression yet.

## Blockers

No source, collision, route, capture-completeness, or relay-readability blockers remain for using slice 02 as a reference slice.

Before accepting a formal slice 02 visual baseline, the remaining blocker is workflow-specific:

- Extend or parameterize `tools/manage_production_slice_baseline.py` so baseline accept/compare can target `production_slice_02` intentionally.

This does not block slice 03 planning. It only blocks treating slice 02 as an accepted visual baseline for future visual diffs.

## Recommendation

Recommended next action: next-slice planning.

Use `docs/current/PRODUCTION_SLICE_SELECTION_CRITERIA.md` to select `production_slice_03`. Slice 02 has done its job as a second workflow proof: it validated a different role, different spawn/extraction model, route smoke, source/render/collision review, camera capture completeness, and relay readability.

Only return to slice 02 before slice 03 if the immediate goal becomes formal baseline acceptance. In that case, create a small scoped issue to generalize the baseline accept/compare tool and accept the current slice 02 captures.
