"""Immutable source contract for Marl's first memory and grounded response."""

from __future__ import annotations

from typing import Any

from creature_catalog_contract import validate_creature_catalog
from validate_full_level_traversal import solid_cells

SOURCE_KEY = "living_expedition_07"
REFUGE_FIELD = "burrow_refuges"
REFUGE_ID = "deep_cache_burrow_refuge_01"
OPPORTUNITY_ID = "marl_guarded_nest_opportunity_01"
CONTEXT_ID = "deep_cache_eel_marl_ground_pin"
PAYOFF_ID = "silt_hound_root_claws_payoff_01"
MEMORY_ID = "guarded_the_nest"
ADAPTATION_ID = "root_claws"
ACTION_ID = "ground_pin"
SPECIES_ID = "silt_hound"
INDIVIDUAL_ID = "silt_hound_juvenile_01"
RESCUE_ID = "silt_hound_rescue_01"
BOAT_ID = "surface_boat_entry"
HOSTILE_ID = "deep_cache_territorial_eel"
CACHE_ID = "salvage_deep_right_cache"
REGION_ID = "lower_loop_to_deep_cache_pressure"
DARK_ZONE_ID = "deep_cache_dark_pocket"
ACCESS_IDS = ["dive_light_1"]
REVIEW_ACCESS_IDS = ["dive_light_1", "shock_prod"]
AVAILABILITY = "all_supported_seeds"
CAMERA_IDS = ["living_expedition_07_refuge_review_01", "living_expedition_07_pin_review_01"]
OBSERVATIONS = ["physical_dig_complete", "live_warning_lunge", "group_sheltered", "pair_present"]
RECORDS = {
    REFUGE_ID: REFUGE_FIELD,
    OPPORTUNITY_ID: "creature_memory_opportunities",
    CONTEXT_ID: "companion_contexts",
    PAYOFF_ID: "creature_adaptation_payoffs",
}
CHAIN_IDS = {*RECORDS, MEMORY_ID, ADAPTATION_ID, ACTION_ID}
HARD_ACCESS_COLLECTIONS = (
    "entities", "zones", "material_projects", "regional_journeys", "survey_targets",
    "progression_containers", "route_objectives", "creature_rescues", "hostile_encounters",
    "material_candidate_pools", "biological_resource_sources",
)


def items(payload: dict, field: str) -> list[dict]:
    value = payload.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _contains(value: Any, ids: set[str]) -> bool:
    if isinstance(value, str):
        return value in ids
    if isinstance(value, dict):
        return any(key in ids or _contains(nested, ids) for key, nested in value.items())
    return isinstance(value, list) and any(_contains(nested, ids) for nested in value)


def uses_living_expedition_07(payload: dict) -> bool:
    source = payload.get("source", {})
    return (
        REFUGE_FIELD in payload
        or (isinstance(source, dict) and SOURCE_KEY in source)
        or any(_contains(payload.get(field, []), CHAIN_IDS) for field in RECORDS.values())
    )


def expected_memory_records(payload: dict) -> dict[str, str]:
    return {OPPORTUNITY_ID: MEMORY_ID} if uses_living_expedition_07(payload) else {}


def expected_payoff_records(payload: dict) -> dict[str, str]:
    return {PAYOFF_ID: ADAPTATION_ID} if uses_living_expedition_07(payload) else {}


def _expect(item: dict, expected: dict, label: str, extras: tuple[str, ...] = ()) -> list[str]:
    failures = []
    for field, value in expected.items():
        actual = item.get(field)
        if actual != value or isinstance(actual, bool) != isinstance(value, bool):
            failures.append(f"{label}.{field} must be {value!r}.")
    unknown = set(item) - set(expected) - set(extras) - {"intent"}
    if unknown:
        failures.append(f"{label} has unsupported source/state fields {sorted(unknown)}.")
    return failures


def _one(payload: dict, field: str, item_id: str, failures: list[str]) -> dict:
    matches = [item for item in items(payload, field) if item.get("id") == item_id]
    if len(matches) != 1:
        failures.append(f"LE07 requires exactly one {field} record {item_id!r}.")
        return {}
    return matches[0]


def source_expectations() -> dict[str, dict]:
    identity = {"species_id": SPECIES_ID, "individual_id": INDIVIDUAL_ID, "availability": AVAILABILITY}
    return {
        REFUGE_ID: {
            "id": REFUGE_ID, **identity, "refuge_kind": "soft_silt_burrow",
            "wildlife_kind": "burrow_scallop_group", "action_id": "excavate",
            "hostile_id": HOSTILE_ID, "region_zone_id": REGION_ID, "dark_zone_id": DARK_ZONE_ID,
            "required_access_ids": ACCESS_IDS, "bondable": False, "harvestable": False,
            "optional": True, "reward_ids": [],
        },
        OPPORTUNITY_ID: {
            "id": OPPORTUNITY_ID, **identity, "memory_id": MEMORY_ID,
            "event_kind": "burrow_refuge_sheltered", "action_id": "excavate",
            "target_id": REFUGE_ID, "hostile_id": HOSTILE_ID, "required_rescue_id": RESCUE_ID,
            "adaptation_ids": [ADAPTATION_ID], "payoff_id": PAYOFF_ID,
            "required_observations": OBSERVATIONS, "required_access_ids": ACCESS_IDS,
            "commit_map_id": "production_level_01", "commit_entry_id": BOAT_ID,
            "optional": True, "reward_ids": [],
        },
        CONTEXT_ID: {
            "id": CONTEXT_ID, **identity, "context_kind": "independent_action_review",
            "action_id": ACTION_ID, "required_adaptation_id": ADAPTATION_ID,
            "target_id": HOSTILE_ID, "required_access_ids": REVIEW_ACCESS_IDS,
            "effect_kind": "grounded_hold", "max_hold_seconds": 1.75,
            "cooldown_seconds": 8.0, "damage": 0,
        },
        PAYOFF_ID: {
            "id": PAYOFF_ID, **identity, "adaptation_id": ADAPTATION_ID,
            "target_id": HOSTILE_ID, "independent_context_id": CONTEXT_ID,
            "required_access_ids": REVIEW_ACCESS_IDS,
        },
    }


def _geometry(payload: dict, refuge: dict, context: dict, hostile: dict) -> tuple[set, list[str]]:
    """Check bounded tile geometry; actor sweeps/encounter reach are authoring evidence."""
    failures: list[str] = []
    points: set[tuple[int, int]] = set()
    units = payload.get("units", {})
    width, height = units.get("width_tiles"), units.get("height_tiles")
    if any(type(value) is not int or value <= 0 for value in (width, height)):
        return points, ["LE07 requires positive integer map dimensions."]
    try:
        solids = solid_cells(payload)
    except (KeyError, TypeError, ValueError, OverflowError):
        return points, ["LE07 requires valid solid terrain geometry."]

    def point(value: Any, label: str) -> tuple[int, int] | None:
        if not isinstance(value, dict) or set(value) != {"x", "y"}:
            failures.append(f"{label} must contain only integer x/y coordinates.")
            return None
        x, y = value["x"], value["y"]
        if type(x) is not int or type(y) is not int or not (0 <= x < width and 0 <= y < height):
            failures.append(f"{label} must be in-bounds integer coordinates.")
            return None
        cell = (x, y)
        points.add(cell)
        if cell in solids:
            failures.append(f"{label} lies in solid terrain.")
        return cell

    x, y, w, h = (refuge.get(field) for field in ("x", "y", "w", "h"))
    bounds_valid = all(type(value) is int for value in (x, y, w, h))
    if not bounds_valid or not (0 <= x < width and 0 <= y < height and 0 < w <= width-x and 0 < h <= height-y):
        failures.append(f"{REFUGE_ID} must have positive, in-bounds integer bounds.")
    else:
        for cy in range(y, y+h):
            for cx in range(x, x+w):
                point({"x": cx, "y": cy}, REFUGE_ID)
    for field in ("approach_point", "dig_point"):
        cell = point(refuge.get(field), f"{REFUGE_ID}.{field}")
        if field == "dig_point" and cell and bounds_valid and not (x <= cell[0] < x+w and y <= cell[1] < y+h):
            failures.append("Refuge dig_point must lie inside its bounds.")
    path = refuge.get("wildlife_path")
    if not isinstance(path, list) or not (2 <= len(path) <= 8):
        failures.append("Refuge wildlife_path must have 2-8 points.")
    else:
        path_cells = [point(value, "Refuge wildlife_path") for value in path]
        last = path_cells[-1]
        if last and bounds_valid and not (x <= last[0] < x+w and y <= last[1] < y+h):
            failures.append("Refuge wildlife_path must end inside shelter.")
    anchors = context.get("ground_anchors")
    if not isinstance(anchors, list) or not (1 <= len(anchors) <= 4):
        failures.append("Ground Pin requires 1-4 ground_anchors.")
    else:
        seen = set()
        territory = hostile.get("territory", {})
        for anchor in anchors:
            cell = point(anchor, "Ground Pin anchor")
            if cell is None:
                continue
            if cell in seen:
                failures.append("Ground Pin ground_anchors contain a duplicate.")
            seen.add(cell)
            if (cell[0], cell[1]+1) not in solids:
                failures.append("Ground Pin anchor requires solid floor directly below it.")
            try:
                inside = (territory["x"] <= cell[0] < territory["x"] + territory["w"]
                          and territory["y"] <= cell[1] < territory["y"] + territory["h"])
            except (KeyError, TypeError):
                inside = False
            if not inside:
                failures.append("Ground Pin anchor must lie in the existing eel territory.")
    return points, failures


def validate_living_expedition_07_relationship(payload: dict, catalog: dict) -> list[str]:
    if not uses_living_expedition_07(payload):
        return []
    failures = validate_creature_catalog(catalog)
    if payload.get("id") != "production_level_01":
        failures.append("LE07 is supported only on production_level_01.")
    if [item.get("id") for item in items(payload, REFUGE_FIELD)] != [REFUGE_ID]:
        failures.append(f"{REFUGE_FIELD} must contain exactly {REFUGE_ID!r}.")
    records = {key: _one(payload, field, key, failures) for key, field in RECORDS.items()}
    for key in RECORDS:
        count = sum(item.get("id") == key for field in payload for item in items(payload, field))
        if count != 1:
            failures.append(f"LE07 id {key!r} must occur exactly once across source collections.")
    for key, expected in source_expectations().items():
        extras = ("x", "y", "w", "h", "approach_point", "dig_point", "wildlife_path") if key == REFUGE_ID else ()
        if key == CONTEXT_ID:
            extras = ("ground_anchors",)
        failures.extend(_expect(records[key], expected, key, extras))

    targets = {
        RESCUE_ID: ("creature_rescues", {"individual_id": INDIVIDUAL_ID, "required_capability_id": "salvage_cutter"}),
        BOAT_ID: ("entities", {"type": "boat_spawn"}),
        HOSTILE_ID: ("hostile_encounters", {"kind": "territorial_eel", "behavior": "territorial_lunge", "required_weapon_capability_id": "shock_prod"}),
        CACHE_ID: ("entities", {"type": "salvage", "guarded_by_hostile_id": HOSTILE_ID, "interaction": "timed_salvage", "interaction_seconds": 2.5}),
        REGION_ID: ("zones", {"type": "marker"}),
        DARK_ZONE_ID: ("zones", {"visibility_zone": True, "visual_only": True, "required_upgrade_id": "dive_light_1"}),
    }
    resolved = {}
    for key, (field, expected) in targets.items():
        target = _one(payload, field, key, failures)
        resolved[key] = target
        failures.extend(_expect(target, expected, key, tuple(target)))
    cache = resolved[CACHE_ID]
    if any(field.startswith("required_") for field in cache):
        failures.append("LE07 must keep the guarded cache attemptable without a capability lock.")
    for field in HARD_ACCESS_COLLECTIONS:
        for item in items(payload, field):
            if _contains(item, CHAIN_IDS):
                failures.append(f"{field} {item.get('id')!r} cannot depend on the optional LE07 chain.")
    for camera_id in CAMERA_IDS:
        _one(payload, "camera_tests", camera_id, failures)
    source = payload.get("source", {})
    provenance = source.get(SOURCE_KEY) if isinstance(source, dict) else None
    if not isinstance(provenance, dict):
        failures.append(f"source.{SOURCE_KEY} must be an object.")
    else:
        failures.extend(_expect(provenance, {
            "source": "tools/production_level_01_living_expedition_07.py",
            "refuge_ids": [REFUGE_ID], "memory_opportunity_ids": [OPPORTUNITY_ID],
            "companion_context_ids": [CONTEXT_ID], "adaptation_payoff_ids": [PAYOFF_ID],
            "camera_test_ids": CAMERA_IDS, "availability": AVAILABILITY, "terrain_changes": [],
        }, f"source.{SOURCE_KEY}"))
    _, geometry_failures = _geometry(payload, records[REFUGE_ID], records[CONTEXT_ID], resolved[HOSTILE_ID])
    failures.extend(geometry_failures)
    return failures


def validate_living_expedition_07_reachability(payload: dict, reachable: set[tuple[int, int]]) -> list[str]:
    if not uses_living_expedition_07(payload):
        return []
    failures: list[str] = []
    refuge = _one(payload, REFUGE_FIELD, REFUGE_ID, failures)
    context = _one(payload, "companion_contexts", CONTEXT_ID, failures)
    hostile = _one(payload, "hostile_encounters", HOSTILE_ID, failures)
    points, geometry_failures = _geometry(payload, refuge, context, hostile)
    failures.extend(geometry_failures)
    for cell in sorted(points - reachable):
        failures.append(f"LE07 source point {cell} is unreachable.")
    boat = _one(payload, "entities", BOAT_ID, failures)
    if (boat.get("entry_x"), boat.get("entry_y")) not in reachable:
        failures.append("LE07 canonical boat return is unreachable.")
    return failures
