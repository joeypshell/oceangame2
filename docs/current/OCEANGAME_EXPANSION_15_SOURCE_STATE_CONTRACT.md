# OceanGame Expansion 15 Source, State, Input, And Presentation Contract

Date: 2026-07-25

Issue: #1095

Plan: `docs/current/OCEANGAME_EXPANSION_15_PLAN.md`

## Decision

Expansion 15 composes two existing world promises into one deliberate night
choice:

1. `upper_left_wreck_relay_route`
2. `southwest_jellyfish_bloom`

The map source describes each lead. Existing profile, project, discovery, day,
and condition owners determine whether it is known, unresolved, scheduled, or
ready. One new session-scoped state owner stores only the selected lead id.

Selecting a lead changes guidance only. It does not grant a reward, complete a
discovery, build a project, change a condition, move the player, reveal an
exact route, or write profile data.

## Source Contract

The established source path remains:

```text
tools/create_production_level_01_map.py
maps/production_level_01.greybox.json
```

An existing `regional_journeys` or `daily_conditions` record may opt into the
planner with one nested `expedition_lead` object. The parent record's `id` is
the lead id; the nested object does not duplicate it.

The relay record uses:

```json
{
  "expedition_lead": {
    "lead_type": "regional_journey",
    "label": "Northwest Wreck Relay",
    "summary": "MAIN PROGRESSION | Stabilizer required | Deeper-wreck lead + valuable core",
    "active_guidance": "Plan: Follow the archive signal northwest",
    "order": 10
  }
}
```

The bloom record uses:

```json
{
  "expedition_lead": {
    "lead_type": "daily_condition",
    "label": "Southwest Jellyfish Bloom",
    "summary": "OPTIONAL RESOURCE | No build | Jellyfish patrol | 1 conductive coil",
    "active_guidance": "Plan: Search the southwest migration lane",
    "order": 20
  }
}
```

The nested object has exactly these fields:

| Field | Rule |
| --- | --- |
| `lead_type` | `regional_journey` or `daily_condition`; must match its parent collection |
| `label` | required single-line display-safe text, at most 48 characters |
| `summary` | required single-line display-safe text, at most 96 characters |
| `active_guidance` | required single-line display-safe text, at most 96 characters |
| `order` | required non-negative integer, unique across opted-in leads |

The source order is `(order, parent id)`. Runtime must not use dictionary
iteration order.

All existing parent relationships remain authoritative:

- The relay journey owns `required_discovery_id`,
  `required_capability_id`, `entry_gate_ids`, `landmark_zone_id`,
  `payoff_target_id`, `survey_target_id`, `commit_entry_id`, and
  `route_context`.
- The relay survey owns its scanner requirement, discovery id, interaction,
  pending result, and canonical-boat commitment.
- The bloom condition owns `schedule`, `forecast_label`, `active_label`, and
  `route_context`.
- Existing material pools and moving hazards link to the bloom through
  `daily_condition_id`.
- Existing material projects own recipes, prerequisites, build phase, and
  granted capabilities.

`expedition_lead` may not contain coordinates, target ids, capability ids,
project ids, condition schedules, rewards, score, material quantities,
completion flags, current day, selected/highlighted state, profile state, UI
visibility, or arbitrary effects. Those facts are referenced through the
parent records and their existing owners.

Other regional journeys and daily conditions remain valid without
`expedition_lead`. The resolver ignores them for Expansion 15 instead of
converting every existing source record into a mission.

## Lead Eligibility

Eligibility means that the player knows about a still-relevant opportunity.
It is separate from readiness.

### Northwest Wreck Relay

The relay lead is eligible when:

- its opted-in journey and all referenced records exist
- the profile has completed the journey's `required_discovery_id`
- the profile has not completed the discovery id owned by the referenced
  survey target

Missing `current_stabilizer` or scanner capability does not hide a known lead.
The resolver reports preparation needed through existing project and
capability facts. This allows the player to pin the relay, build the
stabilizer during the same debrief when ready, or use the selected plan to
guide another preparation day.

The relay becomes invalid immediately after its referenced survey discovery
commits at the canonical boat.

### Southwest Jellyfish Bloom

The bloom lead is eligible in debrief when its id appears in
`DailyConditionState.next_ids()`. It remains valid during the selected active
day while its id appears in `current_ids()`.

At the debrief after that active day, eligibility is evaluated against the
next-day forecast again. If the next day does not schedule the bloom, the old
selection expires whether or not the optional coil was collected. Selecting
the bloom never activates it, changes its schedule, guarantees collection, or
marks it complete.

### Choice Count

The interactive planner appears only when exactly two eligible leads are
available. The focused review fixture must establish the archive discovery,
leave the relay discovery unresolved, and enter the night before an even day,
producing the relay and bloom in source order.

Zero or one eligible lead preserves the current debrief and `N/DAY` behavior.
More than two is a contract violation: runtime must not truncate or silently
choose. It should report the invalid count for smoke/debug evidence and leave
the existing debrief usable.

## Readiness Projection

A stateless resolver produces read-only reports from source plus current
owners. It may query:

- `ExpansionProfileState` for completed discoveries, completed projects,
  capabilities, and banked materials
- `MaterialProjectRuntime.status_for()` for the project that grants a journey's
  required capability
- referenced survey capability requirements
- `ExpeditionDayState` for phase and day number
- `DailyConditionState` for current and next condition ids

It must not duplicate project recipes, condition scheduling, discovery state,
or capability ownership.

Each report contains only:

```text
lead_id
lead_type
label
summary
active_guidance
order
route_context
eligibility_context
readiness_state
readiness_label
```

Supported readiness states are:

- `ready`: required journey and survey capabilities are owned, or the daily
  opportunity needs no capability
- `prepare`: the known regional lead has an incomplete or ready-to-build
  source project/capability requirement
- `invalid`: references or state no longer satisfy the contract; excluded from
  normal choices but exposed to deterministic diagnostics

Readiness text may summarize existing project status and source labels. It
must not promise a reward beyond the authored opportunity or invent a recipe.
Choice summaries must make each lead's role, requirement, risk, and authored
payoff directly comparable without relying on the player to infer them from
destination flavor text.

## Ownership

| Owner | Responsibility |
| --- | --- |
| production-level generator/source | immutable lead metadata and all existing journey/condition relationships |
| map validators/progression audit | field shape, references, legal lead types, source-only data, and dependency integrity |
| `GreyboxWorld` getters | read-only copies of source collections |
| `ExpansionProfileState` | durable discoveries, projects, capabilities, banked materials, and profile persistence |
| `MaterialProjectRuntime` | project selection, readiness, recipe text, and night build transaction |
| `ExpeditionDayState` | day number, phase, daylight, sorties, day results, and current-day material selections |
| `DailyConditionState` | deterministic current/next condition ids and labels |
| `RegionalJourneyPresentation` | existing single broad promise and nearby/pending relay feedback |
| `PrimaryDiveObjective` | opening banked-target completion rule |
| `NextDiveObjectivePrompt` | result-only prompt after primary-objective completion |
| `ProgressionProjectTracker` | active-day banked/held recipe projection |
| `ResultPresentationBuilder` | completed/failed run result ordering |
| new `ExpeditionLeadResolver` | stateless eligibility and readiness projection |
| new `ExpeditionPlanState` | selected lead id only |
| new `ExpeditionPlanPanel` | debrief-only highlight and selected presentation |
| `ExpeditionDayDebrief` | debrief lifecycle, build/day commands, and planner input delegation |
| `ExpeditionDayPresentation` | compact active-day selected-plan line |
| `main.gd` | initialization, delegation, and refresh only |

No planner state belongs in `GreyboxWorld`, source JSON,
`ExpansionProfileState`, `ResultPresentationBuilder`,
`PrimaryDiveObjective`, `ProgressionProjectTracker`, or
`RegionalJourneyPresentation`.

The panel may own a highlighted row index for the current debrief. That is
transient presentation state, not selected-plan state, and resets from the
selected lead or first source-ordered choice when the panel opens.

## Selected-Plan State

`ExpeditionPlanState` stores one string:

```text
selected_lead_id
```

It supports select, replace, clear, and report operations. The coordinator
passes the currently eligible ids; the state owner must reject selection of an
unknown or invalid id.

The selection:

- can be created or changed only during debrief
- survives `begin_next_day()`, multiple sorties, open-surface oxygen refill,
  boat offload, map reload, hazard/oxygen/combat failure, and manual retry
  inside the running session
- is not recreated during `_load_playable_map()`
- clears when the resolver says its source lead is invalid
- never auto-selects a replacement
- starts empty in a new application session or isolated review session
- is absent from the profile payload and does not change profile schema v4

For the relay, canonical-boat discovery commitment makes the selection invalid
and clears it. For the bloom, the debrief after its scheduled day clears it
when that condition is no longer a next-day candidate.

## Input Routing

Existing bindings and mobile commands are reused. Expansion 15 adds no input
action and does not change `project.godot` or the mobile command catalog.

| Input | Active-day owner | Debrief owner |
| --- | --- | --- |
| `Tab/TOOL` | active-tool cycle | move planner highlight |
| `E/ACT` | container/world interaction | pin highlighted lead |
| `P/BUILD` | existing project guidance | existing project build |
| `N/DAY` | existing boat-only end-day request | existing next-day start |
| `Q/USE` | active-tool use/hold | no planner action |
| `R/RESET` | existing retry/reset | no planner action |

Debrief routing takes precedence before active-tool and world-interaction
dispatch. Desktop `Tab` arrives through `active_tool_cycle_next`; mobile
`TOOL` emits the same action. Desktop `E` and mobile `ACT` use the existing key
event. Both paths must produce the same planner command result.

When exactly two choices are available, `N/DAY` returns unchanged with
`reason: plan_required` until one valid lead is pinned. A pinned lead may be
in `ready` or `prepare` state; readiness is information, not a second lock.
When the planner is inactive because fewer than two choices exist, next-day
start remains unchanged.

`P/BUILD` remains authoritative for the project transaction. Building the
Current Stabilizer refreshes relay readiness without changing the pinned id.

## Presentation Boundary

The full two-choice surface appears only during debrief:

- exactly two source-ordered rows
- source label and summary
- resolver-owned readiness line
- distinct highlighted and pinned states
- compact `Tab/TOOL`, `E/ACT`, `P/BUILD`, and `N/DAY` guidance

`ExpeditionDayDebrief` retains the existing night summary, project lines,
condition forecast, and next-day command. The planner panel sits alongside
that content and must not cover it at desktop or iPhone-landscape review
sizes.

During active play, the panel is hidden. `ExpeditionDayPresentation` adds only
the selected source `active_guidance` line near the existing day/condition
header. Critical oxygen, failure, combat, cargo, scanner, interaction, and
project feedback retain their current priority and remain visible.

The selected line does not replace the active condition label, regional
promise, primary objective, project tracker, or result prompt. It states player
intent; those existing surfaces continue to state world facts and immediate
actions.

No selected-plan text is added to `ResultPresentationBuilder`. Selection alone
never creates a completion result.

## Failure, Review, And Determinism

- Failure cleanup must not clear the selected id or mutate either source lead.
- Fresh-profile and isolated-review startup create a fresh empty plan state.
- Smoke/capture fixtures may establish profile/day facts through existing
  test helpers, but may not rewrite map data at runtime.
- Lead order and reports must be deterministic across native and Web builds.
- The unselected lead remains eligible and receives no discovery, reward,
  project, condition, or completion mutation.

## Validation Obligations

#1096 must validate the nested schema, parent type, ordering, compact text,
source-only fields, and existing references. #1097 must author the two blocks
through the generator without topology or relationship drift.

#1098 must prove state and resolver lifecycle independently. #1099 must prove
desktop/mobile routing, debrief gating, project coexistence, and compact active
guidance. #1100 owns the integrated journey and CI regression.

This contract issue changes documentation only.

## Non-Goals

No quest log, mission list, map screen, exact marker, route line, automatic
navigation, reward, currency, new discovery, project, material, capability,
tool, enemy, terrain, collision, topology, profile migration, persistent day
state, inventory UI, HUD replacement, or slice-03 work belongs to this
contract.

#52/#53 remain deferred optional slice-03 presentation polish.
