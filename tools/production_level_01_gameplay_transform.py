#!/usr/bin/env python3
"""Transform the proven slice-01 gameplay source into full-level coordinates."""

from __future__ import annotations

from copy import deepcopy

from production_level_01_scanner_artifact import source_overrides
from production_slice_01_gameplay_source import gameplay_sections


SLICE_SOURCE_BOUNDS = {"x": 58, "y": 0, "w": 72, "h": 84}
LOCAL_TO_GLOBAL_OFFSET = {"x": 58, "y": 0}
SLICE_LOCAL_ENTRY = (33, 0)
BOAT_WIDTH = 8

SOURCE_MAP_ID = "production_slice_01"
CANDIDATE_MAP_ID = "production_level_01"
CANDIDATE_MAP_PATH = "res://maps/production_level_01.greybox.json"

SPATIAL_SECTIONS = (
    "zones",
    "progression_containers",
    "moving_hazards",
    "hostile_encounters",
    "biological_resource_sources",
    "survey_targets",
    "background",
    "entities",
    "camera_tests",
)

EXCLUDED_IDS = {
    "zones": {
        "production_slice_bounds",
        "lower_left_loop_connector",
        "lower_left_loop_current",
    },
    "material_projects": {"current_stabilizer_project"},
    "entities": {"surface_boat_entry"},
}

CANDIDATE_PRESENTATION_OVERRIDES = {
    ("zones", "deep_cache_first_step_cue"): {
        "intent": "Opening lower-loop objective cue for its first required target.",
    },
    ("zones", "southwest_pocket_pre_pickup_cue"): {
        "cue_text": "Lower-loop cache ahead",
        "intent": "Pre-pickup route cue for the required non-eel lower-loop payoff.",
    },
    ("route_objectives", "deep_cache_route_objective"): {
        "label": "Lower-loop trail",
        "intent": (
            "Opening objective banks two non-eel lower-loop payoffs before the "
            "shock-prod-gated deep-right cache."
        ),
    },
    ("entities", "salvage_southwest_return_cache"): {
        "intent": (
            "Non-eel valuable payoff completing the opening lower-loop trail; the "
            "separate material route supplies the propulsion-fins recipe."
        ),
    },
    ("entities", "material_rubber_lower_loop"): {
        "intent": "Lower-loop rubber candidate on the non-eel western approach.",
    },
}
CANDIDATE_SOURCE_OVERRIDES = source_overrides()

POINT_FIELDS = ("scan_anchor",)
POINT_LIST_FIELDS = ("path", "patrol", "evade_path", "lane", "candidate_positions")
RECT_FIELDS = ("territory", "evade_geometry")


def slice_local_gameplay_sections() -> dict:
    """Return a fresh copy of the shared gameplay source in slice-local space."""
    return gameplay_sections(SLICE_LOCAL_ENTRY, SLICE_SOURCE_BOUNDS, BOAT_WIDTH)


def _shift_xy(record: dict, x_key: str = "x", y_key: str = "y") -> None:
    if x_key in record:
        record[x_key] = record[x_key] + LOCAL_TO_GLOBAL_OFFSET["x"]
    if y_key in record:
        record[y_key] = record[y_key] + LOCAL_TO_GLOBAL_OFFSET["y"]


def _transform_record(section: str, source_record: dict) -> dict:
    transformed = deepcopy(source_record)
    if section == "camera_tests":
        _shift_xy(transformed, "center_x", "center_y")
        return transformed

    _shift_xy(transformed)
    _shift_xy(transformed, "entry_x", "entry_y")

    for field in POINT_FIELDS:
        point = transformed.get(field)
        if isinstance(point, dict):
            _shift_xy(point)
    for field in POINT_LIST_FIELDS:
        for point in transformed.get(field, []):
            _shift_xy(point)
    for field in RECT_FIELDS:
        rectangle = transformed.get(field)
        if isinstance(rectangle, dict):
            _shift_xy(rectangle)

    if section == "survey_targets":
        transformed["commit_map_id"] = CANDIDATE_MAP_ID
        transformed["commit_map_path"] = CANDIDATE_MAP_PATH
    return transformed


def _geometry_snapshot(section: str, record: dict) -> dict:
    geometry: dict = {}
    if section == "camera_tests":
        for key in ("center_x", "center_y"):
            if key in record:
                geometry[key] = record[key]
    else:
        for key in ("x", "y", "w", "h", "entry_x", "entry_y"):
            if key in record:
                geometry[key] = record[key]
        for field in POINT_FIELDS:
            if field in record:
                geometry[field] = deepcopy(record[field])
        for field in POINT_LIST_FIELDS:
            if field in record:
                geometry[field] = deepcopy(record[field])
        for field in RECT_FIELDS:
            if field in record:
                geometry[field] = deepcopy(record[field])
    return geometry


def transform_gameplay_sections(source_sections: dict | None = None) -> tuple[dict, dict]:
    """Return candidate gameplay sections and inspectable transform provenance."""
    source = source_sections if source_sections is not None else slice_local_gameplay_sections()
    transformed: dict = {}
    reused_ids: dict[str, list[str]] = {}
    coordinate_records: list[dict] = []

    for section, value in source.items():
        if section == "review_questions":
            continue
        if not isinstance(value, list):
            transformed[section] = deepcopy(value)
            continue

        excluded = EXCLUDED_IDS.get(section, set())
        output_records: list = []
        output_ids: list[str] = []
        for source_record in value:
            record_id = str(source_record.get("id", ""))
            if record_id in excluded:
                continue
            effective_source = deepcopy(source_record)
            effective_source.update(
                deepcopy(CANDIDATE_SOURCE_OVERRIDES.get((section, record_id), {}))
            )
            output_record = (
                _transform_record(section, effective_source)
                if section in SPATIAL_SECTIONS
                else effective_source
            )
            output_record.update(
                deepcopy(CANDIDATE_PRESENTATION_OVERRIDES.get((section, record_id), {}))
            )
            output_records.append(output_record)
            if record_id:
                output_ids.append(record_id)

            local_geometry = _geometry_snapshot(section, effective_source)
            if local_geometry:
                coordinate_records.append(
                    {
                        "section": section,
                        "id": record_id,
                        "slice_local": local_geometry,
                        "full_global": _geometry_snapshot(section, output_record),
                    }
                )

        transformed[section] = output_records
        if output_ids:
            reused_ids[section] = output_ids

    provenance = {
        "source_module": "tools/production_slice_01_gameplay_source.py",
        "source_map_id": SOURCE_MAP_ID,
        "source_bounds": deepcopy(SLICE_SOURCE_BOUNDS),
        "local_to_global_offset": deepcopy(LOCAL_TO_GLOBAL_OFFSET),
        "candidate_map_id": CANDIDATE_MAP_ID,
        "coordinate_rule": "full_global = slice_local + (58, 0)",
        "reused_ids": reused_ids,
        "excluded_ids": {
            section: sorted(record_ids)
            for section, record_ids in EXCLUDED_IDS.items()
        },
        "excluded_non_gameplay_sections": ["review_questions"],
        "candidate_reference_overrides": [
            {
                "section": "survey_targets",
                "fields": {
                    "commit_map_id": CANDIDATE_MAP_ID,
                    "commit_map_path": CANDIDATE_MAP_PATH,
                    "commit_entry_id": "surface_boat_entry",
                },
                "intent": "Commit transformed findings at the candidate's canonical boat.",
            }
        ],
        "candidate_presentation_overrides": [
            {
                "section": section,
                "id": record_id,
                "fields": deepcopy(fields),
                "intent": "Remove superseded relay wording without changing mechanics.",
            }
            for (section, record_id), fields in CANDIDATE_PRESENTATION_OVERRIDES.items()
        ],
        "candidate_source_overrides": [
            {
                "section": section,
                "id": record_id,
                "fields": deepcopy(fields),
                "intent": "Full-level scanner artifact source; slices remain unchanged.",
            }
            for (section, record_id), fields in CANDIDATE_SOURCE_OVERRIDES.items()
        ],
        "coordinate_records": coordinate_records,
    }
    return transformed, provenance
