# Production Slice 02 Visual Baseline Decision

Date: 2026-07-05
Updated: 2026-07-06

Issue: #43 `Decide production slice 02 visual baseline`
Update issue: #64 `Decide and accept production slice 02 visual baseline`

## Decision

Do not accept the current `production_slice_02` captures as the visual baseline yet.

The current normal and debug captures are valid review artifacts for topology, route layout, entity placement, and source/render comparison, but they should not become the locked comparison target for future visual changes.

## 2026-07-06 Update

Accept the current `production_slice_02` normal captures as the visual baseline for the slice.

This supersedes the current operational status of the original deferral, while preserving the historical reason #43 did not accept the baseline on 2026-07-05. The original blockers were resolved by #44 and #45, and the multi-slice baseline workflow now supports `production_slice_02` directly.

Baseline artifacts:

- Baseline directory: `visual_baselines/production_slice_02_accepted/`
- Review sheet: `references/asset_reviews/production_slice_02_visual_baseline_review.png`
- Source captures: `visual_captures/production_slice_02/`
- Debug review captures: `visual_captures/production_slice_02_debug/`

If future camera framing, terrain source cleanup, relay art, or terrain art changes intentionally alter these views, compare against this baseline first, then accept a replacement baseline only after that change is reviewed.

## Rationale

- The five normal captures render correctly and show the intended later-game relay route, main chamber, lower terminal, and return path.
- The debug captures confirm the source grid and entity markers are visible for review.
- The slice already has source/render/collision parity and route smoke coverage from earlier issues, so this is not a topology or collision blocker.
- The capture framing still needs a focused pass before the images are useful as a long-lived visual baseline. Several views include avoidable crop edges or gray outside-map space, and the overview does not yet read as a polished baseline sheet.
- The relay extraction area still reads like a placeholder rectangle rather than an intentional in-world relay/sub extraction visual, so accepting it now would lock a known temporary visual.

## Follow-Up Blockers

The original blockers were tracked as focused issues:

- #44 `Tune production slice 02 camera framing` - resolved by tuning the five authored camera tests and regenerating normal/debug captures.
- #45 `Add readable relay extraction visual for production slice 02` - resolved by rendering in-water base zones as relay/sub return visuals with a spawn cue.

Both original blockers are resolved. The new slice 02 baseline was accepted under #64 after running the slice-specific accept/compare workflow for `production_slice_02`.

## Verification

Reviewed fresh captures from:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-debug-map
```

Both capture passes wrote the expected five `production_slice_02` views.

The #64 acceptance pass also verified:

```powershell
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02
python tools/check_camera_captures.py maps/production_slice_02.greybox.json visual_captures/production_slice_02_debug
python tools/manage_production_slice_baseline.py --slice production_slice_02 accept
python tools/manage_production_slice_baseline.py --slice production_slice_02 compare
```
