# Expansion 07 Player Gate Correction

Date: 2026-07-12

Issues: #815, #825, #827, #829

Status: passive fins/current correction implemented; #799 remains the player GO/HOLD gate.

## Decision

1. `salvage_deep_right_cache` is guarded by eel behavior, not a collection permission.
2. `propulsion_fins` requires an explicitly recovered blueprint plus Ti2/Rubber1; neither knowledge nor equipment is bought with score.
3. Fins passively overcome the standard east current. The player swims through normally after the upgrade; `E`/ACT is never part of standard current traversal.
4. The east pocket remains in `production_slice_01` and contains a guaranteed scanner blueprint, optional valuable cache, anomaly survey, mineral trace, and glow-anemone sample.
5. `current_stabilizer` is a later optional advanced-current project targeting the lower-left relay current. It is not a shock-prod prerequisite.
6. Main-world geography is contiguous by default. Prompted connectors are reserved for explicit exceptional entrances or interiors and are not the ordinary capability-gate pattern.

## Behavioral Eel Guard

The deep cache remains normal 2.5-second `timed_salvage` with `guarded_by_hostile_id: deep_cache_territorial_eel`.

- An unarmed diver may begin the attempt.
- Eel warning, lunge, contact, damage, and knockback interrupt progress.
- Defeating the eel lets the unchanged cargo, restoration, and boat-banking path complete.
- No hidden capability lock is present on collection.

## Fins Recipe

`lower_loop_upgrade_chest` grants durable discovery `propulsion_fins_blueprint` only after explicit `E`/ACT interaction. The recipe is:

```text
2 titanium_scrap + 1 rubber_sheet
```

It builds only during `night_debrief`, spends no wallet, and reports `Fins installed - east current passable`. The compact project tracker distinguishes banked and held titanium/rubber until completion.

## Passive Current Journey

`upper_right_current_pocket_gate` is the standard left-pushing current and requires `propulsion_fins`.

- Before fins, pushback prevents eastward passage while oxygen/daylight continue.
- After fins, the current applies no push and the player collision envelope can move through the same corridor.
- The gate has no world connector and pressing `E` there cannot change maps.
- `east_current_scanner_blueprint_chest` grants `survey_scanner_blueprint`; Ti1/Coil1 then builds the scanner only during `night_debrief`.
- `salvage_current_pocket_cache` remains an optional 300-score payoff and cannot substitute for scanner knowledge or materials.
- `lower_right_anomaly_survey` now lives in the same pocket and commits at the canonical surface boat.

The pocket has a small source-authored chamber extension so its cache, anomaly, mineral survey, and biological sample do not compete for one interaction position.

## Optional Advanced Current

`lower_left_loop_current` now requires `current_stabilizer`, uses stronger flow, and overlaps the optional historical relay connector. `current_stabilizer_project` remains available after the current weapon/capacitor chain; `shock_prod_project` depends directly on `salvage_cutter_project`.

This preserves a later stronger-current tier without making an unrelated relay trip mandatory for scanner or weapon progression.

## Verification Contract

- Generator, map validation, parity, and progression audit prove the same-map chain and optional relay status.
- `--smoke-current-gate` proves pushback before fins, no push after fins, a clear player collision sweep, and no `E` transition.
- `--smoke-upgrade-chest` proves both blueprint interactions, exact recipe presentation, night builds, passive east-current traversal, and optional-cache independence.
- `--smoke-anomaly-survey-journey` proves blueprint-to-scanner-to-anomaly-to-cutter-plan commitment without connectors.
- Combat coverage proves shock prod follows cutter and precedes the behaviorally guarded cache.
- `--capture-current-gate` writes before/after east-current review images without accepting baselines.
- #914 remains the current human GO/HOLD closeout.
