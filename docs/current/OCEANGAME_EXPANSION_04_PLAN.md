# OceanGame Expansion 04 Plan

Date: 2026-07-10

Issues: #726-#735

Milestone: OceanGame Expansion 04 `Capability-Gated Map Progression`

## Decision

Expansion 04 will prove one complete capability-planned remembered-place loop inside the existing `production_slice_01` topology:

```text
see valuable salvage across an overpowering current
-> finish the cutter/anomaly prerequisites
-> gather one more guaranteed material recipe
-> build a durable current stabilizer at night
-> return to the same upper-right room
-> cross the current and bring the payoff home
```

The pass reuses the current-gate grammar and gives the stabilizer durable profile ownership. #815 later migrated `lower_left_loop_current` from the legacy session upgrade to durable recipe-built `propulsion_fins`; the two gates remain separate capability ids and traversal roles.

## Player Promise

The player should understand: "There is valuable salvage in that east pocket, but this current is stronger than my diver. A stabilizer project will let me cross it on a later day."

The payoff must be visible before unlock, the blocker must name the missing capability, and the player must still travel from the boat through remembered geography after the project is complete.

## Locked Source Contract

| Role | Id | Rule |
| --- | --- | --- |
| Existing prerequisite project | `salvage_cutter_project` | Must be complete before the stabilizer may build. |
| Existing knowledge | `lower_right_anomaly_discovery` | Remains the practical knowledge prerequisite. |
| New project | `current_stabilizer_project` | Night-only, exact-once project. |
| New durable capability | `current_stabilizer` | Profile-owned and available on every later day/map. |
| New gate | `upper_right_current_pocket_gate` | Left-pushing current across the east side of the existing upper-right room. |
| New payoff | `salvage_current_pocket_cache` | Visible valuable salvage behind the gate; normal cargo/banking semantics. |

The project recipe is exactly 2 `titanium_scrap` and 1 `conductive_coil`. The existing authored day pools guarantee that recipe on every supported day seed. Completion consumes the recipe once and records the project/capability pair atomically.

## Locked Placement

The gate uses the existing open east pocket in the upper-right wreck room:

- rectangle: `x=65, y=40, w=2, h=2`
- current direction: `left`
- strength: `2.2`, stronger than normal swim progress
- route context: `upper_right_current_pocket`
- required durable capability: `current_stabilizer`
- payoff point: `x=69, y=40`

`salvage_sealed_wreck_cache` remains at `x=61, y=40`, before the new gate. The cutter payoff therefore remains fully completable during Expansion 03 progression. No terrain rectangle, collision cell, connector, spawn, extraction zone, primary objective, or camera test changes.

## Meaningful-Change Filter

This pass is valid because it adds:

- curiosity: a visible reward across a readable environmental blocker
- pressure: the player scouts the promise while oxygen/daylight continue
- payoff: one compact project changes traversal, not only a stat number
- remembered-place progress: the same pocket changes after a later night
- route choice: the optional return competes with cargo, oxygen, and daylight
- another-day motivation: the project explicitly promises a reachable place

Work that does not support this chain remains deferred.

## Gate Behavior

Before unlock:

- a restrained source-derived cue shows current direction and boundary
- entering the gate pushes left strongly enough to defeat normal rightward swimming
- oxygen and daylight continue
- compact feedback reads `Ripping current - need current stabilizer`
- terrain, collision, payoff visibility, and unrelated interactions remain unchanged

After unlock:

- the same authored volume stops applying blocking pushback
- the player crosses under normal movement and ongoing oxygen/daylight pressure
- the capability persists through reset, connector travel, day changes, and profile reload
- the payoff uses existing valuable salvage, cargo-full protection, failure restoration, boat banking, score, and result behavior

The gate is route pressure, not collision. It does not teleport the player, cut terrain, open a shortcut, or create a global water simulation.

## Project And Profile Rules

- Valid profile schemas v1 and v2 migrate to schema v3 without losing scanner, discovery, cutter, material, or project state.
- The stabilizer project/capability must always be both complete or both absent.
- The cutter project must already be complete; direct stabilizer unlock is rejected.
- The anomaly discovery remains required.
- The build is available only during night debrief.
- `P` acts on the first incomplete source-ordered project whose prerequisites are satisfied; there is no recipe menu.
- Save failure restores consumed materials and leaves project/capability incomplete.
- Durable `propulsion_fins` and `current_stabilizer` remain separate ids, projects, and gate roles.

## Ownership Boundaries

- JSON/generator source: project order, recipe, prior-project link, gate rectangle/direction/strength/requirement, payoff position/role, and route context.
- Validators: supported ids, exactly one current requirement kind, project graph, backlinks, guaranteed recipe, legal open placement, reachability, and no runtime fields.
- `expansion_profile_state.gd`: durable project/capability pair, material transaction, schema migration, and persistence.
- `material_project_runtime.gd`: source-ordered project catalog, active project, readiness, debrief lines, and build delegation.
- `current_gate_controller.gd`: requirement resolution, pushback, and prompt state.
- Focused world renderer/helper: source-derived current affordance only.
- Existing cargo/offload/sortie/day owners: payoff collection, failure, boat commit, oxygen, and daylight.
- `main.gd`: delegation and compact presentation coordination only.

## Planned Issue Order

1. #726 lock the experience and source contract.
2. #727 lock project, profile, and gate ownership.
3. #728 extend schema and validator coverage.
4. #729 author the gate, project, and payoff through the generator path.
5. #730 generalize the project/profile owners for the stabilizer.
6. #731 implement durable current-gate resolution.
7. #732 add promise, return, and payoff feedback.
8. #733 add integrated deterministic journey smoke and CI.
9. #734 capture and review the visual impact.
10. #735 verify public Web deployment and record GO or HOLD.

## Validation Plan

Validation must cover:

- positive/negative source fixtures for current capability requirements and project prerequisites
- regeneration, SVG render, map validation, terrain/collision parity, and unchanged source topology
- existing cutter project and legacy current-gate regressions
- profile v1/v2 migration, exact pairing, prerequisite ordering, exact recipe, rollback, and reload
- blocked push strength, oxygen/daylight continuation, unlocked crossing, reset/day/connector durability
- payoff visibility, cargo-full protection, failure restoration, boat banking, score, and result text
- one integrated `--smoke-expansion-04-current-pocket` journey in CI/release validation

Treat `SCRIPT ERROR` and `ERROR:` output as failures even when Godot exits zero.

## Visual And Web Plan

- Use a restrained current cue derived from the authored gate; no new broad art pass.
- Capture locked current, project-ready debrief, unlocked crossing, and payoff feedback at 1280x720 and 1920x1080.
- Compare every accepted production-slice baseline before any decision.
- Reject unrelated terrain, collision, player, boat, prop, camera, or HUD drift.
- Verify exact merged Web build metadata, initialization, requests, console, and dual-viewport framing.

## Deferred Work

- #52/#53 optional slice-03 presentation polish
- additional current, darkness, oxygen/depth, pressure, sealed-route, or enemy gates
- map-scale expansion, shortcut/fast-travel networks, or terrain destruction
- project menus, inventory UI, tool selection, durability, batteries, broad recipes, or economy
- practical research, enemies, weapons, biological resources, daily encounter ecology, and regional growth
- final current art/audio and broad environment replacement

## Exit Criteria

Expansion 04 may close with **GO** only when:

1. A fresh eligible player can see and understand the current-pocket promise before owning the stabilizer.
2. Existing progression remains completable and every recipe prerequisite is guaranteed.
3. The night project creates one exact, durable profile capability without ownership ambiguity.
4. The locked gate prevents normal crossing without collision and the unlocked gate permits it.
5. The player collects, risks, restores on failure, and banks the authored payoff through existing systems.
6. Source validation/parity, regression/integrated smokes, captures, baseline review, and public Web verification pass.
7. Review answers yes to: "Did the stabilizer change the player's relationship with a place they remembered rather than act as a generic stat purchase?"

A **HOLD** must name the smallest corrective pass and must not broaden into Expansion 05.
