# Controlled Gameplay Pass 19 Plan

Date: 2026-07-09

Issue: #380 `Plan Controlled Gameplay Pass 19 around cargo capacity upgrade`
Milestone: Simple Diver Game 04 `Progression And Economy Slice`

## Decision

Pass 19 should add one session-scoped cargo upgrade to `production_slice_01`:

```text
bank salvage -> earn session wallet -> buy cargo +1 -> carry three salvage before banking
```

This follows Pass 18's oxygen upgrade with a second small progression choice that changes route planning. The player should feel one concrete difference after purchase: a longer or deeper salvage route can carry one more pickup before returning to the boat.

## Target Experience

- The default slice still starts with base cargo capacity `2`.
- Banked salvage still creates session wallet payout.
- At extraction, the player can buy one cargo capacity upgrade when they have enough wallet.
- The upgrade raises held salvage capacity from `2` to `3` for the current app session.
- Cargo capacity affects instant, timed, and pry salvage consistently.
- Fresh app launch starts from base capacity again.

## Meaningful-Change Filter

Pass 19 is valuable only if cargo capacity changes a real decision:

- a player can choose between returning early with two salvage or continuing for a third pickup after upgrading
- cargo-full feedback remains clear before and after purchase
- banking, hazard reset, oxygen failure, and held salvage restore rules remain understandable
- the pass does not become a shop, inventory, upgrade-tree, save, or economy-balancing system

If the work starts requiring map expansion, new salvage placement, broad UI, persistence, enemies, procedural generation, or full production-map work, defer that to a later milestone.

## Planned Issue Batch

Implementation order:

1. #380 Plan Controlled Gameplay Pass 19 around cargo capacity upgrade.
2. #381 Document Pass 19 cargo capacity progression contract.
3. #382 Extend session progression helper for cargo capacity upgrade.
4. #383 Implement session cargo capacity upgrade purchase.
5. #384 Add compact cargo upgrade overlay and result feedback.
6. #385 Add deterministic Pass 19 cargo upgrade smoke coverage.
7. #386 Add focused Pass 19 cargo upgrade review capture.
8. #387 Review Pass 19 visual impact and baseline decision.
9. #388 Verify public Web preview after Pass 19 cargo upgrade pass.
10. #389 Add Pass 19 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected Milestone 05 goal.

## Source-Of-Truth Boundaries

Pass 19 runtime work should not change map source data.

Do not change:

- `production_slice_01` topology, collision, spawn, extraction, camera tests, route objectives, or salvage placement
- map converters, terrain rendering, or parity rules
- accepted visual baselines unless the visual-review issue identifies an intentional difference

The cargo upgrade is session progression state, not map metadata. If a later pass wants source-authored cargo gates or route locks, plan that as separate map/source work.

## Runtime And UI Boundaries

Runtime may:

- add one cargo upgrade state to the existing session progression helper
- keep `2` as base held salvage capacity
- add `+1` capacity after purchase, for an upgraded total of `3`
- allow purchase only at extraction
- keep wallet and purchased upgrade state through retry/reset in the same app session
- apply the upgraded capacity to pickup checks, timed salvage completion, pry salvage completion, overlay counts, result text, and smoke helpers

Runtime must not:

- add persistent save data
- add a store scene, inventory screen, loadout menu, or upgrade tree
- change oxygen upgrade behavior from Pass 18
- change salvage values, timed salvage duration, pry salvage steps, hazards, route objectives, or source map data

Recommended prototype settings:

```text
upgrade id: cargo_pouch_1
cost: 700 session wallet
effect: held salvage capacity +1
base capacity: 2
upgraded capacity: 3
purchase location: extraction only
```

Use compact overlay/result text. Examples:

```text
Wallet 700 | C: Cargo +1 (700)
Cargo +1 upgraded
Need 200 more
Held 2/3
```

## Validation And Smoke Plan

Add one focused smoke:

```text
--smoke-pass-19-cargo-upgrade
```

The smoke should verify:

- base cargo capacity remains `2`
- cargo-full behavior still blocks over-collection before purchase
- insufficient-funds purchase is blocked
- successful purchase spends wallet and raises capacity to `3`
- the player can hold three salvage only after purchase
- banking still clears held cargo and adds score/payout normally
- hazard reset and oxygen failure do not delete collectable salvage unexpectedly
- Pass 18 oxygen upgrade and existing cargo, timed salvage, pry salvage, hazard, route, and objective smokes remain stable

## Capture And Visual Plan

Add one focused review capture:

```text
visual_captures/pass_19_cargo_upgrade/
```

The capture should frame extraction or a nearby salvage route with wallet, cargo prompt, and upgraded held-capacity feedback visible. It is a review artifact, not automatic baseline acceptance.

Visual review should compare normal production-slice baselines and accept only intentional differences. Expected stable areas are terrain, camera framing, player, boat, salvage art, hazard art, route cues, and map topology.

## Deferred Work

Keep these out of Pass 19:

- #52 and #53 slice-03 camera/topology polish
- persistent save data
- shop/store scene
- multiple cargo tiers or upgrade tree
- inventory/loadout UI
- economy balancing beyond one prototype cost
- source-authored cargo gates or capacity-locked routes
- enemies, procedural generation, or full-map productionization
- broad art replacement

## Exit Criteria

Pass 19 is done when:

- the cargo capacity contract is documented
- session progression supports one cargo upgrade
- runtime capacity checks use base or upgraded capacity consistently
- compact overlay/result feedback is readable
- deterministic smoke covers purchase and capacity behavior
- a focused capture exists for review
- visual impact is reviewed
- public Web preview is verified
- closeout records what changed, what stayed stable, and the next recommendation
