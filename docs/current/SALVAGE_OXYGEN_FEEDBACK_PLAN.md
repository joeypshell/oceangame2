# Salvage/Oxygen Feedback Plan

Date: 2026-07-06

Issue: #105 `Plan salvage and oxygen feedback readability pass`

## Decision

The next controlled prototype target is the existing review overlay feedback for salvage and oxygen.

The pass should make the current loop easier to read while preserving the existing mechanics: collect salvage, carry held salvage, return to extraction, complete/reset the run, drain/refill oxygen, and surface/drop held salvage on oxygen depletion or hazard hit.

## Single Target

Improve the compact status overlay so it more clearly communicates:

- banked salvage versus held salvage
- when the player should return to extraction
- low oxygen pressure
- oxygen depletion, hazard reset, and run-complete moments

This is a readability pass for already-existing state. It is not a new gameplay-system pass.

## Affected Areas

- `scripts/main/main.gd`
  - `_create_review_overlay()`
  - `_update_status_label()`
  - existing `_last_status_note` strings if needed
- `docs/current/PROJECT_CONTEXT.md`
- screenshot/capture review outputs only if #106 creates or refreshes local review captures

No new asset is expected. If #106 adds a committed image asset unexpectedly, it must update `docs/ASSET_MANIFEST.md`.

## Untouched Areas

- `maps/*.greybox.json`
- terrain/collision generation
- player movement constants and collision shape
- player, boat, prop, terrain, and background art
- production-slice route design and authored camera tests
- salvage collection radius and entity placement
- hazard and oxygen mechanics
- extraction semantics and reset behavior
- accepted visual baselines until #107 explicitly reviews and accepts any changed captures

## Expected Screenshot Differences

Expected differences:

- The top-left review overlay may become slightly clearer or taller.
- Text may be reorganized to distinguish banked, held, oxygen, and prompt/state.
- Low oxygen and reset/failure prompts may read more clearly.

Unchanged:

- cave terrain, water, background, player, boat, props, salvage/hazard world positions, camera framing, and map topology.

## Unacceptable Drift

- Any map source, route, collision, or entity-placement change.
- Any new health, inventory, economy, upgrade, enemy, stamina, or salvage-type system.
- Any baseline replacement inside the implementation issue.
- Any overlay text that wraps awkwardly or obscures the playable area more than the current compact review panel.
- Any change that makes oxygen, hazard, salvage banking, run completion, or reset behave differently from the current smoke-tested semantics.

## Follow-Up Issues

- #106 `Implement salvage and oxygen feedback polish`
- #107 `Review and accept feedback polish baselines`
- #108 `Verify public Web preview after feedback polish`

## Verification Plan

The implementation chain should use:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-interaction
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-player-facing
& 'C:\Program Files\Git\cmd\git.exe' diff --check
```

If screenshots or accepted baselines change, #107 should run:

```powershell
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```
