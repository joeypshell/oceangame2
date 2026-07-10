# OceanGame Expansion 03 Plan

Date: 2026-07-10

Issues: #706-#715

Milestone: OceanGame Expansion 03 `Seeded Materials And First Tool Project`

## Decision

Expansion 03 will prove one complete material-to-capability return loop without adding a broad crafting game:

```text
notice sealed wreck -> gather day-seeded materials -> bank at canonical boat
-> finish anomaly knowledge -> build cutter at night -> return next day
-> cut open remembered wreck -> bring payoff home
```

The default map remains `production_slice_01`. Geography, collision, connectors, camera tests, daylight, oxygen, normal salvage, and the existing survey journey stay authoritative.

## Player Promise

The player should understand: "I found a place I cannot open yet. Today's materials and the anomaly discovery can produce a cutter, so a later dive can change that known place."

This is the first retained reason to begin another day beyond score. The target must be visible before the project is complete and still worth revisiting after the cutter unlocks it.

## Locked Content

| Role | Id | Rule |
| --- | --- | --- |
| Common material | `titanium_scrap` | Bank 2 for the project. |
| Special component | `conductive_coil` | Bank 1 for the project. |
| Knowledge | `lower_right_anomaly_discovery` | Existing committed Expansion 01 discovery. |
| Project | `salvage_cutter_project` | Available only in the night debrief. |
| Durable capability | `salvage_cutter` | Always available after completion; no equip step. |
| Remembered target | `salvage_sealed_wreck_cache` | Source-authored cutter interaction in slice 01. |
| Interaction | `cutter_salvage` | Two seconds in range; leaving cancels progress. |
| Payoff | valuable salvage | Uses the existing valuable score/cargo semantics. |

The project recipe is exactly 2 `titanium_scrap`, 1 `conductive_coil`, and the committed anomaly discovery. Completion consumes the materials once and adds `salvage_cutter` to the versioned profile.

## Meaningful-Change Filter

This pass is valid because it adds:

- curiosity: a sealed wreck is readable before it can be opened
- pressure: material pickups consume cargo slots under oxygen and daylight
- payoff: banked items become one durable capability, not generic score
- remembered-place progress: the cutter changes a previously blocked target
- route choice: authored candidate slots rotate inside known safe/deep routes
- another-day motivation: project completion and the return payoff span nights

Any work that does not support this chain is deferred.

## Material Candidates

Materials use source-authored candidate pools. Runtime may select candidate ids but may not invent coordinates, move terrain, or reroll geography.

- `titanium_scrap_pool`: at least four reachable authored slots; select two each day.
- `conductive_coil_pool`: at least two reachable authored slots; select one each day.
- Every selected slot yields one unit.
- The selected set is derived deterministically from map id, pool id, and `day_number` using a documented stable algorithm.
- The same day and source produce the same ids across reloads, connectors, smoke, native, and Web builds.
- Selection always exposes the full first-project recipe. No required material depends on chance.
- Common slots may span safe and deep routes. The conductive coil should reinforce a meaningful deeper-route decision without requiring a new destination.

## Day And Depletion Rules

- The expedition-day owner records the material day seed, selected ids by map, and depleted ids.
- Reloading a map or crossing a connector during the same day does not reroll or respawn depleted candidates.
- A normal next day selects from the same authored pools using the next day number.
- Manual reset and recoverable hazard/oxygen failure restore unbanked material pickups to their active same-day slots.
- Forced nightfall away from the boat clears unbanked material cargo. The next day uses its own selected set.
- Banked profile materials remain durable across day changes, reset, and profile reload.

## Cargo And Boat Rules

- Each material unit consumes one existing cargo-capacity slot.
- Material pickup adds no salvage score and no wallet value.
- Unbanked materials cross source-authored connectors with the diver.
- Relay/base extraction may keep legacy salvage behavior, but it never commits typed materials.
- Only the canonical `production_slice_01` boat commits typed materials to the profile.
- Cargo-full material candidates and the sealed target remain present.
- Failure clears held typed materials and restores their source availability according to the day rules.

## Night Project

The existing compact debrief gains one project summary and one action:

- locked knowledge: `Cutter project: anomaly knowledge required`
- incomplete: `Cutter project: Ti 1/2 | Coil 0/1`
- ready: `P: Build salvage cutter`
- completed: `Salvage cutter built`

`P` is scoped to debrief while the existing active-run propulsion purchase remains unchanged. Building does not automatically begin the next day; `N` keeps that responsibility.

There is no inventory grid, recipe browser, crafting station, queue, timer, equip slot, durability, charge, or tool upgrade in this pass.

## Cutter Interaction

- Before unlock, proximity shows `Sealed wreck | Cutter required` and cannot collect the target.
- After unlock, proximity begins `cutter_salvage` progress automatically, matching the current in-range salvage interaction style.
- Oxygen and daylight continue while cutting.
- Leaving range cancels progress.
- Cargo capacity blocks completion without deleting the target.
- Completion enters normal held valuable salvage and must still be banked.
- Failure before banking restores the payoff; the durable cutter remains unlocked.
- No terrain is cut and no collision or topology changes.

## Runtime Ownership

- `expedition_day_state.gd`: day seed, selected candidate ids, and same-day depletion.
- A focused material cargo/runtime owner: held typed cargo, candidate activation, connector preservation, failure restoration, and boat commit coordination.
- `expansion_profile_state.gd`: versioned banked material quantities, committed discovery, completed project/capability, load/save/migration.
- A focused project owner: recipe readiness and exact-once transaction.
- A focused cutter interaction owner: locked/progress/cancel/complete behavior.
- `greybox_world.gd` and focused world helpers: source metadata queries and visibility only.
- `main.gd`: delegation, input routing, and presentation coordination; it must not become the material or project state owner.

## Source-Of-Truth Boundaries

- Candidate pools, candidate slots, material ids, project metadata, target id, required tool, and interaction timing are machine-readable source data.
- Update the slice-01 generator/helper first, then regenerate JSON and SVG.
- Validators must prove ids, supported values, counts, bounds, non-solid placement, reachability, and guaranteed prerequisites.
- Runtime may select or hide authored candidates but may not alter source topology.
- Existing `tools/create_production_slice_map.py` and `tools/validate_greybox_map.py` are at the 500-line target; add focused helpers instead of growing them past the policy.

## Planned Issue Order

1. #706 plan the player promise and exit contract.
2. #707 define material, project, persistence, connector, and boat ownership.
3. #708 add source schema and focused validation.
4. #709 author candidate slots and the sealed target through the generator path.
5. #710 implement deterministic selection, typed cargo, and canonical-boat banking.
6. #711 implement the night project and durable cutter capability.
7. #712 unlock the remembered sealed-wreck interaction and payoff.
8. #713 add deterministic journey smoke, CI, and release validation.
9. #714 add focused captures and make a controlled visual decision.
10. #715 verify public Web deployment and record GO or HOLD.

## Validation Plan

Validation must cover:

- positive and negative source schema fixtures
- source regeneration, SVG render, map validation, reachability, and parity
- deterministic same-day selection and valid next-day variation
- guaranteed recipe materials
- cargo capacity, connector preservation, canonical-boat commit, reset, hazard, oxygen, and nightfall cleanup
- project knowledge/material gating, exact-once consumption, capability persistence, and profile migration
- cutter locked/progress/cancel/capacity/complete/failure behavior
- all existing expedition-day, anomaly, salvage, cargo, connector, oxygen, and hazard smoke contracts
- one integrated Expansion 03 journey smoke in CI and release-candidate validation

Treat `SCRIPT ERROR` and `ERROR:` output as failures even when Godot exits zero.

## Visual And Web Plan

- Use existing material/salvage visual language; no new broad asset pass is required.
- Capture a readable material state, project-ready debrief, locked sealed target, and active cutter progress.
- Inspect 1280x720 and 1920x1080 without accepting unrelated terrain, player, boat, prop, or camera drift.
- Compare all accepted production-slice baselines before any acceptance.
- Verify the merged public build metadata, initialization, requests, console, and dual-viewport framing.

## Deferred Work

- #52/#53 optional slice-03 presentation polish
- tool selection, upgrades, durability, batteries, broad recipes, inventory UI, economy, or material conversion
- map-scale capability gates, which belong to Expansion 04
- practical research, enemies, weapons, biological resources, daily encounter ecology, and regional growth
- new destinations or connectors solely for material placement
- Emergency Week, overnight survival taxes, procedural geography, and shortcuts/fast travel

## Exit Criteria

Expansion 03 may close with **GO** only when:

1. A fresh player can encounter the sealed target before owning the cutter.
2. Every day deterministically offers the complete project recipe through reachable authored slots.
3. Material cargo, connectors, boat commitment, failures, nightfall, and next-day depletion match the ownership contract.
4. The anomaly discovery plus banked materials completes one exact-once night project.
5. The durable cutter opens the remembered target and produces a bankable payoff.
6. Focused and regression smokes, map validation/parity, captures, baselines, and public Web verification pass.
7. Review answers yes to: "Does finding material create anticipation for a specific return rather than feel like generic currency?"

A **HOLD** must name the smallest corrective pass; it must not silently expand into Expansion 04.
