# Controlled Gameplay Pass 17 Closeout

Date: 2026-07-09

Issue: #349 `Add Pass 17 closeout and next-step evaluation`
Implementation issues: #340-#348

## Result

Controlled Gameplay Pass 17 is complete.

The pass added one compact source-authored `pry_salvage` interaction to `production_slice_01`. The default dive now has two non-instant salvage rhythms:

- continuous timed salvage at `salvage_deep_right_cache`
- staged pry salvage at `salvage_pry_locker`

This gives the current slice another small oxygen/cargo decision without adding inventory, loadouts, upgrades, enemies, procedural generation, or map-scale expansion.

## Implemented Behavior

- `salvage_pry_locker` is authored as a valuable `pry_salvage` target.
- The target requires 3 completed pry stages at 1.2 seconds per stage.
- Staying near the target advances the current stage.
- Leaving range cancels only the current partial stage.
- Completed stages persist during normal exploration, banking, and oxygen refill.
- Hazard reset, oxygen failure, and manual reset clear uncollected pry progress.
- Cargo capacity still applies: if cargo is full, the target stays available and uncollected until space is freed.
- Completing all pry stages collects the target into held cargo with compact overlay feedback.

## Source And Validation Decisions

The source-of-truth path stayed intact:

```text
tools/create_production_slice_map.py
maps/production_slice_01.greybox.json
references/greybox/production_slice_01.svg
docs/MAP_SPEC.md
tools/validate_greybox_map.py
```

The new salvage metadata is:

```json
{
  "interaction": "pry_salvage",
  "interaction_seconds": 1.2,
  "pry_stages": 3,
  "interaction_label": "sealed cache"
}
```

Validation now catches unsupported interaction names, missing or invalid pry timing/stage fields, misplaced interaction metadata, and normal salvage placement/reachability problems.

## Verification

Pass 17 added deterministic smoke coverage:

```text
--smoke-pry-salvage
```

The smoke verifies non-instant collection, partial-stage progress, partial-stage cancel on leaving range, saved completed stages, completion into held cargo, cargo-full blocking without deletion, banking after capacity frees, hazard reset, oxygen failure/reset, and primary objective stability.

Regression coverage during the pass included salvage loop, cargo capacity, timed salvage, oxygen pressure, hazard pressure, safe/deep route choice, route outcome, primary dive completion, production-slice captures, map parity, map validation, file-length audit, and GitHub Actions headless smoke.

## Capture And Visual Decision

Focused review capture:

```text
visual_captures/pry_salvage/production_slice_01_pry_salvage.png
```

Visual decision:

```text
docs/current/PASS_17_PRY_SALVAGE_VISUAL_BASELINE_DECISION.md
```

No production-slice baseline changes were accepted. Normal slice 01-04 captures matched accepted baselines, and the focused Pass 17 capture remains a review artifact only.

## Web Preview

Web verification:

```text
docs/current/PASS_17_PRY_SALVAGE_WEB_PREVIEW_VERIFICATION.md
```

The public preview was verified against deployed runtime/export commit:

```text
7fb78dc3eb4715583dec7ffd6b81925a6dda0bcd
```

The browser check matched `build_info.json`, initialized the Godot canvas, and reported no failed network requests, missing resources, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages.

## Stable Areas

Pass 17 did not change:

- terrain topology or collision
- spawn, boat, extraction, route scale, or camera tests
- primary objective completion requirements
- instant salvage, timed salvage, cargo score values, or banking semantics
- oxygen drain, refill, rest-pocket cap, failure, or result behavior
- hazard warning, penalty, reset, or player tint behavior
- accepted visual baselines
- #52/#53 deferred slice-03 polish status

## Remaining Gaps

Milestone 03 now has a working second tool-like salvage verb at prototype level. The game still lacks progression, payout decisions, upgrades/unlocks, broader presentation polish, and a larger connected run structure.

Still deferred:

- #52 `Tune production slice 03 camera framing`
- #53 `Clean production slice 03 topology artifacts in source generator`

Keep them deferred unless slice-03 presentation becomes the selected goal.

## Next Recommendation

Use `docs/current/SIMPLE_DIVER_GAME_ROADMAP.md` as the north star and plan the next actionable batch from:

```text
Milestone 04: Progression And Economy Slice
```

Recommended next direction: add one small source-safe reason for salvage to matter across attempts, such as a minimal payout/progression decision or one upgrade/unlock prototype. Keep it narrower than a full economy, inventory screen, save-heavy progression system, enemy system, procedural map pass, or full-map productionization.
