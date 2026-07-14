# OceanGame Expansion 11 Source And State Contract

Date: 2026-07-14

Issue: #905

Plan: `docs/current/OCEANGAME_EXPANSION_11_PLAN.md`

## Decision

Expansion 11 replaces the 900-score, session-only light purchase with one
durable material project. `dive_light_1` keeps its stable capability id and
existing readability effect, but `ExpansionProfileState` becomes its only
mutable ownership source.

The committed Signal Reef discovery reveals the project. Building it at night
consumes one titanium scrap, one conductive coil, and one insulating gel. The
player then returns through continuous `production_level_01` geography to one
visible, scoutable dark-water survey. The light enables survey progress; it
does not create collision, a teleport, or an `E` crossing.

## Stable Ids And Labels

| Role | Stable id | Display text |
| --- | --- | --- |
| Knowledge prerequisite | `lower_right_signal_reef_discovery` | Signal Reef chart |
| Material project | `dive_light_1_project` | Dive light project |
| Durable capability | `dive_light_1` | Dive light |
| Dark route marker | `signal_reef_deep_harmonic_dark_zone` | Deep harmonic dark water |
| Survey target | `signal_reef_deep_harmonic_survey` | Survey deep harmonic |
| Committed discovery | `signal_reef_deep_harmonic_discovery` | Deep harmonic chart |
| Commit entry | `surface_boat_entry` | Surface boat |

The finding label is `Discovery logged: Deep harmonic chart`. The next-lead
label is `Next lead: signal descends into deeper water`. These labels promise a
later deep-water problem without implementing pressure, another light tier, or
new geography in this milestone.

## Project Source Record

The full-level source helper must author this project relationship:

```json
{
  "id": "dive_light_1_project",
  "required_discovery_id": "lower_right_signal_reef_discovery",
  "required_materials": {
    "titanium_scrap": 1,
    "conductive_coil": 1,
    "insulating_gel": 1
  },
  "unlocks_capability_id": "dive_light_1",
  "target_id": "signal_reef_deep_harmonic_survey",
  "build_phase": "night_debrief",
  "project_label": "Dive light project",
  "completion_label": "Dive light built"
}
```

The project has no `required_project_id`. Signal Reef knowledge already proves
the scanner-and-fins journey. Source-array order must not invent a dependency
on the cutter, shock prod, capacitor, or stabilizer. Once its knowledge and
materials are present, the light project must be selectable at debrief even if
an unrelated earlier project remains incomplete.

Only banked profile materials satisfy the recipe. Score and the session wallet
cannot substitute for an ingredient. All three sources must remain guaranteed
and reachable under every supported daily selection; insulating gel remains a
replenishable, noncombat glow-anemone material.

## Dark Route And Survey Records

Issue #907 selects an existing open-water rectangle in the lower-right Signal
Reef region after source validation. Coordinates are deliberately not invented
in this contract. The rectangle must require no terrain or collision edit and
must be reachable from Signal Reef and returnable to the boat.

The dark route is a marker-zone readability treatment with:

- `id: signal_reef_deep_harmonic_dark_zone`
- `visibility_zone: true`
- `visibility_level: dark`
- `required_upgrade_id: dive_light_1`
- `visual_only: true`
- `route_context: east_current_signal_reef_route`

`required_upgrade_id` remains the established visibility-zone field name, but
runtime resolves it against durable profile capability ownership. The marker
never owns collision, movement denial, oxygen cost, survey progress, or state.

The survey target reuses the existing regional timed-survey contract:

- `id: signal_reef_deep_harmonic_survey`
- `target_type: regional`
- `required_capability_id: survey_scanner_1`
- `required_light_capability_id: dive_light_1`
- `required_route_id: east_current_signal_reef_route`
- `route_context: east_current_signal_reef_route`
- `interaction: survey`
- `interaction_seconds: 3.0`
- `interaction_label: Survey deep harmonic`
- `clue_label: Deep harmonic | Stronger light required`
- `discovery_id: signal_reef_deep_harmonic_discovery`
- `commit_map_id: production_level_01`
- `commit_map_path: res://maps/production_level_01.greybox.json`
- `commit_entry_id: surface_boat_entry`
- the finding and next-lead labels above

`required_light_capability_id` is a focused second requirement. It does not
replace `required_capability_id`, which continues to name the scanner. It must
not become an arbitrary list of tool, combat, score, or route prerequisites.

Before the light is owned, the target remains rendered and its water remains
swimmable. Entering range reports `Deep harmonic | Stronger light required`,
holds progress at zero, and does not create pending state. There is no invisible
wall and no prompted crossing. With the light, the existing survey timer runs;
leaving range cancels partial progress.

## Mutable State Ownership

| State | Sole owner |
| --- | --- |
| Authored project, zone, survey, labels, and commit relationship | production-level source helper |
| Banked materials, completed project, capability, committed discovery | `ExpansionProfileState` |
| Project eligibility, debrief selection, and compact guidance | `MaterialProjectRuntime` |
| Timed survey progress and target presentation state | `AnomalySurveyRuntime` plus its interaction controller |
| Pending expedition discovery and exact commit location | `ExpeditionDiscoveryState` |
| Oxygen and cargo session purchases | `SessionProgression` |
| Light cone and local visibility rendering | existing player/world light-profile consumers |

`SessionProgression` must remove light cost, purchase, and owned-state mutation.
`config/progression_contract.json` must no longer list `dive_light_1` under
`session_upgrades`. Compatibility getters used by rendering may remain only if
they delegate to `ExpansionProfileState.has_capability("dive_light_1")`; they
must not cache or mutate a second ownership boolean.

## Night Transaction And Persistence

The build command is valid only during the existing `night_debrief` phase. It
uses the current project transaction rules:

1. Reject missing knowledge, missing materials, wrong phase, or inconsistent
   project/capability state without mutation.
2. Snapshot banked materials, completed projects, and capabilities.
3. Consume exactly Ti 1, Coil 1, and Gel 1; record the completed project and
   capability together; then persist once.
4. On storage failure, restore every snapshot and report failure.
5. Repeated build attempts consume nothing and report already completed.

The existing recovery debrief may build from materials banked before recovery;
held or otherwise unbanked materials never count. Starting another day, normal
reset, hazard contact, oxygen failure, combat defeat, or profile reload never
revokes a completed light project.

The current profile schema can add the supported project/capability/discovery
ids without auto-granting them. There is no persisted legacy session-light bit
to migrate. A fresh or existing profile without the completed project starts
without the light and follows the new knowledge-and-recipe chain. A profile
payload containing only one half of the project/capability pair remains invalid
rather than being silently repaired.

## Survey, Failure, And Commit Semantics

- Pre-light attempts create no progress and no pending state.
- With the light, leaving range cancels partial timed progress.
- Completion creates pending expedition state only; it does not persist the
  discovery or show the committed next lead.
- Reset, hazard contact, oxygen failure, combat defeat, and nightfall recovery
  away from the boat clear partial and pending survey state through the existing
  cleanup paths. They do not remove the durable light.
- Map-transition preservation remains only the behavior already owned by
  `ExpeditionDiscoveryState`; Expansion 11 adds no transition or teleport.
- Only `surface_boat_entry` on `production_level_01` commits the pending result.
- Storage failure leaves the result pending so it can be retried safely.
- Repeated survey or boat contact after commit is idempotent and cannot create a
  second discovery, material reward, score reward, or project completion.

## Historical Light Migration

The old Pass 20 names are historical compatibility surfaces, not authority for
the new design:

- `--smoke-pass-20-light-upgrade` may remain as a regression flag, but it must
  stop buying light with score. Its migrated assertions should prove base versus
  durable light-profile values, project/capability persistence, and independence
  from the oxygen/cargo session upgrades.
- `--smoke-darkness-light-gate` remains useful. Its setup must obtain the light
  through profile/project state rather than the wallet.
- `--capture-darkness-light-gate` remains a focused visual regression and must
  use the same durable setup.
- `--capture-pass-20-light-upgrade` and its committed image remain historical
  Pass 20 evidence. They are not regenerated or treated as an Expansion 11
  baseline. Active tooling must not describe the 900-score purchase as current.
- #910's fresh-profile Expansion 11 journey smoke is the canonical end-to-end
  proof; compatibility smokes cannot bypass its knowledge, materials, night,
  return, and commit chain.

## Preserved Surfaces

- `production_level_01` remains one continuous map with unchanged terrain,
  collision, spawn, extraction, and east-current traversal.
- Slices 01-04 remain unchanged regression/provenance fixtures. Their historic
  dark-pocket source and captures may exercise durable light rendering but do
  not gain the new project or survey.
- Oxygen, cargo, offload, daylight, current, combat, hazard, and score ownership
  remain unchanged.
- No pressure mechanic, battery, charge meter, second light tier, inventory,
  broad lighting rewrite, topology expansion, teleport, connector, or `E` gate
  belongs to Expansion 11.

## Verification Contract

Implementation issues must prove:

- one owner for `dive_light_1` and no score purchase path
- exact recipe, knowledge, source references, and guaranteed material supply
- open-water pre-light access with zero survey progress
- atomic night build, storage rollback, reload persistence, and idempotency
- improved existing light/zone rendering from durable capability state
- cancel, failure cleanup, pending state, canonical-boat commit, and exact-once
  discovery behavior
- unchanged topology, continuous return, slices, oxygen/cargo, currents, combat,
  and unrelated visual baselines
