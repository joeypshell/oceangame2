# Controlled Gameplay Pass 12 Source Rules

Date: 2026-07-08

Issue: #225 `Document Pass 12 oxygen/rest source rules and target segment`

## Decision

Pass 12 should author exactly one oxygen rest pocket in `production_slice_01` before runtime work begins.

Selected source target:

```text
lower_loop_oxygen_rest_pocket
```

The target is a small route marker/zone in the lower-loop return corridor. It should live inside the existing route context shared by `lower_loop_route` and `return_pressure_to_boat`, near `salvage_lower_loop`, `salvage_return_branch`, and `hazard_lower_bend`.

## Target Segment

Recommended rectangle in tile coordinates:

```json
{
  "id": "lower_loop_oxygen_rest_pocket",
  "type": "marker",
  "x": 27,
  "y": 60,
  "w": 8,
  "h": 5,
  "route_context": "oxygen_rest_pressure",
  "oxygen_rest": true,
  "oxygen_rest_label": "Rest pocket",
  "oxygen_rest_cap_seconds": 45,
  "oxygen_rest_refill_per_second": 8
}
```

This rectangle is currently open water and reachable from the authored `boat_spawn` entry. It sits above the lower-loop payoff area, west of `hazard_lower_bend`, and inside the existing return-pressure corridor, so it can support either a return-to-boat decision or a deeper lower-loop commitment without changing terrain topology.

## Intended Player Decision

The player should read the pocket as a brief in-cave stabilizer:

- enter the lower loop and collect or approach payoff salvage
- decide whether to pause at the rest pocket for a limited oxygen recovery
- leave the pocket and choose whether to continue deeper, take the southwest pocket, or return to bank at the boat

The pocket should make oxygen planning more legible. It should not remove the cost of route commitment.

## Authored Data

The generator/source path should author:

- one marker/zone id: `lower_loop_oxygen_rest_pocket`
- `route_context: "oxygen_rest_pressure"`
- `oxygen_rest: true`
- `oxygen_rest_label: "Rest pocket"`
- `oxygen_rest_cap_seconds: 45`
- `oxygen_rest_refill_per_second: 8`
- an `intent` string explaining the lower-loop oxygen/rest decision

The map source should not author runtime state such as current oxygen, used/unused state, cooldown timers, player progress, score, cargo, completion, or result text.

## Runtime-Derived Behavior

Runtime may derive:

- whether the player is inside the rest pocket
- compact overlay text such as `Rest pocket +oxygen`
- oxygen refill while inside the pocket
- the cap check that prevents recovery above `oxygen_rest_cap_seconds`
- reset cleanup for any temporary rest-pocket feedback state
- smoke/capture setup positions from the marker rectangle

Runtime must not treat the rest pocket as extraction, banking, scoring, or completion.

## Validation Rules

The validator should eventually enforce:

- oxygen-rest metadata is supported only on marker/zone records, not salvage or hazard entities
- `oxygen_rest` must be boolean `true` when rest metadata is present
- `oxygen_rest_label` is optional but must be compact display-safe text when present
- `oxygen_rest_cap_seconds` must be positive and must not exceed the normal oxygen maximum
- `oxygen_rest_refill_per_second` must be positive
- the rectangle must be inside map bounds
- every cell in the rectangle must be non-solid and reachable from the player entry
- only one Pass 12 rest pocket should be authored in `production_slice_01`

## Bounds And Collision Expectations

The selected rectangle must remain non-solid water. Do not add, remove, or move terrain to make the pocket work unless a separate source-map issue is created.

The rest pocket should not create collision, block movement, move salvage, move hazards, move camera tests, or alter the boat spawn/extraction rectangle.

## Reset And Oxygen Expectations

Expected runtime semantics for later issues:

- oxygen drains normally outside extraction and outside the rest pocket
- oxygen refills at the boat/extraction as before
- oxygen refills slowly inside the rest pocket, capped at `oxygen_rest_cap_seconds`
- entering the rest pocket with oxygen already above the cap shows readable feedback but should not increase oxygen
- hazard hit, oxygen failure, manual reset, and run completion clear temporary rest feedback
- cargo, held salvage, banked salvage, route outcome, and result score remain unchanged by the rest pocket itself

## Verification For Source Authoring

After #227 authors the marker through the generator, run:

```powershell
python tools/create_production_slice_map.py
python tools/render_greybox_map.py maps/production_slice_01.greybox.json references/greybox/production_slice_01.svg
python tools/validate_greybox_map.py maps/production_slice_01.greybox.json
python tools/check_map_parity.py maps/production_slice_01.greybox.json
```

Keep #52 and #53 deferred slice-03 polish unless slice-03 presentation becomes the selected goal.
