"""Validate the bounded Signal Reef nursery source relationship."""

from __future__ import annotations

from typing import Any

from creature_catalog_contract import STATE_FIELDS


SOURCE_KEY = "living_expedition_06"
JOURNEY_ID = "signal_reef_nursery_journey_01"
SCHOOL_ID = "signal_reef_filter_skate_school_01"
NURSERY_ID = "signal_reef_filter_skate_nursery_01"
PRESSURE_ID = "signal_reef_jellyfish_pressure_01"
ANCHOR_CONTEXT_ID = "spark_ray_anchor_nursery_context_01"
GUARDIAN_CONTEXT_ID = "spark_ray_guardian_nursery_context_01"
COMMITMENT_EVENT_ID = "signal_reef_nursery_commit_01"
SPECIES_ID = "spark_ray"
INDIVIDUAL_ID = "spark_ray_juvenile_01"
ROUTE_ID = "east_current_signal_reef_route"
WEST_GATE_ID = "lower_right_west_current_gate"
EAST_GATE_ID = "lower_right_east_current_gate"
LANDMARK_ID = "lower_right_signal_reef_landmark"
DARK_ZONE_ID = "signal_reef_deep_harmonic_dark_zone"
BOAT_ENTRY_ID = "surface_boat_entry"
ACCESS_IDS = ["propulsion_fins", "dive_light_1"]
ANCHOR_ADAPTATION_ID = "anchor_fins"
ANCHOR_ACTION_ID = "anchor_brace"
GUARDIAN_ADAPTATION_ID = "guardian_pulse"
GUARDIAN_ACTION_ID = "guardian_pulse_action"
AVAILABILITY = "all_supported_seeds"
CAMERA_IDS = [
    "living_expedition_06_approach_review_01",
    "living_expedition_06_anchor_review_01",
    "living_expedition_06_guardian_review_01",
    "living_expedition_06_pending_return_review_01",
    "living_expedition_06_restored_review_01",
]

NEW_COLLECTIONS = {
    "regional_creature_journeys": JOURNEY_ID,
    "passive_wildlife_groups": SCHOOL_ID,
    "creature_nurseries": NURSERY_ID,
    "ecological_pressures": PRESSURE_ID,
}
OPTIONAL_CHAIN_IDS = {
    JOURNEY_ID,
    SCHOOL_ID,
    NURSERY_ID,
    PRESSURE_ID,
    ANCHOR_CONTEXT_ID,
    GUARDIAN_CONTEXT_ID,
    COMMITMENT_EVENT_ID,
}
SOURCE_RECORD_IDS = OPTIONAL_CHAIN_IDS - {COMMITMENT_EVENT_ID}
HARD_ACCESS_COLLECTIONS = (
    "material_projects",
    "zones",
    "regional_journeys",
    "survey_targets",
    "progression_containers",
    "route_objectives",
    "creature_rescues",
    "creature_memory_opportunities",
)
SEED_FIELDS = {"day_seed", "seed", "spawn_chance", "spawn_weight"}
MUTABLE_FIELDS = STATE_FIELDS | {
    "adaptation_method",
    "commit_day_number",
    "commitment_state",
    "field_state",
    "restoration_day_number",
    "restoration_state",
    "school_state",
}
RECORD_FIELDS = {
    JOURNEY_ID: {
        "id", "journey_kind", "species_id", "individual_id", "school_id", "nursery_id",
        "pressure_id", "adaptation_context_ids", "route_id", "gate_ids", "landmark_zone_id",
        "dark_zone_id", "commit_map_id", "commit_entry_id", "commitment_event_id",
        "review_camera_ids", "required_access_ids", "optional", "reward_ids",
        "progression_effect", "availability", "intent",
    },
    SCHOOL_ID: {
        "id", "wildlife_kind", "x", "y", "path", "nursery_id", "pressure_id", "bondable",
        "harvestable", "collectible", "reward_ids", "availability", "intent",
    },
    NURSERY_ID: {
        "id", "nursery_kind", "x", "y", "w", "h", "school_id", "landmark_zone_id",
        "availability", "intent",
    },
    PRESSURE_ID: {
        "id", "pressure_kind", "x", "y", "w", "h", "path", "school_id", "damaging",
        "reward_ids", "availability", "intent",
    },
    ANCHOR_CONTEXT_ID: {
        "id", "context_kind", "branch_kind", "species_id", "individual_id", "journey_id",
        "action_id", "required_adaptation_id", "target_id", "school_id", "nursery_id",
        "required_access_ids", "availability", "intent",
    },
    GUARDIAN_CONTEXT_ID: {
        "id", "context_kind", "branch_kind", "species_id", "individual_id", "journey_id",
        "action_id", "required_adaptation_id", "target_id", "school_id", "nursery_id",
        "required_access_ids", "availability", "intent",
    },
}


def _items(payload: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = payload.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _one(payload: dict[str, Any], field: str, item_id: str, failures: list[str]) -> dict[str, Any]:
    matches = [item for item in _items(payload, field) if item.get("id") == item_id]
    if len(matches) != 1:
        failures.append(f"Living Expedition 06 requires exactly one {field} record {item_id!r}.")
        return {}
    return matches[0]


def _expect(item: dict[str, Any], expected: dict[str, Any], label: str) -> list[str]:
    return [
        f"{label}.{field} must be {value!r}."
        for field, value in expected.items()
        if item.get(field) != value
    ]


def _unsupported_fields(item: dict[str, Any], item_id: str) -> list[str]:
    unsupported = sorted(set(item) - RECORD_FIELDS[item_id])
    return [f"{item_id} contains unsupported source fields {unsupported}."] if unsupported else []


def _forbidden_paths(value: Any, prefix: str = "") -> list[str]:
    paths: list[str] = []
    if isinstance(value, dict):
        for key, nested in value.items():
            path = f"{prefix}.{key}" if prefix else str(key)
            if key in MUTABLE_FIELDS or key in SEED_FIELDS:
                paths.append(path)
            paths.extend(_forbidden_paths(nested, path))
    elif isinstance(value, list):
        for index, nested in enumerate(value):
            paths.extend(_forbidden_paths(nested, f"{prefix}[{index}]"))
    return paths


def _contains_id(value: Any, ids: set[str]) -> bool:
    if isinstance(value, str):
        return value in ids
    if isinstance(value, dict):
        return any(str(key) in ids or _contains_id(nested, ids) for key, nested in value.items())
    if isinstance(value, list):
        return any(_contains_id(nested, ids) for nested in value)
    return False


def _catalog_index(catalog: dict[str, Any], field: str) -> dict[str, dict[str, Any]]:
    return {str(item.get("id", "")): item for item in _items(catalog, field)}


def _source_id_failures(map_data: dict[str, Any]) -> list[str]:
    counts = {item_id: 0 for item_id in SOURCE_RECORD_IDS}
    for value in map_data.values():
        if not isinstance(value, list):
            continue
        for item in value:
            if isinstance(item, dict) and item.get("id") in counts:
                counts[str(item["id"])] += 1
    return [
        f"Living Expedition 06 source id {item_id!r} must occur exactly once across top-level collections."
        for item_id, count in sorted(counts.items())
        if count != 1
    ]


def _map_index(map_data: dict[str, Any]) -> dict[str, dict[str, Any]]:
    fields = (
        "entities", "zones", "regional_journeys", "camera_tests", "passive_wildlife_groups",
        "creature_nurseries", "ecological_pressures",
    )
    return {str(item.get("id", "")): item for field in fields for item in _items(map_data, field)}


def _solid_cells(map_data: dict[str, Any]) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for item in _items(map_data, "terrain"):
        if item.get("type") != "solid":
            continue
        try:
            cells.update(
                (x, y)
                for y in range(int(item["y"]), int(item["y"]) + int(item["h"]))
                for x in range(int(item["x"]), int(item["x"]) + int(item["w"]))
            )
        except (KeyError, TypeError, ValueError):
            continue
    return cells


def _geometry_failures(map_data: dict[str, Any], item: dict[str, Any], label: str) -> list[str]:
    failures: list[str] = []
    try:
        width = int(map_data["units"]["width_tiles"])
        height = int(map_data["units"]["height_tiles"])
        points = [(int(item["x"]), int(item["y"]))]
        if "w" in item or "h" in item:
            w, h = int(item["w"]), int(item["h"])
            if w <= 0 or h <= 0:
                failures.append(f"{label} dimensions must be positive.")
            points.extend((x, y) for y in range(int(item["y"]), int(item["y"]) + h) for x in range(int(item["x"]), int(item["x"]) + w))
        path = item.get("path", [])
        if "path" in item and (not isinstance(path, list) or len(path) < 2):
            failures.append(f"{label}.path must contain at least two point objects.")
        for point in path if isinstance(path, list) else []:
            if not isinstance(point, dict):
                failures.append(f"{label}.path entries must be objects.")
                continue
            points.append((int(point["x"]), int(point["y"])))
    except (KeyError, TypeError, ValueError):
        return [f"{label} geometry must use integer tile coordinates."]
    solids = _solid_cells(map_data)
    for point in points:
        if point[0] < 0 or point[1] < 0 or point[0] >= width or point[1] >= height:
            failures.append(f"{label} geometry is out of bounds at {point}.")
        elif point in solids:
            failures.append(f"{label} geometry is inside solid terrain at {point}.")
    return list(dict.fromkeys(failures))


def uses_living_expedition_06(map_data: dict[str, Any]) -> bool:
    source = map_data.get("source", {})
    if isinstance(source, dict) and SOURCE_KEY in source:
        return True
    return any(
        item.get("id") in OPTIONAL_CHAIN_IDS
        for field in (*NEW_COLLECTIONS, "companion_contexts")
        for item in _items(map_data, field)
    )


def validate_living_expedition_06_relationship(
    map_data: dict[str, Any], catalog: dict[str, Any]
) -> list[str]:
    if not uses_living_expedition_06(map_data):
        return []
    failures: list[str] = []
    if map_data.get("id") != "production_level_01":
        failures.append("Living Expedition 06 is supported only on production_level_01.")
    for field, expected_id in NEW_COLLECTIONS.items():
        ids = [item.get("id") for item in _items(map_data, field)]
        if ids != [expected_id]:
            failures.append(f"Living Expedition 06 requires {field} ids [{expected_id!r}].")
    failures.extend(_source_id_failures(map_data))

    journey = _one(map_data, "regional_creature_journeys", JOURNEY_ID, failures)
    school = _one(map_data, "passive_wildlife_groups", SCHOOL_ID, failures)
    nursery = _one(map_data, "creature_nurseries", NURSERY_ID, failures)
    pressure = _one(map_data, "ecological_pressures", PRESSURE_ID, failures)
    anchor = _one(map_data, "companion_contexts", ANCHOR_CONTEXT_ID, failures)
    guardian = _one(map_data, "companion_contexts", GUARDIAN_CONTEXT_ID, failures)
    map_items = _map_index(map_data)

    expected_records = {
        JOURNEY_ID: (journey, {
            "journey_kind": "regional_habitat_restoration", "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID, "school_id": SCHOOL_ID, "nursery_id": NURSERY_ID,
            "pressure_id": PRESSURE_ID, "adaptation_context_ids": [ANCHOR_CONTEXT_ID, GUARDIAN_CONTEXT_ID],
            "route_id": ROUTE_ID, "gate_ids": [WEST_GATE_ID, EAST_GATE_ID],
            "landmark_zone_id": LANDMARK_ID, "dark_zone_id": DARK_ZONE_ID,
            "commit_map_id": "production_level_01", "commit_entry_id": BOAT_ENTRY_ID,
            "commitment_event_id": COMMITMENT_EVENT_ID, "review_camera_ids": CAMERA_IDS,
            "required_access_ids": ACCESS_IDS, "optional": True, "reward_ids": [],
            "progression_effect": "none", "availability": AVAILABILITY,
        }),
        SCHOOL_ID: (school, {
            "wildlife_kind": "juvenile_filter_skate_school", "nursery_id": NURSERY_ID,
            "pressure_id": PRESSURE_ID, "bondable": False, "harvestable": False,
            "collectible": False, "reward_ids": [], "availability": AVAILABILITY,
        }),
        NURSERY_ID: (nursery, {
            "nursery_kind": "filter_skate_nursery", "school_id": SCHOOL_ID,
            "landmark_zone_id": LANDMARK_ID, "availability": AVAILABILITY,
        }),
        PRESSURE_ID: (pressure, {
            "pressure_kind": "jellyfish_displacement_cycle", "school_id": SCHOOL_ID,
            "damaging": False, "reward_ids": [], "availability": AVAILABILITY,
        }),
        ANCHOR_CONTEXT_ID: (anchor, {
            "context_kind": "regional_journey_action", "branch_kind": "current_lee",
            "species_id": SPECIES_ID, "individual_id": INDIVIDUAL_ID, "journey_id": JOURNEY_ID,
            "action_id": ANCHOR_ACTION_ID, "required_adaptation_id": ANCHOR_ADAPTATION_ID,
            "target_id": EAST_GATE_ID, "school_id": SCHOOL_ID, "nursery_id": NURSERY_ID,
            "required_access_ids": ACCESS_IDS, "availability": AVAILABILITY,
        }),
        GUARDIAN_CONTEXT_ID: (guardian, {
            "context_kind": "regional_journey_action", "branch_kind": "pressure_interrupt",
            "species_id": SPECIES_ID, "individual_id": INDIVIDUAL_ID, "journey_id": JOURNEY_ID,
            "action_id": GUARDIAN_ACTION_ID, "required_adaptation_id": GUARDIAN_ADAPTATION_ID,
            "target_id": PRESSURE_ID, "school_id": SCHOOL_ID, "nursery_id": NURSERY_ID,
            "required_access_ids": ACCESS_IDS, "availability": AVAILABILITY,
        }),
    }
    for item_id, (item, expected) in expected_records.items():
        if not item:
            continue
        failures.extend(_unsupported_fields(item, item_id))
        failures.extend(_expect(item, expected, item_id))
        forbidden = _forbidden_paths(item)
        if forbidden:
            failures.append(f"{item_id} contains mutable or seed-dependent fields: {forbidden}.")
    for item_id, item in ((SCHOOL_ID, school), (NURSERY_ID, nursery), (PRESSURE_ID, pressure)):
        if item:
            failures.extend(_geometry_failures(map_data, item, item_id))

    species = _catalog_index(catalog, "species").get(SPECIES_ID, {})
    individual = _catalog_index(catalog, "individuals").get(INDIVIDUAL_ID, {})
    actions = _catalog_index(catalog, "actions")
    adaptations = _catalog_index(catalog, "adaptations")
    if individual.get("species_id") != SPECIES_ID or individual.get("default_callsign") != "Kite":
        failures.append("Living Expedition 06 individual must resolve to catalog-backed Kite.")
    if species.get("adaptation_ids") != [ANCHOR_ADAPTATION_ID, GUARDIAN_ADAPTATION_ID]:
        failures.append("Living Expedition 06 requires Kite's mutually exclusive catalog adaptations.")
    for context, adaptation_id, action_id in (
        (anchor, ANCHOR_ADAPTATION_ID, ANCHOR_ACTION_ID),
        (guardian, GUARDIAN_ADAPTATION_ID, GUARDIAN_ACTION_ID),
    ):
        if not context:
            continue
        adaptation = adaptations.get(adaptation_id, {})
        actual_action_id = str(context.get("action_id", ""))
        action = actions.get(actual_action_id, {})
        if adaptation.get("independent_action_id") != actual_action_id or adaptation.get("mounted_action_id") != actual_action_id:
            failures.append(f"{context.get('id')} adaptation/action combination is unsupported.")
        if action.get("roles") != ["independent", "mounted"] or action.get("damaging") is not False:
            failures.append(f"{context.get('id')} action must remain non-damaging in both companion roles.")

    expected_targets = {
        ROUTE_ID: ("regional_journeys", {"required_capability_id": "propulsion_fins"}),
        WEST_GATE_ID: ("zones", {"current_gate": True, "required_capability_id": "propulsion_fins"}),
        EAST_GATE_ID: ("zones", {"current_gate": True, "required_capability_id": "propulsion_fins"}),
        LANDMARK_ID: ("zones", {"regional_landmark": True, "regional_journey_id": ROUTE_ID}),
        DARK_ZONE_ID: ("zones", {"visibility_zone": True, "required_upgrade_id": "dive_light_1"}),
        BOAT_ENTRY_ID: ("entities", {"type": "boat_spawn"}),
    }
    for target_id, (_field, expected) in expected_targets.items():
        target = map_items.get(target_id, {})
        if not target:
            failures.append(f"Living Expedition 06 target {target_id!r} does not resolve.")
        else:
            failures.extend(_expect(target, expected, target_id))
    for camera_id in CAMERA_IDS:
        if camera_id not in map_items:
            failures.append(f"Living Expedition 06 camera {camera_id!r} does not resolve.")
    if map_items.get(ROUTE_ID, {}).get("entry_gate_ids") != [WEST_GATE_ID, EAST_GATE_ID]:
        failures.append(f"{ROUTE_ID}.entry_gate_ids must preserve both Signal Reef gates.")
    if map_items.get(ROUTE_ID, {}).get("landmark_zone_id") != LANDMARK_ID:
        failures.append(f"{ROUTE_ID}.landmark_zone_id must preserve Signal Reef.")
    if map_items.get(ROUTE_ID, {}).get("commit_entry_id") != BOAT_ENTRY_ID:
        failures.append(f"{ROUTE_ID}.commit_entry_id must preserve the canonical boat.")

    for field in HARD_ACCESS_COLLECTIONS:
        for item in _items(map_data, field):
            if _contains_id(item, OPTIONAL_CHAIN_IDS):
                failures.append(f"{field} record {item.get('id')!r} cannot depend on the optional LE06 chain.")
    source = map_data.get("source", {})
    provenance = source.get(SOURCE_KEY, {}) if isinstance(source, dict) else {}
    if not isinstance(provenance, dict):
        failures.append(f"source.{SOURCE_KEY} must be an object.")
    else:
        failures.extend(_expect(provenance, {
            "source": "tools/production_level_01_living_expedition_06.py",
            "journey_ids": [JOURNEY_ID], "passive_wildlife_ids": [SCHOOL_ID],
            "nursery_ids": [NURSERY_ID], "ecological_pressure_ids": [PRESSURE_ID],
            "companion_context_ids": [ANCHOR_CONTEXT_ID, GUARDIAN_CONTEXT_ID],
            "camera_test_ids": CAMERA_IDS, "availability": AVAILABILITY, "terrain_changes": [],
        }, f"source.{SOURCE_KEY}"))
    return failures


def validate_living_expedition_06_reachability(
    map_data: dict[str, Any], reachable: set[tuple[int, int]]
) -> list[str]:
    if not uses_living_expedition_06(map_data):
        return []
    failures: list[str] = []
    for field, item_id in NEW_COLLECTIONS.items():
        item = next((entry for entry in _items(map_data, field) if entry.get("id") == item_id), {})
        if field == "regional_creature_journeys":
            continue
        cells: set[tuple[int, int]] = set()
        try:
            cells.add((int(item["x"]), int(item["y"])))
            if "w" in item and "h" in item:
                cells.update(
                    (x, y)
                    for y in range(int(item["y"]), int(item["y"]) + int(item["h"]))
                    for x in range(int(item["x"]), int(item["x"]) + int(item["w"]))
                )
            for point in item.get("path", []):
                cells.add((int(point["x"]), int(point["y"])))
        except (KeyError, TypeError, ValueError):
            continue
        if not cells or not cells.issubset(reachable):
            failures.append(f"Living Expedition 06 {item_id} must remain in reachable open water.")
    boat = _map_index(map_data).get(BOAT_ENTRY_ID, {})
    boat_point = (boat.get("entry_x", boat.get("x")), boat.get("entry_y", boat.get("y")))
    if not boat or boat_point not in reachable:
        failures.append("Living Expedition 06 canonical boat return is unreachable.")
    return failures
