# OceanGame Expansion 04 Source Contract

Date: 2026-07-10

Issue: #728

Plan: `docs/current/OCEANGAME_EXPANSION_04_PLAN.md`

State: `docs/current/OCEANGAME_EXPANSION_04_STATE_CONTRACT.md`

## Scope

Expansion 04 extends two existing source concepts without changing terrain or inventing runtime state:

1. current markers may require either one session upgrade or one durable capability
2. material projects may form one ordered prerequisite chain and target either a tool interaction or current gate

The closed Expansion 03 cutter project remains valid without modification.

## Durable Current Requirement

A current marker defines exactly one requirement:

```json
{
  "id": "upper_right_current_pocket_gate",
  "type": "marker",
  "x": 65,
  "y": 40,
  "w": 2,
  "h": 2,
  "current_gate": true,
  "current_direction": "left",
  "current_strength": 2.2,
  "required_capability_id": "current_stabilizer",
  "current_gate_label": "Ripping current",
  "route_context": "upper_right_current_pocket"
}
```

Rules:

- `required_upgrade_id` preserves the legacy session-upgrade path.
- `required_capability_id` selects durable profile ownership.
- Both or neither is invalid.
- The requirement id is lower_snake_case.
- Existing direction, strength, label, rectangle, non-solid, bounds, and reachability rules remain authoritative.
- A durable gate must be targeted by exactly one supported material project whose unlocked capability matches.
- Source does not store capability ownership, blocked state, push progress, or prompt text state.

## Ordered Material Project

The stabilizer is the second project in source order:

```json
{
  "id": "current_stabilizer_project",
  "required_project_id": "salvage_cutter_project",
  "required_discovery_id": "lower_right_anomaly_discovery",
  "required_materials": {
    "titanium_scrap": 2,
    "conductive_coil": 1
  },
  "unlocks_capability_id": "current_stabilizer",
  "target_gate_id": "upper_right_current_pocket_gate",
  "build_phase": "night_debrief"
}
```

Rules:

- Supported order is cutter project, then stabilizer project.
- `required_project_id`, when present, must reference an earlier supported project.
- Self, missing, forward, and circular prerequisites are invalid.
- Every project defines exactly one of `target_id` or `target_gate_id`.
- Cutter uses `target_id` and retains its tool-target backlink.
- Stabilizer uses `target_gate_id`; the gate's `required_capability_id` must equal the project's `unlocks_capability_id`.
- Each supported project uses the exact 2 titanium plus 1 coil recipe and the anomaly discovery.
- Authored daily pool yields must guarantee each recipe; the projects are sequential, so one day need not fund both simultaneously.
- Build phase remains `night_debrief`.

## Payoff Source

The valuable salvage behind the current remains a normal salvage entity. Existing entity schema, reachability, tier, cargo, failure, banking, score, and result behavior stay authoritative.

The project targets the gate, not the payoff. Runtime access is created by crossing the source-authored current volume after capability unlock; no source collected/opened state is allowed.

## Forbidden Source State

Current gates and projects must not author:

- profile schema, unlocked capability, completed project, or material inventory
- active/blocked/current progress or player position
- held/banked/collected payoff state
- oxygen/daylight values, score, wallet, result text, or UI visibility
- collision, terrain changes, generated coordinates, shortcut state, or destination loading

## Validation Entry Points

```powershell
python tools/test_validate_current_gates.py
python tools/test_validate_material_sources.py
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
```

The focused validators remain below 500 lines and are called by the normal map/release validation path.
