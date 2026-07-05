# Asset Manifest

## Status Values

- `planned`: needed but not made.
- `draft`: made but not approved.
- `approved`: accepted for current prototype.
- `locked`: should not change without explicit revision.
- `replaced`: no longer used.

## Terrain Modules

| Asset | Size | Purpose | Status | Notes |
|---|---:|---|---|---|
| `assets/terrain/terrain_floor_short_01.png` | 256x128 | Background or landmark floor module | draft | AI-generated v1; no longer primary seam-critical terrain. |
| `assets/terrain/terrain_floor_long_01.png` | 512x256 | Background or landmark floor module | draft | AI-generated v1; no longer primary seam-critical terrain. |
| `assets/terrain/terrain_wall_left_01.png` | 128x256 | Background or landmark wall module | draft | AI-generated v1; no longer primary seam-critical terrain. |
| `assets/terrain/terrain_wall_right_01.png` | 128x256 | Background or landmark wall module | draft | AI-generated v1; no longer primary seam-critical terrain. |
| `assets/terrain/terrain_ceiling_01.png` | 512x128 | Background or landmark ceiling module | draft | AI-generated v1; no longer primary seam-critical terrain. |
| `assets/terrain/terrain_arch_01.png` | 256x256 | Background or landmark cave arch | draft | AI-generated v1; use as non-collision decoration unless converted into tile-compatible pieces. |
| `assets/terrain/background_rocks_01.png` | 512x256 | Distant rock silhouettes | draft | AI-generated v1; low-contrast non-collision depth layer. |

Review sheet:

```text
references/asset_reviews/terrain_kit_01.png
```

## Terrain Tilesets

| Asset | Size | Purpose | Status | Notes |
|---|---:|---|---|---|
| `assets/terrain_tiles/cave_tileset_v1.png` | 256x96 | First grid-aligned cave terrain atlas | draft | 32x32 tiles; supports exposed-side masks, inner corners, and a fill variant. |
| `assets/terrain_tiles/cave_tileset_v1_manifest.json` | n/a | Tile metadata | draft | Names atlas coordinates and mask semantics. |

Review sheet:

```text
references/asset_reviews/cave_tileset_v1_review.png
```

## Props

| Asset | Size | Purpose | Status | Notes |
|---|---:|---|---|---|
| `salvage_crate_01.png` | 32x32 | Collectible | planned | Warm accent color. |
| `mine_01.png` | 32x32 | Hazard | planned | High readability. |
| `lamp_01.png` | 32x64 | Cave marker or prop | planned | Optional for first pass. |
| `coral_cluster_01.png` | 64x64 | Decoration | planned | Separate from terrain modules. |
| `wreck_fragment_01.png` | 128x64 | Salvage-zone prop | planned | Optional for first pass. |

## Player

| Asset | Size | Purpose | Status | Notes |
|---|---:|---|---|---|
| `player_diver_01.png` | 96x64 | Player diver | planned | Side-view, clean readable silhouette. |
| `research_sub_01.png` | 192x96 | Player or support vehicle | planned | Side-view, clean illustrated style. |

## UI

| Asset | Size | Purpose | Status | Notes |
|---|---:|---|---|---|
| `salvage_icon_01.png` | 32x32 | Score icon | planned | Simple and readable. |
| `hazard_icon_01.png` | 32x32 | Damage or warning icon | planned | Optional. |
