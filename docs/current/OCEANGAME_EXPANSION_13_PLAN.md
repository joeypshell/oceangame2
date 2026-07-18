# OceanGame Expansion 13 Plan

Date: 2026-07-16

Status: Complete with owner GO in #969 after bounded corrections
#980/#982-#990, #1000-#1009, and audio interlude #1020-#1023. See
`docs/current/OCEANGAME_EXPANSION_13_CLOSEOUT.md`. The original frozen
implementation decision follows; its source/state contract remains locked in
`docs/current/OCEANGAME_EXPANSION_13_SOURCE_STATE_CONTRACT.md`.

## Decision

OceanGame Expansion 13 is **Southeast Wreck Return**.

The player will follow the completed abyssal chart through the existing
pressure-protected lower route to the currently empty southeast chamber. One
source-authored wreck landmark will contain a cutter-opened recorder and a
scanner survey whose result remains pending until the canonical boat.

This is a regional-identity milestone with honest oxygen-distance pressure. It
reuses the durable pressure suit, salvage cutter, and survey scanner instead of
adding another capability immediately. The optional session `O2 tank +15`
remains secondary preparation: the route is possible on the base tank with a
tight margin and materially safer after the purchase, but score never becomes
a mandatory progression key.

## Evidence And Alternatives

Collision-aware traversal from `surface_boat_entry` establishes the useful
candidate:

- the farthest reachable player-footprint point is near tile `(150.5, 149.5)`
  in the empty southeast chamber
- one-way travel is about `7,368 px` or `36.8s` at `200 px/s`
- the ideal round trip is about `73.7s`
- base `90s` oxygen leaves `16.3s` before interactions or mistakes
- the optional `105s` session tank leaves `31.3s`
- the shortest route crosses the existing
  `abyssal_basin_pressure_zone`, so the pressure suit remains a real prior
  requirement without a new wall or zone

The planned existing-style `2s` cutter interaction plus `3s` survey produces
about `78.7s` of minimum ideal demand. That leaves roughly `11.3s` on the base
tank and `26.3s` with the session upgrade. Exact authoring must rerun the
validator, but it must preserve that relationship rather than tune an idle
timer merely to cross a threshold.

Alternatives:

- **Pure oxygen-capacity progression:** deferred. Every current chamber is
  physically round-trip reachable on the base tank. A new durable timer
  increase would duplicate the session owner or require artificial drain,
  global rebalance, or an inflated interaction.
- **Exceptional interior:** deferred. The full level still has empty,
  memorable contiguous geography, and normal progression should not become
  prompted connector travel.
- **Another regional identity:** selected. The southeast chamber is the
  farthest honest route, follows the accepted pressure journey, and can make
  three existing capabilities useful together.

## Target Experience

1. Committing the abyssal discovery leaves one broad southeast wreck echo.
2. The next objective points toward a distant hull signal, not an exact path.
3. The player travels through the remembered pressure route with the existing
   suit and reaches a visually distinct wreck archive in continuous water.
4. The cutter removes one sealed recorder housing. Full cargo blocks the cut
   without deleting the target and clearly recommends a boat return.
5. Clearing the recorder exposes one nearby scanner survey. `Q/SCAN` is still
   required, oxygen and daylight continue, and leaving range cancels progress.
6. Recorder cargo and the pending survey return through the same long route.
7. The canonical boat banks the recorder and commits the finding exactly once.
8. The result names what was learned and leaves one broad later promise without
   selecting Expansion 14.

## Meaningful-Change Filter

The milestone must create:

- curiosity through a named distant wreck promise
- remembered-place progress through the existing abyssal crossing
- payoff for previously built pressure, cutter, and scanner capabilities
- meaningful preparation through optional oxygen margin and cargo planning
- one chained in-world interaction rather than another isolated pickup
- a tense return carrying both valuable cargo and pending knowledge
- a reason to begin another expedition after the wreck finding commits

A background prop, longer timer, HUD line, disconnected cutter target, or
ungated scanner marker does not satisfy the milestone by itself.

## Selected Contract

Proposed stable ids:

- prerequisite discovery: `abyssal_basin_harmonic_source_discovery`
- route: `southeast_wreck_archive_route`
- landmark: `southeast_wreck_archive_landmark`
- backdrop: `southeast_wreck_archive_backdrop`
- cutter target: `southeast_wreck_recorder`
- survey: `southeast_wreck_archive_survey`
- discovery: `southeast_wreck_archive_discovery`
- commit entry: `surface_boat_entry`

Required existing capabilities:

- `pressure_suit_1` for the existing pressure crossing
- `salvage_cutter` for the recorder housing
- `survey_scanner_1` for the archive survey

The source/state contract must name one explicit relationship from the cutter
target to the survey. Before the recorder is cleared, scan progress is zero and
feedback names the cutter step. Clearing it in the current sortie may expose
the survey immediately; banking it makes that cleared state durable. Hazard,
oxygen, or combat failure restores an unbanked recorder and clears uncommitted
survey progress. The survey finding still commits only at the boat.

No new project, recipe, material, capability, wallet purchase, or profile owner
belongs in this expansion. It is a content payoff for the progression already
earned.

## Source-Of-Truth Boundaries

- `maps/full_cave_sketch_01.greybox.json` remains topology/provenance.
- A focused `tools/production_level_01_expansion_13.py` helper should own the
  route, landmark, backdrop, cutter target, survey, camera records, and review
  metadata.
- `maps/production_level_01.greybox.json` and its SVG remain generated output.
- Use existing open water near the measured southeast endpoint. Do not alter
  terrain, collision, the top opening, pressure-zone bounds, or slices 01-04.
- The validator must prove exact prerequisites, recorder-to-survey ordering,
  non-circular progression, player-footprint reachability, existing pressure
  crossing, oxygen margins, and direct boat return.
- Any new landmark art must be one named, reviewable background asset or an
  established renderer variant, never a regenerated scene.

## Runtime And State Boundaries

- `ExpansionProfileState` remains the durable owner for prior capabilities,
  banked recorder identity if required, and committed discovery.
- `SortieState` remains the sole mutable oxygen, cargo, failure, and offload
  owner. Expansion 13 reads capacity; it does not store or change oxygen.
- `SessionProgression` keeps the optional score-funded `O2 tank +15`. It is not
  required by source metadata and does not satisfy cutter, scanner, or pressure
  requirements.
- Reuse `CutterSalvageController` and the survey/pending-discovery owner. Add a
  small focused dependency helper only if the cutter-to-survey relationship
  cannot remain cohesive in those owners. Do not grow `main.gd`.
- Existing scanner corrections remain locked: explicit `Q`, full-cargo
  guidance, one pending result, and boat-return explanation.
- Existing pressure behavior, cargo banking, daylight, health, combat, and
  profile reload semantics remain unchanged.

## Recommended Issue Order

1. Lock the Expansion 13 southeast-wreck source and state contract.
2. Add validator coverage for the route budget and cutter-to-survey dependency.
3. Author the route, landmark, recorder, survey, and review records through the
   focused production-level source helper.
4. Implement the cutter-to-survey dependency with failure, cargo, banking, and
   reload semantics in focused owners.
5. Integrate compact objective/feedback and the boat-committed wreck result.
6. Add one deterministic fresh-profile southeast-wreck journey smoke and run
   the release suite at this integration boundary.
7. Add focused desktop/mobile captures for promise, arrival, cutter step,
   survey progress, and pending return.
8. Review and accept only intentional full-level visual differences.
9. Verify the exact merged runtime on the public Web preview.
10. Run the real player journey and close with GO, HOLD, or a bounded correction.

## Validation And Review

- regenerate `production_level_01` twice and prove repeatability
- validate schema, progression graph, player-footprint path, pressure crossing,
  base/upgraded oxygen margins, target order, and direct boat return
- prove pre-recorder scan denial, explicit cutter progress, cargo-full safety,
  explicit `Q` survey progress, leave-range cancellation, failure restoration,
  profile reload, and exact-once boat commitment
- keep slices 01-04 and all terrain/collision records unchanged
- run the complete release suite once after the integrated journey is ready
- capture only affected full-level views at desktop/mobile sizes
- compare before baseline acceptance and verify the exact deployed SHA

## Non-Goals

- no new oxygen upgrade, recipe, material, project, or capability
- no base-tank reduction, arbitrary drain volume, new pressure tier, or global
  oxygen/pressure rebalance
- no terrain expansion, teleport, prompted connector, loaded interior, map menu,
  stabilizer entry, shortcut, or fast travel
- no second enemy, weapon tier, vehicle, inventory screen, broad crafting,
  regional population pass, or broad art replacement
- no slice-03 polish; #52/#53 remain deferred
- no closure of #849 inside this gameplay milestone

## Exit Criteria

Expansion 13 reaches its player gate when the accepted abyssal finding points to
one readable southeast wreck, the unchanged continuous route honestly makes
oxygen preparation useful without mandatory score, the existing pressure suit,
cutter, and scanner form one understandable interaction chain, and both the
valuable recorder and pending finding return to the canonical boat with source,
progression, smoke, visual, mobile, and Web evidence intact.

Exit question: **Did the distant wreck turn prior upgrades and the far southeast
route into a tense, memorable expedition whose discovery felt worth bringing
back to the boat?**
