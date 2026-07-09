# Controlled Gameplay Pass 20 Light Contract

Date: 2026-07-09

Issue: #401 `Document Pass 20 light upgrade contract and boundaries`
Plan: `docs/current/CONTROLLED_GAMEPLAY_PASS_20_PLAN.md`

## Decision

Pass 20 adds one session-scoped light confidence upgrade:

```text
newly banked salvage score -> session wallet -> dive_light_1 -> longer/brighter light cone
```

This is a narrow readability/progression step. It should make deeper or tighter routes feel more confident after purchase without adding dynamic darkness, enemies, stealth, a store scene, inventory, save files, broad economy, upgrade tree, map gates, or new topology.

## Authority

For Pass 20, light progression authority lives in runtime code, not map source.

Authoritative runtime constants should define:

- upgrade id: `dive_light_1`
- upgrade cost: `900`
- upgrade effect: `Light +range`
- purchase location: boat/extraction only
- base cone range scale: `1.0`
- upgraded cone range scale: `1.25`
- base cone alpha: `0.38`
- upgraded cone alpha: `0.48`

The map source remains responsible for terrain, collision, extraction, routes, objectives, salvage placement, salvage interaction metadata, hazards, and camera tests. Pass 20 must not add light upgrade metadata to `maps/production_slice_01.greybox.json`.

## Wallet Rules

Pass 20 uses the existing Pass 18/19 session wallet rules:

- The session wallet starts at `0` on fresh app launch.
- The wallet persists through retry/reset inside the current app session.
- The wallet does not persist to disk.
- Wallet gain comes only from newly banked salvage score.
- Held or restored unbanked salvage does not create wallet value.
- Oxygen bonus remains result scoring only and does not become wallet value.
- Session-best score remains separate from wallet value.

The light upgrade spends wallet; it does not change payout math.

## Upgrade Rules

Pass 20 adds exactly one light upgrade:

```text
dive_light_1: Light +range
```

Rules:

- The upgrade can be purchased only while the player is at the boat/extraction area.
- Purchase succeeds only when wallet is at least `900`.
- Purchase spends `900` wallet.
- Purchase can happen once per app session.
- Purchase persists through retry/reset inside the current app session.
- Purchase does not persist to disk.
- Insufficient funds leave wallet, score, oxygen, cargo, light state, and run state unchanged.
- Re-purchase attempts leave wallet and run state unchanged.

The upgrade should apply by adjusting the existing player `LightCone` sprite only:

- base: range scale `1.0`, alpha `0.38`
- upgraded: range scale `1.25`, alpha `0.48`
- facing changes must continue to flip the light cone by sign without scaling the player root

## Reset And Failure Rules

Retry/reset should clear expedition state but not session progression:

- clears held cargo, banked run cargo, run score, objective progress, timed/pry interaction progress, hazard state, and oxygen run state
- preserves session wallet
- preserves the purchased oxygen tank upgrade
- preserves the purchased cargo capacity upgrade
- preserves the purchased light upgrade

Fresh app launch should clear all session progression:

- session wallet
- purchased oxygen tank upgrade
- purchased cargo capacity upgrade
- purchased light upgrade

Hazard reset and oxygen failure should not change light upgrade ownership.

## Runtime Boundaries

The light upgrade may affect:

- player `LightCone` visual range
- player `LightCone` alpha
- overlay prompt and purchase feedback
- result/progression text
- smoke helpers that assert light state
- focused capture framing for visual review

The light upgrade must not affect:

- player collision, movement speed, acceleration, or camera
- oxygen capacity, oxygen drain, oxygen-rest pockets, or oxygen bonus scoring
- cargo capacity or cargo-full behavior
- salvage values, salvage placement, timed salvage, pry salvage, hazards, or objectives
- map source, terrain, collision, route metadata, camera tests, or Web export packaging

## UI Rules

Use compact overlay/result text only.

Allowed text examples:

```text
L: Light +range (900)
Light +range upgraded
Light +range already upgraded
Need 300 more
Light base
Light +range
```

No dedicated shop/store scene is part of Pass 20. Stronger live feedback still wins over progression prompts:

- oxygen failure
- hazard warning/contact
- cargo-full prompt
- salvage pickup feedback
- timed salvage progress
- pry salvage progress
- objective route feedback
- completion/failure result panel

## Smoke Contract

`--smoke-pass-20-light-upgrade` should verify:

- fresh state starts with no light upgrade
- base player light uses range scale `1.0` and alpha `0.38`
- insufficient-funds purchase is blocked
- successful purchase spends `900` wallet
- upgraded light uses range scale `1.25` and alpha `0.48`
- retry/reset preserves the light upgrade and reapplies the visual state
- oxygen and cargo upgrade ownership remains independent
- player-facing smoke continues to confirm root scale remains stable while the light cone flips by sign

Existing cargo, oxygen, timed salvage, pry salvage, hazard, route, objective, Pass 18 progression, and Pass 19 cargo smokes should remain green.

## Non-Goals

Pass 20 must not add:

- persistent save files
- a store scene
- an inventory screen
- loadouts
- multiple light tiers
- an upgrade tree
- dark-area gates or map source light requirements
- stealth, visibility puzzles, darkness damage, or enemies
- procedural generation
- full-map productionization
- broad art replacement

## Deferred Work

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.
