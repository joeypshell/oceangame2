# Simple Diver Game 09 Fauna And Hazard Contract

Date: 2026-07-09

Issue: #650
Milestone: Simple Diver Game 09 `2D Subnautica Expansion Planning`

## Decision

The first expansion may add one source-authored territorial eel encounter on the slice-02 anomaly approach.

The eel is living route pressure, not an enemy or combat target. It waits at an authored home point, gives a short warning when the player enters its territory, lunges along one fixed authored segment, returns home, and pauses before it can trigger again. The player reads the cycle, waits or slips past, and retains oxygen/cargo/return pressure as the main stakes.

No other fauna behavior is selected for the first expansion slice.

## Vocabulary

| Category | Meaning | First expansion status |
| --- | --- | --- |
| Environmental hazard | Static source point/zone with no apparent agency, such as a mine or current. | Preserve existing behavior. |
| Moving hazard | Deterministic obstacle moving on an authored patrol regardless of player behavior. | Preserve existing `linear_patrol` jellyfish. |
| Passive fauna | Non-damaging life used for mood or route recognition. | Deferred; do not add ambient spawning. |
| Territorial fauna | One creature that reacts inside a bounded authored territory without global pursuit. | Select one eel lunge encounter. |
| Enemy | Actor with combat, health, defeat, loot, or broad pursuit behavior. | Out of scope. |

Territorial fauna is separate from `moving_hazards` because its state responds to a player entering one source-authored territory. It is still deterministic and map-local.

## Target Experience

- The player sees the eel and its territory before committing to the anomaly approach.
- A compact warning gives enough time to stop or retreat.
- The fixed lunge opens a readable pass window after it moves through.
- The eel protects the approach, not the survey target itself; scanning remains possible from a stable safe pocket.
- Contact is costly through existing oxygen/reset semantics, not damage combat.
- Learning the cycle makes the route easier on a retry.

This supports curiosity, pressure, remembered-place progress, and timing choice without becoming a reflex-heavy action encounter.

## First Candidate

Planning ID:

```text
lower_right_anomaly_guard_eel
```

Planned role:

- map: `production_slice_02`
- context: route from `relay_sub_entry` toward the lower terminal/anomaly destination
- behavior: `territorial_lunge`
- route role: one timing gate before the anomaly's stable survey pocket
- non-role: no hard lock, chase, kill requirement, random spawn, or survey interruption loop with no safe window

Exact placement and timing require a focused source/encounter contract after the anomaly target is authored. Do not infer coordinates from screenshots.

## Planned Source Shape

Use a dedicated top-level `fauna` collection so reactive creatures are not disguised as salvage, static hazards, route markers, or unconditional moving hazards.

One future record may include:

```json
{
  "id": "lower_right_anomaly_guard_eel",
  "kind": "eel",
  "behavior": "territorial_lunge",
  "home": {"x": 0, "y": 0},
  "lunge_path": [
    {"x": 0, "y": 0},
    {"x": 0, "y": 0}
  ],
  "territory_zone_id": "lower_right_anomaly_approach",
  "warning_seconds": 0.8,
  "lunge_speed_tiles_per_second": 2.0,
  "return_speed_tiles_per_second": 1.0,
  "cooldown_seconds": 1.5,
  "route_context": "lower_right_anomaly",
  "display_label": "Territorial eel",
  "intent": "One readable lunge cycle guarding the anomaly approach."
}
```

The zero coordinates are shape examples only. The generator must author real reachable open-water points after source review.

Source must not author runtime state, current position, player position, health, damage, loot, score, oxygen penalty amount, save state, animation frame, or UI layout.

## Deterministic Behavior

The focused runtime owner uses this finite sequence:

1. `idle`: eel stays at home until the player enters the territory.
2. `warning`: fixed warning timer; the eel does not track or retarget the player.
3. `lunge`: move from the first to last authored path point at fixed speed.
4. `return`: move back along the same path at fixed speed.
5. `cooldown`: remain at home for a fixed time, then return to `idle`.

Once warning begins, the cycle completes even if the player steps out. This avoids edge-trigger flicker and makes smoke/capture timing repeatable.

No random numbers, navigation mesh, obstacle avoidance, flocking, line-of-sight search, offscreen spawn logic, dynamic path generation, global pursuit, or difficulty scaling are permitted in the first implementation.

## Contact And State Semantics

Contact reuses the existing hazard path:

- apply the existing hazard oxygen penalty
- return the player to the current map entry/spawn
- restore held/unbanked salvage
- clear timed/pry/survey progress
- clear pending anomaly discovery under #648
- preserve session wallet/upgrades and committed profile discoveries
- enter the existing failed result path if the penalty empties oxygen

Reset, map load, connector travel, and failure return the eel to `idle` at its source-authored home. No fauna state persists to profile or world state.

## Validation Expectations

Future validation must catch:

- non-list or oversized first-slice `fauna` collections
- duplicate/non-lower_snake_case IDs
- unsupported kind/behavior
- missing or dangling territory marker references
- invalid compact labels/route context
- home/path points outside bounds, in solid terrain, unreachable, or disconnected from the authored entry/return route
- paths with fewer or more points than the first two-point lunge contract permits
- non-positive warning/speed/cooldown values
- territory/path placement that leaves no reachable safe wait pocket or makes the anomaly/return route inaccessible
- runtime-only/combat/persistence fields in source

Map validation should prove source reachability with the encounter ignored as dynamic pressure; deterministic smoke proves the timing window with the encounter active.

## Visual And Audio Feedback

- Use one named eel sprite or narrowly scoped procedural fallback, with a readable facing/pose change during warning and lunge.
- Keep a compact warning prompt such as `Territorial eel - wait`.
- Reuse the existing hazard contact feedback path.
- At most one short warning cue may be added through `audio_cue_player.gd`; silence must not make the encounter unreadable.
- Do not add health bars, damage numbers, targeting reticles, combat effects, broad ambience, music, or creature voice systems.

## Smoke And Capture Expectations

Suggested smoke: `--smoke-anomaly-guard-eel`.

It should report and verify:

- source ID, territory, path, and timing values
- exact `idle -> warning -> lunge -> return -> cooldown -> idle` transitions
- deterministic positions at fixed elapsed times
- warning-only range before contact
- a safe pass/survey route window
- existing oxygen, cargo restoration, reset, and failed-result contact semantics
- pending discovery cleanup and committed discovery preservation
- normal behavior on maps without fauna metadata

Suggested capture: `--capture-anomaly-guard-eel`, framing the warning/lunge approach and anomaly context. It is review-only until a separate comparison/acceptance decision.

## Ownership Boundary

- generator/source: slice-02 generator
- schema/validation: `docs/MAP_SPEC.md` and greybox validator
- source/runtime indexing and rendering: new focused world helper(s), not more growth in `greybox_world.gd`
- behavior state: new sub-500-line territorial fauna controller
- contact: existing hazard handler through a narrow report/API
- smoke/capture: new domain files because current helpers are near the line ceiling

## Explicitly Deferred

- passive fauna schools or ambient spawners
- additional territorial creatures
- combat, weapons, health, defeat, loot, drops, harvesting, or capture
- random spawns, population simulation, food chains, migration, breeding, or ecology
- global chase, pathfinding, navigation meshes, behavior trees, or difficulty scaling
- persistent fauna/world state

## Planning Verification

```powershell
python tools/check_file_lengths.py
git diff --check
```
