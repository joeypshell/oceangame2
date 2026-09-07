# Living Expedition 07 Source Verification

Date: 2026-09-07. Issue: [#1390](https://github.com/joeypshell/oceangame2/issues/1390).
Contract: [source/state](LIVING_EXPEDITION_07_SOURCE_STATE_CONTRACT.md).

## Implemented Boundary

Production source, review SVG, and placement tests only. The refuge, its passive
group, memory, night choice, and Ground Pin are **not playable yet**. #1391 is
next; #1392-#1397 retain their ordered runtime/review/owner boundaries.

`tools/production_level_01_living_expedition_07.py` owns placement and composes
through `tools/create_production_level_01_map.py`. Immutable ids/relationships
come from the #1389 contract. Generated JSON is never hand-edited.

| Source record | Tile placement |
| --- | --- |
| `deep_cache_burrow_refuge_01` | `(120,77,3,2)`, above existing floor at `y=79` |
| Approach / dig | `(119,77)` / `(121,78)` |
| Passive scallop path | `(119,78)` -> `(120,78)` -> `(121,78)` |
| Ground Pin anchors | `(121,78)`, `(122,78)` |
| Refuge / pin cameras | `(121,77)` / `(123,77)`, zoom `0.7` |

Both cameras are source review anchors, not new player checkpoints. The refuge
sits just below the existing pressure-approach marker, inside the visual-only
dark pocket and eel territory. No zone or terrain was expanded to contain it.

## Clearance And Live Encounter

- Terrain stays at 14,898 solid cells / 376 rectangles. Tests strip only LE07's
  appended records and compare the entire remaining map against the pre-transform
  generator output: LE05 rescue/deposit, LE06 nursery, eel, cache, gear and daily
  guarantees are unchanged.
- Both actual scene collider sizes, diver `26x18` and Marl `32x20`, have swept
  clear approaches and a 6,756px round trip to canonical boat `(91,0)`. The route
  remains clear with all other capability zones excluded. This is geometry
  evidence, not a promise that a round trip plus combat fits every oxygen loadout.
- The Godot source smoke instantiates the shipped world and actors. Existing
  Excavate physically reaches the dig stop envelope. A subsequent collision move
  proves access to a low anchor with escape clearance; it does not implement Pin.
  Marl's current fin gait needs about 24.3px below its center, beyond its collider;
  the review pose reserves 24.5px above the floor. #1393/#1394 must preserve that
  visual clearance when implementing the planted pose.
- From unchanged eel home `(124.5,74.5)` in world-tile centers, the diver lures at
  `(122.5,77.5)`, descends to `(122.5,78.5)` during recovery, then dodges left only
  after the second lunge locks. Two real warning/lunge cycles produce physical
  polygon contact near Marl with **zero diver hits**. The eel returns home normally.
  No hostile teleport, altered phase, enlarged range, territory edit, damage,
  defeat, or hold is used. Every sampled eel visual-body bound remains terrain-clear.
- Sixteen actual daily selections cover rotating materials and both condition
  states while preserving immutable source and the LE05 deposit. LE07 records
  are outside every random material/condition pool, so availability has no seed
  dependency. Fresh runtime event/reset behavior is still #1391 work.
- The source SVG and non-headless scene capture were inspected. The gold box is
  a test-only source boundary, not final refuge art. No baseline was accepted.

## Reproduce

```powershell
python tools/create_production_level_01_map.py
python tools/render_greybox_map.py maps/production_level_01.greybox.json references/greybox/production_level_01.svg
python tools/test_production_level_01_living_expedition_07.py
python tools/test_living_expedition_07_contract.py
python tools/validate_greybox_map.py maps/production_level_01.greybox.json
python tools/check_map_parity.py maps/production_level_01.greybox.json
python tools/audit_progression_graph.py
& $godot --headless --path . --script res://scripts/main/smoke/smoke_living_expedition_07_source.gd
& $godot --path . --script res://scripts/main/smoke/smoke_living_expedition_07_source.gd --capture-source-placement
python tools/check_file_lengths.py
git diff --check
```

Use the local Godot executable for `$godot`; see [local run](tooling/local_run.md).
The optional capture writes ignored `tmp/living_expedition_07/source_contact.png`.
Do not run capture headless, commit its `.import`, or treat it as baseline acceptance.
`SCRIPT ERROR` / `ERROR:` always fail verification, even with exit code zero.

Two generator runs produced identical JSON SHA256:
`09d52effa231709c49616e42dd4e522bb1fdba538274ae08ba43b603c12f7b0b`.
Six source tests and twelve schema/graph fixtures passed. Progression audit passes
with 171 nodes / 691 edges; new action/event labels remain `[proposed]`.
CI source validation and core smoke include the two focused placement tests.
The full local release suite is deferred to #1395, not repeated for source authoring.
