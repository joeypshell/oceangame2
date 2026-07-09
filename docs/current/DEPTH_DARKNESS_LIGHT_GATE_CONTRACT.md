# Depth Darkness Light Gate Contract

Date: 2026-07-09

Issue: #442 `Design depth darkness and flashlight progression gate`

## Decision

The first darkness/visibility pass should be visual readability pressure, not a hard movement, collision, pickup, oxygen, or objective gate.

The existing `Light +range` upgrade should make a source-authored dark route easier to read by extending/brightening the player light and reducing dark-zone opacity or warning pressure. It should not be required to enter the area in the first implementation.

## Target Experience

The player can swim into a darker deep-route pocket before upgrading the light, but the area feels riskier because salvage, hazards, terrain edges, and return path context are less comfortable to parse. After buying `dive_light_1`, the same area becomes visibly clearer, giving the upgrade an obvious player-facing use without adding inventory, combat, save state, or map-scale expansion.

## Source Metadata

Use marker zones for the first pass so darkness stays source-authored alongside other route-pressure volumes.

Recommended marker fields:

- `type`: `marker`
- `visibility_zone`: `true`
- `visibility_level`: `dim` or `dark`
- `visibility_label`: compact display-safe text, such as `Dark pocket`
- `route_context`: lower_snake_case route grouping
- `required_upgrade_id`: optional upgrade id that improves readability, first target `dive_light_1`
- `visual_only`: `true` for the first pass
- `intent`: optional human-readable source note

Recommended first metadata shape:

```json
{
  "id": "deep_cache_dark_pocket",
  "type": "marker",
  "x": 50,
  "y": 68,
  "w": 16,
  "h": 11,
  "visibility_zone": true,
  "visibility_level": "dark",
  "visibility_label": "Dark pocket",
  "route_context": "deep_cache_pressure",
  "required_upgrade_id": "dive_light_1",
  "visual_only": true,
  "intent": "First visual-only darkness pressure zone around the lower-loop-to-deep-cache route."
}
```

## Candidate Placement

First authored marker: `production_slice_01`, inside the existing `lower_loop_to_deep_cache_pressure` route-pressure area near `salvage_deep_right_cache`. The rectangle is tightened to the reachable lower portion of that pressure area so the marker does not include ceiling/terrain cells.

Reasons:

- It is already part of the deep-route primary objective path.
- It includes timed salvage, moving-hazard/navigation pressure, and return pressure.
- It gives `Light +range` a clear use without adding a new route.
- It keeps the default slice as the validation target.

## Runtime Boundaries

First implementation should:

- render a dark overlay or local visibility treatment only inside the authored marker zone
- keep player movement, collision, cargo, oxygen, salvage, hazards, objectives, and scoring unchanged
- make `dive_light_1` improve readability in the zone
- show compact overlay feedback only if needed, such as `Dark pocket - light helps`
- preserve current `Light +range` purchase semantics

It must not:

- block entry before the light upgrade
- hide collision-critical terrain completely
- author oxygen penalties, score values, pickup locks, runtime state, or save data
- replace terrain, player, boat, salvage, or hazard art
- become a broad lighting/fog system in the first pass

## Validation And Smoke Plan

Add validator support for the marker metadata:

- `visibility_zone` metadata is supported only on marker zones.
- marker rectangle must be in bounds, non-solid, and reachable.
- `visibility_level` must be `dim` or `dark`.
- `required_upgrade_id`, if present, must be lower_snake_case.
- `visual_only`, if present, must be boolean.
- metadata must not author collision, oxygen, score, cargo, objective progress, or completion state.

Add one deterministic smoke after runtime support:

- load `production_slice_01`
- find `deep_cache_dark_pocket`
- verify the player can enter before `dive_light_1`
- verify the compact dark-zone state/overlay is active before upgrade
- purchase or grant `dive_light_1`
- verify the upgraded light profile improves the zone state
- verify existing light upgrade, route, movement, and player-facing smokes still pass

## Capture Plan

Add one focused capture after runtime support:

- suggested flag: `--capture-darkness-light-gate`
- frame the deep-cache dark pocket with player, terrain edge, route context, and overlay feedback visible
- capture before/after light upgrade if possible, or produce a review sheet with both states
- write under `visual_captures/darkness_light_gate/`
- do not accept broad baselines in the implementation issue

Expected intentional visual difference:

- local dark overlay/readability treatment around the authored zone
- clearer player light/readability after `dive_light_1`

Reject as drift:

- map topology, collision, camera framing, route markers, salvage positions, hazard behavior, oxygen timing, cargo state, terrain art, player sprite, or boat/base visuals changing as a side effect

## Follow-Up Issue Order

1. Add visibility-zone metadata to map spec and validator.
2. Author `deep_cache_dark_pocket` in the production-slice source generator.
3. Implement visual-only darkness runtime and `dive_light_1` readability improvement.
4. Add deterministic smoke coverage.
5. Add focused before/after capture.
6. Review visual impact and Web preview.

## Deferred

- hard route locks
- darkness damage or oxygen penalties
- stealth, enemies, or combat visibility
- global fog-of-war
- multi-zone darkness tuning
- save-state or persistent map reveal
- full lighting art replacement
