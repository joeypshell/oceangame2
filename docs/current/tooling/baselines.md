# Baselines And Review Sheets

List configured production-slice baseline targets:

```bash
python tools/manage_production_slice_baseline.py --list-slices
```

Accept the current production-slice captures as the named visual baseline:

```bash
python tools/manage_production_slice_baseline.py accept
python tools/manage_production_slice_baseline.py --slice production_slice_02 accept
python tools/manage_production_slice_baseline.py --slice production_slice_03 accept
python tools/manage_production_slice_baseline.py --slice production_slice_04 accept
```

The default command remains `production_slice_01` for backward compatibility. Slice-specific acceptance copies the configured captures into `visual_baselines/<slice>_accepted/` and writes a small manifest. Only run `accept` after that slice's current visuals are intentionally accepted as the comparison target.

The accept command only manages the configured PNG view files and `manifest.json`. It removes generated Godot/OS sidecars such as `*.import` from the target accepted-baseline directory and fails if other unexpected files are present. To clean or verify accepted baseline directories without accepting new images:

```bash
python tools/manage_production_slice_baseline.py clean-generated --all-slices
python tools/manage_production_slice_baseline.py check-clean --all-slices
```

Render the accepted-baseline comparison sheet:

```bash
python tools/manage_production_slice_baseline.py compare
python tools/manage_production_slice_baseline.py --slice production_slice_02 compare
python tools/manage_production_slice_baseline.py --slice production_slice_03 compare
python tools/manage_production_slice_baseline.py --slice production_slice_04 compare
```

This writes the slice-specific review sheet under `references/asset_reviews/`, showing accepted baseline, current capture, and difference columns for the configured views. If the difference column reveals an unexpected visual change, keep the baseline fixed and create a follow-up issue.

Render all configured accepted-baseline comparison sheets with one command:

```bash
python tools/manage_production_slice_baseline.py compare-all
```

This compares `production_slice_01` through `production_slice_04` using the committed baseline-manager config. It fails if a configured current capture or accepted baseline view is missing or unreadable, and it does not accept or overwrite baseline PNGs.

For a future slice that has current captures but no accepted baseline yet, compare against the current capture directory as a tooling sanity check without accepting anything:

```powershell
python tools/manage_production_slice_baseline.py --slice production_slice_02 --baseline-dir visual_captures/production_slice_02 compare --output "$env:TEMP\production_slice_tooling_sanity_review.png"
```

Generate the production slice source/render/collision review sheet:

```bash
python tools/render_map_review.py maps/production_slice_01.greybox.json references/greybox/production_slice_01_source_render_collision_review.png --godot-capture visual_captures/production_slice_01/production_slice_overview.png
```

This writes `references/greybox/production_slice_01_source_render_collision_review.png`, comparing authored JSON topology, expected collision rectangles from the JSON terrain source, and the Godot rendered overview capture. Run `python tools/check_map_parity.py maps/production_slice_01.greybox.json` alongside it to verify Godot runtime terrain/collision cells match the source.

Generate the second production slice source/render/collision review sheet:

```bash
python tools/render_map_review.py maps/production_slice_02.greybox.json references/greybox/production_slice_02_source_render_collision_review.png --godot-capture visual_captures/production_slice_02/production_slice_02_overview.png
```

This writes `references/greybox/production_slice_02_source_render_collision_review.png`, comparing authored JSON topology, expected collision rectangles from the JSON terrain source, and the Godot rendered overview capture. Run `python tools/check_map_parity.py maps/production_slice_02.greybox.json` alongside it to verify Godot runtime terrain/collision cells match the source.

Generate the third production slice source/render/collision review sheet:

```bash
python tools/render_map_review.py maps/production_slice_03.greybox.json references/greybox/production_slice_03_source_render_collision_review.png --godot-capture visual_captures/production_slice_03/production_slice_03_overview.png
```

This writes `references/greybox/production_slice_03_source_render_collision_review.png`, comparing authored JSON topology, expected collision rectangles from the JSON terrain source, and the Godot rendered overview capture. Run `python tools/check_map_parity.py maps/production_slice_03.greybox.json` alongside it to verify Godot runtime terrain/collision cells match the source.

Generate the fourth production slice source/render/collision review sheet:

```bash
python tools/render_map_review.py maps/production_slice_04.greybox.json references/greybox/production_slice_04_source_render_collision_review.png --godot-capture visual_captures/production_slice_04/production_slice_04_overview.png
```

This writes `references/greybox/production_slice_04_source_render_collision_review.png`, comparing authored JSON topology, expected collision rectangles from the JSON terrain source, and the Godot rendered overview capture. Run `python tools/check_map_parity.py maps/production_slice_04.greybox.json` alongside it to verify Godot runtime terrain/collision cells match the source.
