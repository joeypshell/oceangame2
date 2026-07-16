# Validation And Map Source Tools

Validate map reachability:

```bash
python tools/validate_greybox_map.py maps/cave_salvage_test_01.greybox.json
python tools/validate_greybox_map.py maps/cave_salvage_organic_01.greybox.json
python tools/validate_greybox_map.py maps/cave_tileset_test_01.greybox.json
python tools/validate_greybox_map.py maps/full_cave_sketch_01.greybox.json
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
python tools/validate_greybox_map.py maps/production_slice_03.greybox.json
python tools/validate_greybox_map.py maps/production_slice_04.greybox.json
```

Check that Godot's runtime terrain and collision match the authored JSON source:

```bash
python tools/check_map_parity.py
```

Check one map only:

```bash
python tools/check_map_parity.py maps/cave_salvage_organic_01.greybox.json
```

Validate committed asset-manifest paths:

```bash
python tools/check_asset_manifest.py
```

The checker reads table rows in `docs/ASSET_MANIFEST.md` whose asset path is the first column and whose status is `draft`, `approved`, or `locked`. It fails only for missing files under committed asset folders such as `assets/` and `references/asset_reviews/`, so planned future assets and prose examples do not block the check.

Audit agent-friendly file lengths:

```bash
python tools/check_file_lengths.py
```

This treats 500 lines as the default target and growth guard for human-authored files. It fails on new non-allowlisted source/docs/config files over that target and reports actionable temporary debt, documented cohesive-owner exceptions, and generated map data separately. A cohesive-owner exception must state why retaining one owner is safer; do not split Godot state or lifecycle code solely to satisfy the number. Keep new tooling docs small enough that the audit does not need an exception.

Audit the cross-map progression graph whenever changing maps, objectives, connectors, rewards, upgrades, discoveries, projects, gates, enemies, or guarded payoffs:

```bash
python tools/audit_progression_graph.py
```

Expansion 13 source changes must also run `python tools/test_validate_southeast_wreck_return.py` and `python tools/validate_southeast_wreck_return.py maps/production_level_01.greybox.json`; the focused validator enforces the one-way recorder/survey dependency, unchanged terrain, pressure crossing, player-footprint return, and base/optional oxygen margins.

The command derives the Expansion 01-07 dependency graph from production map JSON plus the minimal runtime-only `config/progression_contract.json`. It fails on stale generated constants/review docs, unresolved references, hard cycles, self-gated funding/materials, guard/counter inversions, and unreachable mandatory stages. Use `--write` only after intentional source changes to refresh `scripts/main/progression_contract.gd` and `docs/current/PROGRESSION_GRAPH.md`. The standalone `Progression audit` GitHub check runs the focused fixtures and audit on every pull request update and every push to `main`, without downloading Godot.

Run the Simple Diver Game release-candidate validation gates:

```bash
python tools/run_release_candidate_validation.py
python tools/run_release_candidate_validation.py --list
python tools/run_release_candidate_validation.py --skip-godot
```

The runner composes existing checks in release-candidate order: file-length audit, whitespace, progression graph fixtures/audit, asset manifest, committed capture inventory, accepted-baseline directory cleanliness, map validation, headless import/startup, Godot map parity, and selected core smokes. It skips Godot-backed gates only when Godot is unavailable or `--skip-godot` is passed; use `--require-godot` for a strict release gate.

Regenerate the SVG preview from source data:

```bash
python tools/render_greybox_map.py maps/cave_salvage_test_01.greybox.json references/greybox/cave_salvage_test_01.svg
python tools/render_greybox_map.py maps/cave_salvage_organic_01.greybox.json references/greybox/cave_salvage_organic_01.svg
python tools/render_greybox_map.py maps/cave_tileset_test_01.greybox.json references/greybox/cave_tileset_test_01.svg
python tools/render_greybox_map.py maps/full_cave_sketch_01.greybox.json references/greybox/full_cave_sketch_01.svg
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/render_greybox_map.py maps/production_slice_02.greybox.json references/greybox/production_slice_02.svg
python tools/render_greybox_map.py maps/production_slice_03.greybox.json references/greybox/production_slice_03.svg
python tools/render_greybox_map.py maps/production_slice_04.greybox.json references/greybox/production_slice_04.svg
```

Regenerate the supplied full-map sketch topology draft:

```bash
python tools/convert_full_cave_sketch_map.py
python tools/render_greybox_map.py maps/full_cave_sketch_01.greybox.json references/greybox/full_cave_sketch_01.svg
python tools/validate_greybox_map.py maps/full_cave_sketch_01.greybox.json
```

This draft converts `references/source_maps/full_cave_sketch_01.png` into topology only. White source regions become open water, gray/black source regions become solid terrain/collision, icons are ignored by filling small non-white holes, and a `boat_spawn` entity marks the top-water entry/extraction point.

The converter also writes `references/greybox/full_cave_sketch_01_conversion_review.png`, a side-by-side review sheet showing the source thumbnail, generated open/solid tiles, and source-plus-generated overlay. It prints and embeds conversion stats such as open tiles, filled icon pixels, open components, thin corridor tiles, edge transitions, and open boundary tiles.

Regenerate the first focused production slice:

```bash
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
```

This slice is generated from `maps/full_cave_sketch_01.greybox.json` using bounds `x=58, y=0, w=72, h=84`. It keeps the top-water shaft open for `boat_spawn`, seals left/right/bottom crop edges, and fills unreachable open pockets created by the high-fidelity sketch conversion.

Regenerate the second focused production slice:

```bash
python tools/create_production_slice_02_map.py
python tools/render_greybox_map.py maps/production_slice_02.greybox.json references/greybox/production_slice_02.svg
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
python tools/check_map_parity.py maps/production_slice_02.greybox.json
```

This slice is generated from `maps/full_cave_sketch_01.greybox.json` using bounds `x=88, y=78, w=66, h=72`. It is a later-game destination/connector candidate with an in-water `spawn` and `base` extraction zone rather than a top-water boat.

Regenerate the third focused production slice:

```bash
python tools/create_production_slice_03_map.py
python tools/render_greybox_map.py maps/production_slice_03.greybox.json references/greybox/production_slice_03.svg
python tools/validate_greybox_map.py maps/production_slice_03.greybox.json
python tools/check_map_parity.py maps/production_slice_03.greybox.json
```

This slice is generated from `maps/full_cave_sketch_01.greybox.json` using bounds `x=0, y=8, w=76, h=82`. It is an upper-left connector/landmark room-cluster candidate with an in-water `spawn` and `base` extraction zone near the east-side relay context.

Regenerate the fourth focused production slice:

```bash
python tools/create_production_slice_04_map.py
python tools/render_greybox_map.py maps/production_slice_04.greybox.json references/greybox/production_slice_04.svg
python tools/validate_greybox_map.py maps/production_slice_04.greybox.json
python tools/check_map_parity.py maps/production_slice_04.greybox.json
```

This slice is generated from `maps/full_cave_sketch_01.greybox.json` using bounds `x=0, y=86, w=88, h=50`. It is a lower-left connector/return-loop candidate with an in-water `spawn` and `base` relay extraction zone near the east-side connector context.
