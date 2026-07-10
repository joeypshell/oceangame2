# OceanGame Expansion 03 Closeout

Date: 2026-07-10

Issues: #706-#715

Milestone: OceanGame Expansion 03 `Seeded Materials And First Tool Project`

## Decision

**GO** to OceanGame Expansion 04: Capability-Gated Map Progression.

Finding material now creates anticipation for a specific remembered return rather than behaving like generic currency. Titanium and the conductive coil consume cargo space, survive only through the defined boat/connector rules, feed one named cutter project at night, and unlock the sealed wreck the player could inspect earlier. The valuable payoff still has to come home.

This is a GO for the interaction and ownership proof, not a claim that material pacing or long-term retention is balanced. Expansion 04 should prove one capability-planned place before adding more recipes, tools, or map scale.

## Delivered Experience

- `production_slice_01` authors deterministic titanium and conductive-coil candidate pools with guaranteed daily prerequisites.
- Day seed and depletion remain stable across reloads and source-authored connectors.
- Typed materials share cargo capacity with salvage, add no score, and commit only at the canonical boat.
- Hazard, oxygen, reset, and forced-night paths restore or clear unbanked material state according to the ownership contract.
- The anomaly discovery plus exactly 2 titanium and 1 coil makes one night-only salvage-cutter project available.
- Completing the project consumes its recipe once and stores the durable cutter in the versioned profile.
- The sealed wreck is visible while locked, reports the missing cutter, then supports a timed cancel-on-leave cutting interaction.
- The opened wreck produces existing valuable salvage that remains subject to cargo and boat-banking pressure.

## Ownership And Source Boundaries

- JSON/generator source owns candidate pools, candidate positions, material ids, project metadata, target requirements, and interaction timing.
- Validators prove supported values, pool guarantees, legal placement, reachability, and non-circular prerequisites before runtime.
- `expedition_day_state.gd` owns deterministic day selection and depletion.
- Focused material, project, cargo, cutter, debrief, smoke, and capture helpers own their domains; `main.gd` remains orchestration debt.
- `expansion_profile_state.gd` owns banked materials, committed discovery, completed project, and durable capability with schema migration.
- `greybox_world.gd` coordinates source-derived nodes while focused world helpers own material and tool-target rendering/query state.
- Terrain topology, collision, connectors, camera tests, accepted baselines, and existing expedition semantics remain unchanged.

## Deterministic Evidence

- Source validator fixtures, all map validators, regeneration/parity checks, and focused material/project/cutter state smokes pass.
- `--smoke-expansion-03-material-project` covers recipe selection, cargo/connector/boat rules, knowledge and project gates, profile reload, next-day rotation, locked/unlocked wreck behavior, failure restoration, and payoff banking.
- The full release-candidate validation suite passed locally with Godot 4.7.
- GitHub `Godot Smoke` run `29075848135` passed for merged commit `9322863`.
- Four focused states were inspected at 1280x720 and 1920x1080. Text and target affordances remained readable.
- All production-slice comparisons remained clean; no baseline accept command ran.
- Public build `9322863ac25486a2a869d5e7f154cc58dbb70183` passed metadata, initialization, request, error, and dual-viewport framing checks.

Visual decision: `docs/current/OCEANGAME_EXPANSION_03_VISUAL_BASELINE_DECISION.md`.

Web evidence: `docs/current/OCEANGAME_EXPANSION_03_WEB_PREVIEW_VERIFICATION.md`.

## Known Risks

- Material/project communication is deliberately compact and text-led; player testing may require clearer individual material silhouettes or pacing changes.
- The first recipe is guaranteed and narrow. It does not yet prove a larger project catalog, competing recipes, or satisfying material abundance.
- The sealed wreck proves a remembered interaction gate without changing terrain collision. Expansion 04 must prove that a capability meaningfully changes access to a place.
- `main.gd` remains temporary file-length debt. New gate work should use focused owners and split only at stable boundaries.
- The Node.js action-version warnings in the Web workflow are maintenance debt, not runtime failure.

## Deferred Work

- #52/#53 remain deferred optional slice-03 presentation polish.
- Tool selection, durability, batteries, broad crafting, inventory UI, economy, and material conversion remain deferred.
- Practical research, enemies, weapons, biological resources, daily encounter ecology, and regional growth stay in their named later milestones.
- Emergency Week, overnight survival taxes, arbitrary procedural geography, and shortcut/fast-travel networks remain rejected.
- The Expansion 04 issue batch belongs to the next drift cycle; this closeout selects its direction only.

## Expansion 04 Entry Conditions

The next batch should plan one source-authored capability gate around remembered geography before authoring or runtime work. It must lock:

1. One blocker type and one diver capability, chosen from oxygen/depth, darkness/light, current/propulsion, or another already supported progression axis.
2. A place the player can see or understand before the capability is available.
3. Source, validator, runtime, feedback, persistence, and return-route ownership.
4. A meaningful payoff behind the gate without broad map expansion or a shortcut network.
5. Deterministic smoke, focused capture, visual decision, Web verification, and GO/HOLD closeout.

Only Expansion 04 should receive the next approximately ten actionable issues. Expansions 05-09 remain directional.
