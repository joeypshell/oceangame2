# Controlled Gameplay Pass 20 Plan

Date: 2026-07-09

Issue: #400 `Plan Controlled Gameplay Pass 20 around light confidence upgrade`
Milestone: Simple Diver Game 04 `Progression And Economy Slice`

## Decision

Pass 20 should add one session-scoped light confidence upgrade to `production_slice_01`:

```text
bank salvage -> earn session wallet -> buy Light +range -> dive with a longer, slightly brighter cone
```

This follows Pass 18's oxygen upgrade and Pass 19's cargo upgrade with a third small progression choice. The player should feel one concrete difference after purchase: deeper routes and tight return paths have clearer forward readability, without adding a darkness system or changing map scale.

## Target Experience

- The default slice starts with the existing player light cone.
- Banked salvage still creates session wallet payout.
- At extraction, the player can buy one light upgrade when they have enough wallet.
- The upgrade modestly extends and brightens the existing light cone for the current app session.
- The effect helps visual confidence on routes but does not change collision, reachability, salvage values, objective rules, or oxygen math.
- Fresh app launch starts from the base light state.

## Meaningful-Change Filter

Pass 20 is valuable only if the light upgrade makes route reading feel more confident:

- upgraded light is visible in a focused capture and public preview
- base light still reads correctly before purchase
- purchase feedback is compact and consistent with oxygen/cargo upgrades
- retry/reset preserves the purchase inside the session
- the pass does not become a full lighting, stealth, enemy, darkness, inventory, save, or map-expansion system

If the work starts requiring new map topology, dynamic darkness, enemy behavior, broad art replacement, persistent saves, or multiple equipment choices, defer that to a later milestone.

## Planned Issue Batch

Implementation order:

1. #400 Plan Controlled Gameplay Pass 20 around light confidence upgrade.
2. #401 Document Pass 20 light upgrade contract and boundaries.
3. #402 Extend session progression helper for light upgrade state.
4. #403 Implement session light upgrade runtime purchase and player light effect.
5. #404 Add compact light upgrade overlay and result feedback.
6. #405 Add deterministic Pass 20 light upgrade smoke coverage.
7. #406 Add focused Pass 20 light upgrade review capture.
8. #407 Review Pass 20 visual impact and baseline decision.
9. #408 Verify public Web preview after Pass 20 light upgrade pass.
10. #409 Add Pass 20 closeout and next-step evaluation.

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.

## Source-Of-Truth Boundaries

Pass 20 runtime work should not change map source data.

Do not change:

- `production_slice_01` topology, collision, spawn, extraction, camera tests, route objectives, or salvage placement
- map converters, terrain rendering, parity rules, or source-authored route metadata
- accepted visual baselines unless the visual-review issue identifies an intentional difference

The light upgrade is session progression state. If a later pass wants source-authored dark areas, light gates, or visibility-based route design, plan that as separate map/source work.

## Runtime And UI Boundaries

Runtime may:

- add one light upgrade state to the existing session progression helper
- keep the existing `LightCone` sprite as the base state
- apply an upgraded cone length/brightness after purchase
- allow purchase only at extraction
- keep wallet and purchased upgrade state through retry/reset in the same app session
- show compact prompt, success, already-owned, and insufficient-funds feedback

Runtime must not:

- add persistent save data
- add a store scene, inventory screen, equipment menu, or upgrade tree
- add darkness damage, stealth, enemies, or visibility-gated collision
- change oxygen upgrade or cargo upgrade behavior
- change route objectives, salvage values, hazards, or source map data

Recommended prototype settings:

```text
upgrade id: dive_light_1
cost: 900 session wallet
effect: light cone range x1.25 and alpha +0.10, capped for readability
purchase location: extraction only
```

Use compact overlay/result text. Examples:

```text
L: Light +range (900)
Light +range upgraded
Light +range
Need 300 more
```

## Validation And Smoke Plan

Add one focused smoke:

```text
--smoke-pass-20-light-upgrade
```

The smoke should verify:

- fresh state starts with base light settings
- insufficient-funds purchase is blocked
- successful purchase spends wallet and marks the light upgrade owned
- upgraded light settings are applied to the player
- retry/reset preserves the upgraded light state
- oxygen and cargo upgrades remain independent
- player-facing behavior still flips the light cone without root transform drift

## Capture And Visual Plan

Add one focused review capture:

```text
visual_captures/pass_20_light_upgrade/
```

The capture should frame a readable cave route with the upgraded light effect and compact overlay feedback visible. It is a review artifact, not automatic baseline acceptance.

Visual review should compare normal production-slice baselines and accept only intentional differences. Expected stable areas are terrain, camera framing, player body, boat, salvage art, hazard art, route cues, objectives, and map topology.

## Deferred Work

Keep these out of Pass 20:

- #52 and #53 slice-03 camera/topology polish
- persistent save data
- store/equipment scenes
- multiple light tiers or an upgrade tree
- dark-area source gates
- enemies, stealth, darkness damage, or visibility puzzles
- procedural generation or full-map productionization
- broad art replacement

## Exit Criteria

Pass 20 is done when:

- the light upgrade contract is documented
- session progression supports one light upgrade
- runtime purchase applies the upgraded light effect
- compact overlay/result feedback is readable
- deterministic smoke covers purchase, effect, and reset behavior
- a focused capture exists for review
- visual impact is reviewed
- public Web preview is verified
- closeout records what changed, what stayed stable, and the next recommendation
