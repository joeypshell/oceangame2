# Controlled Gameplay Pass 19 Cargo Contract

Date: 2026-07-09

Issue: #381 `Document Pass 19 cargo capacity progression contract`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_19_PLAN.md`

## Decision

Pass 19 adds one session-scoped cargo capacity upgrade:

```text
newly banked salvage score -> session wallet -> cargo_pouch_1 -> held salvage capacity 3
```

This is a narrow progression step. It should make banking routes feel different after purchase without adding a store scene, inventory screen, save file, broad economy, upgrade tree, map gate, or new map topology.

## Authority

For Pass 19, cargo progression authority lives in runtime code, not map source.

Authoritative runtime constants should define:

- upgrade id: `cargo_pouch_1`
- upgrade cost: `700`
- upgrade effect: `held salvage capacity +1`
- base held salvage capacity: `2`
- upgraded held salvage capacity: `3`
- purchase location: boat/extraction only

The map source remains responsible for terrain, collision, extraction, routes, objectives, salvage placement, salvage interaction metadata, hazards, and camera tests. Pass 19 must not add cargo upgrade metadata to `maps/production_slice_01.greybox.json`.

## Wallet Rules

Pass 19 uses the existing Pass 18 session wallet rules:

- The session wallet starts at `0` on fresh app launch.
- The wallet persists through retry/reset inside the current app session.
- The wallet does not persist to disk.
- Wallet gain comes only from newly banked salvage score.
- Held or restored unbanked salvage does not create wallet value.
- Oxygen bonus remains result scoring only and does not become wallet value.
- Session-best score remains separate from wallet value.

The cargo upgrade spends wallet; it does not change payout math.

## Upgrade Rules

Pass 19 adds exactly one cargo upgrade:

```text
cargo_pouch_1: Cargo +1
```

Rules:

- The upgrade can be purchased only while the player is at the boat/extraction area.
- Purchase succeeds only when wallet is at least `700`.
- Purchase spends `700` wallet.
- Purchase can happen once per app session.
- Purchase persists through retry/reset inside the current app session.
- Purchase does not persist to disk.
- Purchase raises held salvage capacity from `2` to `3`.
- Insufficient funds leave wallet, cargo, score, oxygen, and run state unchanged.
- Re-purchase attempts leave wallet and run state unchanged.

The cargo upgrade should apply to every path that checks held capacity:

- instant salvage pickup
- timed salvage completion
- staged pry salvage completion
- cargo-full feedback
- status overlay held count
- result text where capacity is shown or implied
- smoke helpers that assert capacity behavior

## Reset And Failure Rules

Retry/reset should clear expedition state but not session progression:

- clears held cargo, banked run cargo, run score, objective progress, timed/pry interaction progress, hazard state, and oxygen run state
- preserves session wallet
- preserves the purchased oxygen tank upgrade
- preserves the purchased cargo capacity upgrade

Fresh app launch should clear all session progression:

- session wallet
- purchased oxygen tank upgrade
- purchased cargo capacity upgrade

Hazard reset and oxygen failure should restore held/unbanked salvage according to existing semantics. They should not award wallet from restored held cargo, and they should not delete salvage because cargo is full.

## Cargo Semantics

Base capacity remains `2`.

Before purchase:

- the player can hold at most two salvage
- a third salvage attempt should show the existing cargo-full behavior
- timed/pry salvage should not disappear when completion is blocked by full cargo

After purchase:

- the player can hold at most three salvage
- banking at extraction clears all held cargo and adds score/payout normally
- existing cargo-full behavior should still trigger when trying to exceed three held salvage

The upgrade changes return-pressure decisions but does not change salvage value, oxygen cost, hazard penalty, route objective requirements, or map reachability.

## UI Rules

Use compact overlay/result text only.

Allowed text examples:

```text
Wallet 700 | C: Cargo +1 (700)
Cargo +1 upgraded
Cargo +1 already upgraded
Need 200 more
Held 2/3
```

No dedicated shop/store scene is part of Pass 19. Stronger live feedback still wins over progression prompts:

- oxygen failure
- hazard warning/contact
- cargo-full prompt
- salvage pickup feedback
- timed salvage progress
- pry salvage progress
- objective route feedback
- completion/failure result panel

## Smoke Contract

`--smoke-pass-19-cargo-upgrade` should verify:

- base capacity is `2`
- cargo-full behavior blocks a third held salvage before purchase
- insufficient-funds purchase is blocked
- successful purchase spends `700` wallet
- upgraded capacity is `3`
- three held salvage can be carried after purchase
- a fourth salvage attempt is still blocked
- banking clears held cargo and awards score/payout normally
- retry/reset preserves the cargo upgrade
- hazard reset or oxygen failure restores unbanked/held salvage without wallet payout

Existing cargo, oxygen, timed salvage, pry salvage, hazard, route, objective, and Pass 18 progression smokes should remain green.

## Non-Goals

Pass 19 must not add:

- persistent save files
- a store scene
- an inventory screen
- loadouts
- multiple cargo tiers
- upgrade trees
- economy balance curves
- map topology changes
- source-authored cargo gates
- enemies
- procedural generation
- full-map productionization
- broad art replacement

## Deferred Work

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.
