# Simple Diver Game 09 Persistence And Expedition State Contract

Date: 2026-07-09

Issue: #648
Milestone: Simple Diver Game 09 `2D Subnautica Expansion Planning`

## Decision

Keep the release candidate's map-leg and session behavior intact, and add only one profile-persistent concept for the first expansion: a successfully returned anomaly discovery.

The anomaly survey may create a pending discovery that survives source-authored map transitions during the return journey. It becomes profile state only after the player reaches the canonical boat/extraction completion point. Reset, oxygen failure, or an unbanked hazard reset clears the pending discovery; previously committed discoveries remain safe.

Do not persist wallet, purchased upgrades, salvage depletion, hazard positions, cargo, oxygen, or best scores in the first expansion slice.

## State Lifetimes

### Map-Leg State

State owned by the currently loaded slice:

- current oxygen and warning thresholds
- held/banked cargo and score for that map leg
- salvage collected/restored state
- timed/pry interaction progress
- current hazard warning/contact/cooldown and moving-hazard positions
- map-local objective progress and result panel
- connector overlap/prompt and current-gate pushback
- map-local status/feedback text

Current behavior is the contract: loading a destination map creates a fresh map leg, clears cargo and run bookkeeping, resets interactions/hazards/objectives, and refills oxygen to the current session capacity.

### Expedition State

State that may cross connectors during one anomaly attempt but is not yet durable:

- active anomaly objective ID
- pending discovery ID and source map/target IDs
- whether the pending discovery has been investigated but not returned
- the canonical return destination required to commit it

The first implementation should keep this state in one focused expansion-state owner. It must not be duplicated in connector metadata, `main.gd`, result text, or map entity dictionaries.

### Session State

State that lasts until the running game process ends:

- wallet and total payout
- purchased oxygen, cargo, light, and propulsion upgrades
- opened progression containers
- current map-keyed best scores
- any existing audio dedupe/cooldown state whose owner already treats it as session state

These remain session-only for the first expansion. Existing purchases continue to survive `R` reset and world connectors but do not become profile upgrades yet.

### Profile State

The minimal future profile contains only stable discovery facts needed to make the expansion meaningful across launches:

- schema version
- completed discovery IDs
- optional capability IDs only after #649 selects and implements one profile-level capability

The first required discovery is the completed anomaly survey chosen by the implementation batch. Existing release-candidate wallet/upgrades and final-dive result bookkeeping do not need retroactive profile migration.

### World-Persistent State

None in the first expansion slice.

Salvage, hazards, moving-hazard positions, opened map entities, terrain, doors, currents, and destination population reset from source/runtime rules. A completed profile discovery may change objective/connector availability through a focused runtime owner, but it does not mutate map JSON or save arbitrary world-node state.

## State Classification

| State | Lifetime | Commit point | Reset/failure behavior |
| --- | --- | --- | --- |
| Oxygen | Map leg | None | Refill/reset under current rules. |
| Held cargo/score | Map leg | Existing extraction banking | Restore source salvage on failure/reset. |
| Banked map-leg score | Map leg/result | Existing run result | Cleared when another map is loaded; wallet payout remains session state. |
| Salvage availability | Map leg | None | Rebuilt from source on load/reset. |
| Timed/pry progress | Map leg | Collection completion | Clear partial state on leave/reset/failure as currently defined. |
| Static/moving hazards | Map leg | None | Reset to source/runtime initial state. |
| Route/primary objectives | Map leg | Existing extraction completion | Reset when the map leg resets/loads. |
| Connector definitions | Source data | Never runtime-saved | Reload from generated map JSON. |
| Connector eligibility | Session/expedition query | Current progression/discovery owner | Recomputed; never written into map source. |
| Wallet/upgrades | Session | Existing bank/purchase events | Preserve through reset/connectors/failure; clear on process restart. |
| Opened progression containers | Session | Existing interaction | Preserve through reset/connectors; clear on process restart. |
| Best scores | Session, map-keyed | Successful result | Preserve through reset; clear on process restart. |
| Pending anomaly discovery | Expedition | Canonical boat return | Preserve through connectors; clear on reset, hazard restoration, or oxygen failure before commit. |
| Completed anomaly discovery | Profile | Successful canonical return | Never clear on normal reset/failure. |

## Existing Transition Contract

### `R` Reset

- Restore current-map salvage and clear held/banked map-leg bookkeeping.
- Clear timed/pry progress, hazards, objective/result state, oxygen warnings, and pending anomaly discovery.
- Refill oxygen and place the player at the current map's authored spawn.
- Preserve session wallet, upgrades, opened progression containers, and best scores.
- Preserve completed profile discoveries.

### Hazard Contact

- Keep the existing oxygen penalty, spawn bump, held-salvage restoration, and failure escalation.
- If an anomaly discovery is pending and unbanked, clear it and make the source-authored survey available on a later attempt.
- Do not remove completed profile discoveries or session purchases.

### Oxygen Failure

- Restore held salvage, clear interactions and the pending anomaly discovery, surface/reset under existing result semantics, and wait for retry.
- Do not award or commit discovery progress.
- Preserve completed profile discoveries and existing session progression.

### World Connector Transition

- Keep current destination loading: authored destination map/path/entry, fresh oxygen, empty cargo, reset map-local objectives/interactions/hazards.
- Preserve session wallet/upgrades and opened progression-container state.
- Preserve only the focused pending anomaly discovery from expedition state.
- Do not carry arbitrary node state, salvage dictionaries, result panels, or source entity instances between maps.

### Successful Anomaly Return

- Investigating the source-authored anomaly creates a pending discovery, not profile state.
- Returning through slice 02 -> slice 04 -> slice 01 preserves that pending discovery.
- Entering the canonical slice-01 boat/extraction completion path commits the discovery ID once, clears pending state, and presents compact result/next-lead feedback.
- Repeating an already completed survey must not duplicate payout, unlock, or discovery records.

## Minimal Profile Boundary

Future storage may serialize one structured record such as:

```json
{
  "schema_version": 1,
  "completed_discoveries": ["lower_right_anomaly_survey"],
  "unlocked_capabilities": []
}
```

Storage is not implemented in Milestone 09 planning. When selected later:

- use a focused profile-state owner, not `main.gd`
- write under Godot `user://`, never the repository
- validate types, IDs, duplicates, and supported schema versions before applying state
- treat missing or invalid files as a recoverable fresh profile with a visible diagnostic, not a crash
- write atomically through a temporary file and replacement
- migrate explicitly one schema version at a time; do not silently reinterpret unknown versions
- never persist node paths, scene instances, absolute OS paths, generated map contents, or transient UI state

## First Expansion Compatibility

Keep unchanged:

- release-candidate map-leg reset and connector behavior
- session wallet and four current upgrades
- current cargo/oxygen/hazard/salvage failure semantics
- map-keyed session best scores
- source-authored connector definitions and map IDs
- release-journey smoke behavior when no expansion state is active

The first implementation should add the pending/committed discovery path beside those rules, not convert all existing state to persistence.

## Deterministic Verification Expectations

A future focused state smoke should prove:

- pending discovery is absent before investigation
- investigation creates one pending ID
- connectors preserve that ID while map-leg state resets normally
- `R`, hazard restoration, and oxygen failure clear pending state
- canonical boat return commits exactly once
- retry and already-completed survey paths do not duplicate state
- session wallet/upgrades retain current behavior
- maps without expansion metadata retain the release-candidate path

## Non-Goals

- multiple profiles, cloud saves, autosave slots, or save UI
- persistent wallet/economy/upgrade migration
- world depletion, placed items, base state, fauna populations, or hazard positions
- arbitrary dictionary serialization or generic component persistence
- save-heavy sandbox progression

## Planning Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
