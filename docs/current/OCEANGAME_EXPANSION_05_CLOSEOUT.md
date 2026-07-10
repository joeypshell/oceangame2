# OceanGame Expansion 05 Closeout

Date: 2026-07-10

Issues: #748-#757

Milestone: OceanGame Expansion 05 `Practical Research Foundation`

## Decision

**GO** to planning OceanGame Expansion 06: Combat Foundation in the next drift cycle.

Yes, the habitat finding makes the player smarter and changes a later expedition decision. The player crosses a remembered stabilizer gate, sees an incomplete mineral clue, spends oxygen and daylight surveying it, returns an uncommitted finding to the canonical boat, and learns that conductive coils favor deep-cache machinery. The following fresh day presents that broad habitat lead and guarantees the source-authored deep-cache coil candidate without adding yield or an exact coordinate.

This is practical knowledge rather than checklist text: the clue withholds composition, the finding names a remembered kind of place, and the player still chooses and travels the route. It proves one resource-research journey, not a field guide, research tree, or broad scanner mode.

## Delivered Experience

- `upper_right_mineral_trace_survey` sits in legal open water beyond the existing durable current gate and requires the existing scanner.
- Partial survey progress is compact, cancel-on-leave, and keeps oxygen/daylight pressure active.
- Connector travel preserves one pending finding; reset, hazard contact, and oxygen failure clear unbanked research.
- Only the canonical surface boat commits `upper_right_mineral_trace_research`, exactly once, to the existing profile schema.
- The current day's material selection stays cached after commit.
- The next fresh day uses the source-authored `conductive_coil_pool` research link to select `material_coil_deep_cache` and show `Research lead | Coils near deep-cache machinery`.
- Daily material yield remains two titanium plus one conductive coil; cargo capacity and boat-only banking remain unchanged.
- The legacy anomaly discovery remains independent and compatible with the second discovery id.

## Ownership And Source Boundaries

- The production-slice generator owns the resource target, clue/finding text, discovery link, route context, commit destination, researched pool subset, and lead label.
- Survey and material validators reject unsupported ids, illegal placement, broken target-to-pool links, invalid subsets, runtime-owned fields, and changed yield guarantees.
- `expedition_discovery_state.gd` owns one pending finding and exact commit semantics.
- `expansion_profile_state.gd` owns both durable discovery ids without a schema bump.
- `anomaly_survey_runtime.gd` derives resource versus anomaly behavior from source while preserving scanner and legacy-anomaly rules.
- `expedition_day_state.gd` owns the current-day selection cache; `material_candidate_selector.gd` applies researched subsets only for a fresh selection.
- `material_runtime_controller.gd` and `practical_research_presentation.gd` expose the source-derived habitat lead without taking over cargo, banking, projects, or day lifecycle.
- `main.gd` remains orchestration debt; Expansion 05 added focused helpers rather than moving research ownership into it.

## Deterministic Evidence

- Generator repeatability, SVG render, source validation, cross-domain research validation, reachability, and Godot terrain/collision parity pass.
- Focused profile/pending and material-selection state smokes pass.
- `--smoke-expansion-05-practical-research` covers gate/scanner requirements, partial/cancel behavior, oxygen pressure, connector preservation, all failure cleanup paths, exact boat commit, reload, current-day stability, next-day selection, habitat lead, unchanged yield/cargo/banking, and legacy anomaly compatibility.
- The full release-candidate validation suite passed locally with Godot 4.7 after the final runtime merge.
- GitHub `Godot Smoke` run `29085923650` passed merged runtime commit `f381361`.
- Four focused states were inspected at 1280x720 and 1920x1080. Text, marker states, gate context, boat commit, and next-day machinery/coil context remained readable.
- Accepted production-slice baselines stayed unchanged. The slice-01 standard comparison contains accumulated out-of-scope differences, so no baseline accept command ran.
- Public build `f381361fc7ef1ada8ba87468159610409aced102` passed exact metadata, initialization, request, error, and dual-viewport framing checks.

Visual decision: `docs/current/OCEANGAME_EXPANSION_05_VISUAL_BASELINE_DECISION.md`.

Web evidence: `docs/current/OCEANGAME_EXPANSION_05_WEB_PREVIEW_VERIFICATION.md`.

## Known Risks

- One resource subject and one two-candidate pool do not establish broad research pacing, competing findings, or a catalog UI.
- On some unresearched day numbers, the normal two-candidate rotation already selects the deep-cache coil. Research still supplies actionable habitat knowledge and guarantees that candidate; the deterministic day-three counterfactual proves a changed selection, but future research effects should avoid frequent immediate-day aliasing.
- The next-day HUD keeps both the committed finding and the practical lead visible. The reviewed state fits, but a future durable research log may allow tighter hierarchy.
- The standard slice-01 accepted baseline predates several intentional HUD/material/visibility changes; any consolidation needs its own scoped review.
- `main.gd` remains temporary file-length debt. Split only at cohesive ownership boundaries when selected work needs one.

## Deferred Work

- #52/#53 remain deferred optional slice-03 presentation polish.
- Broad field guides, research catalogs, exact map markers, quest lists, multiple scanner modes, and research trees remain deferred.
- Additional material families, recipes, project menus, inventory UI, economy, and map-scale expansion remain deferred.
- Biological resources and weapon progression remain in Expansion 07; daily ecology and seeded conditions remain in Expansion 08; regional growth remains in Expansion 09.
- Emergency Week, overnight survival taxes, arbitrary procedural geography, and shortcut/fast-travel networks remain rejected.

## Expansion 06 Entry Conditions

The next drift cycle may create one scoped Combat Foundation batch. Before implementation, it must lock:

1. One source-authored hostile encounter and territory in existing geography.
2. Health as a state separate from oxygen, with readable damage, retreat, defeat, and recovery.
3. One first weapon whose prerequisites do not require defeating the enemy it answers.
4. Viable evade and fight choices that preserve salvage, oxygen, daylight, cargo, and route pressure.
5. Source/schema, runtime, UI, failure, smoke, capture, visual, and Web ownership.
6. No broad arsenal, enemy roster, combat economy, procedural encounters, or map-scale expansion.

No Expansion 06 implementation issue is created by this closeout. The next drift cycle owns that issue-level batch.
