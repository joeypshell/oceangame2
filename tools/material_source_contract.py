"""Locked ids and rules for the bounded material/project source schema."""

from __future__ import annotations

import re


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,47}$")
SUPPORTED_MATERIALS = {
    "titanium_scrap", "rubber_sheet", "conductive_coil", "insulating_gel", "eel_electrocyte",
}
SUPPORTED_PROJECTS = {
    "propulsion_fins_project", "survey_scanner_project", "salvage_cutter_project", "current_stabilizer_project",
    "shock_prod_project", "shock_prod_capacitor_project", "dive_light_1_project", "pressure_suit_1_project",
}
SUPPORTED_CAPABILITIES = {
    "propulsion_fins", "survey_scanner_1", "salvage_cutter", "current_stabilizer", "shock_prod", "shock_prod_capacitor",
    "dive_light_1", "pressure_suit_1",
}
SUPPORTED_STRATEGIES = {"day_rotation_v1"}
SUPPORTED_BUILD_PHASES = {"night_debrief"}
MINIMUM_CANDIDATES = {"titanium_scrap": 4, "rubber_sheet": 2, "conductive_coil": 2}
EXPECTED_RECIPES = {
    "propulsion_fins_project": {"titanium_scrap": 2, "rubber_sheet": 1},
    "survey_scanner_project": {"titanium_scrap": 1, "conductive_coil": 1},
    "salvage_cutter_project": {"titanium_scrap": 2, "conductive_coil": 1},
    "current_stabilizer_project": {"titanium_scrap": 2, "conductive_coil": 1},
    "shock_prod_project": {"titanium_scrap": 2, "conductive_coil": 1},
    "shock_prod_capacitor_project": {
        "conductive_coil": 1, "insulating_gel": 1, "eel_electrocyte": 1,
    },
    "dive_light_1_project": {
        "titanium_scrap": 1, "conductive_coil": 1, "insulating_gel": 1,
    },
    "pressure_suit_1_project": {
        "titanium_scrap": 2, "rubber_sheet": 1, "insulating_gel": 1,
    },
}
PROJECT_RULES = {
    "propulsion_fins_project": {
        "capability_id": "propulsion_fins",
        "required_discovery_id": "propulsion_fins_blueprint",
        "required_project_id": None,
        "target_field": "target_gate_id",
    },
    "survey_scanner_project": {
        "capability_id": "survey_scanner_1",
        "required_discovery_id": "survey_scanner_blueprint",
        "required_project_id": None,
        "target_field": "target_id",
        "target_collection": "survey_targets",
    },
    "salvage_cutter_project": {
        "capability_id": "salvage_cutter",
        "required_discovery_id": "salvage_cutter_blueprint",
        "legacy_required_discovery_id": "lower_right_anomaly_discovery",
        "required_project_id": None,
        "target_field": "target_id",
    },
    "current_stabilizer_project": {
        "capability_id": "current_stabilizer",
        "required_discovery_id": "southeast_wreck_archive_discovery",
        "legacy_required_discovery_id": "lower_right_anomaly_discovery",
        "required_project_id": "salvage_cutter_project",
        "target_field": "target_gate_id",
        "target_id": "upper_left_wreck_relay_current",
        "legacy_target_id": "lower_left_loop_current",
        "canonical_map_id": "production_level_01",
        "legacy_map_ids": ("production_slice_01", "material_fixture"),
    },
    "shock_prod_project": {
        "capability_id": "shock_prod",
        "required_discovery_id": "lower_right_anomaly_discovery",
        "required_project_id": "salvage_cutter_project",
        "target_field": "target_hostile_id",
        "hostile_required_capability_id": "shock_prod",
    },
    "shock_prod_capacitor_project": {
        "capability_id": "shock_prod_capacitor",
        "required_discovery_id": "lower_right_anomaly_discovery",
        "required_project_id": "shock_prod_project",
        "target_field": "target_hostile_id",
        "hostile_required_capability_id": "shock_prod",
        "capability_effect": "interrupt_warning_lunge",
    },
    "dive_light_1_project": {
        "capability_id": "dive_light_1",
        "required_discovery_id": "lower_right_signal_reef_discovery",
        "required_project_id": None,
        "target_field": "target_id",
        "target_collection": "survey_targets",
        "target_capability_field": "required_light_capability_id",
    },
    "pressure_suit_1_project": {
        "capability_id": "pressure_suit_1",
        "required_discovery_id": "signal_reef_deep_harmonic_discovery",
        "required_project_id": None,
        "target_field": "target_id",
        "target_collection": "survey_targets",
        "target_capability_field": "required_pressure_capability_id",
    },
}
MATERIAL_FIELDS = {"material_id", "material_quantity", "candidate_pool_id"}
TOOL_FIELDS = {"required_tool_id", "tool_project_id"}
PROJECT_FIELDS = {
    "id", "required_project_id", "required_discovery_id", "required_materials", "unlocks_capability_id",
    "target_id", "target_gate_id", "target_hostile_id", "capability_effect", "build_phase", "project_label",
    "completion_label",
}
RUNTIME_FIELDS = {
    "active", "banked", "capability_owned", "collected", "completed", "day_seed", "depleted", "held",
    "oxygen", "profile_state", "progress", "result_text", "save_path", "score", "selected", "wallet",
}


def project_rule_for_map(project_id: str, map_id: str, primary_discovery_present: bool = True) -> dict | None:
    """Resolve one exact canonical or legacy rule without accepting mixed pairs."""
    source = PROJECT_RULES.get(project_id)
    if source is None:
        return None
    rule = dict(source)
    canonical_map_id = str(rule.get("canonical_map_id", ""))
    legacy_map_ids = set(rule.get("legacy_map_ids", ()))
    use_legacy = bool(canonical_map_id and map_id in legacy_map_ids)
    if canonical_map_id and map_id != canonical_map_id and not use_legacy:
        rule["unsupported_map_id"] = map_id
    if not canonical_map_id and rule.get("legacy_required_discovery_id") is not None:
        use_legacy = not primary_discovery_present
    if use_legacy:
        rule["required_discovery_id"] = rule["legacy_required_discovery_id"]
        if "legacy_target_id" in rule:
            rule["target_id"] = rule["legacy_target_id"]
    return rule
