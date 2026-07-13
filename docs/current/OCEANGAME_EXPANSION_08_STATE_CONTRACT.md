# Expansion 08 Daily Condition State Contract

Date: 2026-07-13

Issue: #838

Plan: `OCEANGAME_EXPANSION_08_PLAN.md`

## Ownership

| State | Owner | Lifetime |
| --- | --- | --- |
| Immutable condition, bonus-pool, candidate, and patrol records | JSON/world source helpers | loaded map |
| Current and next condition ids | focused daily-condition owner | expedition day/session |
| Day number and transition phase | existing expedition-day state | session |
| Selected/depleted bonus candidate | existing day/material owners | current day |
| Held/banked bonus coil | existing material cargo/profile owners | sortie/durable profile |
| Active patrol motion/warning | existing moving-hazard owner | current map/day |
| Forecast and active-condition text | focused condition presentation plus debrief | current/next day |
| Delegation only | `main.gd` | scene runtime |

## Lifecycle

- Day 1 derives baseline current state and the day-2 bloom forecast before material/hazard initialization.
- Starting a day derives current and next condition ids from that day number and immutable definitions.
- Odd days have no active condition id. Even days use `southwest_jellyfish_bloom`.
- Connector travel preserves day number, current/next ids, selected bonus candidate, depletion, and patrol phase under existing day/connector semantics.
- Starting another day clears unbanked condition content through existing lifecycle owners, then rotates the condition before loading slice 01.
- Restarting the application follows existing session-day behavior and starts at day 1; no profile schema or migration is added.

## Material And Hazard Boundaries

- Material selection filters out condition-bound pools unless their condition is current, then delegates to the unchanged stable selector.
- Normal pools are never filtered and keep existing order, counts, researched subsets, and guarantees.
- The bonus candidate uses unchanged cargo-full, collection, held, connector, failure restoration, boat banking, typed inventory, and project-spend paths.
- A banked bonus coil remains durable after the condition rotates away.
- The moving-hazard owner filters condition-linked patrols before update/warning/contact checks and asks the world to show only active patrol nodes.
- `deep_route_jellyfish_patrol` remains active on every day. Condition activation does not reset or retune unrelated hazards.

## Presentation

- The debrief appends the exact next-day forecast before `N: Start day`.
- A bloom day adds one compact active-condition line; baseline days add no persistent condition line.
- Condition text never displaces failure, combat, oxygen, cargo-full, or interaction feedback.
- No calendar, weather panel, map marker, inventory screen, ecology catalog, or loadout UI is added.

## Failure And Determinism

- Oxygen, daylight, hazard, combat, reset, cargo, and banking rules remain unchanged.
- Condition selection uses integer day parity only, with no engine RNG, wall clock, platform hash, or arbitrary coordinate selection.
- Required progression remains executable with the condition active or inactive.
- Deterministic reports expose day, current/next condition ids, active patrol ids, selected/depleted bonus ids, held/banked material, oxygen, and daylight.
