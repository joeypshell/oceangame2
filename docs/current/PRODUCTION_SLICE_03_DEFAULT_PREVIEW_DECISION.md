# Production Slice 03 Default Preview Decision

Date: 2026-07-06

Issue: #58 `Decide whether production slice 03 should affect the default preview`

## Decision

Keep `production_slice_01` as the default preview map.

Keep `production_slice_03` as a validated reference slice with its own local launch path, route smoke, captures, debug captures, source/render/collision review, and accepted visual baseline. Do not promote it to the default Godot or public web preview in this pass.

## Rationale

- Slice 01 is still the clearest public-facing first-area proof: it has a top-water `boat_spawn`, direct boat/extraction fiction, and the simplest collect-return loop for someone opening the preview cold.
- Slice 03 has a different job. It proves compact connector and landmark-room topology, an in-water relay entry, dense stacked rooms, and high-fidelity full-sketch conversion behavior.
- Promoting slice 03 would make the default preview feel like a mid-route connector instead of an introductory salvage area.
- Slice 03 now has its own accepted baseline in `visual_baselines/production_slice_03_accepted/`, so it can be protected as a reference without becoming the default.
- The project already has explicit local launch commands for slice 03. A dev-only map selector or web preview map selector should be handled as its own scoped implementation rather than hidden inside a default-map decision.

## Current Access

Run slice 03 locally:

```powershell
.\tools\open_godot_project.ps1 -Run -ProductionSlice3Map
```

Or from Command Prompt:

```cmd
run-production-slice-03.cmd
```

Opening the Godot editor and pressing Play without a `--map-path` argument should continue to load `production_slice_01`.

## Follow-Up Guidance

- Keep #57 as the right implementation path if local review needs a dev-only map selector.
- Keep #59 unblocked for selecting a fourth production slice now that slice-03 baseline/default-preview decisions are recorded.
- Treat any future default-preview change as a separate implementation pass with launch smoke, route smoke, capture checks, docs, and web-preview expectation updates.

## Verification

Documentation-only decision. Confirmed `scripts/main/main.gd` still sets:

```gdscript
const DEFAULT_MAP_PATH := "res://maps/production_slice_01.greybox.json"
```

Final verification:

```powershell
git diff --check
```
