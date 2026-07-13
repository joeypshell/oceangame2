# OceanGame Expansion 09 Plan

Date: 2026-07-13

Corrective planning issue: #855

Supersedes: #852 connector-first regional plan

Milestone: OceanGame Expansion 09 `Contiguous Full-Level Foundation`

Status: Complete with player GO and default promotion. See `docs/current/OCEANGAME_EXPANSION_09_CLOSEOUT.md`.

## Decision

Expansion 09 will put the complete supplied cave topology into one playable production-level candidate before adding teleport, connector-based world travel, the current stabilizer as an access requirement, or new pressure progression.

The candidate will be a separately named generated map:

```text
maps/production_level_01.greybox.json
```

It will derive from `maps/full_cave_sketch_01.greybox.json`, preserve one continuous water space, and carry the proven `production_slice_01` gameplay into full-map coordinates through source-owned transformation. The player must be able to leave the top boat, swim through former slice boundaries, and return to the same boat without pressing `E`, changing maps, or teleporting.

The implementation kept `production_slice_01` as the default until the candidate passed source, clearance, route, camera, performance, visual, player, and Web review. The previous Drowned Relay Terminal, relay refuge, stabilizer entry, pressure survey, pressure lining, and connector journey were not part of this milestone.

## Why This Is The Next Meaningful Change

The current game has enough loop and progression systems to test a larger world, but its normal play space still feels like a focused slice. The player has explicitly selected map scale and continuous exploration as the next priority.

This pass is meaningful only if it changes the player's sense of place:

- the cave reads as one level rather than a set of destinations
- distant areas are reached by swimming through remembered geography
- the boat remains the physical start, bank, and return point
- the production pipeline can own the full topology without manual scene repair
- later capabilities can be planned against one real map

This pass does not need another upgrade, enemy, resource chain, or interaction to prove that change.

## Confirmed Source Facts

The existing full-sketch conversion currently provides:

- `158 x 161` tiles
- one connected open-water component containing 10,530 cells
- 14,908 solid cells represented by 364 collision rectangles
- a top-water boat entry at source coordinate `(91, 0)` with width 8
- 27 open boundary cells requiring intentional production treatment
- 459 thin-corridor cells that make cell-only reachability insufficient

The four production slices are cropped views of this source. Their offsets are useful provenance, but their sealed crop edges are artificial level boundaries. They must not be stitched together.

`production_slice_01` uses source bounds `x=58, y=0, w=72, h=84`. Its local gameplay coordinates therefore transform to full-map coordinates by adding `(58, 0)`. This transform must be explicit and testable rather than repeated by hand.

## Target Experience

The first full-level review journey should:

1. Start at the existing top-water boat.
2. Play the proven slice-01 opening and progression surface in its original full-map location.
3. Swim continuously into representative upper-left, lower-left, and lower-right cave areas.
4. Show no connector prompt, transition overlay, map selector, or loading event during that journey.
5. Keep the same map id, expedition day, oxygen, health, cargo, and player state throughout.
6. Return through the cave to the same top boat and use normal banking/end-day behavior.

The outer regions may be terrain-first in this milestone. They need enough source-authored route markers and camera tests to validate traversal and orientation, but they do not need new regional progression content yet.

## Source Of Truth Boundaries

### Full Topology

- `references/source_maps/full_cave_sketch_01.png` remains the human reference image.
- `tools/convert_full_cave_sketch_map.py` remains the reproducible image-to-draft converter.
- `maps/full_cave_sketch_01.greybox.json` remains a generated topology draft, not the promoted runtime map.
- Add a focused production generator, expected as `tools/create_production_level_01_map.py`, that reads the full draft and writes the candidate.
- Production cleanup must be named source data or generator constants with rationale. Do not edit generated JSON or Godot collision by hand.

### Existing Gameplay Overlay

- Extract or expose the slice-01 authored gameplay definitions through a shared generator module without changing regenerated `production_slice_01` output.
- The full-level generator applies the explicit `(58, 0)` transform to topology-bound entities, zones, routes, backgrounds, camera tests, and related coordinates.
- Preserve stable gameplay ids where the same authored content is reused.
- Exclude slice crop-bound zones, artificial seals, relay extraction stand-ins, world connectors, connector prompts, and connector destination metadata.
- Exclude the optional advanced stabilizer route as an Expansion 09 entry requirement. Existing runtime/profile support may remain untouched for regression.

### Reference Fixtures

- `production_slice_01` through `production_slice_04` remain generated regression and provenance fixtures.
- Do not change their topology merely to make the full level work.
- Do not construct the full level by reading or merging their generated JSON.
- #52/#53 remain deferred optional slice-03 presentation work.

## Production Topology Rules

The generator must make the draft safe as one level without redesigning it wholesale:

- seal unintended outer-boundary openings
- preserve only the intentional top-water boat opening
- remove artificial crop seams rather than reproducing them
- preserve the supplied cave silhouette wherever player clearance and collision allow
- record every targeted solid/open cleanup in source coordinates
- keep all intended water in one direct boat-reachable and boat-returnable component
- mark any intentionally decorative pocket explicitly instead of silently abandoning it

If a corridor fails player-footprint clearance, make the smallest source-owned cleanup that restores the intended route. Do not use runtime teleports as a clearance workaround.

## Validation And Parity

The candidate cannot be promoted on cell connectivity alone. Validation must prove:

- map schema and entity metadata are valid
- source render and Godot collision remain in parity
- unintended boundary exits are sealed
- the boat entry and extraction footprint are valid
- all intended open sectors are reachable with the actual player footprint
- transformed gameplay entities remain in bounds, non-solid, reachable, and returnable
- mandatory progression remains non-circular and seed-independent
- representative full-level routes reach the upper-left, lower-left, and lower-right sectors and return directly to the boat
- the route keeps one map id and invokes no connector transition
- camera limits never expose blank space and can frame both local routes and the larger level
- startup, terrain construction, collision creation, and Web rendering remain practical with no errors

Add deterministic source coordinates or route markers for validation. Do not encode route proof as screenshot interpretation.

## Runtime Boundaries

- The runtime must load `production_level_01` through the normal JSON world path.
- Add an explicit local/review selector while the map is a candidate.
- Do not add a full-level-specific teleport controller, connector controller, map menu, or `E` transition.
- Existing connector code and slice fixtures may remain for regression, but the full-level journey cannot depend on them.
- Preserve current oxygen, daylight, cargo, banking, health, enemy, material, survey, profile, project, and day-reset semantics.
- Keep `main.gd` as orchestration. Put only genuinely new map-selection or review support in focused existing owners.
- Measure large-map startup and runtime behavior before inventing optimization work. Optimize only an observed bottleneck.

## Smoke Plan

Add one deterministic full-level journey smoke that reports and verifies:

- candidate map id and dimensions
- top boat start and extraction identity
- transformed slice-01 gameplay ids and global positions
- representative sector marker ids and reached coordinates
- unchanged map id across all sector legs
- zero connector transitions or connector prompts
- oxygen, daylight, health, cargo, and day state continuity
- direct return to the canonical boat
- normal bank/commit behavior after return

Keep the current slice-01 journey, progression audit, map validation, and collision parity checks green. Run focused checks per issue and the integrated release suite after the full journey is assembled, not after every documentation or capture-only change.

## Visual And Camera Review

Generate only candidate-specific artifacts until promotion:

- full-map SVG preview and source/render/collision review
- full-level overview for topology inspection
- top boat/opening frame
- transformed slice-01 gameplay frame
- upper-left, lower-left, and lower-right traversal frames
- at least one return-to-boat frame
- supported desktop and mobile gameplay views

Review for terrain continuity, accidental seams, repeated background noise, camera blank space, player scale, readable passages, and usable mobile controls. Keep accepted slice baselines unchanged unless promotion intentionally replaces a default-map baseline.

## Promotion Gate

`production_slice_01` stayed the default while the full map was a candidate. Promotion required:

1. Generator determinism and clean regeneration.
2. Schema, boundary, footprint, reachability, direct-return, progression, and parity validation.
3. Deterministic continuous-journey smoke and existing regression coverage.
4. Practical desktop and Web load/render behavior.
5. Focused visual review with only explained differences.
6. Player confirmation that the level feels continuous, navigable, and worth exploring.

Only after GO should a scoped issue change the default map, regenerate affected default captures, verify the exact public Web SHA, and close the milestone.

## Recommended Issue Batch

The accepted plan is represented by frozen issues #857-#865:

1. Lock the full-level source, coordinate-transform, boundary, and exclusion contract.
2. Extract reusable slice-01 gameplay source definitions with zero regenerated slice diff.
3. Generate `production_level_01` from the complete full-sketch topology and clean its outer boundary.
4. Add player-footprint, full-sector reachability, direct-return, and full-level parity validation.
5. Transform the slice-01 gameplay overlay and author representative full-level route/camera markers.
6. Add candidate map selection, camera bounds, and measured large-map runtime checks.
7. Add the deterministic no-connector full-level journey smoke and CI coverage.
8. Generate focused full-level captures, review the candidate, and make only targeted source-owned topology corrections.
9. On player GO, promote the full level, verify the exact public Web build, and record the Expansion 09 closeout.

Do not split these merely to fill a queue. Split only when implementation reveals a real ownership or validation boundary.

## Deferred Work

- current-stabilizer access design and any advanced-current payoff
- pressure surveys, pressure lining, decompression, or depth simulation
- teleport, connector, map-menu, or exceptional-interior expansion
- new region-specific resources, wildlife, enemies, weapons, research, mysteries, or progression chains
- broad crafting, economy, inventory, vehicles, bases, or save expansion
- #52/#53 slice-03 presentation polish
- #849 repository-health work, which remains independent
- final terrain, background, prop, creature, player, audio, or HUD replacement

## Exit Criteria

Expansion 09 is technically ready for final player review when one generated candidate contains the complete full-sketch topology, all intended sectors pass actual-player clearance and direct-return validation, current gameplay works at transformed coordinates, a deterministic journey swims through former slice boundaries without changing maps, camera and runtime behavior remain practical, candidate visuals are reviewed, and the public review build initializes cleanly.

The milestone closes only after the player answers:

> Does this now feel like one full level that can support future capability-gated exploration without needing teleports?

Automation may prove source fidelity and technical traversal. It cannot claim that the larger level is readable, memorable, or enjoyable.
