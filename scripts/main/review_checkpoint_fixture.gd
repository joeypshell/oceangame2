extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")

const EXPANSION_14_START := "expansion_14_start"
const EXPANSION_16_START := "expansion_16_start"
const EXPANSION_17_START := "expansion_17_start"
const EXPANSION_18_START := "expansion_18_start"
const EXPANSION_14_MAP_PATH := "res://maps/production_level_01.greybox.json"
const EXPANSION_16_MAP_PATH := EXPANSION_14_MAP_PATH
const EXPANSION_17_MAP_PATH := EXPANSION_14_MAP_PATH
const EXPANSION_18_MAP_PATH := EXPANSION_14_MAP_PATH
const PRIOR_PROJECT_IDS := [
	ExpansionProfileState.PROPULSION_FINS_PROJECT_ID,
	ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID,
	ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID,
	ExpansionProfileState.SHOCK_PROD_PROJECT_ID,
	ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID,
	ExpansionProfileState.DIVE_LIGHT_PROJECT_ID,
	ExpansionProfileState.PRESSURE_SUIT_PROJECT_ID,
]
const PRIOR_DISCOVERY_IDS := [
	ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID,
	ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID,
	ExpansionProfileState.ANOMALY_DISCOVERY_ID,
	ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID,
	ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID,
	ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID,
	ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID,
	ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID,
	ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID,
	ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID,
]
const STABILIZER_RECIPE := {
	ExpansionProfileState.TITANIUM_MATERIAL_ID: 2,
	ExpansionProfileState.COIL_MATERIAL_ID: 1,
}
const EXPANSION_16_PRIOR_PROJECT_IDS := [
	ExpansionProfileState.PROPULSION_FINS_PROJECT_ID,
	ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID,
	ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID,
	ExpansionProfileState.SHOCK_PROD_PROJECT_ID,
	ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID,
	ExpansionProfileState.DIVE_LIGHT_PROJECT_ID,
	ExpansionProfileState.PRESSURE_SUIT_PROJECT_ID,
	ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID,
]
const EXPANSION_16_PRIOR_DISCOVERY_IDS := [
	ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID,
	ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID,
	ExpansionProfileState.ANOMALY_DISCOVERY_ID,
	ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID,
	ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID,
	ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID,
	ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID,
	ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID,
	ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID,
	ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID,
	ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID,
]
const EXPANSION_17_PRIOR_PROJECT_IDS := [
	ExpansionProfileState.PROPULSION_FINS_PROJECT_ID,
	ExpansionProfileState.SURVEY_SCANNER_PROJECT_ID,
	ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID,
	ExpansionProfileState.SHOCK_PROD_PROJECT_ID,
	ExpansionProfileState.SHOCK_PROD_CAPACITOR_PROJECT_ID,
	ExpansionProfileState.DIVE_LIGHT_PROJECT_ID,
	ExpansionProfileState.PRESSURE_SUIT_PROJECT_ID,
	ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID,
	ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID,
]
const EXPANSION_17_PRIOR_DISCOVERY_IDS := [
	ExpansionProfileState.PROPULSION_FINS_BLUEPRINT_ID,
	ExpansionProfileState.SURVEY_SCANNER_BLUEPRINT_ID,
	ExpansionProfileState.ANOMALY_DISCOVERY_ID,
	ExpansionProfileState.SALVAGE_CUTTER_BLUEPRINT_ID,
	ExpansionProfileState.MINERAL_TRACE_RESEARCH_ID,
	ExpansionProfileState.SIGNAL_REEF_DISCOVERY_ID,
	ExpansionProfileState.DEEP_HARMONIC_DISCOVERY_ID,
	ExpansionProfileState.ABYSSAL_HARMONIC_DISCOVERY_ID,
	ExpansionProfileState.SOUTHEAST_WRECK_NAVIGATION_DATA_ID,
	ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID,
	ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID,
	ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID,
]
const EXPANSION_18_PRIOR_PROJECT_IDS := EXPANSION_17_PRIOR_PROJECT_IDS
const EXPANSION_18_PRIOR_DISCOVERY_IDS := EXPANSION_17_PRIOR_DISCOVERY_IDS + [
	ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID,
	ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID,
	ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID,
]
const REBREATHER_RECIPE := {
	ExpansionProfileState.TITANIUM_MATERIAL_ID: 1,
	ExpansionProfileState.RUBBER_MATERIAL_ID: 1,
	ExpansionProfileState.COIL_MATERIAL_ID: 1,
	ExpansionProfileState.INSULATING_GEL_MATERIAL_ID: 1,
}


static func is_supported(checkpoint_id: String) -> bool:
	return checkpoint_id in [EXPANSION_14_START, EXPANSION_16_START, EXPANSION_17_START, EXPANSION_18_START]


static func required_map_path(checkpoint_id: String) -> String:
	return EXPANSION_14_MAP_PATH if is_supported(checkpoint_id) else ""


static func apply(checkpoint_id: String, profile) -> Dictionary:
	if not is_supported(checkpoint_id):
		return _result(false, checkpoint_id, "unsupported_checkpoint")
	if profile == null:
		return _result(false, checkpoint_id, "missing_profile")
	if not _profile_is_empty(profile):
		return _result(false, checkpoint_id, "profile_not_empty")

	var source := _load_project_source(required_map_path(checkpoint_id))
	if not bool(source.get("ready", false)):
		return _result(false, checkpoint_id, str(source.get("reason", "source_error")), source)
	var project_ids: Array = _project_ids_for(checkpoint_id)
	var discovery_ids: Array = _discovery_ids_for(checkpoint_id)
	var recipe: Dictionary = _recipe_for(checkpoint_id)
	var projects: Array = source.get("projects", [])
	for project_id in project_ids:
		var completion := _complete_project(profile, _project_by_id(projects, project_id))
		if not bool(completion.get("ready", false)):
			return _result(false, checkpoint_id, "project_fixture_failed", completion)
	for discovery_id in discovery_ids:
		var discovery := _complete_discovery(profile, discovery_id)
		if not bool(discovery.get("ready", false)):
			return _result(false, checkpoint_id, "discovery_fixture_failed", discovery)
	for target_id in _banked_target_ids_for(checkpoint_id):
		var banked: Dictionary = profile.bank_tool_target(target_id, false)
		if not bool(banked.get("changed", false)):
			return _result(false, checkpoint_id, "recorder_fixture_failed", banked)
	if not recipe.is_empty():
		var deposit: Dictionary = profile.deposit_materials(recipe, false)
		if not bool(deposit.get("changed", false)):
			return _result(false, checkpoint_id, "recipe_fixture_failed", deposit)
	if not _boundary_is_ready(checkpoint_id, profile):
		return _result(false, checkpoint_id, "checkpoint_boundary_drift", profile.report())
	var result := {
		"map_path": required_map_path(checkpoint_id),
		"completed_projects": project_ids.duplicate(),
		"banked_materials": recipe.duplicate(true),
	}
	if checkpoint_id == EXPANSION_18_START:
		result["active_objective_id"] = "transfer_hub_core_recovery"
		result["active_objective_label"] = "Transfer Hub"
	return _result(true, checkpoint_id, "ready", result)


static func _project_ids_for(checkpoint_id: String) -> Array:
	if checkpoint_id == EXPANSION_18_START:
		return EXPANSION_18_PRIOR_PROJECT_IDS
	if checkpoint_id == EXPANSION_17_START:
		return EXPANSION_17_PRIOR_PROJECT_IDS
	if checkpoint_id == EXPANSION_16_START:
		return EXPANSION_16_PRIOR_PROJECT_IDS
	return PRIOR_PROJECT_IDS


static func _discovery_ids_for(checkpoint_id: String) -> Array:
	if checkpoint_id == EXPANSION_18_START:
		return EXPANSION_18_PRIOR_DISCOVERY_IDS
	if checkpoint_id == EXPANSION_17_START:
		return EXPANSION_17_PRIOR_DISCOVERY_IDS
	if checkpoint_id == EXPANSION_16_START:
		return EXPANSION_16_PRIOR_DISCOVERY_IDS
	return PRIOR_DISCOVERY_IDS


static func _recipe_for(checkpoint_id: String) -> Dictionary:
	if checkpoint_id in [EXPANSION_17_START, EXPANSION_18_START]:
		return {}
	return REBREATHER_RECIPE if checkpoint_id == EXPANSION_16_START else STABILIZER_RECIPE


static func _banked_target_ids_for(checkpoint_id: String) -> Array:
	var target_ids: Array = [ExpansionProfileState.SOUTHEAST_WRECK_RECORDER_ID]
	if checkpoint_id in [EXPANSION_17_START, EXPANSION_18_START]:
		target_ids.append(ExpansionProfileState.FAR_WEST_WRECK_RECORDER_ID)
	return target_ids


static func _complete_project(profile, project: Dictionary) -> Dictionary:
	if project.is_empty():
		return {"ready": false, "reason": "missing_project"}
	var discovery := _complete_discovery(profile, str(project.get("required_discovery_id", "")))
	if not bool(discovery.get("ready", false)):
		return discovery
	var missing := {}
	for material_id in project.get("required_materials", {}):
		var quantity: int = int(project["required_materials"][material_id]) - profile.material_quantity(str(material_id))
		if quantity > 0:
			missing[str(material_id)] = quantity
	if not missing.is_empty():
		var deposited: Dictionary = profile.deposit_materials(missing, false)
		if not bool(deposited.get("changed", false)):
			return {"ready": false, "reason": "material_fixture_failed", "detail": deposited}
	var completed: Dictionary = profile.complete_material_project(project, false)
	return {
		"ready": bool(completed.get("changed", false)),
		"reason": str(completed.get("reason", "project_failed")),
		"project_id": str(project.get("id", "")),
		"detail": completed,
	}


static func _complete_discovery(profile, discovery_id: String) -> Dictionary:
	if discovery_id.is_empty() or profile.has_completed_discovery(discovery_id):
		return {"ready": true, "reason": "already_completed", "discovery_id": discovery_id}
	var completed: Dictionary = profile.complete_discovery(discovery_id, false)
	return {
		"ready": bool(completed.get("changed", false)),
		"reason": str(completed.get("reason", "discovery_failed")),
		"discovery_id": discovery_id,
		"detail": completed,
	}


static func _load_project_source(map_path: String) -> Dictionary:
	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		return {"ready": false, "reason": "map_open_failed", "map_path": map_path}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {"ready": false, "reason": "map_parse_failed", "map_path": map_path}
	var projects = json.data.get("material_projects", [])
	if typeof(projects) != TYPE_ARRAY:
		return {"ready": false, "reason": "project_source_invalid", "map_path": map_path}
	return {"ready": true, "projects": projects}


static func _project_by_id(projects: Array, project_id: String) -> Dictionary:
	for project in projects:
		if typeof(project) == TYPE_DICTIONARY and str(project.get("id", "")) == project_id:
			return project.duplicate(true)
	return {}


static func _profile_is_empty(profile) -> bool:
	var report: Dictionary = profile.report()
	return (
		report.get("completed_discoveries", []).is_empty()
		and report.get("unlocked_capabilities", []).is_empty()
		and report.get("completed_projects", []).is_empty()
		and report.get("material_inventory", {}).is_empty()
		and report.get("banked_tool_target_ids", []).is_empty()
	)


static func _boundary_is_ready(checkpoint_id: String, profile) -> bool:
	if checkpoint_id == EXPANSION_18_START:
		return (
			profile.has_completed_project(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID)
			and profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID)
			and profile.has_completed_discovery(ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID)
			and profile.has_completed_discovery(ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID)
			and profile.has_completed_discovery(ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID)
			and not profile.has_completed_discovery(ExpansionProfileState.TRANSFER_HUB_NAVIGATION_CORE_DISCOVERY_ID)
			and profile.material_inventory().is_empty()
		)
	if checkpoint_id == EXPANSION_17_START:
		return (
			profile.has_completed_project(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID)
			and profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID)
			and profile.has_completed_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID)
			and profile.has_banked_tool_target(ExpansionProfileState.FAR_WEST_WRECK_RECORDER_ID)
			and not profile.has_completed_discovery(ExpansionProfileState.WESTERN_CHASM_FRAGMENT_DISCOVERY_ID)
			and not profile.has_completed_discovery(ExpansionProfileState.ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID)
			and not profile.has_completed_discovery(ExpansionProfileState.WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID)
			and profile.material_inventory().is_empty()
		)
	if checkpoint_id == EXPANSION_16_START:
		return (
			profile.has_completed_project(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID)
			and profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID)
			and profile.has_completed_discovery(ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID)
			and not profile.has_completed_project(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_PROJECT_ID)
			and not profile.has_capability(ExpansionProfileState.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID)
			and not profile.has_completed_discovery(ExpansionProfileState.FAR_WEST_WRECK_DISCOVERY_ID)
			and not profile.has_banked_tool_target(ExpansionProfileState.FAR_WEST_WRECK_RECORDER_ID)
			and profile.material_inventory() == REBREATHER_RECIPE
		)
	return (
		profile.has_completed_discovery(ExpansionProfileState.SOUTHEAST_WRECK_DISCOVERY_ID)
		and profile.has_banked_tool_target(ExpansionProfileState.SOUTHEAST_WRECK_RECORDER_ID)
		and profile.has_completed_project(ExpansionProfileState.SALVAGE_CUTTER_PROJECT_ID)
		and not profile.has_completed_project(ExpansionProfileState.CURRENT_STABILIZER_PROJECT_ID)
		and not profile.has_capability(ExpansionProfileState.CURRENT_STABILIZER_CAPABILITY_ID)
		and not profile.has_completed_discovery(ExpansionProfileState.UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID)
		and profile.material_inventory() == STABILIZER_RECIPE
	)


static func _result(ready: bool, checkpoint_id: String, reason: String, extra := {}) -> Dictionary:
	var result := {"ready": ready, "checkpoint_id": checkpoint_id, "reason": reason}
	for key in extra:
		result[key] = extra[key]
	return result
