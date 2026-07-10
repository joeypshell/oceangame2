# Expansion 01 Survey Source Contract

Date: 2026-07-09

Issue: #665
Milestone: OceanGame Expansion 01 `Anomaly Survey Foundation`

## Decision

Author anomaly survey targets in a dedicated top-level `survey_targets` list. A survey target is a non-salvage interaction area that produces one pending discovery after timed in-range work. It must never enter cargo, add score directly, or store runtime/profile state in map JSON.

Existing `zones[].world_connector` records remain the only source shape for map travel. Survey targets may name the canonical commit destination, but they do not duplicate connector rectangles or carry transition state.

## Required Shape

Each `survey_targets` item requires:

- `id`: unique lower_snake_case target ID, distinct from entity, zone, progression-container, and moving-hazard IDs.
- `target_type`: `anomaly` for Expansion 01.
- `x`, `y`, `w`, `h`: positive integer tile rectangle inside the current map.
- `required_capability_id`: `survey_scanner_1` for Expansion 01.
- `interaction`: `survey`.
- `interaction_seconds`: positive number.
- `interaction_label`: lower_snake_case or short display-safe text.
- `discovery_id`: unique lower_snake_case profile discovery ID.
- `route_context`: lower_snake_case route grouping used by review/smoke logic.
- `commit_map_id`: lower_snake_case canonical return map ID.
- `commit_map_path`: committed `res://maps/*.greybox.json` path whose map ID matches `commit_map_id`.
- `commit_entry_id`: existing `boat_spawn` ID in the commit map.

The complete target rectangle must contain reachable, non-solid water cells. Runtime may choose its visual center from this rectangle, but the rectangle does not create terrain, collision, extraction, or a connector.

## First Authored Target

Issue #667 should author this exact semantic record through `tools/create_production_slice_02_map.py`, with final coordinates selected from validated open water:

```json
{
  "id": "lower_right_anomaly_survey",
  "target_type": "anomaly",
  "x": 0,
  "y": 0,
  "w": 3,
  "h": 3,
  "required_capability_id": "survey_scanner_1",
  "interaction": "survey",
  "interaction_seconds": 3.0,
  "interaction_label": "Survey anomaly",
  "discovery_id": "lower_right_anomaly_discovery",
  "route_context": "lower_right_anomaly_route",
  "commit_map_id": "production_slice_01",
  "commit_map_path": "res://maps/production_slice_01.greybox.json",
  "commit_entry_id": "surface_boat_entry"
}
```

The zero coordinates above are placeholders and must not be copied into generated JSON. The generator must choose a reachable slice-02 destination that supports the source-authored return route.

## Source And State Boundary

Map source owns stable identity, placement, required capability, interaction timing/label, discovery identity, route context, and canonical commit destination.

Map source must not include:

- partial progress, active/pending/completed/committed flags
- profile dictionaries or schema versions
- capability ownership
- wallet, price, payout, cargo, score, oxygen, or failure state
- connector overlap, current map leg, result text, UI layout, or save paths

The focused runtime/state owners from #666/#668 interpret the source record and own all transient or durable state.

## Validation Rules

- `survey_targets`, when present, is a list of objects.
- Required IDs and route/capability/discovery fields use lower_snake_case.
- Target and discovery IDs are unique; target IDs do not collide with other authored map objects.
- Only `anomaly`, `survey_scanner_1`, and `survey` are accepted in Expansion 01.
- Timing is positive and labels are display-safe.
- The commit path stays inside the project, resolves to a committed greybox map, matches the authored map ID, and references a `boat_spawn` entry.
- Every rectangle cell is in bounds, non-solid, and reachable from the current map entry.
- Survey-specific metadata on entities, zones, progression containers, or moving hazards is invalid.
- Runtime/profile-state fields in a target are invalid.

## Verification

```powershell
python tools/test_validate_survey_targets.py
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/validate_greybox_map.py maps/production_slice_02.greybox.json
python tools/validate_greybox_map.py maps/production_slice_03.greybox.json
python tools/validate_greybox_map.py maps/production_slice_04.greybox.json
python tools/check_file_lengths.py
git diff --check
```
