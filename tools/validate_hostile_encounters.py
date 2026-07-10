#!/usr/bin/env python3
"""Validate the bounded Expansion 06 hostile encounter source contract."""

from __future__ import annotations

import math
import re
from typing import Any


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'|-]{0,47}$")
HOSTILE_ID = "deep_cache_territorial_eel"
HOSTILE_KIND = "territorial_eel"
HOSTILE_BEHAVIOR = "territorial_lunge"
WEAPON_CAPABILITY_ID = "shock_prod"
ROUTE_CONTEXT = "deep_cache_pressure"
GUARDED_TARGET_ID = "salvage_deep_right_cache"
GUARDED_TARGET_FIELDS = {"guarded_by_hostile_id"}
FORBIDDEN_TARGET_LOCK_FIELDS = {"required_capability_id", "locked_label", "guard_active_label"}
ALLOWED_FIELDS = {
    "id",
    "kind",
    "x",
    "y",
    "behavior",
    "territory",
    "warning_radius_tiles",
    "warning_seconds",
    "lunge_speed_tiles_per_second",
    "lunge_seconds",
    "recovery_seconds",
    "contact_radius_tiles",
    "health",
    "contact_damage",
    "required_weapon_capability_id",
    "warning_label",
    "retreat_label",
    "defeated_label",
    "route_context",
    "intent",
}
REQUIRED_FIELDS = ALLOWED_FIELDS - {"intent"}
POSITIVE_NUMBER_FIELDS = {
    "warning_radius_tiles",
    "warning_seconds",
    "lunge_speed_tiles_per_second",
    "lunge_seconds",
    "recovery_seconds",
    "contact_radius_tiles",
}
LABEL_FIELDS = {"warning_label", "retreat_label", "defeated_label"}
FORBIDDEN_STATE_FIELDS = {
    "current_health",
    "current_position",
    "phase",
    "phase_timer",
    "defeated",
    "spawn_chance",
    "seed",
    "loot",
    "drops",
    "reward",
    "score",
    "cargo",
    "wallet",
    "discovery_id",
    "runtime_state",
    "attacks",
}
ID_COLLECTIONS = (
    "entities",
    "zones",
    "progression_containers",
    "moving_hazards",
    "route_objectives",
    "survey_targets",
    "material_candidate_pools",
    "material_projects",
)


def _is_int(value: Any) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def _is_positive_number(value: Any) -> bool:
    return (
        isinstance(value, (int, float))
        and not isinstance(value, bool)
        and math.isfinite(float(value))
        and float(value) > 0.0
    )


def _items(map_data: dict[str, Any], collection: str) -> list[dict[str, Any]]:
    value = map_data.get(collection, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _validate_id(value: Any, label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{label} {field} must be a non-empty string."]
    if not ID_PATTERN.match(value):
        return [f"{label} {field} {value!r} must use lower_snake_case."]
    return []


def _validate_label(value: Any, label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value or "\n" in value or "\r" in value:
        return [f"{label} {field} must be short display-safe text."]
    if not DISPLAY_LABEL_PATTERN.match(value):
        return [f"{label} {field} must be short display-safe text."]
    return []


def _validate_territory(value: Any, label: str, width: int, height: int) -> list[str]:
    if not isinstance(value, dict):
        return [f"{label} territory must be an object with x/y/w/h integer fields."]
    failures: list[str] = []
    if set(value) != {"x", "y", "w", "h"}:
        failures.append(f"{label} territory must contain exactly x, y, w, and h.")
    if not all(field in value and _is_int(value[field]) for field in ("x", "y", "w", "h")):
        failures.append(f"{label} territory x/y/w/h must be integers.")
        return failures
    if int(value["w"]) <= 0 or int(value["h"]) <= 0:
        failures.append(f"{label} territory width and height must be positive.")
    if (
        int(value["x"]) < 0
        or int(value["y"]) < 0
        or int(value["x"]) + int(value["w"]) > width
        or int(value["y"]) + int(value["h"]) > height
    ):
        failures.append(f"{label} territory extends outside map bounds.")
    return failures


def _other_source_ids(map_data: dict[str, Any]) -> set[str]:
    return {
        str(item["id"])
        for collection in ID_COLLECTIONS
        for item in _items(map_data, collection)
        if isinstance(item.get("id"), str)
    }


def _validate_guarded_target(map_data: dict[str, Any], hostile: dict[str, Any]) -> list[str]:
    entities = _items(map_data, "entities")
    guarded = [entity for entity in entities if GUARDED_TARGET_FIELDS & set(entity)]
    if len(guarded) != 1:
        return [f"Combat Foundation requires exactly one guarded salvage target, found {len(guarded)}."]

    target = guarded[0]
    label = str(target.get("id", "guarded salvage"))
    failures: list[str] = []
    if target.get("id") != GUARDED_TARGET_ID or target.get("type") != "salvage":
        failures.append(f"Guarded target must be salvage entity {GUARDED_TARGET_ID!r}.")
    if target.get("guarded_by_hostile_id") != HOSTILE_ID:
        failures.append(f"{label} guarded_by_hostile_id must be {HOSTILE_ID!r}.")
    forbidden = FORBIDDEN_TARGET_LOCK_FIELDS & set(target)
    if forbidden:
        failures.append(
            f"{label} must not author hard collection-lock fields: {', '.join(sorted(forbidden))}."
        )
    if target.get("interaction") != "timed_salvage":
        failures.append(f"{label} must remain an attemptable timed_salvage interaction.")

    territory = hostile.get("territory")
    if isinstance(territory, dict) and all(_is_int(territory.get(field)) for field in ("x", "y", "w", "h")):
        point = (target.get("x"), target.get("y"))
        inside = (
            _is_int(point[0])
            and _is_int(point[1])
            and int(territory["x"]) <= int(point[0]) < int(territory["x"]) + int(territory["w"])
            and int(territory["y"]) <= int(point[1]) < int(territory["y"]) + int(territory["h"])
        )
        if not inside:
            failures.append(f"{label} must be inside the guarding hostile territory.")

    for objective in _items(map_data, "route_objectives"):
        required = objective.get("required_banked_targets", [])
        if isinstance(required, list) and GUARDED_TARGET_ID in required:
            failures.append(
                f"{label} cannot be required by pre-weapon route objective {objective.get('id', '<unnamed>')!r}."
            )
    return failures


def validate_hostile_encounter_schema(map_data: dict[str, Any]) -> list[str]:
    raw = map_data.get("hostile_encounters", [])
    if not isinstance(raw, list):
        return ["hostile_encounters must be a list when present."]
    if not raw:
        return []
    if len(raw) != 1:
        return [f"Combat Foundation supports exactly one hostile encounter, found {len(raw)}."]

    units = map_data.get("units", {})
    width = int(units.get("width_tiles", 0))
    height = int(units.get("height_tiles", 0))
    other_ids = _other_source_ids(map_data)
    hostile = raw[0]
    if not isinstance(hostile, dict):
        return ["hostile_encounters[0] must be an object."]
    label = str(hostile.get("id", "hostile_encounters[0]"))
    failures: list[str] = []
    missing = REQUIRED_FIELDS - set(hostile)
    if missing:
        failures.append(f"{label} is missing required fields: {', '.join(sorted(missing))}.")
    forbidden = FORBIDDEN_STATE_FIELDS & set(hostile)
    if forbidden:
        failures.append(f"{label} must not author runtime/reward fields: {', '.join(sorted(forbidden))}.")
    unknown = set(hostile) - ALLOWED_FIELDS
    if unknown:
        failures.append(f"{label} has unsupported fields: {', '.join(sorted(unknown))}.")

    failures.extend(_validate_id(hostile.get("id"), label, "id"))
    if hostile.get("id") != HOSTILE_ID:
        failures.append(f"{label} id must be {HOSTILE_ID!r}.")
    if hostile.get("id") in other_ids:
        failures.append(f"Duplicate source id {hostile.get('id')!r} across hostile and map collections.")
    if hostile.get("kind") != HOSTILE_KIND:
        failures.append(f"{label} kind must be {HOSTILE_KIND!r}.")
    if hostile.get("behavior") != HOSTILE_BEHAVIOR:
        failures.append(f"{label} behavior must be {HOSTILE_BEHAVIOR!r}.")
    if hostile.get("required_weapon_capability_id") != WEAPON_CAPABILITY_ID:
        failures.append(f"{label} required_weapon_capability_id must be {WEAPON_CAPABILITY_ID!r}.")
    if hostile.get("route_context") != ROUTE_CONTEXT:
        failures.append(f"{label} route_context must be {ROUTE_CONTEXT!r}.")

    for field in ("x", "y"):
        if not _is_int(hostile.get(field)):
            failures.append(f"{label} {field} must be an integer tile coordinate.")
        elif int(hostile[field]) < 0 or int(hostile[field]) >= (width if field == "x" else height):
            failures.append(f"{label} {field} is outside map bounds.")
    failures.extend(_validate_territory(hostile.get("territory"), label, width, height))
    territory = hostile.get("territory")
    if isinstance(territory, dict) and all(field in territory and _is_int(territory[field]) for field in ("x", "y", "w", "h")):
        if _is_int(hostile.get("x")) and _is_int(hostile.get("y")):
            home = (int(hostile["x"]), int(hostile["y"]))
            inside = (
                int(territory["x"]) <= home[0] < int(territory["x"]) + int(territory["w"])
                and int(territory["y"]) <= home[1] < int(territory["y"]) + int(territory["h"])
            )
            if not inside:
                failures.append(f"{label} home point must be inside its territory.")

    for field in POSITIVE_NUMBER_FIELDS:
        if not _is_positive_number(hostile.get(field)):
            failures.append(f"{label} {field} must be a finite positive number.")
    if hostile.get("health") != 3 or not _is_int(hostile.get("health")):
        failures.append(f"{label} health must be exactly 3.")
    if hostile.get("contact_damage") != 1 or not _is_int(hostile.get("contact_damage")):
        failures.append(f"{label} contact_damage must be exactly 1.")
    for field in LABEL_FIELDS:
        failures.extend(_validate_label(hostile.get(field), label, field))
    failures.extend(_validate_guarded_target(map_data, hostile))
    return failures


def validate_hostile_encounter_reachability(
    hostile_encounters: list[dict[str, Any]],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    failures: list[str] = []
    if not isinstance(hostile_encounters, list):
        return failures
    for hostile in hostile_encounters:
        if not isinstance(hostile, dict) or not all(_is_int(hostile.get(field)) for field in ("x", "y")):
            continue
        label = str(hostile.get("id", "hostile_encounter"))
        home = (int(hostile["x"]), int(hostile["y"]))
        if home in solid:
            failures.append(f"{label} hostile home {home} is inside solid terrain.")
        elif home not in reachable:
            failures.append(f"{label} hostile home {home} is unreachable.")
        territory = hostile.get("territory")
        if not isinstance(territory, dict) or not all(_is_int(territory.get(field)) for field in ("x", "y", "w", "h")):
            continue
        bottom_y = int(territory["y"]) + int(territory["h"]) - 1
        evade_lane = {(x, bottom_y) for x in range(int(territory["x"]), int(territory["x"]) + int(territory["w"]))}
        blocked = sorted(cell for cell in evade_lane if cell in solid or cell not in reachable)
        if blocked:
            failures.append(f"{label} lower-edge evade lane is not fully open/reachable. Sample: {blocked[:4]}")
        contact_radius = float(hostile.get("contact_radius_tiles", 0.0))
        if any(math.dist(home, cell) <= contact_radius for cell in evade_lane):
            failures.append(f"{label} lower-edge evade lane intersects the home contact envelope.")
    return failures
