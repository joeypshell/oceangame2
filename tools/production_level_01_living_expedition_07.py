"""Source-owned Marl refuge and low eel-contact anchors; no terrain edits."""

from __future__ import annotations

from copy import deepcopy

import living_expedition_07_contract as contract


REFUGE_RECT = (120, 77, 3, 2)
APPROACH_POINT = (119, 77)
DIG_POINT = (121, 78)
WILDLIFE_PATH = ((119, 78), (120, 78), (121, 78))
GROUND_ANCHORS = ((121, 78), (122, 78))


def point(value: tuple[int, int]) -> dict:
    return dict(zip(("x", "y"), value))


def records() -> dict[str, dict]:
    # The schema owns identities/relationships; this transform owns placement.
    values = deepcopy(contract.source_expectations())
    values[contract.REFUGE_ID].update({
        **dict(zip(("x", "y", "w", "h"), REFUGE_RECT)),
        "approach_point": point(APPROACH_POINT),
        "dig_point": point(DIG_POINT),
        "wildlife_path": [point(value) for value in WILDLIFE_PATH],
        "intent": (
            "Open soft silt above the existing deep-cache floor for a passive "
            "scallop group. A live eel warning/lunge makes this a shared event, "
            "not a material pickup or a new geographic gate."
        ),
    })
    values[contract.CONTEXT_ID].update({
        "ground_anchors": [point(value) for value in GROUND_ANCHORS],
        "intent": (
            "Draw the unchanged eel low through normal repeated lunges. Marl "
            "approaches a floor-supported anchor for physical contact; never "
            "teleport the eel down or apply a ranged hold from its home."
        ),
    })
    return values


def camera_tests() -> list[dict]:
    return [
        {
            "id": camera_id, "center_x": x, "center_y": 77, "zoom": 0.7,
            "intent": intent,
        }
        for camera_id, x, intent in zip(contract.CAMERA_IDS, (121, 123), (
            "Refuge, wildlife approach, dig footprint, and existing eel territory.",
            "Floor-supported Marl and eel's physical low-contact opening.",
        ))
    ]


def source_provenance() -> dict:
    return {
        "source": "tools/production_level_01_living_expedition_07.py",
        "refuge_ids": [contract.REFUGE_ID],
        "memory_opportunity_ids": [contract.OPPORTUNITY_ID],
        "companion_context_ids": [contract.CONTEXT_ID],
        "adaptation_payoff_ids": [contract.PAYOFF_ID],
        "camera_test_ids": contract.CAMERA_IDS.copy(),
        "availability": contract.AVAILABILITY,
        "terrain_changes": [],
    }


def author(map_data: dict) -> dict:
    """Append guaranteed optional records without touching existing gameplay."""
    source = map_data.get("source")
    if not isinstance(source, dict) or contract.SOURCE_KEY in source:
        raise ValueError("Expected source without Living Expedition 07 provenance.")
    if contract.REFUGE_FIELD in map_data:
        raise ValueError("Expected source without burrow_refuges.")
    for field, record_id in (
        ("entities", contract.BOAT_ID), ("entities", contract.CACHE_ID),
        ("creature_rescues", contract.RESCUE_ID),
        ("hostile_encounters", contract.HOSTILE_ID),
        ("zones", contract.REGION_ID), ("zones", contract.DARK_ZONE_ID),
    ):
        if sum(item.get("id") == record_id for item in map_data.get(field, [])) != 1:
            raise ValueError(f"Expected one {field} record {record_id!r}.")
    additions = records()
    grouped = {contract.REFUGE_FIELD: [additions[contract.REFUGE_ID]]}
    for record_id, field in contract.RECORDS.items():
        if field != contract.REFUGE_FIELD:
            grouped[field] = [additions[record_id]]
    grouped["camera_tests"] = camera_tests()
    for field, new_records in grouped.items():
        existing = map_data.get(field, [])
        if not isinstance(existing, list):
            raise ValueError(f"Expected {field} to be a list.")
        ids = {item.get("id") for item in existing}
        if any(item["id"] in ids for item in new_records):
            raise ValueError(f"Living Expedition 07 duplicate {field} ids.")
    for field, new_records in grouped.items():
        map_data.setdefault(field, []).extend(new_records)
    source[contract.SOURCE_KEY] = source_provenance()
    return map_data
