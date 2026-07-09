"""Route objective validation helpers for greybox maps."""

from __future__ import annotations

import re


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,31}$")
ROUTE_OBJECTIVE_FORBIDDEN_FIELDS = {
    "x",
    "y",
    "w",
    "h",
    "score",
    "score_value",
    "oxygen",
    "oxygen_bonus",
    "cargo",
    "cargo_capacity",
    "progress",
    "completed",
    "complete",
    "result_text",
}
OBJECTIVE_STEP_CUE_FIELDS = {
    "objective_step_cue",
    "objective_id",
    "target_id",
    "route_context",
    "objective_step_label",
}
OBJECTIVE_STEP_CUE_TRIGGER_FIELDS = OBJECTIVE_STEP_CUE_FIELDS - {"route_context"}


def is_int_value(value) -> bool:
    return isinstance(value, int) and not isinstance(value, bool)


def rect_cells(item: dict) -> set[tuple[int, int]]:
    cells: set[tuple[int, int]] = set()
    for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
        for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
            cells.add((x, y))
    return cells


def validate_required_fields(item: dict, item_label: str, required_fields: tuple[str, ...]) -> list[str]:
    failures: list[str] = []
    for field in required_fields:
        if field not in item:
            failures.append(f"{item_label} is missing required field {field}.")
    return failures


def validate_id(value, item_label: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} id must be a non-empty string."]
    if not ID_PATTERN.match(value):
        return [f"{item_label} id {value!r} must use lower_snake_case."]
    return []


def validate_display_label(value, item_label: str, field: str) -> list[str]:
    if not isinstance(value, str) or not value:
        return [f"{item_label} {field} must be a non-empty string."]
    if "\n" in value or "\r" in value or not (ID_PATTERN.match(value) or DISPLAY_LABEL_PATTERN.match(value)):
        return [f"{item_label} {field} must be lower_snake_case or short display-safe text."]
    return []


def validate_rect_fields(item: dict, item_label: str, width: int, height: int) -> list[str]:
    failures: list[str] = []
    failures.extend(validate_required_fields(item, item_label, ("x", "y", "w", "h")))
    if failures:
        return failures

    for field in ("x", "y", "w", "h"):
        if not is_int_value(item[field]):
            failures.append(f"{item_label} field {field} must be an integer tile coordinate or size.")
    if failures:
        return failures

    if int(item["w"]) <= 0 or int(item["h"]) <= 0:
        failures.append(f"{item_label} width and height must be positive.")
    if int(item["x"]) < 0 or int(item["y"]) < 0:
        failures.append(f"{item_label} rectangle origin must be inside map bounds.")
    if int(item["x"]) + int(item["w"]) > width or int(item["y"]) + int(item["h"]) > height:
        failures.append(f"{item_label} rectangle extends outside map bounds.")
    return failures


def validate_id_list(value, item_label: str, field: str) -> list[str]:
    failures: list[str] = []
    if not isinstance(value, list) or not value:
        return [f"{item_label} {field} must be a non-empty list."]
    seen: set[str] = set()
    for index, entry in enumerate(value):
        entry_label = f"{item_label} {field}[{index}]"
        failures.extend(validate_id(entry, entry_label))
        if isinstance(entry, str):
            if entry in seen:
                failures.append(f"{item_label} {field} contains duplicate id {entry!r}.")
            seen.add(entry)
    return failures


def validate_route_objective_schema(map_data: dict, entities: list[dict], zones: list[dict]) -> list[str]:
    if "route_objectives" not in map_data:
        return []

    objectives = map_data["route_objectives"]
    if not isinstance(objectives, list):
        return ["route_objectives must be a list."]

    failures: list[str] = []
    width = int(map_data["units"]["width_tiles"])
    height = int(map_data["units"]["height_tiles"])
    entities_by_id = {entity.get("id"): entity for entity in entities if isinstance(entity.get("id"), str)}
    zones_by_id = {zone.get("id"): zone for zone in zones if isinstance(zone.get("id"), str)}
    seen_ids: set[str] = set()

    for index, objective in enumerate(objectives):
        item_label = f"route_objectives[{index}]"
        if not isinstance(objective, dict):
            failures.append(f"{item_label} must be an object.")
            continue

        failures.extend(validate_required_fields(objective, item_label, ("id", "route_context", "label", "required_banked_targets")))
        if "id" in objective:
            failures.extend(validate_id(objective["id"], item_label))
            if objective["id"] in seen_ids:
                failures.append(f"Duplicate route objective id {objective['id']!r}.")
            seen_ids.add(objective["id"])
        if "route_context" in objective:
            route_context = objective["route_context"]
            if not isinstance(route_context, str) or not route_context:
                failures.append(f"{item_label} route_context must be a non-empty string.")
            elif not ID_PATTERN.match(route_context):
                failures.append(f"{item_label} route_context {route_context!r} must use lower_snake_case.")
        if "label" in objective:
            failures.extend(validate_display_label(objective["label"], item_label, "label"))
        if "required_banked_targets" in objective:
            failures.extend(validate_id_list(objective["required_banked_targets"], item_label, "required_banked_targets"))
            target_ids = objective["required_banked_targets"] if isinstance(objective["required_banked_targets"], list) else []
            for target_id in target_ids:
                target = entities_by_id.get(target_id)
                if target is None:
                    failures.append(f"{item_label} required target {target_id!r} does not exist in entities.")
                elif target.get("type") != "salvage":
                    failures.append(f"{item_label} required target {target_id!r} must reference a salvage entity.")
                elif target.get("kind") == "stress_marker":
                    failures.append(f"{item_label} required target {target_id!r} must not be stress_marker salvage.")
        if "supporting_marker_ids" in objective:
            marker_ids = objective["supporting_marker_ids"]
            failures.extend(validate_id_list(marker_ids, item_label, "supporting_marker_ids"))
            for marker_id in marker_ids if isinstance(marker_ids, list) else []:
                marker = zones_by_id.get(marker_id)
                if marker is None:
                    failures.append(f"{item_label} supporting marker {marker_id!r} does not exist in zones.")
                elif marker.get("type") != "marker":
                    failures.append(f"{item_label} supporting marker {marker_id!r} must reference a marker zone.")
                else:
                    failures.extend(validate_rect_fields(marker, f"supporting marker {marker_id}", width, height))
        if "intent" in objective and (not isinstance(objective["intent"], str) or not objective["intent"]):
            failures.append(f"{item_label} intent must be a non-empty string when present.")

        forbidden_fields = ROUTE_OBJECTIVE_FORBIDDEN_FIELDS & set(objective.keys())
        if forbidden_fields:
            fields = ", ".join(sorted(forbidden_fields))
            failures.append(f"{item_label} must not author runtime/placement fields: {fields}.")

    return failures


def validate_objective_step_cue_schema(map_data: dict, entities: list[dict], zones: list[dict]) -> list[str]:
    failures: list[str] = []
    objectives = map_data.get("route_objectives", [])
    objectives_by_id = {
        objective.get("id"): objective
        for objective in objectives
        if isinstance(objective, dict) and isinstance(objective.get("id"), str)
    }
    entities_by_id = {entity.get("id"): entity for entity in entities if isinstance(entity.get("id"), str)}
    cue_zone_ids: list[str] = []

    for index, zone in enumerate(zones):
        cue_fields = OBJECTIVE_STEP_CUE_TRIGGER_FIELDS & set(zone.keys())
        if not cue_fields:
            continue

        item_label = str(zone.get("id", f"zone[{index}]"))
        if zone.get("type") != "marker":
            fields = ", ".join(sorted(cue_fields))
            failures.append(f"{item_label} objective-step cue metadata ({fields}) is only supported on marker zones.")
            continue

        cue_zone_ids.append(item_label)
        failures.extend(
            validate_required_fields(
                zone,
                item_label,
                ("objective_step_cue", "objective_id", "target_id", "route_context", "objective_step_label"),
            )
        )
        if zone.get("objective_step_cue") is not True:
            failures.append(f"{item_label} objective_step_cue must be true when objective-step metadata is present.")

        objective_id = zone.get("objective_id")
        target_id = zone.get("target_id")
        route_context = zone.get("route_context")

        if "objective_id" in zone:
            failures.extend(validate_id(objective_id, f"{item_label} objective_id"))
        if "target_id" in zone:
            failures.extend(validate_id(target_id, f"{item_label} target_id"))
        if "route_context" in zone:
            if not isinstance(route_context, str) or not route_context:
                failures.append(f"{item_label} route_context must be a non-empty string.")
            elif not ID_PATTERN.match(route_context):
                failures.append(f"{item_label} route_context {route_context!r} must use lower_snake_case.")
        if "objective_step_label" in zone:
            failures.extend(validate_display_label(zone["objective_step_label"], item_label, "objective_step_label"))

        objective = objectives_by_id.get(objective_id)
        target = entities_by_id.get(target_id)
        if isinstance(objective_id, str) and objective is None:
            failures.append(f"{item_label} objective_id {objective_id!r} does not exist in route_objectives.")
        if isinstance(target_id, str):
            if target is None:
                failures.append(f"{item_label} target_id {target_id!r} does not exist in entities.")
            elif target.get("type") != "salvage":
                failures.append(f"{item_label} target_id {target_id!r} must reference a salvage entity.")
            elif target.get("kind") == "stress_marker":
                failures.append(f"{item_label} target_id {target_id!r} must not be stress_marker salvage.")
        if isinstance(objective, dict):
            required_targets = objective.get("required_banked_targets", [])
            if isinstance(target_id, str) and isinstance(required_targets, list) and target_id not in required_targets:
                failures.append(f"{item_label} target_id {target_id!r} must be required by objective {objective_id!r}.")
            marker_ids = objective.get("supporting_marker_ids", [])
            if isinstance(marker_ids, list) and zone.get("id") not in marker_ids:
                failures.append(f"{item_label} must be listed in objective {objective_id!r} supporting_marker_ids.")
            if isinstance(route_context, str) and objective.get("route_context") != route_context:
                failures.append(f"{item_label} route_context must match objective {objective_id!r}.")

    if len(cue_zone_ids) > 1:
        failures.append(f"Only one objective-step cue marker is currently supported. Found: {cue_zone_ids}.")
    return failures


def validate_route_objective_reachability(
    map_data: dict,
    entities: list[dict],
    zones: list[dict],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    objectives = map_data.get("route_objectives", [])
    if not isinstance(objectives, list):
        return []

    failures: list[str] = []
    width = int(map_data["units"]["width_tiles"])
    height = int(map_data["units"]["height_tiles"])
    entities_by_id = {entity.get("id"): entity for entity in entities if isinstance(entity.get("id"), str)}
    zones_by_id = {zone.get("id"): zone for zone in zones if isinstance(zone.get("id"), str)}

    for objective in objectives:
        if not isinstance(objective, dict):
            continue
        item_label = f"route objective {objective.get('id', '<unnamed>')}"
        target_ids = objective.get("required_banked_targets", [])
        for target_id in target_ids if isinstance(target_ids, list) else []:
            target = entities_by_id.get(target_id)
            if not target or target.get("type") != "salvage":
                continue
            if not all(is_int_value(target.get(field)) for field in ("x", "y")):
                continue
            point = (int(target["x"]), int(target["y"]))
            if point in solid:
                failures.append(f"{item_label} required target {target_id!r} is inside solid terrain at {point}.")
            elif point not in reachable:
                failures.append(f"{item_label} required target {target_id!r} is unreachable at {point}.")
        marker_ids = objective.get("supporting_marker_ids", [])
        for marker_id in marker_ids if isinstance(marker_ids, list) else []:
            marker = zones_by_id.get(marker_id)
            if not marker or marker.get("type") != "marker" or validate_rect_fields(marker, marker_id, width, height):
                continue
            cells = rect_cells(marker)
            open_cells = cells - solid
            reachable_open_cells = open_cells & reachable
            if not open_cells:
                failures.append(f"{item_label} supporting marker {marker_id!r} has no open cells.")
            elif not reachable_open_cells:
                failures.append(f"{item_label} supporting marker {marker_id!r} has no reachable open cells.")
    return failures


def validate_objective_step_cue_reachability(
    map_data: dict,
    entities: list[dict],
    zones: list[dict],
    solid: set[tuple[int, int]],
    reachable: set[tuple[int, int]],
) -> list[str]:
    failures: list[str] = []
    entry_rects = [
        rect_cells(entity)
        for entity in entities
        if entity.get("type") == "boat_spawn" and all(is_int_value(entity.get(field)) for field in ("x", "y", "w", "h"))
    ]

    for zone in zones:
        if not (OBJECTIVE_STEP_CUE_TRIGGER_FIELDS & set(zone.keys())):
            continue
        if zone.get("type") != "marker" or validate_rect_fields(zone, str(zone.get("id", "objective_step_cue")), int(map_data["units"]["width_tiles"]), int(map_data["units"]["height_tiles"])):
            continue

        item_label = str(zone.get("id", "objective_step_cue"))
        cells = rect_cells(zone)
        solid_cells = sorted(cells & solid)
        reachable_open_cells = (cells - solid) & reachable
        if solid_cells:
            failures.append(f"{item_label} objective-step cue rectangle contains solid cells. Sample: {solid_cells[:4]}")
        if not reachable_open_cells:
            failures.append(f"{item_label} objective-step cue rectangle has no reachable open cells.")
        if any(cells & entry_rect for entry_rect in entry_rects):
            failures.append(f"{item_label} objective-step cue rectangle must not overlap the boat/extraction area.")
    return failures
