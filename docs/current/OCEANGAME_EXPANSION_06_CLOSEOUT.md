# OceanGame Expansion 06 Closeout

Date: 2026-07-10

Issues: #768-#777

Milestone: OceanGame Expansion 06 `Combat Foundation`

## Decision

**GO** to planning OceanGame Expansion 07: Biological Resources And Weapon Progression in the next drift cycle.

Yes, one fight-or-evade encounter adds preparation and route pressure without taking over salvage and exploration. The player first meets a readable territorial eel on the existing lower-loop-to-deep-cache journey, can use the preserved lower-edge lane without a weapon, gathers the shock prod's non-enemy prerequisites through established material routes, builds it during the night debrief, and may return to clear the territory for that day.

Combat remains a cost and choice. Oxygen and daylight continue during the encounter, health is separate from oxygen, combat defeat restores unbanked state, and killing the eel grants no score, cargo, material, discovery, or required progression. Existing deep-cache salvage and research remain the payoff.

## Delivered Experience

- `deep_cache_hostile_territory` and `deep_cache_territorial_eel` are immutable source-authored records in unchanged slice-01 geography.
- The 0.75-second warning, bounded lunge, 1.25-second recovery, and lower-edge route support a patient unarmed evade.
- Player health is a focused 3-point owner with hit invulnerability, connector preservation, boat refill, and deterministic combat-defeat cleanup.
- `shock_prod_project` requires the completed stabilizer project, the existing discovery, two titanium, and one conductive coil; it does not require an enemy drop.
- The short-range shock prod uses one attack input, one cooldown, and three hits to defeat the eel.
- Eel defeat persists for the current day, resets on a new day, and grants no reward.
- Existing cargo, banking, salvage, materials, research, hazards, oxygen, daylight, connectors, and profile semantics remain intact.

## Ownership And Source Boundaries

- The production-slice expansion source owns the territory, hostile timings/geometry, labels, project recipe, capability links, and review intent.
- Focused validators reject illegal placement, unreachable payoffs, blocked evade paths, circular prerequisites, runtime-owned fields, and reward/drop fields.
- `player_health_state.gd` owns combat health and invulnerability; `territorial_hostile_controller.gd` owns day-local encounter state; `shock_prod_controller.gd` owns attack range/cooldown.
- `greybox_hostile_renderer.gd` renders only source-derived territory/hostile presentation.
- Existing profile and project owners keep durable capability and atomic night-build semantics.
- `main.gd` delegates orchestration and remains temporary file-length debt rather than becoming the combat owner.

## Deterministic Evidence

- All implementation and review issues #768-#776 were merged before this closeout.
- Generator repeatability, SVG render, source validation, hostile fixtures, reachability, viable evade-route checks, and Godot terrain/collision parity pass.
- Focused player-health and combat-state smokes pass.
- `--smoke-expansion-06-combat-foundation` covers unarmed retreat, contact damage/invulnerability, oxygen/daylight pressure, exact project build/reload, three-hit no-reward victory, cargo/banking compatibility, connector/day behavior, combat cleanup, and failure resets.
- The full release-candidate validation suite passed locally with Godot 4.7 after the final capture implementation.
- GitHub `Godot Smoke` run `29093205027` passed merged runtime commit `90dfd01`.
- Warning, lunge/evade, and armed-damage states were inspected at 1280x720 and 1920x1080. The visual decision is GO; accepted baselines remain unchanged and clean.
- Public build `90dfd01c4437df3687067f1256d885cac80f8892` passed exact metadata, initialization, request, error, and dual-viewport framing checks.

Visual decision: `docs/current/OCEANGAME_EXPANSION_06_VISUAL_BASELINE_DECISION.md`.

Web evidence: `docs/current/OCEANGAME_EXPANSION_06_WEB_PREVIEW_VERIFICATION.md`.

## Known Risks

- One territorial enemy does not establish a roster, pursuit AI, broad encounter pacing, or an ecology.
- The eel uses functional prototype presentation; final animation, audio, impact effects, and accessibility feedback remain production work.
- The compact HUD fits the reviewed states but will need hierarchy work before more weapons, conditions, or creature knowledge are displayed simultaneously.
- Health currently has only boat/reset recovery and no broader recovery items, armor, or status effects.
- The standard slice-01 accepted baseline predates several intentional HUD/material/visibility changes; any consolidation needs its own scoped review.
- `main.gd` remains temporary file-length debt. Split only at cohesive ownership boundaries when selected work needs one.

## Deferred Work

- #52/#53 remain deferred optional slice-03 presentation polish.
- Biological samples, hostile materials, harvesting rules, and equipment progression remain directional Expansion 07 work.
- Daily conditions and broader enemy ecology remain Expansion 08; regional map growth remains Expansion 09.
- Additional weapons/enemies, ammo, durability, armor, health pickups, bosses, procedural encounters, combat economy, broad art replacement, and map-scale expansion remain deferred.
- Emergency Week, overnight survival taxes, arbitrary procedural geography, and shortcut/fast-travel networks remain rejected.

## Expansion 07 Entry Conditions

The next drift cycle may plan and create one scoped Biological Resources And Weapon Progression batch. Before implementation, it must lock:

1. Guaranteed source-authored habitat candidates and replenishment for any mandatory biological material.
2. Explicit sample, harvest, and defeat semantics that distinguish passive wildlife from hostile creatures.
3. One useful weapon or suit project with low counts and no circular enemy-versus-required-weapon dependency.
4. A payoff that changes a route, threat response, or interaction rather than adding generic currency.
5. Validation, runtime ownership, failure/reset rules, smoke, capture, visual, and Web boundaries.
6. No broad ecosystem simulation, creature catalog, arsenal, grind, or map-scale expansion.

No Expansion 07 implementation issue is created by this closeout. The next drift cycle owns that plan and issue-level batch.
