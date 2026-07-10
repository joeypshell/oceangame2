# OceanGame Expansion 07 Plan

Date: 2026-07-10

Issues: #790-#799

Milestone: OceanGame Expansion 07 `Biological Resources And Weapon Progression`

Contracts: `OCEANGAME_EXPANSION_07_SOURCE_CONTRACT.md` and `OCEANGAME_EXPANSION_07_STATE_CONTRACT.md`

## Decision

Expansion 07 proves one bounded ecology-to-equipment journey in unchanged `production_slice_01` geography:

```text
return through the stabilizer-gated upper-right pocket
-> use the existing scanner to sample one glow anemone without harming it
-> bank one insulating gel at the boat
-> use the base shock prod to defeat the existing territorial eel
-> explicitly harvest one electrocyte from the defeated remains
-> bank the electrocyte and one conductive coil
-> build one shock-prod capacitor during night debrief
-> return and interrupt a warned eel lunge into recovery
```

Eel defeat still grants nothing automatically. The player chooses whether to spend cargo space and interaction time harvesting the remains. Both biological sources replenish on a fresh day, while banked materials and the completed project remain durable.

## Target Experience

The passive source should read as a living part of a remembered habitat: "I can sample this organism without killing it, and its insulating gel has a practical use."

The hostile source should read as a distinct prepared harvest: "Defeating the eel made a component available, but I still have to collect and return it safely."

After the project, the player should understand: "The capacitor did not make every hit stronger; it gave me a new answer to the lunge I already learned."

## Locked Roles

| Role | Id | Rule |
| --- | --- | --- |
| Passive organism | `upper_right_glow_anemone_sample` | Scanner-assisted, 1.5-second, cancel-on-leave nonlethal sample in the current pocket. |
| Passive material | `insulating_gel` | Quantity 1 per fresh day; enters shared cargo and boat banking. |
| Existing hostile | `deep_cache_territorial_eel` | Base shock prod remains sufficient; defeat grants no automatic reward. |
| Hostile harvest | `deep_cache_eel_electrocyte_harvest` | Available only after linked eel defeat; 1.5-second cancel-on-leave harvest. |
| Hostile material | `eel_electrocyte` | Quantity 1 per fresh day; enters shared cargo and boat banking. |
| Existing base input | `conductive_coil` | Quantity 1 in the capacitor recipe. |
| Project | `shock_prod_capacitor_project` | Requires `shock_prod_project`, existing anomaly knowledge, and the three locked inputs. |
| Capability | `shock_prod_capacitor` | A valid hit during warning or lunge moves a surviving eel into recovery; damage stays 1. |

The passive source target is the open-water area immediately east of `upper_right_current_pocket_gate`. Source authoring may move its exact point within that existing pocket only when validation proves the selected point solid or unreadable. Terrain and the gate do not move.

## Interaction And Cargo Rules

- Both interactions use the existing collection radius and require continuous proximity for 1.5 seconds.
- Leaving range cancels current progress. A completed collection remains depleted for the current day.
- The glow anemone requires `survey_scanner_1`; sampling never changes health, hostile state, or organism availability beyond the daily material collection.
- The electrocyte interaction is hidden until `deep_cache_territorial_eel` is defeated for the current day.
- Eel defeat, damage, and the final weapon hit never add material, score, wallet value, cargo, or discovery state.
- Each quantity occupies one slot in the existing shared salvage/material cargo capacity.
- Cargo-full completion is blocked before depletion, so the source remains available.
- Boat commitment uses the existing typed material inventory transaction. No inventory screen or separate biological wallet is added.

## Project And Tactical Payoff

The exact recipe is:

```json
{
  "conductive_coil": 1,
  "insulating_gel": 1,
  "eel_electrocyte": 1
}
```

The project requires `shock_prod_project` and `lower_right_anomaly_discovery`, is built only during `night_debrief`, and unlocks `shock_prod_capacitor` exactly once.

Without the capability, all Expansion 06 shock-prod range, cooldown, damage, defeat, and feedback behavior remains unchanged. With it, a valid hit while the eel is in `warning` or `lunge` deals the same 1 damage and, if the eel survives, changes its phase to normal source-timed recovery. Hits at home, returning, recovery, out of range, or during cooldown do not interrupt.

## Meaningful-Change Filter

- Curiosity: a passive organism in a previously unlocked pocket has a practical use.
- Pressure: both samples consume time and cargo under oxygen/daylight risk.
- Payoff: the project adds a learned counter to a familiar attack, not a percentage stat.
- Remembered-place progress: the player revisits both the current pocket and deep-cache territory.
- Route choice: the eel may still be evaded; fighting and harvesting remain optional until the player pursues the project.
- Another-day motivation: banked inputs become one night project and a reason to return.

## Source And Runtime Boundaries

- The generator owns immutable biological source records and the capacitor project record.
- Focused validators own legal shape, placement, links, guarantees, and non-circular dependency checks.
- A focused biological interaction owner owns progress and current-day source availability.
- Existing material cargo/profile owners retain held quantities, boat commitment, durable inventory, and atomic project spending.
- Existing hostile and shock-prod owners retain combat phases, health, targeting, cooldown, and damage.
- `main.gd` delegates updates, reset calls, and compact presentation only.
- World helpers render/query source records without creating collision or changing topology.

## Planned Issue Order

1. #790 lock this plan and both contracts.
2. #791 add schema, validation, profile, and project support.
3. #792 author both sources and the project through the generator.
4. #793 implement biological sampling, harvest, cargo, failure, and replenishment.
5. #794 implement the capacitor project and lunge interruption.
6. #795 add integrated deterministic journey smoke and CI/release coverage.
7. #796 add focused dual-viewport captures.
8. #797 review visual impact and record GO or HOLD.
9. #798 verify the exact merged Web build.
10. #799 gather player GO/HOLD and close the milestone.

## Validation And Review

Validation must cover source shape, forbidden drop/runtime fields, unique links, open/reachable placement, guaranteed one-per-day inputs, project ordering, and generator repeatability. Runtime coverage must prove cancel, cargo-full, boat bank, unbanked restoration, connector preservation, fresh-day replenishment, base-weapon non-circularity, exact project spend/reload, unchanged damage, and the upgraded interrupt window.

Focused captures show passive sampling, defeated-eel harvest, and upgraded recovery at 1280x720 and 1920x1080. Standard baselines are unchanged unless #797 explicitly accepts an intentional difference. #798 verifies exact-SHA deployment before #799 asks for player review.

## Deferred Work

- #52/#53 optional slice-03 presentation polish
- more passive species, enemy materials, weapons, suit upgrades, creature research, harvest tools, recipes, or status effects
- ammo, durability, armor, health pickups, pursuit AI, bosses, procedural encounters, ecology simulation, farming, breeding, or combat economy
- daily conditions/enemy ecology in Expansion 08 and regional map growth in Expansion 09
- terrain changes, map-scale expansion, broad art replacement, inventory/loadout UI, and final creature animation/audio

## Exit Criteria

Expansion 07 may close with GO only when:

1. The passive sample is readable, nonlethal, guaranteed, reachable, and replenishes without grind.
2. The eel material requires defeat plus explicit harvest; defeat alone grants nothing.
3. Both materials obey shared cargo, banking, failure, connector, and new-day rules.
4. The base shock prod can obtain the hostile material before the capacitor exists.
5. The project spends the exact low-count recipe once and persists durably.
6. The capacitor interrupts only warning/lunge, preserves 1 damage, and leaves evade viable.
7. Existing map, salvage, material, research, project, combat, health, oxygen, daylight, and profile behavior remains deterministic.
8. Validation, smoke, captures, visual review, release validation, and exact-SHA Web verification pass.
9. Player review answers yes to: "Do creatures feel like part of the ocean's ecology and technology rather than disposable loot containers?"

A HOLD must name the smallest corrective issue and must not broaden into Expansion 08.
