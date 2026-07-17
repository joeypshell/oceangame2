# OceanGame Expansion 13 Closeout

Date: 2026-07-16

Issues: #960-#969

Milestone: OceanGame Expansion 13 `Southeast Wreck Return`

## Decision

**GO.** The player approved exact public runtime
`a9d143131b2a27009b7f57e49cab979016fa52ee` after the complete Southeast
Wreck journey. No corrective issue was requested.

The accepted exit answer is that the distant wreck made the existing pressure
suit, salvage cutter, survey scanner, and far-southeast return route feel
sufficiently tense and worthwhile to close the milestone.

## Delivered Journey

- The committed abyssal finding leaves one broad southeast wreck echo without
  an exact path marker.
- The unchanged contiguous route crosses the existing pressure zone and keeps
  the base tank viable but tight; the optional session oxygen upgrade improves
  margin without becoming a source prerequisite.
- One source-authored recorder requires the existing cutter before it exposes
  the archive survey.
- The survey requires explicit `Q/SCAN`, cancels when the player leaves range,
  and remains independent of cargo capacity.
- Failure restores unbanked recorder and survey state according to the existing
  sortie rules.
- Recorder cargo and pending knowledge return to the canonical surface boat,
  where the discovery commits exactly once and names the wreck archive result.

## Source And Validation Evidence

- `tools/production_level_01_expansion_13.py` owns the route, landmark,
  backdrop, recorder, survey, camera, and review records; generated JSON and
  SVG remain derived output.
- Validation proves the prerequisite chain, cutter-to-survey ordering,
  non-circular progression, player-footprint reachability, pressure crossing,
  base and upgraded oxygen margins, and direct boat return.
- `SurveyDependencyState`, `ExpansionProfileState`, existing cutter/survey
  owners, and `RegionalJourneyPresentation` preserve focused state and feedback
  ownership without growing `main.gd`.
- `--smoke-expansion-13-southeast-wreck-return` protects the collision-active
  journey, cargo-full safety, explicit interactions, failure restoration,
  exact-once boat commitment, and profile reload.
- The integrated smoke and progression workflows passed for the accepted
  runtime. The file-length audit and diff-hygiene checks report no new
  non-allowlisted oversized file.

## Visual And Web Evidence

- #967 accepted only the intentional southeast wreck backdrop, recorder, and
  survey-cue differences in the full-level overview and lower-right views.
- Terrain, collision, boat, diver, existing props, camera geometry, unrelated
  HUD/lighting, and slices 01-04 remained stable. No `.import` sidecar entered
  the accepted baseline.
- Focused desktop/mobile captures cover the broad promise, cutter requirement,
  partial cutter progress, explicit partial survey, and pending boat return.
- The public build reports exact SHA
  `a9d143131b2a27009b7f57e49cab979016fa52ee`, `git_ref=main`, and
  `dirty=false`.
- [Godot Web Export run 29541554518](https://github.com/joeypshell/oceangame2/actions/runs/29541554518),
  [Godot Smoke run 29541470293](https://github.com/joeypshell/oceangame2/actions/runs/29541470293),
  and [Progression Audit run 29541470317](https://github.com/joeypshell/oceangame2/actions/runs/29541470317)
  succeeded for that exact candidate.
- The public checker passed root, isolated review, slice fallback,
  desktop/wide/mobile framing, touch probes, requests, and console guards.

## Stable Boundaries

- `production_level_01` remains the normal editor, local, and public Web map.
- The full level retains continuous geography; no terrain, collision,
  teleport, connector, map-menu, stabilizer-entry, or fast-travel change landed.
- Expansion 13 adds no recipe, material, capability, enemy, inventory, vehicle,
  pressure tier, or global oxygen rebalance.
- Cargo, oxygen, daylight, health, combat, cutter, survey, profile, and
  boat-commit owners keep their established responsibilities.

## Deferred And Next

- #52/#53 remain deferred optional slice-03 presentation polish.
- #849 remains separate UID bookkeeping and did not block this milestone.
- Pure oxygen-capacity progression, other regional identities, exceptional
  interiors, vehicles, and broader production content remain directional.
- No next implementation milestone is selected here. A fresh drift audit must
  choose one bounded direction, document its goal and exit question, and create
  only that milestone's issue batch.
