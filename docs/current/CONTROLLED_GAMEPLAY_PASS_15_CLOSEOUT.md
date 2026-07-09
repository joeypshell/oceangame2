# Controlled Gameplay Pass 15 Closeout

Date: 2026-07-08

Issue: #307 `Add Pass 15 closeout and next-step evaluation`
Implementation issues: #298-#306

## Result

Controlled Gameplay Pass 15 is complete.

The pass added one compact objective follow-through cue for the existing `deep_cache_route_objective`. After the player leaves the boat and reaches the first deep-cache route step, the overlay can show:

```text
Objective route: Lower loop
```

This bridges the Pass 14 start cue into the Pass 13 route objective without adding a quest log, objective selector, new reward, terrain change, or map-scale expansion.

## Implemented Behavior

- `deep_cache_first_step_cue` is source-authored in `production_slice_01`.
- The marker references `deep_cache_route_objective`, target `salvage_lower_loop`, and route context `deep_cache_commitment`.
- The cue appears only while the active run is inside the marker and the first required target is not held or banked.
- The cue hides at the boat/extraction area, after objective progress, after run completion, and after run failure.
- Existing stronger feedback still wins: pickup, cargo-full, hazard, oxygen, rest-pocket, timed-salvage, result, and completion states are unchanged.

## Source And Text Decisions

Pass 15 kept the source-of-truth path intact:

```text
tools/create_production_slice_map.py
maps/production_slice_01.greybox.json
references/greybox/production_slice_01.svg
```

The marker contract is documented in:

```text
docs/current/CONTROLLED_GAMEPLAY_PASS_15_OBJECTIVE_STEP_CUE_CONTRACT.md
```

Validation now checks the narrow objective-step cue metadata instead of relying on runtime-only coordinates.

## Verification

Pass 15 added deterministic smoke coverage:

```text
--smoke-pass-15-objective-follow-through
```

The smoke verifies the cue appears at `deep_cache_first_step_cue`, stays hidden at the extraction start, hides after the first objective target is held or banked, and does not leave stale state after completion or failure.

Relevant verification across the pass included:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
python tools/check_file_lengths.py
git diff --check
```

Runtime and regression smokes included the Pass 15 smoke plus existing objective, route, timed salvage, cargo, hazard, and oxygen checks.

## Capture And Visual Decision

Focused review capture:

```text
visual_captures/pass_15_objective_follow_through/production_slice_01_objective_follow_through.png
```

Visual decision:

```text
docs/current/PASS_15_OBJECTIVE_FOLLOW_THROUGH_VISUAL_BASELINE_DECISION.md
```

No production-slice baseline changes were accepted. Normal slice 01-04 captures matched accepted baselines, and the focused Pass 15 capture remains a review artifact only.

## Web Preview

Web verification:

```text
docs/current/PASS_15_OBJECTIVE_FOLLOW_THROUGH_WEB_PREVIEW_VERIFICATION.md
```

The public preview was verified against deployed runtime commit:

```text
263dbaf245cc37b29128d45a4dd691a10c9fedc8
```

The browser check matched `build_info.json`, initialized the Godot canvas, and reported no missing resources, Godot `SCRIPT ERROR`, or Godot `ERROR:` messages.

## Stable Areas

Pass 15 did not change:

- terrain topology or collision
- spawn, boat, extraction, camera tests, or route scale
- salvage placement, salvage score, cargo capacity, or banking semantics
- timed-salvage duration, progress, cancellation, or completion behavior
- oxygen drain, refill, rest-pocket cap, failure, or result behavior
- hazard warning, penalty, reset, or player tint behavior
- accepted visual baselines
- #52/#53 deferred slice-03 polish status

## Remaining Gaps

Pass 15 improves objective follow-through, but it is still a small cue pass. The project should not keep adding narrow overlay labels unless they directly support the finished simple diver game.

Still deferred:

- #52 `Tune production slice 03 camera framing`
- #53 `Clean production slice 03 topology artifacts in source generator`

Keep them deferred unless slice-03 presentation becomes the selected goal.

## Next Recommendation

Use `docs/current/SIMPLE_DIVER_GAME_ROADMAP.md` as the north star and create the next actionable batch from Milestone 02 or Milestone 03.

Recommended next direction:

```text
Milestone 02: Core Diver Loop Vertical Slice
```

That batch should make the current default dive feel more like a complete playable run: clearer start, middle, return, completion, and retry rhythm. If the team wants a new mechanic instead, choose one tightly scoped Milestone 03 salvage-tool interaction rather than another objective-label pass.
