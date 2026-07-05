# Art Bible

## Visual Goal

The game should look like a clean, readable, stylized ocean adventure. The art should be simple enough to iterate safely and consistent enough to scale into a larger project later.

## Camera And Scale

- Camera: top-down 2D.
- Tile size: 32x32 pixels unless later changed deliberately.
- Initial map size: about 40x25 tiles.
- Player size: about 1.5 tiles wide.
- Default view: enough space to see navigation hazards before reaching them.

## Style Rules

- Shape language: simple, readable silhouettes.
- Texture density: low to medium.
- Lighting: bright ocean daylight or lightly tinted underwater ambience.
- Outlines: optional soft edge accents; avoid heavy black outlines unless the full style commits to them.
- Detail: readable at gameplay zoom first, attractive second.
- Color: limited ocean palette with strong contrast between interactive and background objects.

## Suggested Palette Roles

- Deep water: dark blue.
- Shallow water: lighter blue or teal.
- Sand: pale warm tan.
- Rock: muted gray or blue-gray.
- Dock: restrained brown.
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
- Dramatic lighting that hides gameplay information.
- Whole-scene redraws to fix one asset.

## Asset Approval Rule

Once an asset is approved, future changes must either:

- edit only that asset, or
- create a named variant.

Approved unrelated assets should not be replaced as a side effect of another fix.

