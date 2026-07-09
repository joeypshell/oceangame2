# Simple Diver Progression Gates Plan

Date: 2026-07-09

Issue: #441 `Plan source-authored progression gates across the simple diver world`

## Decision

Use progression gates sparingly to make the small diver game feel connected and worth replaying. A gate should block, soften, or warn about one authored route until the player has learned, earned, or upgraded something specific.

Do not use gates as a reason to produce the whole full-sketch map. Each gate must be source-authored in the selected slice or connector, validated from map data, covered by one focused smoke/capture path when implemented, and tied to a clear player-facing payoff.

## Current World Anchors

| Area | Current role | Useful gate pressure |
|---|---|---|
| `production_slice_01` boat hub | Default start, primary dive, wallet/upgrades, deep-cache objective | Tutorial-safe gates, light confidence, first tool/reward gates |
| `production_slice_01 lower_left_loop_connector` | Prompted connector into slice 04 | Future return-loop or upgrade-check gate, not another connector by default |
| `production_slice_04 relay loop` | Reachable lower-left reference slice after Pass 21 | Destination payoff, return-loop pressure, first current gate candidate |
| `production_slice_03` | Deferred connector/landmark reference | Keep #52/#53 deferred unless slice 03 becomes the selected world route |

## Gate Types

| Gate type | Opens with | Prototype status | First useful target |
|---|---|---|---|
| Darkness / light | Existing `Light +range` session upgrade | Prototype-ready as readability pressure, not a hard lock | A darker branch near the connector or lower-loop return where better light makes route choice safer |
| Current / propulsion | `propulsion_fins` session upgrade | First source/runtime prototype implemented by #443/#444 | `lower_left_loop_current` overlapping the slice 01 connector to slice 04 |
| Locked chest / key | Key flag, opened cache flag, or reward state | Contract defined by #445 | One small `upgrade_chest` in slice 01 that rewards a simple upgrade/currency beat |
| Tool interaction | Existing timed/pry salvage patterns or one future tool flag | Partly ready; keep to one interaction family at a time | A sealed cache or obstruction that reuses source-authored marker/salvage interaction semantics |
| Dodge hazard / enemy | Learned route timing, route cue, or future upgrade | Design-only for now; treat as moving hazard, not combat | One deterministic patrol/dodge beat after planning #449, if it improves the core dive loop |

## Source-Of-Truth Boundaries

Gate metadata belongs in map JSON source or generator code, not in hand-placed Godot scene geometry.

Source metadata may describe:

- gate id, type, compact label, and intent
- gate rectangle or source entity reference
- required upgrade, key, tool, objective, or route state by id
- destination or payoff ids already authored elsewhere
- validation route/context ids for smoke and capture discovery

Source metadata must not describe:

- runtime progress counters, collected/opened flags, or save state
- score values, oxygen values, cargo limits, wallet totals, or upgrade prices
- player coordinates outside authored spawn/entry semantics
- collision changes that are not represented by terrain/source topology
- camera-only fixes or visual-only Godot scene placement

## Prototype-Ready Now

The next implementation should choose exactly one of these:

1. Current gate contract, then one current/propulsion gate in the connected slice-01/slice-04 route.
2. Treasure/cache contract, then one upgrade chest or locked cache reward with flag-like runtime state.
3. Darkness/light contract, then one visual readability gate tied to the existing light upgrade.

The first current gate is now `lower_left_loop_current`: it soft-pushes the diver away from the lower-left connector until `propulsion_fins` is purchased. The first upgrade chest is `lower_loop_upgrade_chest`, a one-time wallet reward on an optional lower-loop detour. Do not add keys, locked salvage caches, or more current zones until that reward beat has been reviewed.

## Deferred

- #52/#53 slice-03 camera/topology polish remains deferred unless slice 03 becomes the selected world route.
- Full-map productionization remains deferred.
- Multiple simultaneous gate types remain deferred.
- Hard inventory, loadout screens, save-heavy keyrings, broad economy, combat, enemy ecosystems, procedural generation, and broad art replacement remain out of scope.

## Recommended Issue Order

1. #443 `Add source metadata contract for current-gated routes`.
2. #444 `Prototype one current gate and upgrade check`.
3. #445 `Define treasure chest, key, and locked-cache progression contract`.
4. #446 `Prototype one upgrade chest reward`.
5. #442 `Design depth darkness and flashlight progression gate`.
6. #447/#448 for player animation only after Web framing and gate-review needs are stable.
7. #449/#450 only if the moving hazard remains a small dodge-pressure beat, not combat or AI sprawl.

## Verification Expectations

Each future gate implementation should run:

```powershell
python tools/validate_greybox_map.py maps/<affected>.greybox.json
python tools/check_file_lengths.py
git diff --check
```

Runtime gates should also add one focused smoke, one focused capture when visual feedback matters, and normal route/connector smokes for affected slices.
