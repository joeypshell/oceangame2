"""Validate the bounded Living Expedition 05 excavation source relationship."""

from __future__ import annotations

from typing import Any


SPECIES_ID = "silt_hound"
INDIVIDUAL_ID = "silt_hound_juvenile_01"
RESCUE_ID = "silt_hound_rescue_01"
HABITAT_ID = "companion_habitat_01"
ACTION_ID = "excavate"
CONTEXT_ID = "silt_hound_excavate_context_01"
CANDIDATE_ID = "silt_hound_buried_titanium_01"
POOL_ID = "silt_hound_excavation_pool"
MATERIAL_ID = "titanium_scrap"
BOAT_ENTRY_ID = "surface_boat_entry"
RESCUE_CAMERA_ID = "living_expedition_05_rescue_review_01"
EXCAVATE_CAMERA_ID = "living_expedition_05_excavate_review_01"
AVAILABILITY = "all_supported_seeds"
CONTEXT_KIND = "material_excavation_review"
SOURCE_KEY = "living_expedition_05"

EXCAVATION_FIELDS = {
    "buried_deposit",
    "required_companion_action_id",
    "companion_context_id",
    "presentation_kind",
}
OPTIONAL_CHAIN_IDS = {RESCUE_ID, INDIVIDUAL_ID, CONTEXT_ID, CANDIDATE_ID, POOL_ID}
HARD_ACCESS_COLLECTIONS = (
    "material_projects",
    "zones",
    "regional_journeys",
    "survey_targets",
    "progression_containers",
    "route_objectives",
)
RECORD_FIELDS = {
    RESCUE_ID: {
        "id", "species_id", "individual_id", "x", "y", "rescue_kind", "required_capability_id",
        "commit_map_id", "commit_entry_id", "habitat_id", "excavation_context_id",
        "buried_candidate_id", "review_camera_id", "optional", "availability", "intent",
    },
    CONTEXT_ID: {
        "id", "context_kind", "species_id", "individual_id", "action_id", "target_id",
        "commit_entry_id", "required_access_ids", "availability", "intent",
    },
    CANDIDATE_ID: {
        "id", "type", "x", "y", "kind", "interaction", "material_id", "material_quantity",
        "candidate_pool_id", *EXCAVATION_FIELDS, "intent",
    },
    POOL_ID: {
        "id", "material_id", "selection_strategy", "select_count", "candidate_ids",
        "guaranteed_candidate_ids", "pool_role", "intent",
    },
}


def _items(payload: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = payload.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _matches(payload: dict[str, Any], field: str, item_id: str) -> list[dict[str, Any]]:
    return [item for item in _items(payload, field) if item.get("id") == item_id]


def _one(payload: dict[str, Any], field: str, item_id: str, failures: list[str]) -> dict[str, Any]:
    matches = _matches(payload, field, item_id)
    if len(matches) != 1:
        failures.append(f"Living Expedition 05 requires exactly one {field} record {item_id!r}.")
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


def _catalog_index(catalog: dict[str, Any], field: str) -> dict[str, dict[str, Any]]:
    return {str(item.get("id", "")): item for item in _items(catalog, field)}


def _contains_id(value: Any, ids: set[str]) -> bool:
    if isinstance(value, str):
        return value in ids
    if isinstance(value, dict):
        return any(str(key) in ids or _contains_id(nested, ids) for key, nested in value.items())
    if isinstance(value, list):
        return any(_contains_id(nested, ids) for nested in value)
    return False


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


def _point_failures(map_data: dict[str, Any], item: dict[str, Any], label: str) -> list[str]:
    failures: list[str] = []
    x = item.get("x")
    y = item.get("y")
    if not isinstance(x, int) or isinstance(x, bool) or not isinstance(y, int) or isinstance(y, bool):
        return [f"{label} must use integer tile coordinates."]
    units = map_data.get("units", {})
    try:
        width = int(units["width_tiles"])
        height = int(units["height_tiles"])
    except (KeyError, TypeError, ValueError):
        return [f"{label} cannot be checked without valid map dimensions."]
    if x < 0 or y < 0 or x >= width or y >= height:
        failures.append(f"{label} is out of bounds at {(x, y)}.")
    elif (x, y) in _solid_cells(map_data):
        failures.append(f"{label} is inside solid terrain at {(x, y)}.")
    return failures


def uses_living_expedition_05(map_data: dict[str, Any]) -> bool:
    source = map_data.get("source", {})
    if isinstance(source, dict) and SOURCE_KEY in source:
        return True
    fields = ("creature_rescues", "companion_contexts", "entities", "material_candidate_pools")
    return any(
        str(item.get("id", "")) in {RESCUE_ID, CONTEXT_ID, CANDIDATE_ID, POOL_ID}
        for field in fields
        for item in _items(map_data, field)
    )


def validate_living_expedition_05_relationship(
    map_data: dict[str, Any], catalog: dict[str, Any]
) -> list[str]:
    if not uses_living_expedition_05(map_data):
        return []
    failures: list[str] = []
    species = _catalog_index(catalog, "species").get(SPECIES_ID, {})
    individual = _catalog_index(catalog, "individuals").get(INDIVIDUAL_ID, {})
    action = _catalog_index(catalog, "actions").get(ACTION_ID, {})
    failures.extend(_expect(species, {
        "roles": ["independent"], "ride_capable": False, "base_action_ids": [ACTION_ID],
        "memory_ids": [], "adaptation_ids": [],
    }, SPECIES_ID))
    failures.extend(_expect(individual, {"species_id": SPECIES_ID, "default_callsign": "Marl"}, INDIVIDUAL_ID))
    failures.extend(_expect(action, {
        "roles": ["independent"], "effect_kind": "material_reveal", "damaging": False,
    }, ACTION_ID))

    rescue = _one(map_data, "creature_rescues", RESCUE_ID, failures)
    habitat = _one(map_data, "companion_habitats", HABITAT_ID, failures)
    context = _one(map_data, "companion_contexts", CONTEXT_ID, failures)
    candidate = _one(map_data, "entities", CANDIDATE_ID, failures)
    pool = _one(map_data, "material_candidate_pools", POOL_ID, failures)
    if rescue:
        failures.extend(_unsupported_fields(rescue, RESCUE_ID))
        failures.extend(_expect(rescue, {
            "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID,
            "rescue_kind": "physical_aid",
            "required_capability_id": "salvage_cutter",
            "commit_map_id": map_data.get("id"),
            "commit_entry_id": BOAT_ENTRY_ID,
            "habitat_id": HABITAT_ID,
            "excavation_context_id": CONTEXT_ID,
            "buried_candidate_id": CANDIDATE_ID,
            "review_camera_id": RESCUE_CAMERA_ID,
            "optional": True,
            "availability": AVAILABILITY,
        }, RESCUE_ID))
        failures.extend(_point_failures(map_data, rescue, RESCUE_ID))
    if habitat and habitat.get("individual_ids") != [
        "spark_ray_juvenile_01", "veil_cuttle_juvenile_01", INDIVIDUAL_ID,
    ]:
        failures.append(f"{HABITAT_ID}.individual_ids must preserve Kite, Mica, then Marl.")
    if context:
        failures.extend(_unsupported_fields(context, CONTEXT_ID))
        failures.extend(_expect(context, {
            "context_kind": CONTEXT_KIND,
            "species_id": SPECIES_ID,
            "individual_id": INDIVIDUAL_ID,
            "action_id": ACTION_ID,
            "target_id": CANDIDATE_ID,
            "commit_entry_id": BOAT_ENTRY_ID,
            "required_access_ids": [],
            "availability": AVAILABILITY,
        }, CONTEXT_ID))
    if candidate:
        failures.extend(_unsupported_fields(candidate, CANDIDATE_ID))
        failures.extend(_expect(candidate, {
            "type": "material_candidate",
            "interaction": "material_collect",
            "material_id": MATERIAL_ID,
            "material_quantity": 1,
            "candidate_pool_id": POOL_ID,
            "buried_deposit": True,
            "required_companion_action_id": ACTION_ID,
            "companion_context_id": CONTEXT_ID,
            "presentation_kind": "buried_mineral_mound",
        }, CANDIDATE_ID))
        failures.extend(_point_failures(map_data, candidate, CANDIDATE_ID))
    if pool:
        failures.extend(_unsupported_fields(pool, POOL_ID))
        failures.extend(_expect(pool, {
            "material_id": MATERIAL_ID,
            "selection_strategy": "day_rotation_v1",
            "select_count": 1,
            "candidate_ids": [CANDIDATE_ID],
            "guaranteed_candidate_ids": [CANDIDATE_ID],
            "pool_role": "optional_bonus",
        }, POOL_ID))

    for entity in _items(map_data, "entities"):
        present = EXCAVATION_FIELDS & set(entity)
        if present and entity.get("id") != CANDIDATE_ID:
            failures.append(
                f"{entity.get('id', 'entity')} cannot use Silt Hound excavation metadata {sorted(present)}."
            )
    for field in HARD_ACCESS_COLLECTIONS:
        for item in _items(map_data, field):
            if _contains_id(item, OPTIONAL_CHAIN_IDS):
                failures.append(
                    f"{field} record {item.get('id')!r} cannot depend on the optional Silt Hound chain."
                )

    cameras = {str(item.get("id", "")) for item in _items(map_data, "camera_tests")}
    for camera_id in (RESCUE_CAMERA_ID, EXCAVATE_CAMERA_ID):
        if camera_id not in cameras:
            failures.append(f"Living Expedition 05 camera {camera_id!r} does not resolve.")
    source = map_data.get("source", {})
    provenance = source.get(SOURCE_KEY, {}) if isinstance(source, dict) else {}
    if not isinstance(provenance, dict):
        failures.append(f"source.{SOURCE_KEY} must be an object.")
    else:
        failures.extend(_expect(provenance, {
            "source": "tools/production_level_01_living_expedition_05.py",
            "rescue_ids": [RESCUE_ID],
            "habitat_ids": [HABITAT_ID],
            "companion_context_ids": [CONTEXT_ID],
            "material_candidate_ids": [CANDIDATE_ID],
            "material_pool_ids": [POOL_ID],
            "camera_test_ids": [RESCUE_CAMERA_ID, EXCAVATE_CAMERA_ID],
            "availability": AVAILABILITY,
            "terrain_changes": [],
        }, f"source.{SOURCE_KEY}"))
    return failures
