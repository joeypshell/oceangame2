# Controlled Gameplay Pass 18 Plan

Date: 2026-07-09

Issue: #360 `Plan Controlled Gameplay Pass 18 around session payout progression`
Milestone: Simple Diver Game 04 `Progression And Economy Slice`

## Decision

Pass 18 should add one tiny session-scoped progression loop to `production_slice_01`:

```text
bank salvage -> earn session payout -> buy one oxygen tank upgrade -> retry with a little more range
```

This is the first Milestone 04 step after Pass 17 proved a second non-instant salvage verb. The goal is to make salvage matter across attempts without adding a store scene, inventory screen, save file, broad economy, upgrade tree, enemies, procedural generation, or map-scale expansion.

## Target Experience

- The player completes or partially completes dives as usual.
- Banked salvage creates spendable session payout.
- The payout survives retry/reset inside the current app session.
- At the boat/extraction area, a compact prompt offers one upgrade when the player can afford it.
- Buying the upgrade increases the oxygen tank maximum for later attempts in the same session.
- Fresh app launch starts from the default unupgraded prototype state.

## Meaningful-Change Filter

The pass is valuable only if it creates a reason to try another expedition:

- salvage has a visible use beyond score
- the next attempt feels slightly different because oxygen capacity changed
- failure and retry remain understandable
- no new broad systems are required
- current source-of-truth, smoke, capture, baseline, and Web preview workflows stay intact

If the work becomes a shop UI, save system, multiple upgrades, currency balancing pass, inventory/loadout system, complex economy, enemy system, procedural map pass, or full-map production pass, keep it out of Pass 18.

## Planned Issue Batch

Implementation order:

1. #360 Plan Controlled Gameplay Pass 18 around session payout progression.
2. #361 Document Pass 18 progression contract and source boundaries.
3. #362 Implement session payout wallet from banked salvage score.
4. #363 Implement one session oxygen capacity upgrade purchase.
5. #364 Add compact progression and upgrade overlay feedback.
6. #365 Add deterministic Pass 18 progression and upgrade smoke coverage.
7. #366 Add focused Pass 18 progression review capture.
8. #367 Review Pass 18 visual impact and baseline decision.
9. #368 Verify public Web preview after Pass 18 progression pass.
10. #369 Add Pass 18 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Runtime Boundaries

Runtime may:

- track a session wallet in memory
- add payout when salvage is banked at extraction
- prevent duplicate payout for already-banked cargo in the same run
- show compact wallet and upgrade prompt text near extraction or in the result panel
- allow one oxygen capacity upgrade purchase while at extraction
- persist wallet and purchased upgrade through retry/reset in the same app session
- reset wallet and upgrade state on a fresh app launch

Runtime must not:

- add save files
- add a store scene, inventory screen, loadout menu, or upgrade tree
- change source map topology, collision, spawn, extraction, camera tests, route objectives, or salvage placement
- change tier score values, cargo capacity, timed salvage, pry salvage, hazard, or primary completion semantics unless the Pass 18 contract explicitly requires it

## Payout Decision

Banked salvage score should be the first payout source.

Recommended rule:

```text
session payout gained = newly banked salvage score
```

Held or unbanked salvage does not create payout. Failed expeditions do not convert held salvage into payout. Oxygen bonus remains result scoring only unless a later pass deliberately changes that.

## Upgrade Decision

Add exactly one upgrade:

```text
oxygen tank +15 seconds
```

Recommended settings:

- cost: 500 session payout
- base tank: 90 seconds
- upgraded tank: 105 seconds
- low/critical thresholds stay readable and should not become noisier
- oxygen-rest pocket cap remains below boat/extraction refill maximum

This upgrade is intentionally session-scoped. It proves progression feel without committing to persistence, balance, or upgrade-tree architecture.

## UI Boundaries

Use compact overlay/result text only. Examples:

```text
Wallet 300
Upgrade: O2 tank +15 (500)
O2 tank upgraded
Need 200 more
```

Stronger live feedback still wins: hazard warnings, oxygen failure, cargo-full prompts, salvage pickup feedback, timed/pry progress, completion/failure result panels, and objective route feedback should not be obscured.

## Validation And Smoke Plan

Add one focused smoke:

```text
--smoke-pass-18-progression
```

The smoke should verify:

- banked salvage adds wallet payout
- held/unbanked salvage does not add wallet payout
- failed expeditions do not add wallet payout from restored held salvage
- insufficient-funds purchase is blocked
- successful purchase spends wallet and increases oxygen capacity
- upgrade state survives retry/reset within the session
- existing cargo, oxygen, hazard, timed salvage, pry salvage, primary objective, and result behavior stay stable

## Capture And Visual Plan

Add one focused capture:

```text
visual_captures/pass_18_progression/
```

The capture should frame the boat/extraction area with wallet and upgrade feedback visible. It is a review artifact, not automatic baseline acceptance.

Visual review should compare normal production-slice baselines and accept only intentional differences. The expected outcome is likely no accepted baseline change if normal captures do not show the new prompt state.

## Deferred Work

Keep these out of Pass 18:

- #52 and #53 slice-03 camera/topology polish
- persistent save data
- shop/store scene
- multiple upgrades or upgrade tree
- inventory/loadout UI
- economy balancing beyond one prototype cost
- enemies, procedural generation, or full-map productionization
- broad art replacement

## Exit Criteria

Pass 18 is done when:

- the progression contract is documented
- session wallet and one oxygen upgrade exist
- compact feedback is readable
- deterministic smoke covers payout, purchase, reset, and failure semantics
- a focused capture exists for review
- visual impact is reviewed
- public Web preview is verified
- closeout records what changed, what stayed stable, and the next recommendation
