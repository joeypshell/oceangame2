# Production Slice 02 Visual Baseline Decision

Date: 2026-07-05

Issue: #43 `Decide production slice 02 visual baseline`

## Decision

Do not accept the current `production_slice_02` captures as the visual baseline yet.

The current normal and debug captures are valid review artifacts for topology, route layout, entity placement, and source/render comparison, but they should not become the locked comparison target for future visual changes.

## Rationale

- The five normal captures render correctly and show the intended later-game relay route, main chamber, lower terminal, and return path.
- The debug captures confirm the source grid and entity markers are visible for review.
- The slice already has source/render/collision parity and route smoke coverage from earlier issues, so this is not a topology or collision blocker.
- The capture framing still needs a focused pass before the images are useful as a long-lived visual baseline. Several views include avoidable crop edges or gray outside-map space, and the overview does not yet read as a polished baseline sheet.
- The relay extraction area still reads like a placeholder rectangle rather than an intentional in-world relay/sub extraction visual, so accepting it now would lock a known temporary visual.

## Follow-Up Blockers

The original blockers were tracked as focused issues:

- #44 `Tune production slice 02 camera framing` - resolved by tuning the five authored camera tests and regenerating normal/debug captures.
- #45 `Add readable relay extraction visual for production slice 02`

After #45 is resolved, regenerate the normal and debug captures, then accept a new slice 02 baseline by extending the baseline accept/compare workflow for `production_slice_02`.

## Verification

Reviewed fresh captures from:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-map
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 20 --capture-production-slice-02-debug-map
```

Both capture passes wrote the expected five `production_slice_02` views.
