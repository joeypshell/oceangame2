# OceanGame Expansion 09 Closeout

Date: 2026-07-13

Issues: #857-#865, with player-gate correction #875 via PR #876

Milestone: OceanGame Expansion 09 `Contiguous Full-Level Foundation`

## Decision

**GO.** The player approved the contiguous full level after the candidate review,
the boat offload correction, and a clean-browser input check. `production_level_01`
is now the normal editor, local, and public Web default. The promotion merged in
[PR #877](https://github.com/joeypshell/oceangame2/pull/877) at
`e825c88ece33eefde14acd5af892f2c5bf6f6d3c`.

This GO answers the Expansion 09 exit question: the boat can launch into one
continuous authored cave, representative distant sectors can be reached and
returned from without teleport travel, and the source/runtime evidence is strong
enough to use this level as the next expansion foundation.

## Delivered Foundation

- `tools/create_production_level_01_map.py` generates a separate 158x161-tile
  production source from `full_cave_sketch_01` plus the transformed proven
  slice-01 gameplay overlay.
- The default level keeps one map id and continuous water space through the
  upper-left, lower-left, and lower-right sectors.
- The canonical top-water boat remains the spawn, cargo offload, profile commit,
  health refill, voluntary night, and repeated-sortie owner.
- Normal full-level travel uses swimming and capability gates, with no connector,
  teleport, map-menu, or current-stabilizer entry requirement.
- Slices 01-04 remain unchanged and explicitly selectable as provenance and
  regression fixtures.

## Player And Visual Evidence

- #864 records the explicit player GO after direct play on the exact candidate.
- #875, merged through PR #876, restored canonical boat material offload on the transformed map
  without changing its JSON, terrain, collision, or reviewed captures.
- Fourteen reviewed desktop/mobile views are accepted at
  `visual_baselines/production_level_01_accepted/`.
- The final comparison sheet has black difference panels for all 14 views.
- All 21 accepted slice views remain unchanged; `visual_baselines/.gdignore`
  prevents Godot from creating review-only `.import` sidecars.

## Technical Evidence

- Regeneration caused no tracked map/SVG drift.
- Reachability and parity passed with 14,898 terrain cells and 376 collision
  rectangles.
- Unflagged `--measure-map-runtime` loaded `production_level_01` with full camera
  bounds and practical startup/frame measurements.
- `--smoke-expansion-09-full-level-journey` completed three continuous,
  collision-active boat-return sorties, including second-return material offload
  and a valid night request.
- The release runner's map and gameplay gates passed. Its remaining baseline
  hygiene finding was fixed with `.gdignore`, then retested after a fresh Godot
  import with zero baseline sidecars.
- PR #877 passed `Headless smoke` and `Progression audit`; post-merge runs also
  passed for the exact promotion SHA.
- [Godot Web Export run 29279390276](https://github.com/joeypshell/oceangame2/actions/runs/29279390276)
  built and deployed the exact promotion SHA.
- Public browser verification matched `build_info.json`, initialized desktop,
  wide, and mobile canvases, passed touch alignment, loaded
  `production_level_01` at the root, retained explicit `production_slice_01`
  review selection, and emitted no Godot errors.

## Stable Boundaries

- Map topology, collision, spawn, extraction, entities, gates, and camera tests
  remain source-generated.
- Existing slice baselines, terrain art, player, boat, props, HUD, mobile controls,
  and Expansion 01-08 behavior were not intentionally changed by promotion.
- Historical slice connectors remain regression surfaces, not the default
  full-level traversal model.

## Deferred And Next

- #52/#53 remain deferred optional slice-03 presentation polish.
- Teleport travel, connector-based normal expansion, current-stabilizer entry,
  pressure progression, and new regional content remain outside this milestone.
- No next implementation milestone is selected in this closeout. The next
  planning pass should evaluate the promoted level in normal play and choose one
  bounded capability-gated or regional-content improvement that creates a clear
  reason to explore and return, while preserving continuous authored geography.
- Orientation, sparse-sector readability, broad-camera diver scale, and dense
  mobile HUD concerns remain concrete review inputs, not permission for a broad
  terrain or UI rewrite.
