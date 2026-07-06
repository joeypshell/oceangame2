# Production Slice Selection Criteria

Date: 2026-07-05

Issue: #46 `Document production-slice selection criteria`

## Purpose

Use this checklist when selecting focused production slices from `maps/full_cave_sketch_01.greybox.json` or a later full-map source. A production slice should test one intentional map role, not opportunistically crop a busy-looking area.

Do not promote the whole full sketch into production until the slice workflow is repeatable: source JSON, generated terrain, source-derived collision, route validation, camera captures, review sheets, and visual baseline decisions.

## Slice Roles

### First Area

A first-area slice teaches the core loop: enter from a readable top-water start, collect a small amount of salvage, feel one or two route choices, and return safely.

Good signs:

- Natural top-water opening for a `boat_spawn`.
- Short expedition loop with a clear return-to-boat path.
- Modest salvage and hazard density.
- Low crop-edge risk near the entry and extraction route.

Use `boat_spawn` unless the region clearly cannot support a surface craft.

### Connector

A connector slice proves route readability between larger regions. It should have at least two meaningful exits or route branches, but it does not need to feel like a final destination.

Good signs:

- Strong passage shape: shaft, crossing, shortcut, gate, or return corridor.
- Enough room to test navigation pressure without becoming a giant map.
- Clear fiction for where the player came from and where they are going.

Use `spawn + base` only when the connector is being previewed as a relay drop-off. Otherwise wait until surrounding map context can define entry and extraction honestly.

### Later-Game Destination

A later-game destination slice tests a deeper area with higher route commitment, stronger hazard pressure, or more valuable salvage.

Good signs:

- A broad chamber or memorable route shape.
- A believable in-water relay, sub, or base extraction point.
- A return route that can be validated without inventing a top-water boat.

Use `spawn + base` if the region has no natural surface access but can plausibly be reached from upstream routes in the future full map.

### Terminal Chamber

A terminal chamber is a dead-end payoff area, optional branch, or deeper salvage endpoint. It should make the return trip readable and validate that terminal areas do not become traps.

Good signs:

- One clear way in and out, with enough space to turn around.
- One high-value salvage or landmark beat.
- Hazards placed as pressure, not clutter.

Avoid terminal slices as early production targets unless the entry/extraction plan is already solved.

### Landmark Room

A landmark room exists to make the map memorable. It may be less dense mechanically, but it should carry a strong visual or navigational identity.

Good signs:

- Large silhouette, ruin, arch, shaft, or distinctive chamber contour.
- Good candidate for background art or named route memory.
- Collision can remain grid-derived without hand-tuning the landmark by eye.

Use this role when testing visual identity, not when the project needs a gameplay-route proof.

## Selection Checklist

Before authoring a new slice, record:

- Role: first area, connector, later-game destination, terminal chamber, landmark room, or a deliberate hybrid.
- Bounds: source-map `x`, `y`, `w`, `h`, plus why the crop includes enough context.
- Entry/extraction plan: `boat_spawn`, `spawn + base`, or wait for larger-map context.
- Route choice: at least one readable path decision, terminal branch, or return loop appropriate to the role.
- Salvage/hazard density: source sketch icons are ignored; gameplay objects must be reauthored in JSON.
- Topology clarity: curved sketch corridors, one-tile chokepoints, isolated pockets, and thin pillars must be acceptable or cleaned in source generation.
- Crop-edge risk: note any open boundaries, sealed edges, arbitrary cutoffs, or route exits that need future connection.
- Validation cost: expected generator changes, reachability risk, parity risk, route smoke needs, camera coverage, review artifacts, and baseline decision work.

## Entry And Extraction Decision

Use `boat_spawn` when:

- The slice includes a natural top-water or surface opening.
- A surface craft can visually communicate both entry and salvage return.
- The authored `entry_x`/`entry_y` cell is inside the boat rectangle, open, and reachable.
- The slice is intended to be a first area or surface-connected route.

Use `spawn + base` when:

- The slice has no believable surface opening.
- The fiction is an in-water relay, sub, dock, or forward base.
- The base rectangle can be drawn as a readable return field without changing source collision.
- The slice is a connector, later-game destination, or terminal branch preview.

Wait for larger-map context when:

- The crop only makes sense because of upstream/downstream routes not included in the slice.
- Entry/extraction would require inventing a boat, base, or tunnel that the source topology does not support.
- Sealing crop edges would hide the reason the region is interesting.
- Validation would mostly test artificial boundaries instead of the intended area.

## Lessons From Slice 01

`production_slice_01` worked as the first focused production slice because the top-center entry hub naturally supported `boat_spawn`.

Useful lessons:

- First-area slices should include the entry/extraction model as part of the source data, not as a later scene fix.
- Crop edges must be sealed or explained in the generator/source map, then checked with reachability and source/render/collision review.
- A small collect-return route was enough to validate movement, collision clearance, terrain readability, and baseline capture workflow.
- Camera tests needed follow-up tuning; plan that work as part of the slice cost.

## Lessons From Slice 02

`production_slice_02` was useful because it did not repeat the first-area problem. It tested a lower-right later-game chamber route with an in-water relay.

Useful lessons:

- A region without top-water access should not force `boat_spawn`.
- `spawn + base` is valid when the slice is explicitly framed as a later-game relay or connector.
- Relay extraction must be visually readable in normal captures, while debug overlays remain distinct.
- Camera framing and route smoke are part of making a later-game slice reviewable.
- A slice can be valuable even when it is not a candidate for the default first preview map.

## Minimum Acceptance For A New Slice

A new production slice is ready for implementation when the issue or decision doc states:

- selected role and source bounds
- entry/extraction model and why
- expected route or terminal experience
- intended salvage/hazard density
- crop-edge risks and cleanup plan
- validation commands and expected capture set

If those cannot be stated clearly, keep the region as a planning candidate instead of authoring production JSON.
