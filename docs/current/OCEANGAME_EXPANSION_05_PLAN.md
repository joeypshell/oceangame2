# OceanGame Expansion 05 Plan

Date: 2026-07-10

Issues: #748-#757

Milestone: OceanGame Expansion 05 `Practical Research Foundation`

## Decision

Expansion 05 will prove one practical resource-research journey inside the existing `production_slice_01` topology:

```text
cross the remembered upper-right current with the stabilizer
-> notice an unidentified mineral trace beyond the gate
-> survey it with the existing scanner under oxygen/daylight pressure
-> return the uncommitted finding to the surface boat
-> learn that conductive coils favor deep-cache machinery
-> begin the next day with a useful habitat lead
-> choose the existing deep-cache route and find the expected coil candidate
```

Research changes information and route planning, not material yield. The current day's already-selected material candidates remain stable. A newly committed finding affects only the next fresh day selection.

## Player Promise

Before the scan, the player should understand: "This mineral trace means something, but I need to study it and bring the finding home."

After committing it, the player should understand: "Conductive coils favor machinery in the deep-cache area, so I can plan tomorrow's route around that habitat."

The clue stays incomplete and the finding names a broad remembered place, not coordinates or an exact path.

## Locked Roles

| Role | Id | Rule |
| --- | --- | --- |
| Existing physical gate | `upper_right_current_pocket_gate` | Keeps the trace behind the durable stabilizer return established by Expansion 04. |
| New survey target | `upper_right_mineral_trace_survey` | One resource target in existing open pocket space. |
| Existing scanner | `survey_scanner_1` | Required for the same timed, cancel-on-leave survey interaction. |
| New durable finding | `upper_right_mineral_trace_research` | Commits only at `surface_boat_entry`. |
| Existing material pool | `conductive_coil_pool` | Keeps `select_count=1` and all existing candidates. |
| Researched habitat candidate | `material_coil_deep_cache` | Becomes the deterministic next-day candidate after the finding. |

Recommended compact source text:

- incomplete clue: `Mineral trace | Composition unknown`
- committed finding: `Research: coils favor deep-cache machinery`
- next-day lead: `Research lead | Coils near deep-cache machinery`

Final punctuation may follow existing overlay conventions, but the meaning and partial-information boundary must not drift.

## Meaningful-Change Filter

This pass is valid because it adds:

- curiosity: an unknown trace appears beyond a previously remembered blocker
- pressure: scanning and returning consume oxygen and daylight
- payoff: the committed finding changes a later deterministic material selection
- remembered-place progress: the finding points toward an existing named route context
- route choice: the player can intentionally prioritize the deep-cache machinery route
- another-day motivation: the useful effect waits for the next day boundary

A second generic scan, lore-only result, exact coordinate marker, or extra resource yield would fail this filter.

## State And Timing Rules

- The existing anomaly discovery and new mineral research are separate supported discovery ids.
- Only one uncommitted survey finding may exist at a time.
- Connector travel preserves pending research; manual reset, hazard contact, and oxygen failure clear it.
- The canonical surface boat commits the finding exactly once to the durable profile.
- The persisted profile shape remains unchanged, so no schema bump is expected.
- Committing research does not replace the current day's cached candidate selection.
- Starting the next day clears the day selection cache; source-authored research metadata then selects the deep-cache coil candidate.
- Profile reload preserves the finding and therefore the next fresh day's effect.

## Source Boundaries

- Survey source owns target kind, rectangle, scanner requirement, interaction time/label, clue/finding text, discovery id, broad route context, and boat commit reference.
- Material-pool source owns the finding link, researched candidate subset, and compact habitat lead.
- Validators prove legal open placement, physical reachability after the existing gate, supported ids/effect, target-to-pool links, candidate subset validity, and unchanged daily yield.
- Source must not author current day, selection state, profile state, progress, pending/committed state, oxygen, cargo, score, or exact route coordinates in display text.
- Terrain rectangles, collision, camera tests, connectors, existing salvage/hazards, and material candidate positions remain unchanged.

## Runtime And UI Boundaries

- `expansion_profile_state.gd` owns both durable discovery ids within the existing profile shape.
- `expedition_discovery_state.gd` owns one pending source finding and its commit destination.
- The existing survey runtime keeps anomaly compatibility while deriving target-specific clue/finding behavior from source.
- `expedition_day_state.gd` remains the current-day selection cache owner.
- Material selection/runtime applies a profile-backed researched subset only when creating a fresh day selection.
- A focused presentation helper owns the compact habitat lead; `main.gd` delegates only.
- Existing cargo, banking, recipe, project, scoring, oxygen, daylight, gate, and failure owners remain unchanged.

## Planned Issue Order

1. #748 lock this experience and issue contract.
2. #749 define source, profile, pending, day-cache, runtime, and UI ownership.
3. #750 extend survey/material schema and validator coverage.
4. #751 author the trace and researched coil habitat through the generator path.
5. #752 generalize survey/profile/pending state for the second discovery.
6. #753 apply the finding to next-day selection and compact planning feedback.
7. #754 add integrated deterministic journey smoke and CI/release coverage.
8. #755 add focused dual-viewport captures.
9. #756 review visual impact and record the baseline decision.
10. #757 verify the public Web build and record GO or HOLD.

## Validation Plan

Validation must cover:

- positive/negative source fixtures for resource targets, compact text, links, subsets, and forbidden runtime fields
- generator repeatability, SVG render, map validation, unchanged terrain/collision parity, and reachable target/candidate
- existing anomaly/scanner behavior and profile migration
- one-pending-finding ownership, connector preservation, failure cleanup, canonical exact-once commit, and reload
- current-day selection stability, next-day researched selection, unchanged yield, and unrelated pool rotation
- existing material, project, expedition-day, Expansion 03, and Expansion 04 regressions
- one integrated `--smoke-expansion-05-practical-research` journey in CI and release validation

Treat `SCRIPT ERROR` and `ERROR:` output as failures even when Godot exits zero.

## Visual And Web Plan

- Reuse the existing survey marker grammar with only source-derived state/text differences; no broad art pass.
- Capture the incomplete clue, partial survey, boat-committed finding, and next-day habitat lead/material state at 1280x720 and 1920x1080.
- Compare every accepted production-slice baseline before any acceptance decision.
- Reject unrelated terrain, collision, diver, boat, camera, prop, HUD, material, or visibility drift.
- Verify exact merged Web metadata, initialization, requests, console, and dual-viewport framing.

## Deferred Work

- #52/#53 optional slice-03 presentation polish
- field-guide screens, research catalogs, exact map markers, quest lists, and broad scanner modes
- creature research, combat, weapons, health, biological resources, and countermeasures
- additional resource types, recipes, project menus, inventory UI, economy, or increased daily yield
- more capability gates, map-scale expansion, procedural geography, shortcuts, or fast travel
- final survey/material art and audio

## Exit Criteria

Expansion 05 may close with **GO** only when:

1. The unknown trace is source-authored, physically coherent, readable, and reachable through the existing stabilizer-gated pocket.
2. The existing scanner completes a pressured survey without creating cargo or score.
3. Pending research follows connector/failure rules and commits durably only at the surface boat.
4. Commit leaves the current day unchanged and makes the next fresh day select the source-authored deep-cache coil habitat.
5. The compact lead informs a broad route choice without giving coordinates or becoming checklist text.
6. Existing anomaly, material, project, gate, cargo, oxygen, daylight, map, and profile behavior remains deterministic.
7. Source validation/parity, integrated smoke, captures, baseline review, and public Web verification pass.
8. Review answers yes to: "Did the finding make the player smarter and change the next expedition decision?"

A **HOLD** must name the smallest corrective pass and must not broaden into Expansion 06.
