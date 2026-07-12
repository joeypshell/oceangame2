# Expansion 06 Combat State Contract

Date: 2026-07-10

Issues: #769-#777

Plan: `docs/current/OCEANGAME_EXPANSION_06_PLAN.md`

## Decision

Combat Foundation adds two focused mutable owners and one durable capability value. It does not move oxygen, cargo, materials, survey findings, daylight, map nodes, or project persistence into a combat system.

## Ownership

| State | Owner | Lifetime |
| --- | --- | --- |
| Maximum/current player health, hit invulnerability, last damage report | focused player-health owner | current sortie/day runtime |
| Hostile phase, position, health, lunge snapshot, cooldowns, current-day defeated ids | focused hostile controller | current expedition day |
| Hostile source records and rendered node handles | world source/renderer coordinator | current loaded map |
| `shock_prod_project` and `shock_prod` capability | `expansion_profile_state.gd` | durable profile |
| Project availability, recipe, exact build transaction, compact debrief text | existing material-project/debrief owners | source plus durable profile |
| Attack input delegation, helper updates, status/result composition | `main.gd` orchestration | scene runtime |
| Oxygen, held salvage, local failure flag | `sortie_state.gd` and existing owners | unchanged |
| Held/banked materials, pending discovery, cargo, score, daylight | existing focused owners | unchanged |

`main.gd` must not become the owner of combat health, hostile phase logic, attack geometry, or day-local defeated ids.

## Player Health

- Maximum health is 3. Current health starts at 3.
- Health and oxygen are separate values, labels, failure reasons, and smoke fields.
- A hostile lunge contact requests 1 health damage through the health owner.
- Accepted damage starts 1.0 second of invulnerability. Contacts during that interval report blocked damage and do not change health.
- Nonlethal damage changes only health, feedback, and invulnerability. It does not drop cargo/materials, cancel a survey, move the diver, spend oxygen, alter daylight, or reset the hostile.
- Health persists through source-authored connector travel.
- Entering the canonical boat/offload context restores health to 3. Open-surface oxygen refill outside that context does not restore health.
- A new day and manual `R` reset restore health to 3.
- Static hazards and `deep_route_jellyfish_patrol` retain their current oxygen/drop/reset semantics and never call combat-health damage.

## Combat Defeat

When accepted damage reaches zero:

1. Mark failure reason `combat_defeat` through the existing local failure/result path.
2. Clear the pending survey finding with the combat-defeat reason.
3. Restore held salvage and held materials to their existing source candidates.
4. Reset timed/pry/cutter progress through their existing reset APIs.
5. Return the player to the source-authored spawn and stop motion.
6. Preserve banked score/cargo, durable profile values, project completion, committed discoveries, elapsed daylight, and current day number.
7. Freeze normal hostile/player interaction until `R`.
8. Show `Injured - surfaced, press R` and expose `combat_defeat` in deterministic reports.

The subsequent `R` uses the existing reset path, restores the hostile and full health, and does not roll back durable profile state. Oxygen failure remains `oxygen_failure`; it must not be relabeled as combat defeat.

## Hostile Day State

The focused hostile controller is created once with the scene and owns a dictionary keyed by source id. Each record may contain only runtime-derived values:

- current phase: `home`, `warning`, `lunge`, `recovery`, `returning`, or `defeated`
- current position and lunge target snapshot
- current health and phase timer
- current-day defeated status

Rules:

- Loading a map creates or refreshes active records from immutable source while preserving the current-day defeated id set.
- Connector travel preserves current health, phase-independent defeated ids, and player health. An active nondefeated encounter restarts at `home` when its map reloads.
- Returning to the boat does not restore a defeated hostile during the same day.
- Starting the next day clears defeated ids and rebuilds the source encounter at full health/home.
- Manual reset and combat-defeat retry restore the encounter immediately.
- Hazard contact and oxygen failure restore the encounter because they already reset the local failed expedition state.
- Hostile defeat grants no cargo, material, score, wallet, discovery, or project change.

## Weapon And Profile State

- Durable ids are `shock_prod_project` and `shock_prod`.
- The project requires `current_stabilizer_project`, `lower_right_anomaly_discovery`, two `titanium_scrap`, and one `conductive_coil`.
- Build phase remains `night_debrief`, exact-once, atomic, and limited by the existing one-project-per-debrief rule.
- Completing the project atomically spends the existing profile material inventory and appends both ids.
- The persisted shape remains schema version 3: only supported values expand, so no migration or version bump is required.
- Invalid partial project/capability pairs remain rejected on load.
- Weapon attack cooldown is transient scene state. It resets on map transition, reset, defeat, and new day; it is never persisted.
- The capability changes only attack availability. It does not change cargo, oxygen, health maximum, movement, light, or existing tool interactions.

## Presentation Priority

The fixed overlay always keeps health visible:

```text
Health 3/3
```

When unlocked, a shock-prod ready/cooldown suffix appears. Before then, weapon guidance is contextual to an unarmed attack or nearby eel and follows the current blueprint/project stage rather than occupying the global health line. Prompt priority is:

1. combat defeat
2. accepted combat damage
3. hostile warning/lunge/retreat
4. weapon blocked/hit/victory
5. existing hazard, oxygen, cargo, survey, route, and collection notes

Existing result presentation may name `Combat defeat`; no combat score or reward line is added.

## Required State Checks

- health damage, invulnerability, full-health boat refill, no open-surface health refill
- connector preservation, new-day reset, manual reset, and profile reload
- nonlethal damage leaves all cargo/research/material state intact
- combat defeat restores all unbanked state and preserves banked/profile/day values
- oxygen and existing hazard failure reasons/behavior remain unchanged
- hostile day defeat persistence and all specified restoration paths
- locked weapon, exact project transaction, duplicate-build rejection, reload, and invalid pair rejection
