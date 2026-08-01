#!/usr/bin/env python3
"""Validate source-authored two-fragment wreck-network investigations."""

from __future__ import annotations

import re
from typing import Any


INVESTIGATION_ID = "wreck_network_triangulation"
PREREQUISITE_ID = "far_west_deeper_wreck_discovery"
ANALYSIS_DISCOVERY_ID = "wreck_network_triangulation_discovery"
CANONICAL_MAP_ID = "production_level_01"
CANONICAL_ENTRY_ID = "surface_boat_entry"
SCANNER_CAPABILITY_ID = "survey_scanner_1"
FRAGMENTS = {
    "western_chasm_wreck_fragment_discovery": {
        "journey_id": "western_chasm_wreck_fragment_journey",
        "survey_id": "western_chasm_wreck_fragment_survey",
        "artifact_id": "western_chasm_relay_artifact",
        "route_capability_id": "current_stabilizer",
    },
    "abyssal_shelf_wreck_fragment_discovery": {
        "journey_id": "abyssal_shelf_wreck_fragment_journey",
        "survey_id": "abyssal_shelf_wreck_fragment_survey",
        "artifact_id": "abyssal_shelf_relay_artifact",
        "route_capability_id": "pressure_suit_1",
    },
}
REQUIRED_FIELDS = {
    "id",
    "required_discovery_id",
    "fragment_discovery_ids",
    "analysis_discovery_id",
    "analysis_phase",
    "analysis_label",
    "analysis_result_label",
    "next_lead_label",
    "commit_map_id",
    "commit_entry_id",
}
FORBIDDEN_FIELDS = {
    "active",
    "analysis_ready",
    "completed",
    "completed_fragment_ids",
    "cost",
    "current_day",
    "materials",
    "pending",
    "profile_state",
    "progress",
    "reward",
    "score",
    "selected",
    "selected_lead_id",
    "wallet",
}
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
TEXT_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'|:.,+-]{0,95}$")


def _items(map_data: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = map_data.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _records(map_data: dict[str, Any], field: str, record_id: str) -> list[dict[str, Any]]:
    return [item for item in _items(map_data, field) if item.get("id") == record_id]


def _valid_id(value: Any) -> bool:
    return isinstance(value, str) and ID_PATTERN.fullmatch(value) is not None


def _text_failure(value: Any, label: str, field: str) -> list[str]:
    if not isinstance(value, str) or TEXT_PATTERN.fullmatch(value) is None:
        return [f"{label} {field} must be compact single-line display-safe text."]
    return []


def _discovery_sources(map_data: dict[str, Any], discovery_id: str) -> list[dict[str, Any]]:
    sources = [item for item in _items(map_data, "survey_targets") if item.get("discovery_id") == discovery_id]
    sources.extend(
        item
        for item in _items(map_data, "entities")
        if item.get("type") == "tool_target" and item.get("reward_id") == discovery_id
    )
    return sources


def _project_for_capability(map_data: dict[str, Any], capability_id: str) -> list[dict[str, Any]]:
    return [
        item
        for item in _items(map_data, "material_projects")
        if item.get("unlocks_capability_id") == capability_id
    ]


def _validate_investigation_record(
    map_data: dict[str, Any], investigation: dict[str, Any], label: str
) -> list[str]:
    failures: list[str] = []
    missing = REQUIRED_FIELDS - set(investigation)
    if missing:
        failures.append(f"{label} is missing required fields: {', '.join(sorted(missing))}.")
    unsupported = set(investigation) - REQUIRED_FIELDS - FORBIDDEN_FIELDS
    if unsupported:
        failures.append(f"{label} contains unsupported fields: {', '.join(sorted(unsupported))}.")
    forbidden = FORBIDDEN_FIELDS & set(investigation)
    if forbidden:
        failures.append(f"{label} must not author runtime, cost, or reward state: {', '.join(sorted(forbidden))}.")

    expected_ids = {
        "id": INVESTIGATION_ID,
        "required_discovery_id": PREREQUISITE_ID,
        "analysis_discovery_id": ANALYSIS_DISCOVERY_ID,
        "commit_map_id": CANONICAL_MAP_ID,
        "commit_entry_id": CANONICAL_ENTRY_ID,
    }
    for field, expected in expected_ids.items():
        value = investigation.get(field)
        if not _valid_id(value):
            failures.append(f"{label} {field} must use lower_snake_case.")
        elif value != expected:
            failures.append(f"{label} {field} must be {expected!r}.")
    if investigation.get("analysis_phase") != "night_debrief":
        failures.append(f"{label} analysis_phase must be 'night_debrief'.")
    for field in ("analysis_label", "analysis_result_label", "next_lead_label"):
        failures.extend(_text_failure(investigation.get(field), label, field))

    fragment_ids = investigation.get("fragment_discovery_ids")
    if not isinstance(fragment_ids, list):
        failures.append(f"{label} fragment_discovery_ids must be a list.")
    else:
        normalized = [str(value) for value in fragment_ids]
        if len(normalized) != 2 or len(set(normalized)) != 2:
            failures.append(f"{label} must require exactly two unique fragment discovery ids.")
        if set(normalized) != set(FRAGMENTS):
            failures.append(f"{label} fragment_discovery_ids must match the two contract fragments.")

    boat_entries = [
        item
        for item in _items(map_data, "entities")
        if item.get("id") == CANONICAL_ENTRY_ID and item.get("type") == "boat_spawn"
    ]
    if map_data.get("id") != CANONICAL_MAP_ID or len(boat_entries) != 1:
        failures.append(f"{label} canonical commit must resolve to the production-level boat entry.")
    if len(_discovery_sources(map_data, PREREQUISITE_ID)) != 1:
        failures.append(f"{label} prerequisite must resolve to exactly one discovery source.")
    if _discovery_sources(map_data, ANALYSIS_DISCOVERY_ID):
        failures.append(f"{label} final discovery must be produced only by explicit night analysis.")
    return failures


def _validate_fragment(
    map_data: dict[str, Any], investigation_id: str, discovery_id: str, expected: dict[str, str]
) -> list[str]:
    failures: list[str] = []
    label = f"{investigation_id} fragment {discovery_id}"
    surveys = [
        item for item in _items(map_data, "survey_targets") if item.get("discovery_id") == discovery_id
    ]
    if len(surveys) != 1:
        return [f"{label} must resolve to exactly one survey target."]
    survey = surveys[0]
    expected_survey = {
        "id": expected["survey_id"],
        "investigation_id": investigation_id,
        "target_type": "regional",
        "required_capability_id": SCANNER_CAPABILITY_ID,
        "interaction": "survey",
        "required_route_id": expected["journey_id"],
        "route_context": expected["journey_id"],
        "commit_map_id": CANONICAL_MAP_ID,
        "commit_entry_id": CANONICAL_ENTRY_ID,
        "scan_subject_kind": "artifact",
        "scan_subject_id": expected["artifact_id"],
        "scan_reward_kind": "discovery",
        "scan_reward_id": discovery_id,
    }
    for field, value in expected_survey.items():
        if survey.get(field) != value:
            failures.append(f"{label} survey {field} must be {value!r}.")
    if survey.get("interaction_seconds") != 3.0:
        failures.append(f"{label} survey interaction_seconds must be 3.0.")
    if FORBIDDEN_FIELDS & set(survey):
        failures.append(f"{label} survey must not author mutable investigation state.")

    journeys = _records(map_data, "regional_journeys", expected["journey_id"])
    if len(journeys) != 1:
        return [*failures, f"{label} must resolve to exactly one regional journey."]
    journey = journeys[0]
    expected_journey = {
        "required_discovery_id": PREREQUISITE_ID,
        "required_capability_id": expected["route_capability_id"],
        "survey_target_id": expected["survey_id"],
        "commit_entry_id": CANONICAL_ENTRY_ID,
        "route_context": expected["journey_id"],
    }
    for field, value in expected_journey.items():
        if journey.get(field) != value:
            failures.append(f"{label} journey {field} must be {value!r}.")
    if FORBIDDEN_FIELDS & set(journey):
        failures.append(f"{label} journey must not author mutable investigation state.")

    projects = _project_for_capability(map_data, expected["route_capability_id"])
    if len(projects) != 1:
        failures.append(f"{label} route capability must resolve to exactly one material project.")
    elif projects[0].get("required_discovery_id") in {*FRAGMENTS, ANALYSIS_DISCOVERY_ID}:
        failures.append(f"{label} route capability must be available before either fragment.")
    return failures


def validate_wreck_network_investigation_schema(map_data: dict[str, Any]) -> list[str]:
    """Return schema and progression failures; maps without the optional collection remain valid."""
    investigations = map_data.get("wreck_network_investigations", [])
    if investigations == []:
        return []
    if not isinstance(investigations, list):
        return ["wreck_network_investigations must be a list when present."]
    if len(investigations) != 1 or not isinstance(investigations[0], dict):
        return ["wreck_network_investigations must contain exactly one investigation object."]

    investigation = investigations[0]
    label = str(investigation.get("id", "wreck_network_investigations[0]"))
    failures = _validate_investigation_record(map_data, investigation, label)
    investigation_id = str(investigation.get("id", ""))
    lead_labels: set[str] = set()
    lead_guidance: set[str] = set()
    route_contexts: set[str] = set()
    route_capabilities: set[str] = set()
    for discovery_id, expected in FRAGMENTS.items():
        failures.extend(_validate_fragment(map_data, investigation_id, discovery_id, expected))
        journeys = _records(map_data, "regional_journeys", expected["journey_id"])
        if len(journeys) == 1 and isinstance(journeys[0].get("expedition_lead"), dict):
            lead = journeys[0]["expedition_lead"]
            lead_labels.add(str(lead.get("label", "")))
            lead_guidance.add(str(lead.get("active_guidance", "")))
            route_contexts.add(str(journeys[0].get("route_context", "")))
            route_capabilities.add(str(journeys[0].get("required_capability_id", "")))
    if len(lead_labels) != 2 or "" in lead_labels or len(lead_guidance) != 2 or "" in lead_guidance:
        failures.append(f"{label} fragment leads must use distinct non-empty labels and guidance.")
    if len(route_contexts) != 2 or route_capabilities != {"current_stabilizer", "pressure_suit_1"}:
        failures.append(f"{label} fragment routes must use distinct contexts and capability shapes.")
    return failures
