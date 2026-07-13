# OceanGame Expansion 08 Plan

Date: 2026-07-13

Planning issue: #836

Milestone: OceanGame Expansion 08 `Daily Conditions And Enemy Ecology`

## Decision

Prove one forecasted daily route opportunity without changing authored geography:

```text
baseline day -> night forecast names tomorrow's southwest jellyfish bloom
-> next day adds one optional southwest patrol and one bonus coil trace
-> player chooses whether the extra material is worth the migration pressure
-> banked material persists while the condition rotates away
```

`southwest_jellyfish_bloom` is inactive on odd day numbers and active on even day numbers. The schedule derives only from the existing session-local expedition day number, uses no engine RNG, and is identical on every platform. The night debrief always reports the next day's state before `N` starts it.

This is a bounded deterministic proof, not a generic weather, encounter, or ecosystem framework.

## Target Experience

At night, the player should understand: "Tomorrow the southwest pocket has more jellyfish, but there is an extra conductive trace there." On the next day, the same remembered pocket should visibly match that forecast. The player may pursue it, take another route, or end the day without losing mandatory progression.

The milestone exit question is: **Does the forecast create a reason to plan another day while the map remains learnable?**

## Locked Content

| Role | Id | Rule |
| --- | --- | --- |
| Daily condition | `southwest_jellyfish_bloom` | Even-day, session-local, deterministic, forecast one night ahead. |
| Bonus material pool | `southwest_bloom_coil_bonus_pool` | One condition-bound conductive-coil candidate; never counts toward a required recipe floor. |
| Bonus candidate | `material_coil_southwest_bloom` | One authored open/reachable point in the existing southwest return pocket. |
| Migration patrol | `southwest_bloom_jellyfish_patrol` | One authored condition-bound jellyfish path in that pocket. |
| Existing patrol | `deep_route_jellyfish_patrol` | Remains unconditional and unchanged. |

Exact candidate/path coordinates belong to source authoring after validation proves open placement and a viable approach/retreat lane. Terrain, collision, connectors, camera tests, route markers, and existing entities do not move.

## Meaningful-Change Filter

- Curiosity: the debrief previews a concrete living-ocean change.
- Pressure: the bonus appears with an additional moving hazard, under normal oxygen/daylight/cargo limits.
- Payoff: one extra coil accelerates an optional project input but is not required.
- Remembered-place progress: the opportunity uses the known southwest pocket.
- Route choice: the player may accept or skip the risk.
- Another-day motivation: the forecast gives tomorrow a specific destination.

## Source-Of-Truth Boundaries

- Add one optional top-level daily-condition definition through the slice-01 generator path.
- Add explicit condition links to one optional material pool and one moving hazard. Runtime activation never mutates source dictionaries.
- Condition-bound material pools are optional bonus pools. Validators must exclude them from mandatory recipe guarantees and reject any required progression edge that depends on them.
- Source validation owns ids, links, schedule shape, route context, open/reachable placement, patrol path legality, and non-overlap with blocking interaction centers.
- The progression graph must preserve every current required path on both odd and even days.
- Generated JSON/SVG and Godot world nodes remain outputs of source/generator and renderer rules.

## State And Runtime Boundaries

- A new focused daily-condition owner derives current and next condition ids from day number and immutable definitions.
- The existing expedition-day owner keeps day number and lifecycle; it does not absorb condition schema or presentation.
- Material selection filters condition-bound bonus pools before using the existing selector. Normal pools and guaranteed counts are unchanged.
- Moving-hazard runtime activates and renders the migration patrol only on bloom days. The existing patrol remains active every day.
- Starting the next day recomputes condition state before map/material/hazard initialization. Connector travel preserves the current day and condition.
- Banked bonus material uses the existing cargo, boat, typed inventory, project, and profile owners. Unbanked failure/restoration semantics remain unchanged.
- The debrief appends one compact next-day forecast. The active overlay adds one compact condition line only on bloom days.
- No new save schema is required; conditions are session-day state, matching the current expedition day lifecycle.

## Planned Issue Batch

1. Lock daily-condition source/state contracts and validation.
2. Author the condition, bonus coil candidate, and migration patrol through the generator.
3. Implement deterministic condition lifecycle, forecast, and condition-bound material/hazard activation.
4. Add an integrated deterministic journey smoke and CI/release coverage.
5. Add focused forecast/active-day captures and record a technical visual decision without accepting unrelated baselines.
6. Verify the exact public Web build and record an explicitly labeled technical closeout.

Implementation may split item 3 only if source review finds a real owner boundary; do not add ceremony merely to reach ten issues.

## Validation And Smoke Plan

Source checks must reject missing/duplicate ids, unsupported schedules, dangling condition links, condition pools used by mandatory recipes, invalid material quantities, solid/unreachable candidates, illegal patrol paths, and condition content that changes topology or guaranteed progression.

The integrated smoke must prove:

- day 1 has no bloom patrol or bonus coil
- night 1 forecasts the day-2 bloom before transition
- day 2 activates exactly the authored patrol and bonus candidate
- normal material selections and the unconditional patrol remain unchanged
- the bonus obeys cargo-full, collection, boat banking, connector, hazard, oxygen, and reset semantics
- night 2 forecasts a baseline day; day 3 removes only unbanked condition content while banked inventory persists
- all required progression remains executable on baseline and bloom days
- output reports day, current/next condition ids, active patrol ids, selected bonus candidate ids, held/banked material, oxygen, and daylight

Run focused checks per owner, then one release-candidate suite after the integrated runtime/smoke set merges.

## Visual And Web Plan

- Capture the night forecast and the active southwest patrol/coil opportunity at 1280x720 and 1920x1080.
- Compare standard baselines and require unrelated terrain, camera, player, boat, route, eel, current, and HUD areas to remain unchanged.
- Do not accept a standard baseline solely because the optional patrol appears in a focused setup.
- Verify exact-SHA Web metadata, initialization, failed requests, desktop/wide/mobile framing, and the condition journey before closeout.

## Deferred Work

- random/procedural geography, arbitrary spawn coordinates, broad weather, global visibility changes, or current-strength variation
- more species, combat roles, patrol types, loot tables, ecology simulation, breeding, farming, or population persistence
- condition-driven mandatory materials, rare progression gates, economy, inventory UI, loadouts, or balance systems
- regional/map-scale growth, which remains Expansion 09 direction
- #52/#53 optional slice-03 presentation polish

## Exit Criteria

Expansion 08 can receive technical GO when source validation, both day states, deterministic smoke, focused visual review, release validation, and exact-SHA Web verification pass; required progression remains seed-independent; and the implementation stays inside the locked southwest opportunity. Technical GO will not claim automation proved player motivation or map learnability to a human.
