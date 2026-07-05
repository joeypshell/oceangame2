# Art Bible

## Visual Goal

The game should look like a clean, readable, stylized side-view underwater cave adventure. The art should be simple enough to generate and iterate safely while staying consistent enough to scale into a larger OceanGame-style project later.

The approved primary visual direction is:

```text
references/visual/visual_direction_b_modular_cave.png
```

Use it for modular underwater cave terrain, broad readable rock shapes, clear blue water, sparse salvage props, and side-view gameplay composition. Do not treat it as the final map layout.

## Camera And Scale

- Camera: side-view 2D.
- Gameplay/collision grid: 32x32 pixels.
- Terrain art modules: larger AI-generated chunks such as 128x128, 256x128, 256x256, and 512x256.
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
- Terrain should be modular and asset-friendly: floor chunks, wall chunks, ceiling chunks, arches, ledges, corners, and background silhouettes.
- Decorative coral, seaweed, crates, lamps, wreckage, and bubbles should be separate props, not baked into every terrain chunk.

## Suggested Palette Roles

- Water: clear cyan/blue gradient.
- Cave background: softer blue silhouettes.
- Rock terrain: dark blue-gray with pale sandy top edges.
- Base/boat/sub details: restrained white, orange, yellow, dark metal, and teal glass/light accents.
- Salvage: warm accent color.
- Hazards: high-contrast warning color.
- UI: simple, readable, not decorative.

Exact color values are not locked yet. They should be locked after the first approved visual target.

## Forbidden Styles

Avoid these in the first prototype:

- Painterly full-scene concept art.
- Realistic textured water.
- Noisy generated detail.
- Perspective drift between assets.
- Mixed top-down and side-view assets.
- Retro SNES/pixel cave style.
- Visible small repeated square terrain tiles.
- Generic mobile platformer identity: coins, stars, ladders, and crowded collectible trails.
- Dramatic lighting that hides gameplay information.
- Whole-scene redraws to fix one asset.

## AI Asset Strategy

Use AI generation for larger clean illustrated modules, not tiny seamless tiles as final visible art.

Recommended first terrain modules:

- floor platform short
- floor platform long
- left wall
- right wall
- ceiling
- inside corner
- outside corner
- arch
- ledge
- background rock silhouette

Godot `TileMapLayer` should carry the collision/source map. Generated terrain modules should visually cover or decorate that source map without changing the gameplay topology.

## Asset Approval Rule

Once an asset is approved, future changes must either:

- edit only that asset, or
- create a named variant.

Approved unrelated assets should not be replaced as a side effect of another fix.
