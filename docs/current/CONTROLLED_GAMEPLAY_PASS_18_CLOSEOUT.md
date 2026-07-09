# Controlled Gameplay Pass 18 Closeout

Date: 2026-07-09

Issue: #369 `Add Pass 18 closeout and next-step evaluation`
Milestone: Simple Diver Game 04 `Progression And Economy Slice`

## Result

Controlled Gameplay Pass 18 is complete.

The default production slice now has a tiny session progression loop:

```text
bank salvage -> earn session wallet -> buy one oxygen tank upgrade -> retry with more range
```

This gives salvage one visible use beyond score while staying inside the small-game roadmap. It does not add persistence, a store scene, inventory/loadout UI, a broad economy, enemies, procedural generation, or map-scale expansion.

## Implemented Behavior

- Newly banked salvage score creates session wallet payout.
- Held or restored unbanked salvage does not create wallet payout.
- One session-only oxygen tank upgrade can be purchased at extraction.
- Upgrade cost is `500`; effect is `O2 tank +15`, raising capacity from `90s` to `105s`.
- Wallet and purchased upgrade survive retry/reset inside the app session.
- Fresh app launch starts from the unupgraded state.
- Compact overlay/result text shows wallet, upgrade prompt, purchase feedback, and insufficient-funds feedback.

## Source Decisions

- Progression authority lives in runtime code, not map source.
- `production_slice_01` topology, collision, spawn, extraction, salvage placement, route objectives, and camera tests were not changed.
- Salvage tier scoring and oxygen bonus scoring stayed separate from wallet rules.
- #52 and #53 remain deferred optional slice-03 polish.

## Verification

- `--smoke-pass-18-progression` verifies payout, held/failure no-payout, insufficient funds, purchase spend, upgraded capacity, and reset/refill persistence.
- Existing primary completion, oxygen, cargo, and route smokes stayed green through PR CI.
- Focused review capture: `visual_captures/pass_18_progression/production_slice_01_pass_18_progression.png`.
- Visual decision: `docs/current/PASS_18_PROGRESSION_VISUAL_BASELINE_DECISION.md`.
- Public Web verification: `docs/current/PASS_18_PROGRESSION_WEB_PREVIEW_VERIFICATION.md`.
- Deployed runtime/export commit verified: `c97b0ab9c7b7438057eacd3693b91eb8fcbbac9f`.

## Stable Areas

The pass did not accept or require baseline changes. Normal production-slice captures matched accepted baselines for slices 01-04.

Stable areas:

- terrain topology and collision-derived cave shape
- boat/extraction, player, props, hazards, backgrounds, and camera framing
- timed salvage, pry salvage, cargo, hazard, oxygen-rest, route cues, objective cues, primary completion, and result-panel semantics
- source-of-truth map workflow and Web preview packaging

## Remaining Gaps

Pass 18 proves the first progression feel only. It still lacks:

- persistent save data
- multiple upgrade choices
- cargo/light/tool upgrades
- a shop/store interface
- map areas gated by upgraded capacity or tools
- economy balancing beyond one prototype cost

These are later roadmap work, not regressions.

## Recommended Next Direction

Continue Milestone 04 with one more small progression decision before map-scale expansion.

Recommended next pass:

```text
add one second upgrade or unlock that changes route planning
```

Best candidates:

- cargo capacity +1, if the goal is stronger bank/return decisions
- brighter/longer light cone, if the goal is readable deep-route confidence
- one source-authored tool-gated salvage or obstruction, if the goal is a progression-gated route beat

Keep the next pass scoped to one upgrade/unlock and one deterministic smoke/capture path. Do not jump to broad economy, save files, inventory, enemies, procedural generation, or full-map productionization yet.

## Issue Batch Completed

- #360 Pass 18 plan
- #361 progression contract
- #362 session wallet
- #363 oxygen tank upgrade
- #364 compact overlay feedback
- #365 deterministic smoke
- #366 focused capture
- #367 visual baseline decision
- #368 public Web verification
- #369 closeout
