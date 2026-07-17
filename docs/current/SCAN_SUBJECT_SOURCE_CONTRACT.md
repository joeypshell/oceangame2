# Scan Subject Source Contract

Date: 2026-07-17

Issue: #982

## Decision

An authored scanner subject may opt into one complete metadata block that
separates the physical thing being scanned from the durable reward it grants.
This prevents an invisible proximity rectangle or generic environmental signal
from silently granting an unrelated blueprint.

Existing anomaly, resource, and regional surveys remain valid without this
block. Compatibility is intentional while their presentation is migrated in
small reviewed passes.

## Focused Shape

When any field below is present, all six are required:

- `scan_subject_kind`: `artifact`, `creature`, `environment`, or `resource`.
- `scan_subject_id`: stable lower_snake_case identity for the world subject.
- `scan_presentation_id`: stable lower_snake_case renderer/asset identity.
- `scan_anchor`: integer tile-space `{ "x": ..., "y": ... }` inside both the
  map and the survey rectangle.
- `scan_reward_kind`: `blueprint`, `discovery`, or `research`.
- `scan_reward_id`: supported durable lower_snake_case knowledge identity.

The reward id must equal the existing `discovery_id`; runtime/profile state
therefore keeps one durable owner. The first explicit blueprint knowledge id is
`salvage_cutter_blueprint`.

```json
{
  "id": "salvage_cutter_blueprint_survey",
  "target_type": "anomaly",
  "x": 0,
  "y": 0,
  "w": 2,
  "h": 2,
  "scan_subject_kind": "artifact",
  "scan_subject_id": "salvage_cutter_maintenance_case",
  "scan_presentation_id": "salvage_cutter_blueprint_case",
  "scan_anchor": {"x": 0, "y": 0},
  "scan_reward_kind": "blueprint",
  "scan_reward_id": "salvage_cutter_blueprint",
  "discovery_id": "salvage_cutter_blueprint"
}
```

Coordinates in this example are placeholders. A source helper must choose a
validated reachable placement before generating map JSON.

## Validation

- Blueprint rewards require `scan_subject_kind: "artifact"`.
- Anomaly targets support artifact/environment subjects and discovery or
  blueprint rewards.
- Resource targets support resource subjects and research rewards.
- Regional targets support artifact/creature/environment subjects and
  discovery rewards.
- Subject ids are unique among explicit scan subjects.
- Presentation and reward ids are lower_snake_case and non-empty.
- Anchors use only integer `x`/`y`, remain in bounds, and lie inside the survey
  rectangle; normal reachability validation keeps that rectangle non-solid and
  reachable.
- Unsupported rewards, partial metadata blocks, misplaced survey metadata, and
  authored runtime/profile state are invalid.

## Ownership Boundaries

Source owns subject identity, physical presentation identity, anchor, reward,
timing, clue/finding text, and canonical commit destination. Runtime owns the
scanner cone, line of sight, selection, progress, pending/committed state,
profile persistence, feedback, and rendering state.

Cone length and angle are runtime constants. They must not become per-target
map tuning. Generated map JSON remains derived from focused source helpers.

## Verification

```powershell
python tools/test_validate_survey_targets.py
python tools/validate_greybox_map.py maps/production_level_01.greybox.json
python tools/audit_progression_graph.py
python tools/check_file_lengths.py
git diff --check
```
