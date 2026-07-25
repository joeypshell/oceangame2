# OceanGame Expansion 15 Plan

Date: 2026-07-25

Status: Selected by planning gate #1094. The implementation milestone and
issue batch are created only after this plan is committed.

## Decision

OceanGame Expansion 15 is **Expedition Planning And Choice**.

At night, the player will choose one plan for the following day from exactly
two valid source-derived leads in the focused review state:

1. the unresolved Northwest Wreck Relay regional journey
2. the forecasted Southwest jellyfish bloom opportunity

The selected plan changes the compact next-day guidance through every sortie
without revealing an exact route. Pinning a plan grants no item, capability,
currency, completion credit, or world-state change.

## Why This Direction

The current game already has a substantial progression chain, but most
presentation still chooses the next instruction for the player. Another region
or upgrade would lengthen that chain without proving that the player can make a
meaningful expedition decision.

The alternatives remain useful but are not selected:

- A new capability-gated region or exceptional wreck interior is deferred
  until the player can deliberately choose and prepare for known destinations.
- Durable oxygen-capacity progression is deferred because it risks becoming a
  percentage gate unless paired with a specific remembered route and payoff.

Planning and choice best serves route choice, tomorrow anticipation, and player
agency while reusing the existing map and progression evidence.

## Existing Owner Audit

Expansion 15 must extend, not duplicate, these responsibilities:

- `PrimaryDiveObjective` owns the fixed opening banked-target completion rule.
- `NextDiveObjectivePrompt` owns one result-only prompt after that objective.
- `ProgressionProjectTracker` owns visible banked/held recipe counts for the
  current fins, scanner, or cutter project.
- `RegionalJourneyPresentation` derives one unresolved regional promise from
  source and profile discovery state.
- `ResultPresentationBuilder` orders end-of-run evidence; it is not a planner.
- `ExpeditionDayDebrief` owns the night transition, project build input, daily
  summary, forecast, and next-day start.
- Production-level `regional_journeys`, `daily_conditions`, projects, gates,
  landmarks, targets, and route contexts remain source authority.

The new planner may compose those facts. It must not own a second copy of
discovery, project, capability, objective, condition, or map state.

## Target Experience

1. The player ends a day at the canonical boat.
2. The night surface presents two concise available plans with destination,
   opportunity, and readiness language derived from source and current state.
3. `Tab/TOOL` cycles the highlighted plan and `E/ACT` pins it. Existing
   desktop and mobile controls are reused; `P/BUILD` and `N/DAY` keep their
   current meanings.
4. The player may build the Current Stabilizer during the same debrief.
5. Starting the next day retains the pinned plan through open-surface refills,
   boat offloads, failures, resets, and multiple sorties.
6. Active exploration shows only one compact plan line in the existing
   objective/status responsibility. The full planner is hidden.
7. Completing or invalidating the selected lead clears it. The next night asks
   for a new deliberate choice rather than silently selecting another lead.

The opening day keeps its existing primary objective and prompts. Expansion 15
does not force a planner choice before the player has learned multiple leads.

## Meaningful-Change Filter

The milestone fails if it only:

- copies the existing next-dive prompt into another panel
- shows one eligible lead and a decorative selector
- pins an objective without changing next-day guidance
- gives an exact coordinate, path line, map marker, or automatic route
- awards progression merely for selecting a plan

The focused fixture must expose two simultaneously valid choices with different
route intentions. Cycling and pinning either choice must produce distinct,
source-backed next-day guidance while leaving the unselected opportunity valid.

## Source-Of-Truth Boundary

The established generator path remains:

```text
tools/create_production_level_01_map.py
maps/production_level_01.greybox.json
```

The contract issue may add only the minimum display-safe planning metadata to
existing `regional_journeys` and `daily_conditions`. Existing ids,
prerequisites, route contexts, project rules, schedules, landmarks, gates, and
targets remain authoritative.

The generator must author metadata; generated JSON is not hand-edited. The
validator must reject duplicate/dangling lead references, unsupported lead
types, invalid labels, and planning metadata that attempts to author runtime
selection or rewards.

## State Boundary

Selection is **session/day scoped**, not profile-persistent.

A focused `ExpeditionPlanState` owns only the selected lead id. A stateless
resolver derives eligible lead reports from current world source, profile
knowledge/capabilities/projects, and day/condition state.

The selection:

- survives the selected day, multiple sorties, map reloads, failure, and reset
  inside the running session
- may be changed only at the boat/night planning surface
- clears when its source lead resolves or becomes invalid
- does not survive application restart because current day state is also not
  profile-persistent
- does not change the profile schema or Web review isolation behavior

Underlying discoveries, projects, capabilities, materials, and completed
targets keep their existing durable owners.

## Runtime And UI Boundary

Prefer small focused helpers:

- `expedition_plan_state.gd` for selected-id lifecycle
- `expedition_lead_resolver.gd` for deterministic source/state projection
- `expedition_plan_panel.gd` for the night-only two-choice surface
- a compact presentation helper for the selected next-day line

`main.gd` delegates initialization, input, and refresh. Do not add planner rules
to `main.gd`, `greybox_world.gd`, the result builder, or the project tracker.

The planning panel appears only during debrief. It must fit desktop and iPhone
landscape without covering the existing project build and next-day commands.
During active play, no second panel or always-visible quest journal is added.

## Planned Issue Batch

1. Lock the Expedition 15 source, state, input, and presentation contract.
2. Add expedition-lead metadata validation to the map source format.
3. Author the relay-versus-bloom choice through the production-level generator.
4. Implement session-scoped plan state and deterministic lead resolution.
5. Add the night planning surface, shared controls, and compact active guidance.
6. Add deterministic planning-choice journey smoke and CI coverage.
7. Add focused desktop/mobile planning-choice captures.
8. Review and accept only intentional visual differences.
9. Verify the exact public Web candidate and isolated review behavior.
10. Run the owner journey and close with GO, HOLD, or one bounded correction.

Dependency order:

```text
contract -> schema/validation -> source authoring -> state/resolver
-> UI/input -> integrated smoke -> capture -> visual decision
-> exact Web verification -> owner gate
```

## Validation And Smoke Plan

The focused smoke must prove:

- the fixture derives exactly the regional relay and forecast bloom leads
- both ids, labels, route contexts, and eligibility come from source/state
- cycle and pin inputs work only in the allowed boat/debrief context
- either selection produces distinct next-day guidance
- the unselected lead remains available and receives no mutation
- project building, day start, offload, surface oxygen, failure, reset, and
  repeated sorties preserve the selected lead
- completion or invalidation clears selection without auto-pinning another
- existing primary objective, project tracker, result prompt, regional journey,
  profile persistence, and review isolation remain stable

Run targeted map generation/validation/parity, the progression audit, the new
journey smoke, affected day/profile/objective regressions, and the integrated
release suite once at the milestone boundary.

## Visual And Web Plan

Focused captures should show:

- night debrief with two available leads
- the alternate lead highlighted
- one lead pinned with project/readiness context
- next-day active guidance at desktop and iPhone landscape

Compare accepted full-level and slice baselines before accepting anything. The
expected normal-world difference is limited to the selected compact guidance;
terrain, collision, landmarks, player, boat, cargo/equipment strips, active
tool hotbar, scanner readout, and unrelated HUD remain stable.

Exact-SHA Web verification must cover root continuing play, fresh isolated
review, the focused checkpoint, desktop/wide/mobile framing, touch controls,
resources, and browser/Godot errors.

## Non-Goals

Expansion 15 does not add:

- a quest journal, mission list, map screen, exact marker, route line, or
  automatic navigation
- terrain, collision, regional topology, loaded interior, connector, teleport,
  shortcut, or fast travel
- a new discovery, project, material, capability, tool, enemy, or reward
- profile schema changes or persistent day state
- economy expansion, inventory/loadout UI, production HUD replacement, or new
  visual assets
- changes to cargo, oxygen, daylight, health, combat, scanning, project,
  failure, banking, or canonical-boat semantics

#52/#53 remain deferred optional slice-03 presentation polish.

## Exit Criteria

Expansion 15 is complete only when:

1. two source-derived leads are simultaneously valid in the focused fixture
2. the player deliberately pins either one at night using desktop/mobile input
3. the next day communicates only the selected intention without exact routing
4. all existing progression and failure owners remain stable
5. deterministic smoke, focused capture, visual comparison, and exact Web
   verification pass
6. the owner answers GO to:

> Does choosing a concrete expedition lead at the boat make it clear what I am
> preparing for, give me a meaningful choice between destinations, and make me
> want to begin the next day without turning exploration into a checklist?
