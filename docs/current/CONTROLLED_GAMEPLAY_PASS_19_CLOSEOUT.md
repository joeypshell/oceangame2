# Controlled Gameplay Pass 19 Closeout

Date: 2026-07-09

Issue: #389 `Add Pass 19 closeout and next-step evaluation`
Milestone: Simple Diver Game 04 `Progression And Economy Slice`

## Result

Controlled Gameplay Pass 19 is complete.

The default production slice now has a second tiny session progression decision:

```text
bank salvage -> earn session wallet -> buy Cargo +1 -> carry three salvage before banking
```

This builds on Pass 18's oxygen upgrade and gives the player one visible route-planning change without adding persistence, a store scene, inventory/loadout UI, a broad economy, enemies, procedural generation, or map-scale expansion.

## Implemented Behavior

- Base held-salvage capacity remains `2`.
- One session-only cargo upgrade can be purchased at extraction.
- Upgrade id is `cargo_pouch_1`; cost is `700`; effect is `Cargo +1`, raising held capacity to `3`.
- Wallet and purchased cargo upgrade survive retry/reset inside the app session.
- Fresh app launch starts from the base capacity state.
- Instant, timed, and pry salvage capacity checks use the active base/upgraded capacity.
- Cargo-full blocking keeps collectable salvage available instead of deleting it.
- Compact overlay/result text shows wallet, oxygen upgrade prompt/state, cargo upgrade prompt/state, purchase feedback, and held capacity.

## Source Decisions

- Cargo progression authority lives in runtime code, not map source.
- `production_slice_01` topology, collision, spawn, extraction, salvage placement, route objectives, and camera tests were not changed.
- The cargo upgrade does not add source-authored cargo gates or capacity-locked routes.
- #52 and #53 remain deferred optional slice-03 polish.

## Verification

- `--smoke-pass-19-cargo-upgrade` verifies base capacity, insufficient-funds blocking, purchase spend, upgraded capacity, three-held-cargo behavior, fourth-pickup blocking, banking, reset persistence, and failure restore semantics.
- Existing cargo, oxygen, primary completion, hazard, route, pry, timed salvage, and Pass 18 progression smokes stayed green through PR CI.
- Focused review capture: `visual_captures/pass_19_cargo_upgrade/production_slice_01_pass_19_cargo_upgrade.png`.
- Visual decision: `docs/current/PASS_19_CARGO_UPGRADE_VISUAL_BASELINE_DECISION.md`.
- Public Web verification: `docs/current/PASS_19_CARGO_UPGRADE_WEB_PREVIEW_VERIFICATION.md`.
- Deployed runtime/export commit verified: `6df5388f7cc0971bf7f14cbe4fc753b5b147c152`.

## Stable Areas

The pass did not accept or require production-slice baseline changes. Normal captures matched accepted baselines for slices 01-04.

Stable areas:

- terrain topology and collision-derived cave shape
- boat/extraction, player, props, hazards, backgrounds, and camera framing
- source-authored map workflow, route objectives, timed salvage, pry salvage, hazards, oxygen-rest, route cues, primary completion, and result-panel semantics
- Web preview packaging and build metadata checks

## Remaining Gaps

Pass 19 proves a second small progression choice only. It still lacks:

- persistent save data
- multiple simultaneous upgrade choices
- light/tool upgrades
- a shop/store interface
- source-authored routes gated by upgrades or tools
- economy balancing beyond prototype costs

These are later roadmap work, not regressions.

## Recommended Next Direction

Pause before creating the next batch and choose the next roadmap lane deliberately.

Recommended options:

- stay in Milestone 04 for one more tiny upgrade/unlock, preferably light confidence or a single tool-gated route beat
- move to Milestone 05 only if the goal is a clearly pressure/payoff-driven world slice expansion
- run a short repo-drift evaluation first if the active backlog is empty

Do not jump to broad economy, save files, inventory, enemies, procedural generation, or full-map productionization.

## Issue Batch Completed

- #380 Pass 19 plan
- #381 cargo capacity progression contract
- #382 session cargo upgrade helper state
- #383 cargo capacity upgrade runtime purchase
- #384 compact cargo upgrade overlay and result feedback
- #385 deterministic cargo upgrade smoke
- #386 focused cargo upgrade capture
- #387 visual baseline decision
- #388 public Web verification
- #389 closeout
