# OceanGame Expansion 10 Closeout

Date: 2026-07-13

Issues: #880-#889, with player-gate correction #900 via PR #901

Milestone: OceanGame Expansion 10 `East-Current Regional Journey`

## Decision

**GO.** The player approved the corrected public build after confirming that the
expanded passage remains present when propulsion fins are built between days.
The accepted runtime is `c576d13f9c6dd486cf59579a1ff5170ef983f26f`.

This answers the exit question: building fins turns the east current into the
entrance to a continuous, memorable lower-right journey, and Signal Reef gives
the player a scanner-backed result worth returning to the canonical boat.

## Delivered Journey

- The existing east-current promise and recipe-built propulsion fins lead into
  continuous `production_level_01` geography with no teleport, connector, or
  prompted crossing.
- Two source-authored current seams gate the lower-right route until the player
  owns fins.
- Signal Reef provides a recognizable background landmark and one regional
  scanner survey.
- The survey remains pending away from the boat, clears on existing failure
  paths, and commits only after the return to `surface_boat_entry`.
- The committed result identifies the Signal Reef chart and points broadly to a
  deeper harmonic without implementing the next capability.

## Source And Validation Evidence

- `tools/production_level_01_expansion_10.py` owns the regional journey, current
  seams, landmark, survey target, and focused camera records.
- Generated map JSON and SVG remain derived outputs; slices 01-04 did not change.
- The progression audit proves prerequisite ordering, no-fins denial, unlocked
  reachability, the scanner target, and boat-return commitment.
- `--smoke-expansion-10-regional-journey` completes the collision-active route
  from a fresh profile and now uses the real night/build/next-day input sequence.
- #900 corrected next-day and forced-nightfall reloads so the active full level
  is preserved instead of silently falling back to `production_slice_01`.
- Headless startup, focused night/day regressions, file-length audit, and diff
  hygiene passed for the correction.

## Visual And Web Evidence

- The accepted full-level baseline localizes intentional differences to current
  affordances, the Signal Reef silhouette, and the survey target.
- Terrain topology, boat, diver, HUD, camera framing, and all accepted slice
  baselines remained stable.
- The public preview reports exact SHA
  `c576d13f9c6dd486cf59579a1ff5170ef983f26f` on `main`, with clean build
  metadata.
- Public desktop, wide, fresh-profile, reference-slice, and mobile initialization
  passed, including touch alignment and default full-level selection.
- The player replayed the corrected Web journey and gave GO.

## Stable Boundaries

- `production_level_01` remains the default editor, local, and Web map.
- Map topology, collision, gates, landmarks, entities, and camera tests remain
  source-generated.
- Standard currents remain passive movement gates; they do not use `E`.
- Cargo, oxygen, daylight, night, scanner, combat, and recipe ownership keep
  their existing owners and semantics.
- The correction changed map reload selection and deterministic coverage only;
  it did not edit map source, terrain, assets, captures, or accepted baselines.

## Deferred And Next

- #52/#53 remain deferred optional slice-03 presentation polish.
- Teleports, normal-travel connectors, a current-stabilizer entrance, pressure
  progression, broad map population, and another traversal capability remain
  outside this milestone.
- No next implementation milestone is selected here. A new audit should choose
  one bounded direction from the Phase 2 roadmap and create only that batch.
