"""Locked ids and rules for the bounded material/project source schema."""

from __future__ import annotations

import re


ID_PATTERN = re.compile(r"^[a-z][a-z0-9_]*$")
DISPLAY_LABEL_PATTERN = re.compile(r"^[A-Za-z0-9][A-Za-z0-9 _'-]{0,47}$")
SUPPORTED_MATERIALS = {
    "titanium_scrap", "rubber_sheet", "conductive_coil", "insulating_gel", "eel_electrocyte",
}
SUPPORTED_PROJECTS = {
    "propulsion_fins_project", "salvage_cutter_project", "current_stabilizer_project",
    "shock_prod_project", "shock_prod_capacitor_project",
}
SUPPORTED_CAPABILITIES = {
    "propulsion_fins", "salvage_cutter", "current_stabilizer", "shock_prod", "shock_prod_capacitor",
}
SUPPORTED_STRATEGIES = {"day_rotation_v1"}
SUPPORTED_BUILD_PHASES = {"night_debrief"}
MINIMUM_CANDIDATES = {"titanium_scrap": 4, "rubber_sheet": 2, "conductive_coil": 2}
EXPECTED_RECIPES = {
    "propulsion_fins_project": {"titanium_scrap": 2, "rubber_sheet": 1},
    "salvage_cutter_project": {"titanium_scrap": 2, "conductive_coil": 1},
    "current_stabilizer_project": {"titanium_scrap": 2, "conductive_coil": 1},
    "shock_prod_project": {"titanium_scrap": 2, "conductive_coil": 1},
    "shock_prod_capacitor_project": {
        "conductive_coil": 1, "insulating_gel": 1, "eel_electrocyte": 1,
    },
}
PROJECT_RULES = {
    "propulsion_fins_project": {
        "capability_id": "propulsion_fins",
        "required_discovery_id": None,
        "required_project_id": None,
        "target_field": "target_gate_id",
    },
    "salvage_cutter_project": {
        "capability_id": "salvage_cutter",
        "required_discovery_id": "lower_right_anomaly_discovery",
        "required_project_id": None,
        "target_field": "target_id",
    },
    "current_stabilizer_project": {
        "capability_id": "current_stabilizer",
        "required_discovery_id": "lower_right_anomaly_discovery",
        "required_project_id": "salvage_cutter_project",
        "target_field": "target_gate_id",
    },
    "shock_prod_project": {
        "capability_id": "shock_prod",
        "required_discovery_id": "lower_right_anomaly_discovery",
        "required_project_id": "current_stabilizer_project",
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
