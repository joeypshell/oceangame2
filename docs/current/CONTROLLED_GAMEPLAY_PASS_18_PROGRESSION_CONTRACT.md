# Controlled Gameplay Pass 18 Progression Contract

Date: 2026-07-09

Issue: #361 `Document Pass 18 progression contract and source boundaries`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_18_PLAN.md`

## Decision

Pass 18 progression is a session-scoped prototype:

```text
newly banked salvage score -> session wallet -> one oxygen tank upgrade
```

It proves that salvage can matter across attempts without committing to save files, a store scene, an inventory screen, a loadout system, a broad economy, or an upgrade tree.

## Authority

For Pass 18, progression authority lives in runtime code, not map source.

Authoritative runtime constants should define:

- wallet gain rule: `newly banked salvage score`
- upgrade id: `oxygen_tank_1`
- upgrade cost: `500`
- upgrade effect: `+15` oxygen seconds
- base tank: existing `90` seconds
- upgraded tank: `105` seconds

The map source stays responsible for salvage placement, score tier, collision, extraction, routes, objectives, and camera tests. Pass 18 must not add progression metadata to `maps/production_slice_01.greybox.json` unless a later issue explicitly changes this contract.

## Wallet Rules

- The session wallet starts at `0` on fresh app launch.
- The wallet persists through retry/reset inside the current app session.
- The wallet does not persist to disk.
- Wallet gain comes only from newly banked salvage score.
- Held salvage does not create wallet value.
- Restored/unbanked salvage after hazard reset or oxygen failure does not create wallet value.
- Oxygen bonus remains result scoring only and does not become wallet value in Pass 18.
- Session-best score remains separate from wallet value.

Implementation should avoid double-counting by adding wallet only when held cargo is actually banked at extraction.

## Upgrade Rules

Pass 18 adds exactly one upgrade:

```text
oxygen_tank_1: O2 tank +15
```

Rules:

- The upgrade can be purchased only while the player is at the boat/extraction area.
- Purchase succeeds only when wallet is at least `500`.
- Purchase spends `500` wallet.
- Purchase can happen once per app session.
- Purchase persists through retry/reset inside the current app session.
- Purchase does not persist to disk.
- Purchase increases the refill maximum and reset starting oxygen for later attempts from `90` to `105` seconds.
- Insufficient funds leave wallet, oxygen, cargo, score, and run state unchanged.

Oxygen low/critical feedback should remain readable. The lower-loop oxygen-rest pocket cap should remain below the boat/extraction refill maximum so it stays a rest-pocket cue rather than a full refill.

## Reset And Failure Rules

Retry/reset should clear expedition state but not session progression:

- clears held cargo, banked run cargo, run score, objective progress, timed/pry interaction progress, hazard state, and oxygen run state
- preserves session wallet
- preserves the purchased oxygen upgrade

Fresh app launch should clear both:

- session wallet
- purchased oxygen upgrade

Hazard reset and oxygen failure should keep already-earned wallet because wallet only comes from previously banked salvage. They should not award wallet for held cargo restored to the map.

## UI Rules

Use compact overlay/result text only.

Allowed text examples:

```text
Wallet 300
Upgrade: O2 tank +15 (500)
O2 tank upgraded
Need 200 more
```

No dedicated shop/store scene is part of Pass 18. Stronger live feedback still wins over progression prompts:

- oxygen failure
- hazard warning/contact
- cargo-full prompt
- salvage pickup feedback
- timed salvage progress
- pry salvage progress
- objective route feedback
- completion/failure result panel

## Smoke Contract

`--smoke-pass-18-progression` should verify:

- banked salvage adds wallet
- held/unbanked salvage does not add wallet
- oxygen failure does not award wallet for restored held cargo
- insufficient-funds purchase is blocked
- successful purchase spends wallet and applies the tank upgrade
- retry/reset preserves wallet and upgrade
- fresh app start is not simulated as persistence

## Non-Goals

Pass 18 must not add:

- persistent save files
- a store scene
- an inventory screen
- loadouts
- multiple upgrades
- upgrade trees
- economy balance curves
- enemies
- procedural generation
- full-map productionization
- broad art replacement

## Deferred Work

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.
