# Visual Baselines

Baseline screenshots are saved here when the project reaches a visual checkpoint.

## 001 - Greybox In Engine

File: `001_greybox_in_engine.png`

Represents:

- first Godot-rendered view of `maps/cave_salvage_test_01.greybox.json`
- greybox terrain, extraction zone, salvage, hazards, player marker, and camera scale
- pre-art baseline before modular terrain assets are generated

This is not an art target. It is a topology and scale reference for later visual work.

Regenerate locally with:

```powershell
& 'C:\Program Files\Godot\Godot_v4.7-stable_win64.exe\Godot_v4.7-stable_win64_console.exe' --path . --quit-after 5 --capture-greybox-screenshot
```

Named current-state camera captures are generated separately under `visual_captures/latest/`.

## Production Slice 01 Accepted

Folder: `production_slice_01_accepted/`

Represents:

- accepted comparison target for the first focused production slice
- four named camera views copied from `visual_captures/production_slice_01/`
- current readable cave terrain, salvage/hazard props, boat entry, preview UI, and capture framing

Accept or refresh this baseline with:

```powershell
python tools/manage_production_slice_baseline.py accept
```

Compare current captures against it with:

```powershell
python tools/manage_production_slice_baseline.py compare
```

The comparison sheet is written to `references/asset_reviews/production_slice_01_visual_baseline_review.png`. Update this baseline only after the production slice is intentionally accepted. For unexpected visual differences, keep this baseline fixed and create a follow-up issue.
