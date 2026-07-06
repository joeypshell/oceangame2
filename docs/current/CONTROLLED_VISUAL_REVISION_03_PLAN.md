# Controlled Visual Revision 03 Plan

Date: 2026-07-06

Issue: #84 `Plan controlled visual revision 03`
Follow-ups: #85, #86, #87

## Selected Target

Controlled Visual Revision 03 should replace the procedural `boat_spawn` entry craft drawing with a named committed boat/entry sprite asset, while preserving the existing source-map `boat_spawn` rectangle, entry cell, extraction behavior, player spawn, collision, camera behavior, oxygen/salvage logic, and all map data.

Target asset:

- `assets/vehicles/boat_spawn_01.png`

Likely supporting generator/review artifact:

- `tools/generate_boat_spawn_sprite.py`
- `references/asset_reviews/boat_spawn_01_review.png`

## Why This Target

The boat is the first production-style entry signal in the default slice and public preview. It also carries an important source-of-truth rule: the player starts at the authored `boat_spawn` entry cell and returns to the authored boat/extraction rectangle.

This target is smaller and less risky than terrain, background depth, lighting, or HUD polish:

- one named top-water entry/extraction visual
- one renderer integration point: the existing `boat_spawn` drawing path
- visible in the default Godot and public Web preview
- no map source changes
- no collision, movement, or gameplay changes

## Affected Assets And Code

Expected affected paths for #85:

- `assets/vehicles/boat_spawn_01.png`
- `tools/generate_boat_spawn_sprite.py`
- `references/asset_reviews/boat_spawn_01_review.png`
- `scripts/world/greybox_world.gd`
- `docs/ASSET_MANIFEST.md`
- production-slice captures and baseline review sheets after the renderer/assets change

The boat visual should be selected by the renderer from the existing `boat_spawn` entity. The map source of truth remains unchanged.

## Untouched Areas

The implementation should not intentionally change:

- `maps/*.greybox.json`
- terrain tile source or tile selection
- terrain/collision generation
- `boat_spawn` rectangle, `entry_x`, or `entry_y` source semantics
- player spawn position, collision shape, movement, camera, or light cone
- salvage, hazards, oxygen, extraction, reset, or route-smoke logic
- accepted baseline directories under `visual_baselines/` until #86 accepts replacement baselines
- default preview map selection
- debug marker meanings or colors
- relay/base extraction visuals for non-boat slices

## Expected Screenshot Differences

Expected differences:

- the top-water entry reads more clearly as a compact surface craft or docked salvage boat
- the hatch/tether cue remains visually tied to the authored entry cell
- the authored extraction rectangle remains legible as the return area
- the player, terrain, props, water, UI, relay/base visuals, and map framing remain unchanged

Unexpected differences:

- changed spawn or extraction position
- changed collision clearance or route-smoke behavior
- changed map topology, camera definitions, or default preview map
- changed terrain, relay/base, props, player, HUD, or gameplay visuals
- accepted baseline replacement during implementation

## Capture And Baseline Expectations

Before changing the boat visual:

```bash
python tools/manage_production_slice_baseline.py compare-all
```

After changing the boat visual and regenerating captures:

```bash
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

Expected baseline differences should be concentrated in `production_slice_01` views that include the top-water entry/boat area. Reference slices 02-04 should remain visually unchanged because they use in-water relay extraction instead of `boat_spawn`.

Keep accepted baselines fixed until #86 explicitly reviews and accepts or rejects the replacement baseline.

## Validation Commands

Use source/render and asset checks to prove the visual pass did not alter map semantics:

```bash
python tools/check_map_parity.py
python tools/check_asset_manifest.py
python tools/check_production_slice_captures.py --fail-on-stale
python tools/manage_production_slice_baseline.py compare-all
```

Run Godot smoke checks appropriate to the default boat/extraction path:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-salvage-loop
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --quit-after 1 --smoke-oxygen-pressure
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --headless --path . --smoke-production-slice-route
```

## Follow-Up Issue Shape

Use the follow-up issues created from this plan:

- #85 implement the controlled boat spawn entry art pass
- #86 decide whether to accept replacement baselines after review
- #87 verify the public Web preview after deployment

Do not combine #85 with relay/base art, terrain tile polish, background depth, HUD changes, map cleanup, movement tuning, or whole-scene regeneration.
