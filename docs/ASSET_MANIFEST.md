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
| `terrain_floor_short_01.png` | 256x128 | Short playable cave floor | planned | Large AI-generated module over 32px collision grid. |
| `terrain_floor_long_01.png` | 512x256 | Long playable cave floor | planned | Must have clear top edge. |
| `terrain_wall_left_01.png` | 128x256 | Left cave wall | planned | Non-traversable silhouette. |
| `terrain_wall_right_01.png` | 128x256 | Right cave wall | planned | Non-traversable silhouette. |
| `terrain_ceiling_01.png` | 512x128 | Cave ceiling | planned | Should frame swim space. |
| `terrain_arch_01.png` | 256x256 | Cave arch | planned | Background or collision depending on map. |
| `background_rocks_01.png` | 512x256 | Distant rock silhouettes | planned | Non-collision depth layer. |

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
