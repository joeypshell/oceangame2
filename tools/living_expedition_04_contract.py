"""Validate the bounded Living Expedition 04 companion-hostile relationship."""

from __future__ import annotations

import re
from typing import Any


FIELD = "companion_hostile_responses"
RELATIONSHIP_ID = "deep_cache_eel_companion_response"
HOSTILE_ID = "deep_cache_territorial_eel"
SALVAGE_ID = "salvage_deep_right_cache"
HARVEST_ID = "deep_cache_eel_electrocyte_harvest"
REVIEW_CONTEXT_ID = "living_expedition_04_eel_review_01"
AVAILABILITY = "all_supported_seeds"
ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")

RECORD_FIELDS = {
    "id",
    "kind",
    "hostile_id",
    "guarded_salvage_id",
    "hostile_harvest_id",
    "review_context_id",
    "responses",
    "availability",
    "intent",
}
RESPONSE_FIELDS = {
    "species_id",
    "individual_id",
    "required_adaptation_id",
    "action_id",
    "effect_kind",
    "mutation",
    "damage",
    "required_access_ids",
}
EXPECTED_RESPONSES = {
    "veil_cuttle": {
        "individual_id": "veil_cuttle_juvenile_01",
        "required_adaptation_id": "drift_lens",
        "action_id": "read_drift",
        "effect_kind": "hostile_intent_read",
        "mutation": "none",
    },
    "spark_ray": {
        "individual_id": "spark_ray_juvenile_01",
        "required_adaptation_id": "guardian_pulse",
        "action_id": "guardian_pulse_action",
        "effect_kind": "support_interrupt",
        "damage": 0,
        "required_access_ids": ["shock_prod"],
    },
}


def _items(payload: dict[str, Any], field: str) -> list[dict[str, Any]]:
    value = payload.get(field, [])
    return [item for item in value if isinstance(item, dict)] if isinstance(value, list) else []


def _index(payload: dict[str, Any], field: str) -> dict[str, dict[str, Any]]:
    return {str(item.get("id", "")): item for item in _items(payload, field)}


def _expect_fields(item: dict[str, Any], expected: dict[str, Any], label: str) -> list[str]:
    return [
        f"{label}.{field} must be {value!r}."
        for field, value in expected.items()
        if item.get(field) != value
    ]


def _validate_ids(item: dict[str, Any], fields: tuple[str, ...], label: str) -> list[str]:
    failures: list[str] = []
    for field in fields:
        value = item.get(field)
        if not isinstance(value, str) or not ID_PATTERN.fullmatch(value):
            failures.append(f"{label}.{field} must be a lower_snake_case id.")
    return failures


def _validate_source_links(map_data: dict[str, Any], relationship: dict[str, Any]) -> list[str]:
    failures: list[str] = []
    hostile = _index(map_data, "hostile_encounters").get(str(relationship.get("hostile_id", "")))
    salvage = _index(map_data, "entities").get(str(relationship.get("guarded_salvage_id", "")))
    harvest = _index(map_data, "biological_resource_sources").get(
        str(relationship.get("hostile_harvest_id", ""))
    )
    if hostile is None:
        failures.append(f"{RELATIONSHIP_ID}.hostile_id must reference an existing hostile encounter.")
    elif (
        hostile.get("kind") != "territorial_eel"
        or hostile.get("behavior") != "territorial_lunge"
        or hostile.get("required_weapon_capability_id") != "shock_prod"
    ):
        failures.append(f"{RELATIONSHIP_ID}.hostile_id must retain the Shock-Prod-gated territorial eel.")
    if salvage is None:
        failures.append(f"{RELATIONSHIP_ID}.guarded_salvage_id must reference existing salvage.")
    elif salvage.get("type") != "salvage" or salvage.get("guarded_by_hostile_id") != relationship.get("hostile_id"):
        failures.append(f"{RELATIONSHIP_ID}.guarded_salvage_id must retain its hostile guard relationship.")
    if harvest is None:
        failures.append(f"{RELATIONSHIP_ID}.hostile_harvest_id must reference an existing biological source.")
    elif (
        harvest.get("source_role") != "hostile_harvest"
        or harvest.get("hostile_id") != relationship.get("hostile_id")
        or harvest.get("interaction") != "post_defeat_harvest"
        or harvest.get("material_id") != "eel_electrocyte"
    ):
        failures.append(f"{RELATIONSHIP_ID}.hostile_harvest_id must remain the defeat-only eel electrocyte harvest.")
    return failures


def _validate_response(
    response: dict[str, Any], catalog: dict[str, Any], index: int
) -> list[str]:
    label = f"{RELATIONSHIP_ID}.responses[{index}]"
    failures = _validate_ids(
        response,
        ("species_id", "individual_id", "required_adaptation_id", "action_id", "effect_kind"),
        label,
    )
    unknown = sorted(set(response) - RESPONSE_FIELDS)
    if unknown:
        failures.append(f"{label} contains unsupported authority fields: {unknown}.")
    species_id = str(response.get("species_id", ""))
    expected = EXPECTED_RESPONSES.get(species_id)
    if expected is None:
        failures.append(f"{label}.species_id has no supported LE04 response.")
        return failures
    failures.extend(_expect_fields(response, expected, label))
    expected_fields = {"species_id", *expected.keys()}
    extras = sorted(set(response) - expected_fields)
    if extras:
        failures.append(f"{label} contains fields outside its bounded effect: {extras}.")

    species = _index(catalog, "species").get(species_id, {})
    individual = _index(catalog, "individuals").get(str(response.get("individual_id", "")), {})
    adaptation = _index(catalog, "adaptations").get(str(response.get("required_adaptation_id", "")), {})
    action = _index(catalog, "actions").get(str(response.get("action_id", "")), {})
    if individual.get("species_id") != species_id:
        failures.append(f"{label}.individual_id does not belong to its species.")
    if response.get("required_adaptation_id") not in species.get("adaptation_ids", []):
        failures.append(f"{label}.required_adaptation_id is incompatible with its species.")
    supported_roles = [
        role
        for role in ("independent", "mounted")
        if adaptation.get(f"{role}_action_id") == response.get("action_id")
    ]
    if not supported_roles or any(role not in action.get("roles", []) for role in supported_roles):
        failures.append(f"{label}.action_id is incompatible with its adaptation roles.")
    if action.get("damaging") is not False:
        failures.append(f"{label}.action_id must remain non-damaging in the creature catalog.")
    return failures


def validate_living_expedition_04_relationship(
    map_data: dict[str, Any], catalog: dict[str, Any]
) -> list[str]:
    if FIELD not in map_data:
        return []
    value = map_data.get(FIELD)
    if not isinstance(value, list):
        return [f"{FIELD} must be a list when present."]
    if len(value) != 1 or not isinstance(value[0], dict):
        return [f"{FIELD} must contain exactly one relationship object."]
    relationship = value[0]
    label = str(relationship.get("id", RELATIONSHIP_ID))
    failures = _validate_ids(
        relationship,
        ("id", "kind", "hostile_id", "guarded_salvage_id", "hostile_harvest_id", "review_context_id"),
        label,
    )
    unknown = sorted(set(relationship) - RECORD_FIELDS)
    if unknown:
        failures.append(f"{label} contains copied state, reward, geometry, or authority fields: {unknown}.")
    failures.extend(_expect_fields(relationship, {
        "id": RELATIONSHIP_ID,
        "kind": "companion_hostile_response",
        "hostile_id": HOSTILE_ID,
        "guarded_salvage_id": SALVAGE_ID,
        "hostile_harvest_id": HARVEST_ID,
        "review_context_id": REVIEW_CONTEXT_ID,
        "availability": AVAILABILITY,
    }, label))
    responses = relationship.get("responses")
    if not isinstance(responses, list) or len(responses) != len(EXPECTED_RESPONSES):
        failures.append(f"{label}.responses must contain exactly the Mica and Kite responses.")
        return failures
    if not all(isinstance(response, dict) for response in responses):
        failures.append(f"{label}.responses must contain objects.")
        return failures
    species_ids = [response.get("species_id") for response in responses]
    if species_ids != list(EXPECTED_RESPONSES):
        failures.append(f"{label}.responses must preserve ordered species {list(EXPECTED_RESPONSES)!r}.")
    for index, response in enumerate(responses):
        failures.extend(_validate_response(response, catalog, index))
    failures.extend(_validate_source_links(map_data, relationship))
    return failures
