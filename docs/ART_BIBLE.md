# Art Bible

## Visual Goal

The game should look like a clean, readable, stylized side-view underwater expedition with a living-creature focus. Terrain, diver, companions, wildlife, tools, and UI should be simple enough to generate and revise individually while remaining coherent at gameplay scale.

The approved primary visual direction is:

```text
references/visual/visual_direction_b_modular_cave.png
```

Use it for modular underwater cave terrain, broad readable rock shapes, clear blue water, sparse salvage props, and side-view gameplay composition. Do not treat it as the final map layout.

## Camera And Scale

- Camera: side-view 2D.
- Gameplay/collision grid: 32x32 pixels.
- Seam-critical terrain art: 32x32 grid-aligned tiles selected by `TileMapLayer`.
- Large art modules: background silhouettes, landmarks, and non-collision decoration.
- Initial map size: one compact underwater cave test area.
- Player size: Dave-the-Diver-like side-view scale; the diver should read clearly but leave generous open water around them.
- Default view: enough space to see swim paths, hazards, salvage, and terrain openings before reaching them.

## Style Rules

- Shape language: simple, readable silhouettes.
- Texture density: low to medium.
- Lighting: clear bright underwater daylight for the first prototype; darker cave lighting can be a later controlled layer.
- Outlines: optional soft edge accents; avoid heavy black outlines unless the full style commits to them.
- Detail: readable at gameplay zoom first, attractive second.
- Color: limited ocean palette with strong contrast between interactive and background objects.
- Creatures: distinctive silhouette, movement rhythm, and behavior first; color swaps alone do not establish a species or adaptation.
- Terrain should be modular and asset-friendly: grid-aligned floors, walls, ceilings, corners, and background silhouettes.
- Decorative coral, seaweed, crates, lamps, wreckage, and bubbles should be separate props, not baked into every terrain chunk.

## Current Terrain Tile Pass

The `cave_tileset_v1` polish pass for the first production slice targets these visual defects:

- large solid terrain masses reading as repeated square scratch tiles
- pale sandy top edges overpowering the water and forming bright zipper lines
- semi-transparent cyan-looking cracks showing through the rock texture

Expected screenshot differences after this pass:

- rock interiors read as broader blue-gray planes with lower-contrast accents
- sandy top edges stay gameplay-readable but are thinner and more muted
- map topology, tile-grid alignment, collision, salvage, hazards, and camera framing are unchanged

## Suggested Palette Roles

- Water: clear cyan/blue gradient.
- Cave background: softer blue silhouettes.
- Rock terrain: dark blue-gray with pale sandy top edges.
- Base/boat/sub details: restrained white, orange, yellow, dark metal, and teal glass/light accents.
- Salvage: warm accent color.
- Hazards: high-contrast warning color.
- UI: simple, readable, not decorative.

Exact color values are not locked yet. They should be locked after the first approved visual target.

## Current Entity Prop Pass

Normal gameplay previews should use small readable in-world props instead of abstract debug markers:

- Salvage uses warm ochre/copper/yellow accents and should read as crates, wreck fragments, or relics.
- Hazards reserve red/magenta and dark warning silhouettes, currently mines and jellyfish.
- Simple yellow diamonds and red squares are allowed only as debug/review overlay markers.
- Debug/review overlays may use cyan source grid, white route rectangles, amber extraction/boat outlines, green entry/spawn labels, yellow salvage diamonds, and red hazard squares.
- Entity behavior remains driven by JSON `type`; `kind` selects the first-pass visual variant.

## Current Player Animation Direction

The approved `assets/player/player_diver_01.png` remains the style and scale anchor for player animation. The first animation slice uses `assets/player/player_diver_swim_01.png`, a small swim/idle sheet with matching 96x64 frame bounds, right-facing source frames, runtime visual-only flipping, and no collision, camera, movement, map, oxygen, cargo, or light-cone behavior changes.

## Creature And Adaptation Direction

Creature art must support attachment and mechanical reading rather than act as
collectible decoration.

- Each species needs a recognizable body plan and locomotion silhouette at the
  normal gameplay camera.
- An individual companion should remain identifiable beside the diver without
  crowding traversal or HUD space.
- Base behavior requires readable idle, follow, catch-up, separated/worried,
  encounter-response, and recovery states before broad animation production.
- Ride-capable species need a readable approach, mount, mounted locomotion,
  direct-action, forced-separation, and dismount silhouette at gameplay scale.
- Mounted framing must keep the diver and creature legible as one controlled pair
  without making the rider look pasted on or hiding facing and attack direction.
- Temperament may affect timing, posture, spacing, and idle expression, but not
  make critical behavior visually ambiguous.
- Permanent adaptations need a body, marking, posture, or effect change that is
  visible without opening a stat screen.
- Adaptation effects must show direction, range, target, charge, cooldown, and
  outcome where relevant.
- Companion, passive wildlife, defensive wildlife, territorial enemies, and
  predators need different movement and warning language.
- Do not communicate species only through a floating marker, scan circle,
  recolor, or text label.

The first Spark Ray proof uses one base individual plus separately reviewable
Anchor Fins and Guardian Pulse variants. The base individual needs independent
follow and mounted silhouettes plus a readable non-damaging Glide Surge. Anchor
Fins should broaden the fin-tip silhouette and lower both independent and mounted
current stances. Guardian Pulse should add a conductive stripe, readable aimed
charge in either mode, directional discharge, hit response, and cooldown
recovery. Changing any Spark Ray state must not regenerate terrain, diver, boat,
other wildlife, or the full scene.

## Current Boat Entry Pass

Production-style `boat_spawn` visuals should read as the top-water start and return craft, not as an abstract rectangle:

- Use restrained warm hull colors, pale deck/hatch accents, and small teal glass/details.
- Keep the authored boat rectangle legible as the extraction area.
- Place the hatch/tether cue at the authored `entry_x`/`entry_y` cell so player spawn remains visually tied to source data.
- Do not use the boat visual to redefine collision, spawn, or extraction bounds by eye.

## Current Relay Extraction Pass

In-water `base` extraction zones should read as relay/sub return points, not as plain abstract rectangles:

- Keep the authored base rectangle legible as the extraction/return field.
- Use compact dark metal, warm beacon, and teal glass/light accents so the relay remains distinct from salvage and hazards.
- If a legacy `spawn` point is inside the extraction zone, render a small entry cue at the authored spawn cell.
- Do not use the relay visual to redefine collision, spawn, or extraction bounds by eye.
- Debug/review overlays must still draw amber extraction outlines and green spawn labels distinctly over the normal relay visual.

## Forbidden Styles

Avoid these in the first prototype:

- Painterly full-scene concept art.
- Realistic textured water.
- Noisy generated detail.
- Perspective drift between assets.
- Mixed top-down and side-view assets.
- Retro SNES/pixel cave style.
- Final terrain that reads as obvious repeated square tiles. Temporary grid-readable test tiles are acceptable while proving terrain rules.
- Generic mobile platformer identity: coins, stars, ladders, and crowded collectible trails.
- Generic pet/monster icons, capsule-like capture effects, or color-only creature variants that make individuals read as inventory tokens.
- Dramatic lighting that hides gameplay information.
- Whole-scene redraws to fix one asset.

## AI Asset Strategy

Use AI generation against exact tile masks or controlled tile sheets for seam-critical terrain. Use larger clean illustrated modules for backgrounds, landmarks, and non-collision decoration.

Recommended first terrain tile cases:

- solid fill
- fill variant
- top floor edge
- bottom ceiling edge
- left wall
- right wall
- ceiling
- inside corner
- outside corner
- narrow/isolated collision terrain

Recommended large modules:

- background rock silhouette
- distant arch or ruin
- non-collision ledge decoration

Godot `TileMapLayer` should carry the visible grid-aligned terrain for core collision shapes. Generated large modules may decorate the source map, but they must not redefine collision by eye or be stretched to fit gameplay terrain.

## Asset Approval Rule

Once an asset is approved, future changes must either:

- edit only that asset, or
- create a named variant.

Approved unrelated assets should not be replaced as a side effect of another fix.
