# Controlled Gameplay Pass 03 Plan

Date: 2026-07-06

## Decision

Controlled Gameplay Pass 03 should make the prototype feel more like an expedition instead of a simple pickup test. The next batch should add visible payoff, a reason to return to the boat, and one more authored decision in the default production slice while preserving the source-of-truth map workflow.

This pass should stay small. It should not add a full economy, upgrades, enemies, inventory screens, procedural maps, or whole-scene art replacement.

## Target Experience

The player should be able to:

1. Leave the boat with oxygen pressure already understood.
2. Collect salvage with distinct point value.
3. Feel a light cargo-capacity constraint that makes returning meaningful.
4. Choose between a safer local pickup and a deeper/harder payoff route.
5. Return to extraction and see a compact run result.
6. Restart cleanly and try for a better expedition.

## Meaningful Change Filter

Issues in this batch should create at least one of:

- pressure
- payoff
- remembered-place progress
- route choice
- a reason to try another expedition

Pure polish, broad refactors, and optional slice-03 cleanup stay out of the active path unless they directly support that playable loop.

## Planned Issue Batch

- #120 `Add scored salvage values and banked run score`
- #121 `Add cargo capacity pressure to held salvage`
- #122 `Add deterministic scoring and cargo smoke checks`
- #123 `Add compact expedition result panel after extraction`
- #124 `Improve reset and retry flow after completion or oxygen failure`
- #125 `Author an additional route-choice pickup in production slice 01`
- #126 `Validate expanded slice 01 route choice and return`
- #127 `Review and accept expedition-loop visual baselines`
- #128 `Verify public Web preview after expedition-loop pass`

## Source-Of-Truth Boundaries

- Map/topology changes must start in `tools/create_production_slice_map.py` or the JSON source, then regenerate `maps/production_slice_01.greybox.json` and `references/greybox/production_slice_01.svg`.
- Collision must remain renderer/source-derived.
- Runtime scoring and cargo behavior should read authored salvage metadata rather than hard-coding per-node scene edits.
- Visual changes should be small overlays or named asset variants, not whole-scene regeneration.

## Verification Pattern

Use focused checks as the pass lands:

```powershell
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py
python tools/check_asset_manifest.py
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-route-choice
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

Add more specific smoke flags as scoring, cargo capacity, and run summary behavior become deterministic.
