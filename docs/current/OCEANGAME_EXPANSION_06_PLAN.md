# OceanGame Expansion 06 Plan

Date: 2026-07-10

Issues: #768-#777

Milestone: OceanGame Expansion 06 `Combat Foundation`

Contracts: `docs/current/OCEANGAME_EXPANSION_06_STATE_CONTRACT.md`, `docs/current/OCEANGAME_EXPANSION_06_SOURCE_CONTRACT.md`

## Decision

Expansion 06 will prove one bounded fight-or-evade encounter inside existing `production_slice_01` geography:

```text
remember the lower-loop-to-deep-cache route
-> recognize a territorial eel warning before entering the deep-cache room
-> evade along the room edge or retreat without needing a weapon
-> gather existing titanium and conductive coil outside combat
-> build one shock prod during the night debrief
-> return through remembered geography
-> fight at close range or continue to evade
-> reach the existing deep-cache payoffs under health, oxygen, and daylight pressure
```

Combat is an expedition cost and route choice, not a replacement for salvage, research, or exploration. Defeating the eel makes the territory safer for the rest of the current day but grants no score, cargo, materials, wallet value, discovery, or required progression.

## Target Experience

Before entering, the player should understand: "Something territorial controls this lane. I can read its warning and slip around it."

After building the weapon, the player should understand: "I can spend time and health to clear this territory for today, but fighting is optional."

The encounter reuses the existing deep-cache room because it already has valuable timed salvage, a researched conductive-coil habitat, and approach pressure. The existing jellyfish remains a separate dodge hazard before the room. Terrain, collision, hazard placement, salvage/material placement, and the lower-edge evade corridor remain unchanged.

## Locked Roles

| Role | Id | Rule |
| --- | --- | --- |
| Existing approach pressure | `deep_route_jellyfish_patrol` | Remains a noncombat moving hazard before the selected room. |
| New territory | `deep_cache_hostile_territory` | Source-authored rectangle around the deep-right room; leaves a legal lower-edge evade lane. |
| New hostile | `deep_cache_territorial_eel` | One `territorial_lunge` actor with a source-authored home point inside the territory. |
| New weapon capability | `shock_prod` | Durable profile capability; short-range attack only, with no ammo or durability. |
| New project | `shock_prod_project` | Night-debrief project requiring `current_stabilizer_project`, two titanium scrap, and one conductive coil. |
| Existing payoffs | `salvage_deep_right_cache`, `material_coil_deep_cache` | Remain salvage/material rewards; enemy defeat does not replace them. |

Compact source/presentation labels:

- territory warning: `Territorial eel - watch the lunge`
- unarmed input note: `Shock prod required to fight`
- weapon ready: `Shock prod ready`
- damage: `Eel hit - health -1`
- retreat: `Eel territory - retreat or evade`
- victory: `Territory clear for today`
- defeat: `Injured - surfaced, press R`

## Combat Rules

- Player maximum health is 3 and is always displayed separately from oxygen.
- The eel has 3 health. One valid shock-prod strike deals 1 damage.
- Entering the warning radius starts a 0.75-second telegraph. The eel then lunges toward a snapshot of the player position, constrained to its authored territory, and enters a 1.25-second recovery before returning home.
- A lunge contact deals 1 health damage. The player receives 1.0 second of combat invulnerability after a hit.
- The shock prod uses the `combat_attack` action, with Space as the keyboard default. It reaches 72 pixels in the diver's facing direction and has a 0.65-second cooldown.
- Attacks outside range, during cooldown, or without the capability do not damage the eel.
- The lower edge of the room remains outside the direct home-to-cache line, so a patient unarmed player can read the cycle and cross without taking damage.
- Oxygen and daylight continue normally during warnings, attacks, recovery, retreat, and combat.
- No health pickups, armor, status effects, ammo, durability, targeting reticle, damage numbers, or broad combat HUD are added.

Exact timing may change only if deterministic smoke or dual-viewport review shows the locked encounter is unreadable or the evade route is not viable. Any change must remain in this one-enemy contract.

## State And Failure Rules

- Health is sortie-local mutable state. It starts full, persists through connectors, and refills only at the canonical boat/offload context or on reset/new day.
- Open-surface oxygen refill away from the boat does not restore health.
- The eel controller owns mutable home/warning/lunge/recovery/health/defeated state. Map data never stores runtime state.
- Eel defeat persists across boat returns and connector travel for the current day. A new day restores the eel.
- Manual reset restores the eel and full health while preserving the existing durable profile.
- Static hazards and the existing moving jellyfish retain oxygen/drop/reset behavior and do not deal health damage.
- Oxygen failure remains an oxygen failure. It restores unbanked state and uses the existing failed/retry path without changing health semantics.
- Combat defeat restores unbanked salvage, materials, and pending survey state, returns the diver to the source-authored spawn, records `combat_defeat`, and uses the existing `R` retry path. Banked/profile state and elapsed daylight remain stable.
- Retreating to the canonical boat preserves banked/profile state, refills health, and does not restore a defeated eel until the next day.

## Source Boundaries

- Hostile source owns id, supported behavior, home point, territory rectangle, warning radius/timing, lunge speed/duration, recovery time, contact radius, health, damage, labels, capability reference, and review intent.
- Project source owns id, capability id, existing project prerequisite, non-enemy material recipe, night build phase, and compact labels.
- Validators prove unique ids, legal open-water placement, reachable territory/payoffs, a viable evade path, positive bounded values, supported links, and non-circular pre-combat prerequisites.
- Source must reject mutable state, loot/drop tables, score, cargo, current health, current position, runtime phase, procedural spawn weights, and broad enemy/weapon definitions.
- New records live in a focused slice-01 expansion module because the primary generator is already at the 500-line guard.
- Terrain rectangles, collision, spawn, extraction, connectors, current gates, salvage, materials, surveys, camera tests, and route objectives remain unchanged.

## Runtime And UI Boundaries

- `expansion_profile_state.gd` owns durable `shock_prod` capability and `shock_prod_project` completion in the existing profile shape; no schema-version bump is expected.
- Existing material/project owners consume the approved recipe and keep one-project-per-debrief, exact-once, and atomic persistence semantics.
- A focused player-health owner keeps health, invulnerability, refill, damage, and combat-defeat reporting separate from oxygen.
- A focused hostile controller owns the one deterministic encounter and day-local defeated set.
- A focused world renderer owns the source-derived eel/territory visuals and exposes narrow position/state APIs through `greybox_world.gd`.
- `main.gd` remains orchestration only: delegate update/input/result/reset calls and compose compact helper text without absorbing combat logic.
- The existing status overlay adds one fixed-width health/weapon line and prioritizes warning, damage, defeat, retreat, and victory notes without an inventory/loadout screen.

## Meaningful-Change Filter

This pass is valid because it adds:

- curiosity: a readable living threat controls a known valuable deep-cache room
- pressure: lunge timing competes with oxygen, daylight, health, and cargo risk
- payoff: a night project changes a future response to that place
- remembered-place progress: the player returns to the existing deep-cache route highlighted by practical research
- route choice: evade remains viable while fighting can clear the day-local territory
- another-day motivation: the project and return happen across the debrief boundary

A generic damage zone, mandatory kill, enemy drop, second enemy, broad weapon system, or topology expansion fails this filter.

## Planned Issue Order

1. #768 lock this experience and issue contract.
2. #769 define source, profile, health, hostile, failure, and UI ownership.
3. #770 extend hostile/project schema and focused validator coverage.
4. #771 author the territory, eel, and non-enemy weapon project through the generator path.
5. #772 implement separate health, damage, defeat, and recovery.
6. #773 implement the shock prod and one territorial hostile encounter.
7. #774 add integrated deterministic journey smoke and CI/release coverage.
8. #775 add focused dual-viewport captures.
9. #776 review visual impact and record the baseline decision.
10. #777 verify the public Web build and record GO or HOLD.

## Validation And Review

Validation must cover:

- positive/negative source fixtures, forbidden runtime/drop fields, project prerequisites, and generator repeatability
- unchanged terrain/collision parity, reachable encounter/payoffs, and viable source-derived evade route
- health/oxygen separation, invulnerability, boat-only health refill, connector/day/reset behavior, and combat-defeat cleanup
- locked weapon use, exact project completion/reload, range/cooldown, three-hit victory, no rewards, and day-local restoration
- unarmed warning/retreat/evade, armed fight, existing hazard/oxygen/cargo/material/day regressions, and one integrated smoke in CI/release validation
- deterministic warning/evade and armed damage/victory frames at 1280x720 and 1920x1080
- rejection of unrelated terrain, collision, diver, boat, camera, existing prop, route-cue, cargo, research, or HUD drift
- exact merged Web metadata, browser initialization, requests, errors, and dual-viewport framing

Treat `SCRIPT ERROR` and `ERROR:` output as failures even when Godot exits zero.

## Deferred Work

- #52/#53 optional slice-03 presentation polish
- enemy materials, biological harvesting, weapon/suit upgrades, and creature research in Expansion 07
- additional enemies, weapons, project recipes, ammo, durability, armor, health pickups, bosses, pursuit/pathfinding, procedural spawning, or combat economy
- daily encounter ecology and seeded conditions in Expansion 08
- new regions or map-scale expansion in Expansion 09
- broad art replacement, final creature animation/audio, inventory/loadout UI, or save-slot UI

## Exit Criteria

Expansion 06 may close with **GO** only when:

1. The source-authored territory and eel are readable, reachable, and preserve an unarmed evade route in unchanged geography.
2. Health remains distinct from oxygen and damage, retreat, defeat, boat recovery, connector travel, and new-day reset are understandable.
3. The shock prod is built from existing non-enemy materials through the exact night project and persists durably.
4. A three-hit armed fight and a patient unarmed evade both work under continuing oxygen/daylight pressure.
5. Combat defeat restores all unbanked state without corrupting banked/profile/day state.
6. Enemy defeat grants no Expansion 06 loot and clears only the current day's territory.
7. Existing salvage, research, material, project, gate, hazard, cargo, oxygen, daylight, map, and profile behavior remains deterministic.
8. Source validation/parity, integrated smoke, captures, visual review, release validation, and public Web verification pass.
9. Review answers yes to: "Does combat add route pressure and preparation without taking over salvage and exploration?"

A **HOLD** must name the smallest corrective issue and must not broaden into Expansion 07.
