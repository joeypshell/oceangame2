# OceanGame Expansion 04 Closeout

Date: 2026-07-10

Issues: #726-#735, with validator blocker #739 resolved during authoring

Milestone: OceanGame Expansion 04 `Capability-Gated Map Progression`

## Decision

**GO** to OceanGame Expansion 05: Practical Research Foundation.

Yes, the stabilizer changes the player's relationship with a remembered place instead of acting as a generic stat purchase. The player can see valuable salvage beyond an overpowering current, learn the missing capability, complete its named night project, return through unchanged geography, cross the same boundary, and still risk the payoff on the trip back to the boat.

This is a GO for one complete capability-planned place. It does not prove broad upgrade pacing, a project menu, multiple gate families, or larger map production. Expansion 05 should make knowledge alter expedition or project decisions before the game adds more gates, recipes, or regions.

## Delivered Experience

- The existing upper-right room presents a visible valuable cache beyond a source-authored left-pushing current.
- Locked feedback names the missing `current_stabilizer`; oxygen and daylight continue while the current rejects normal crossing.
- The anomaly, cutter project, and a guaranteed recipe of 2 titanium plus 1 conductive coil make one source-ordered stabilizer project available at night.
- Project completion records one durable profile capability that survives reset, day change, connector travel, and reload.
- The unlocked player crosses the same room under normal expedition pressure; terrain and collision never change.
- The valuable cache retains existing cargo-full protection, failure restoration, boat-only banking, scoring, and result behavior.

## Ownership And Source Boundaries

- JSON/generator source owns the project order and recipe, gate rectangle/direction/strength/requirement, payoff, and route context.
- Validators prove supported requirement kinds, prerequisite ordering, guaranteed recipe, legal open placement, reachability, and non-circular progression.
- `expansion_profile_state.gd` owns the exact durable project/capability pair and schema migration.
- `material_project_runtime.gd` owns source-ordered project readiness and build delegation.
- `current_gate_controller.gd` resolves session and profile requirements separately; the world renderer derives boundary and flow cues from the same gate record.
- Existing expedition, cargo, connector, failure, boat, daylight, and oxygen owners retain their prior semantics.
- `main.gd` remains orchestration debt; Expansion 04 did not move gate ownership into it.

## Deterministic Evidence

- Source fixtures, map generation, SVG rendering, validators, terrain/collision parity, and focused profile/project/gate checks pass.
- `--smoke-expansion-04-current-pocket` covers locked pressure, prerequisites, exact recipe, profile reload, unlocked crossing, failure restoration, cargo capacity, payoff banking, and legacy current independence.
- The full release-candidate validation suite passed locally with Godot 4.7.
- GitHub `Godot Smoke` run `29081121697` passed merged commit `679c16e`.
- Five focused states were inspected at 1280x720 and 1920x1080. Current direction, prompts, project readiness, crossing, held payoff, and banked payoff remained readable.
- Accepted production-slice baselines stayed unchanged. Standard comparison exposed accumulated out-of-scope HUD/material/visibility differences, so no baseline accept command ran.
- Public build `679c16eccad0d87e7f47d50ce2a7737fbd9e050c` passed metadata, initialization, request, error, and dual-viewport framing checks.

Visual decision: `docs/current/OCEANGAME_EXPANSION_04_VISUAL_BASELINE_DECISION.md`.

Web evidence: `docs/current/OCEANGAME_EXPANSION_04_WEB_PREVIEW_VERIFICATION.md`.

## Known Risks

- One guaranteed recipe and one environmental gate do not establish long-term upgrade pacing or competing project choices.
- The current cue is intentionally restrained and may need art/audio refinement after broader player testing.
- The standard slice-01 accepted baseline predates several intentional HUD/material/visibility changes; any consolidation needs its own scoped review.
- `main.gd` remains temporary file-length debt. Split only at cohesive ownership boundaries when feature work needs one.
- Node.js action-version warnings are maintenance debt, not runtime failure.

## Deferred Work

- #52/#53 remain deferred optional slice-03 presentation polish.
- Additional current, darkness, oxygen/depth, pressure, sealed-route, or enemy gates remain deferred until a selected milestone needs them.
- Project menus, inventory UI, durability, batteries, broad recipes, economy, and map-scale expansion remain deferred.
- Combat, biological resources, daily encounter ecology, and regional growth stay in their named later milestones.
- Emergency Week, overnight survival taxes, arbitrary procedural geography, and shortcut/fast-travel networks remain rejected.

## Expansion 05 Entry Conditions

The next batch should plan one practical research journey in which scanning or sampling changes a later expedition or project decision. Before source or runtime work, it must lock:

1. One research subject and one incomplete pre-scan clue.
2. The practical knowledge revealed, without exact-route handholding.
3. Source, profile, runtime, UI, and project ownership.
4. One observable next-expedition or preparation consequence.
5. Deterministic smoke, focused capture, visual decision, Web verification, and GO/HOLD closeout.

The next drift cycle owns the scoped Expansion 05 issue batch. No Expansion 05 implementation issue is created by this closeout.
