# OceanGame Expansion 12 Closeout

Date: 2026-07-15

Issues: #932-#941, with player-HOLD corrections #951-#953

Milestone: OceanGame Expansion 12 `Abyssal Pressure Return`

## Decision

**GO.** The player approved the corrected public build after scanner activation,
full-cargo feedback, and pending-return guidance were aligned with the intended
survey loop. The accepted runtime is
`d864a9ed744bbeb2e72e4b1d72bc1112069fdad6`.

The first deployed candidate received HOLD because proximity advanced surveys
without `Q/SCAN`, full-cargo feedback obscured scanning, and `pending` did not
explain the required boat return. #951-#953 corrected and redeployed only those
observed behaviors. The player then supplied GO with no further defect report.

## Delivered Journey

- The committed deep-harmonic discovery reveals one durable pressure-suit
  project with an exact Ti2/Rubber1/Gel1 recipe.
- Banked materials build the suit only during night debrief, and the completed
  project and capability persist together across profile reload.
- The existing lower-central basin remains continuously swimmable. Before the
  suit, its pressure threshold is scoutable and retreatable but makes the full
  survey-return route non-viable even with the optional session oxygen tank.
- The pressure suit restores normal oxygen drain inside the source-authored
  zone without changing terrain, collision, health, or player position.
- The protected journey reaches one abyssal landmark and timed survey whose
  result remains pending until canonical-boat return and commits exactly once.
- Surveys now require explicit `Q/SCAN` activation, continue to work at full
  cargo, and clearly direct the player back to the boat before another scan.

## Source And Validation Evidence

- Focused production-level source helpers own the project, route, pressure
  zone, landmark, survey, camera records, and boat-commit metadata; generated
  JSON and SVG remain derived outputs.
- Validation proves legal source records, guaranteed non-circular ingredients,
  an unavoidable pressure crossing, pre-suit retreat, unprotected route
  failure, protected return margin, reachability, parity, and unchanged slice
  fixtures.
- `PressureZoneController` supplies one source-derived drain multiplier while
  `SortieState` remains the sole mutable oxygen owner.
- The integrated Expansion 12 journey protects night construction, profile
  reload, warning/grace behavior, survey state, failure cleanup, pending return,
  and exact-once commitment.
- The corrected anomaly-survey journey reports
  `explicit_q=true full_cargo_scan=true pending_boat_guidance=true`.
- File-length and diff-hygiene checks pass with no new oversized human-authored
  file.

## Visual And Web Evidence

- #939 accepted only the intentional full-level abyssal landmark and harmonic
  marker differences. Terrain, collision, camera geometry, player, boat,
  existing props, and slices 01-04 remained unchanged.
- Focused desktop/mobile captures cover pre-suit warning, the exact project,
  protected crossing, partial survey progress, and pending boat return without
  entering accepted baseline folders.
- The corrected public build reports exact SHA
  `d864a9ed744bbeb2e72e4b1d72bc1112069fdad6`, `git_ref=main`, and
  `dirty=false`.
- [Godot Web Export run 29461275873](https://github.com/joeypshell/oceangame2/actions/runs/29461275873),
  [Godot Smoke run 29461276679](https://github.com/joeypshell/oceangame2/actions/runs/29461276679),
  and [Progression Audit run 29461275882](https://github.com/joeypshell/oceangame2/actions/runs/29461275882)
  passed for that runtime.
- The exact-SHA public checker passed root, isolated review, slice fallback,
  desktop/wide/mobile framing, and touch probes without failed requests or
  Godot script/runtime errors.

## Stable Boundaries

- `production_level_01` remains the normal editor, local, and public Web map.
- Pressure remains one bounded environmental capability, not a global depth or
  health-damage simulation.
- Score remains separate from durable equipment recipes; the optional session
  oxygen and cargo upgrades do not replace pressure-suit ingredients.
- Normal travel remains continuous through remembered geography. No teleport,
  prompted standard gate, map menu, or connector-based normal traversal was
  added.
- Cargo, oxygen, daylight, health, combat, survey, profile, and boat-commit
  owners retain their established responsibilities.

## Deferred And Next

- #52/#53 remain deferred optional slice-03 presentation polish.
- #849 remains separate bookkeeping for already-landed UID sidecars.
- Oxygen-distance progression, other regional identities, exceptional
  interiors, vehicles, and broader production content remain directional.
- No next implementation milestone is selected here. A fresh audit should
  choose one bounded direction, document its goal and exit question, and create
  only that milestone's issue batch.
