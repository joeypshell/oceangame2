# Controlled Visual Revision 01 Plan

Date: 2026-07-06

Issue: #69 `Plan first controlled visual revision target`
Implementation follow-up: #70 `Implement controlled sprite prop pass for salvage and hazards`

## Selected Target

The first controlled visual revision should replace the procedural salvage and hazard prop drawings with named committed sprite assets.

Target prop kinds:

- Salvage: `crate`, `wreck_fragment`, `relic`
- Hazards: `mine`, `jellyfish`

## Why This Target

This is the right first visual-revision test because the props are visible across all accepted production slices, but they do not define terrain topology, collision, route layout, extraction, oxygen, or player movement.

It tests the exact workflow the project needs next:

- edit or add individual named assets
- keep JSON maps as the source of truth
- keep debug/review markers separate from normal art
- compare the result against accepted baselines
- avoid whole-scene regeneration

## Affected Assets And Code

Expected affected paths for #70:

- `assets/props/`
- `scripts/world/greybox_world.gd`
- `docs/ASSET_MANIFEST.md`
- production-slice capture folders after the renderer/assets change
- production-slice visual baseline review sheets after comparison

The runtime should continue to choose prop art from the existing JSON `kind` values.

## Untouched Areas

#70 should not intentionally change:

- `maps/*.greybox.json`
- terrain tile source or tile selection
- collision generation
- spawn, extraction, salvage, hazard, oxygen, or reset behavior
- route-smoke logic
- accepted baseline directories under `visual_baselines/`
- default preview map selection
- debug marker meanings or colors

## Expected Screenshot Differences

Expected differences:

- salvage objects read more like distinct crates, relics, or wreck fragments
- hazards read more like mines or jellyfish while keeping the existing red/magenta warning role
- debug captures still show yellow salvage diamonds and red hazard squares over the normal sprite art

Unexpected differences:

- changed terrain shape, collision, route openings, map framing, or player spawn
- changed salvage or hazard placement
- accepted baseline replacement without review
- unrelated terrain, water, boat, relay, player, or UI art changes

## Baseline Comparison Expectations

Before changing visuals:

```bash
python tools/manage_production_slice_baseline.py compare-all
```

After changing visuals and regenerating captures:

```bash
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

The resulting review sheets should show differences concentrated on salvage and hazard props. Keep accepted baselines fixed until the new sprite prop pass is explicitly reviewed and accepted.

## Validation Commands

Use the normal source/render checks to prove the visual pass did not alter map semantics:

```bash
python tools/check_map_parity.py
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

Run Godot smoke checks appropriate to the changed renderer path:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-hazard-interaction
```

## Follow-Up

Implement the visual pass under #70 as a separate scoped issue. Do not combine #70 with slice selection, map cleanup, player art, water/background art, default preview changes, or accepted-baseline replacement.
