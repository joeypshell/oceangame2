# OceanGame Expansion 09 Plan

Date: 2026-07-13

Planning issue: #852

Milestone: OceanGame Expansion 09 `Regional World Growth`

Status: planning decision awaiting review. No implementation issue is approved or created by this plan.

## Decision

Promote `production_slice_02` from a generic later-game reference slice into one bounded authored region: the **Drowned Relay Terminal**.

Use the existing source bounds and terrain unchanged:

```text
full-sketch bounds: x=88, y=78, w=66, h=72
map source: maps/production_slice_02.greybox.json
generator: tools/create_production_slice_02_map.py
entry: relay_sub_entry at local (8, 34)
relay refuge: local (4, 32, 9, 5)
return: return_to_lower_left_relay_connector -> production_slice_04
```

This is the smallest meaningful regional proof because the slice already has validated reachability, terrain/collision parity, accepted reference captures, a broad main chamber, and a distinct lower terminal. Expansion 09 can therefore test regional identity, staged access, cross-region return pressure, practical research, and repeat-visit value without drawing a new map or productionizing the full sketch.

Do not select `production_slice_03` for this milestone. Its optional camera/topology work remains #52/#53 and is not a prerequisite for regional growth. Do not expand the whole full-sketch source.

## Target Experience

The planned journey is:

```text
build the existing current stabilizer -> enter the lower-left relay route
-> reach the Drowned Relay Terminal -> orient around its broken signal mast
-> survey safe-side pressure damage and nonlethally sample one bell jelly
-> carry the finding and pressure membrane back to the canonical boat
-> build one pressure-lining project at night
-> return through remembered geography -> cross the lower-terminal pressure boundary
-> recover the terminal payoff and a deeper signal
-> return to the boat, with a researched terminal material opportunity for a later day
```

The first visit must expose the lower terminal and explain why it is unsafe without allowing accidental progression through it. The safe orientation route must contain every new mandatory prerequisite. The second visit must make the same place traversable through normal swimming, not an `E` transition.

The milestone exit question is: **Does the Drowned Relay Terminal feel like a memorable place worth preparing for and revisiting, while the player still understands how to return to the boat?**

## Meaningful-Change Filter

- Curiosity: the broken signal mast and visible lower terminal promise something below the safe chamber.
- Pressure: oxygen, daylight, cargo, an avoidable jellyfish patrol, and a no-banking relay make the return matter.
- Payoff: the pressure lining opens a previously visible route and secures one durable deeper signal.
- Remembered-place progress: the player crosses the same terminal boundary after a night project changes their capability.
- Route choice: the initial safe chamber, optional resource lane, and lower-terminal commitment have distinct risk.
- Another-day motivation: committed terminal research exposes a useful authored material opportunity, while the deeper signal remains unresolved.

If implementation cannot preserve at least four of these six effects, reduce or hold the milestone rather than shipping a decorated reference slice.

## Region Contract

| Role | Planned source identity | Locked intent |
| --- | --- | --- |
| Region | `drowned_relay_terminal` | Presentation identity for `production_slice_02`; not a second source map. |
| Landmark | `drowned_signal_mast` | One source-authored main-chamber landmark visible from the entry approach. |
| Safe route | existing `approach_route` plus safe side of `main_chamber_route` | Relay to landmark, survey, sample, and return without crossing the pressure boundary. |
| Prior access | existing `current_stabilizer` | Makes the historical lower-left relay route a deliberate late-game approach, not a new prerequisite recipe. |
| Environment survey | `terminal_pressure_survey` | Scanner-backed, safe-side knowledge committed only at the canonical boat. |
| Biological input | `terminal_bell_jelly_membrane_sample` | One guaranteed, nonlethal, scanner-assisted `pressure_membrane`; replenishes on a fresh day. |
| Project | `pressure_lining_project` | Requires committed pressure survey, Ti2, Rubber1, and Pressure Membrane1; builds only at night. |
| Capability | `pressure_lining_1` | Passive suit capability; no inventory slot, activation key, or percentage-stat ladder. |
| Gate | `lower_terminal_pressure_boundary` | Clear safe denial before lining; normal swim-through after lining; never collision or connector travel. |
| Wildlife pressure | one authored jellyfish patrol | Avoidable timing pressure on a secondary lane; not combat, loot, or a mandatory blocker. |
| Payoff | existing `salvage_terminal_relic` plus `lower_terminal_signal_survey` | Valuable cargo and one pending deeper-signal discovery behind the gate. |
| Return reason | `terminal_coil_pool` | Optional researched coil opportunity selected only from authored candidates on later days. |
| Mystery | `bottom_terminal_signal_discovery` | Durable lead toward later world growth; it does not create that destination in this milestone. |

Names are the planning contract for the source-contract issue. That issue may refine display labels, but it must not change the dependency shape or substitute score for ingredients.

## Visual Identity

Keep the existing clear water, blue-gray terrain, sandy edge treatment, and gameplay camera. Give the region identity through a few source-authored layers rather than a global recolor:

- a tall drowned-machinery silhouette and broken teal signal lights at the main-chamber mast
- restrained dark metal, teal glass, and one warm relay beacon around the refuge, consistent with `docs/ART_BIBLE.md`
- pale compression lines or particulate bands at the pressure boundary, visually distinct from red/magenta hazards and warm salvage
- one pale teal bell-jelly silhouette that reads as sampleable wildlife rather than a hostile warning
- denser machinery silhouettes and a repeated signal motif only in the lower terminal after the gate

Do not darken the entire map, hide routes behind atmosphere, bake landmarks into collision terrain, or replace accepted terrain/background modules wholesale. The landmark, pressure cue, wildlife, and terminal payoff should remain readable at gameplay zoom and in the focused review frames.

## Entry, Return, And Connector Decision

Keep the established `production_slice_04` to `production_slice_02` reciprocal connector for this proof only. The Drowned Relay Terminal is treated as a collapsed flooded facility reached through a relay passage, so it qualifies as the explicit interior/destination exception allowed by the roadmap.

This decision does not make prompted connectors the default regional structure:

- add no new connector or shortcut network
- keep ordinary future ocean geography contiguous
- keep currents, darkness, oxygen, pressure, and tool gates as normal movement boundaries inside authored space
- do not use `E` at the pressure boundary
- do not promote reference slices into a menu or fast-travel map

The relay is a refuge, not a second boat. In the integrated journey it may refill oxygen, but it must not bank cargo, commit research, build projects, restore health, end the day, or complete the regional objective. Held salvage, typed materials, biological cargo, pending findings, oxygen, health, daylight, and same-day depletion must survive the outbound and return transitions. Failure restores unbanked regional state and returns the expedition to existing canonical failure handling.

Standalone slice review may still spawn at the relay. Its route smoke must be updated to prove returnability without treating that local spawn as canonical progression commitment.

## Progression And Seed Safety

The mandatory chain is deliberately non-circular:

1. Existing guaranteed anomaly knowledge and Ti2/Coil1 can build `current_stabilizer`; no region material is needed to enter.
2. `terminal_pressure_survey` and `pressure_membrane` are reachable on the safe side of the pressure boundary.
3. Ti2 and Rubber1 retain their existing guaranteed pre-region candidate floors under every supported day.
4. No enemy defeat, optional daily condition, terminal coil candidate, or behind-gate item is required for `pressure_lining_project`.
5. `pressure_lining_1` alone releases the pressure boundary.
6. The valuable terminal payoff and deeper signal are reachable and returnable after release.

The bell-jelly sample is guaranteed once per fresh day and cannot be condition-bound. The terminal coil pool is optional and must never count toward a mandatory recipe floor. The jellyfish patrol must leave an executable approach, retreat, and return lane.

## Source-Of-Truth Boundaries

- `maps/full_cave_sketch_01.greybox.json` remains the topology draft and planning source.
- `tools/create_production_slice_02_map.py` owns the region landmark, relay-refuge semantics, gate, surveys, biological source, candidate pool, patrol, payoff metadata, camera tests, and generated map JSON.
- `tools/create_production_slice_map.py` owns the canonical-boat project catalog entry if the project must be available during debrief. It must reference the slice-02 gate through explicit cross-map IDs rather than duplicate the gate.
- `tools/create_production_slice_04_map.py` continues to own the existing forward connector. Change only its label/intent if the facility fiction requires clarification; do not change topology.
- `docs/MAP_SPEC.md` and validator fixtures must define relay-refuge and pressure-gate rules before source authoring.
- `config/progression_contract.json` must not duplicate map-owned project, gate, survey, material, or connector relationships.
- Godot scenes, runtime nodes, captures, and accepted baselines never own topology or placement.

Terrain topology should remain unchanged. If source validation finds that a viable safe approach, pressure boundary, or return lane cannot fit the existing open water, stop and open a separate targeted topology decision instead of hand-tuning runtime geometry.

## Validation And Preview Boundaries

Validation must prove:

- all region IDs and cross-map references resolve uniquely
- the relay refuge and both connectors are in bounds, non-solid, reachable, and reciprocal
- the safe route, survey, sample, and gate approach are reachable before `pressure_lining_1`
- the gate cannot be crossed before the capability and can be crossed after it
- the lower-terminal payoff, survey, and return connector are capability-reachable after the project
- every mandatory input is guaranteed under every supported seed/day and no dependency cycle exists
- optional terminal candidates are excluded from mandatory floors
- the patrol path is legal and leaves a viable retreat/return lane
- generated terrain and runtime collision remain parity-clean

Extend the progression audit to show the cross-map path through `current_stabilizer`, the safe-side project prerequisites, `pressure_lining_1`, and the lower-terminal payoff. Geometric reachability alone is insufficient for this milestone.

Regenerate only the affected slice-02 JSON, SVG, source/render/collision review, and focused captures. Debug preview must distinguish the landmark, refuge, pressure boundary, mandatory sample/survey, optional material candidates, patrol, and payoff without changing normal collision.

## Runtime And UI Boundaries

- `main.gd` remains orchestration and must not grow for regional logic.
- Existing expedition-day, connector, cargo, material, biological, survey, profile, and project owners retain their domains.
- Add one focused pressure-gate owner if existing current-gate behavior cannot express safe pressure denial without confusing current semantics.
- Cross-map cargo/state preservation belongs with the existing sortie/connector and cargo owners, not map JSON or presentation code.
- The relay refuge may reuse oxygen-refill presentation but must expose compact `Relay refuge - return to boat to bank` guidance.
- Pressure feedback must be compact: boundary warning, project requirement, lining completion, and safe crossing. Do not add a map screen, inventory grid, loadout, research journal, or permanent regional HUD.
- The signal mast, bell jelly, pressure boundary, and terminal payoff need readable individual visuals or existing fallbacks. Do not replace the terrain set, player, boat, all props, or all background art.

## Recommended Issue Batch

Create this dependency-ordered batch only after the plan is reviewed:

1. Lock the Expansion 09 region, relay-refuge, pressure-gate, project, and source validation contract.
2. Extend cross-map progression and staged-reachability audits for the regional chain.
3. Author the Drowned Relay Terminal landmark, safe route metadata, refuge, gate, survey, sample, patrol, optional pool, and payoff through generators.
4. Preserve regional cargo and expedition state across connectors and enforce canonical-boat-only commitment.
5. Implement the pressure survey, guaranteed membrane sample, profile material, and exact night project transaction.
6. Implement passive pressure-boundary behavior, terminal payoff, deeper-signal finding, and researched return opportunity.
7. Add one deterministic integrated regional journey smoke plus focused regressions and CI coverage.
8. Add focused regional captures and review intentional visual differences against all accepted slice baselines.
9. Verify the exact public Web build and run the player GO/HOLD closeout for the regional exit question.

Do not create separate tickets merely to reach ten. Split an item only if implementation review identifies a real ownership or validation boundary.

## Smoke And Review Plan

The integrated journey smoke must report and verify:

- prior `current_stabilizer` requirement and successful region entry
- preserved oxygen, health, daylight, held cargo, and day state across both connectors
- relay oxygen refuge without banking, research commit, project build, health refill, or end-day behavior
- safe-route survey/sample reachability and leave-range cancellation
- exact Pressure Membrane1, Ti2, Rubber1 recipe with no score substitution
- failure restoration before banking and exact-once canonical boat commitment
- night-only `pressure_lining_1` completion and durable profile reload
- denial before lining and normal movement through the same boundary after lining
- lower-terminal payoff, pending deeper signal, return, and canonical commitment
- fresh-day researched terminal coil opportunity with mandatory progression unchanged
- optional patrol approach/retreat viability and existing Expansion 01-08 journeys still green

Run focused checks per issue. Run `python tools/run_release_candidate_validation.py` once after the integrated journey and smoke merge, then again only if later visual/Web work changes executable source.

Visual review must include the relay/landmark orientation frame, blocked pressure boundary, post-lining lower terminal, and return-to-boat payoff at both supported viewports. Accept only the named regional additions. Reject unrelated terrain, collision, camera, player, boat, existing connector, route, eel, daily-condition, or HUD drift.

## Deferred Work

- productionizing the full sketch or combining every slice into one map
- ordinary-region connector chains, fast travel, map menus, or shortcuts
- `production_slice_03` camera/topology polish (#52/#53)
- issue #849 repository-health work
- more pressure tiers, decompression simulation, equipment durability, vehicles, bases, or diving physics
- broad crafting/economy, inventory, project tree, ecosystem simulation, creature catalog, or new combat arsenal
- final terrain, background, prop, creature, player, audio, or HUD replacement
- implementing the bottom-terminal destination named by the deeper signal

## Exit Criteria

Expansion 09 is technically ready for player review when:

- the existing slice-02 terrain becomes a readable Drowned Relay Terminal without source/render/collision drift
- the first visit clearly exposes the landmark, safe route, mandatory survey/sample, and pressure promise
- every mandatory prerequisite is guaranteed, pre-gate, non-circular, and seed-independent
- the relay preserves expedition pressure and cannot replace the canonical boat
- the night project changes the remembered pressure boundary through passive normal traversal
- the lower-terminal payoff and deeper lead can be carried back and committed at the boat
- the researched optional material opportunity gives a concrete later-day return reason
- staged reachability, integrated smoke, release validation, focused visual review, and exact-SHA Web verification pass

The milestone closes only after the user answers the exit question with GO or HOLD. Automation may establish technical readiness, but it must not claim the region is memorable, readable, or motivating to a player.
