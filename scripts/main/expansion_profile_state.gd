extends RefCounted

const ProgressionContract := preload("res://scripts/main/progression_contract.gd")
const CompanionProfileState := preload("res://scripts/main/companion_profile_state.gd")
const SignalReefJourneyProfileState := preload("res://scripts/main/signal_reef_journey_profile_state.gd")
const ExpansionProfileMigrations := preload("res://scripts/main/expansion_profile_migrations.gd")
const ExpansionProfileProjectRules := preload("res://scripts/main/expansion_profile_project_rules.gd")
const ExpansionProfileSchema := preload("res://scripts/main/expansion_profile_schema.gd")
const ExpansionProfileStorage := preload("res://scripts/main/expansion_profile_storage.gd")
const SCHEMA_VERSION := ExpansionProfileSchema.SCHEMA_VERSION
const COMPANION_SCHEMA_VERSION := ExpansionProfileSchema.COMPANION_SCHEMA_VERSION
const TOOL_TARGET_SCHEMA_VERSION := ExpansionProfileSchema.TOOL_TARGET_SCHEMA_VERSION
const PROJECT_SCHEMA_VERSION := ExpansionProfileSchema.PROJECT_SCHEMA_VERSION
const MATERIAL_SCHEMA_VERSION := ExpansionProfileSchema.MATERIAL_SCHEMA_VERSION
const LEGACY_SCHEMA_VERSION := ExpansionProfileSchema.LEGACY_SCHEMA_VERSION
const SURVEY_SCANNER_CAPABILITY_ID := ProgressionContract.SCANNER_CAPABILITY_ID
const SURVEY_SCANNER_PROJECT_ID := "survey_scanner_project"
const SURVEY_SCANNER_BLUEPRINT_ID := "survey_scanner_blueprint"
const SURVEY_SCANNER_TARGET_ID := "lower_right_anomaly_survey"
const PROPULSION_FINS_CAPABILITY_ID := "propulsion_fins"
const PROPULSION_FINS_PROJECT_ID := "propulsion_fins_project"
const PROPULSION_FINS_BLUEPRINT_ID := "propulsion_fins_blueprint"
const PROPULSION_FINS_GATE_ID := "upper_right_current_pocket_gate"
const SALVAGE_CUTTER_CAPABILITY_ID := "salvage_cutter"
const ANOMALY_DISCOVERY_ID := "lower_right_anomaly_discovery"
const SALVAGE_CUTTER_BLUEPRINT_ID := "salvage_cutter_blueprint"
const MINERAL_TRACE_RESEARCH_ID := "upper_right_mineral_trace_research"
const SIGNAL_REEF_DISCOVERY_ID := "lower_right_signal_reef_discovery"
const DEEP_HARMONIC_DISCOVERY_ID := "signal_reef_deep_harmonic_discovery"
const ABYSSAL_HARMONIC_DISCOVERY_ID := "abyssal_basin_harmonic_source_discovery"
const SOUTHEAST_WRECK_DISCOVERY_ID := "southeast_wreck_archive_discovery"
const SOUTHEAST_WRECK_NAVIGATION_DATA_ID := "southeast_wreck_navigation_data"
const UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID := "upper_left_wreck_relay_discovery"
const FAR_WEST_WRECK_DISCOVERY_ID := "far_west_deeper_wreck_discovery"
const WESTERN_CHASM_FRAGMENT_DISCOVERY_ID := "western_chasm_wreck_fragment_discovery"
const ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID := "abyssal_shelf_wreck_fragment_discovery"
const WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID := "wreck_network_triangulation_discovery"
const TRANSFER_HUB_NAVIGATION_CORE_DISCOVERY_ID := "transfer_hub_navigation_core_discovery"
const DIVE_LIGHT_CAPABILITY_ID := ProgressionContract.DIVE_LIGHT_CAPABILITY_ID
const DIVE_LIGHT_PROJECT_ID := "dive_light_1_project"
const DIVE_LIGHT_TARGET_ID := "signal_reef_deep_harmonic_survey"
const PRESSURE_SUIT_CAPABILITY_ID := ProgressionContract.PRESSURE_SUIT_CAPABILITY_ID
const PRESSURE_SUIT_PROJECT_ID := "pressure_suit_1_project"
const CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID := ProgressionContract.CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID
const CLOSED_CIRCUIT_REBREATHER_PROJECT_ID := "closed_circuit_rebreather_project"
const SALVAGE_CUTTER_PROJECT_ID := "salvage_cutter_project"
const SALVAGE_CUTTER_TARGET_ID := "salvage_sealed_wreck_cache"
const SOUTHEAST_WRECK_RECORDER_ID := "southeast_wreck_recorder"
const FAR_WEST_WRECK_RECORDER_ID := "far_west_wreck_data_recorder"
const CURRENT_STABILIZER_CAPABILITY_ID := "current_stabilizer"
const CURRENT_STABILIZER_PROJECT_ID := "current_stabilizer_project"
const CURRENT_STABILIZER_GATE_ID := "lower_left_loop_current"
const SHOCK_PROD_CAPABILITY_ID := "shock_prod"
const SHOCK_PROD_PROJECT_ID := "shock_prod_project"
const SHOCK_PROD_TARGET_ID := "deep_cache_territorial_eel"
const SHOCK_PROD_CAPACITOR_CAPABILITY_ID := "shock_prod_capacitor"
const SHOCK_PROD_CAPACITOR_PROJECT_ID := "shock_prod_capacitor_project"
const TITANIUM_MATERIAL_ID := "titanium_scrap"
const RUBBER_MATERIAL_ID := "rubber_sheet"
const COIL_MATERIAL_ID := "conductive_coil"
const INSULATING_GEL_MATERIAL_ID := "insulating_gel"
const EEL_ELECTROCYTE_MATERIAL_ID := "eel_electrocyte"
const DEFAULT_STORAGE_PATH := "user://oceangame2_profile.json"
const LEGACY_CAPABILITY_IDS := {SURVEY_SCANNER_CAPABILITY_ID: true}
const MATERIAL_SCHEMA_CAPABILITY_IDS := {SURVEY_SCANNER_CAPABILITY_ID: true, SALVAGE_CUTTER_CAPABILITY_ID: true}
const SUPPORTED_CAPABILITY_IDS := {SURVEY_SCANNER_CAPABILITY_ID: true, PROPULSION_FINS_CAPABILITY_ID: true, SALVAGE_CUTTER_CAPABILITY_ID: true, CURRENT_STABILIZER_CAPABILITY_ID: true, SHOCK_PROD_CAPABILITY_ID: true, SHOCK_PROD_CAPACITOR_CAPABILITY_ID: true, DIVE_LIGHT_CAPABILITY_ID: true, PRESSURE_SUIT_CAPABILITY_ID: true, CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID: true}
const SUPPORTED_DISCOVERY_IDS := {PROPULSION_FINS_BLUEPRINT_ID: true, SURVEY_SCANNER_BLUEPRINT_ID: true, ANOMALY_DISCOVERY_ID: true, SALVAGE_CUTTER_BLUEPRINT_ID: true, MINERAL_TRACE_RESEARCH_ID: true, SIGNAL_REEF_DISCOVERY_ID: true, DEEP_HARMONIC_DISCOVERY_ID: true, ABYSSAL_HARMONIC_DISCOVERY_ID: true, SOUTHEAST_WRECK_DISCOVERY_ID: true, SOUTHEAST_WRECK_NAVIGATION_DATA_ID: true, UPPER_LEFT_WRECK_RELAY_DISCOVERY_ID: true, FAR_WEST_WRECK_DISCOVERY_ID: true, WESTERN_CHASM_FRAGMENT_DISCOVERY_ID: true, ABYSSAL_SHELF_FRAGMENT_DISCOVERY_ID: true, WRECK_NETWORK_TRIANGULATION_DISCOVERY_ID: true, TRANSFER_HUB_NAVIGATION_CORE_DISCOVERY_ID: true}
const SUPPORTED_MATERIAL_IDS := {TITANIUM_MATERIAL_ID: true, RUBBER_MATERIAL_ID: true, COIL_MATERIAL_ID: true, INSULATING_GEL_MATERIAL_ID: true, EEL_ELECTROCYTE_MATERIAL_ID: true}
const MATERIAL_SCHEMA_PROJECT_IDS := {SALVAGE_CUTTER_PROJECT_ID: true}
const SUPPORTED_PROJECT_IDS := {PROPULSION_FINS_PROJECT_ID: true, SURVEY_SCANNER_PROJECT_ID: true, SALVAGE_CUTTER_PROJECT_ID: true, CURRENT_STABILIZER_PROJECT_ID: true, SHOCK_PROD_PROJECT_ID: true, SHOCK_PROD_CAPACITOR_PROJECT_ID: true, DIVE_LIGHT_PROJECT_ID: true, PRESSURE_SUIT_PROJECT_ID: true, CLOSED_CIRCUIT_REBREATHER_PROJECT_ID: true}
const SUPPORTED_BANKED_TOOL_TARGET_IDS := {SOUTHEAST_WRECK_RECORDER_ID: true, FAR_WEST_WRECK_RECORDER_ID: true}
const PROJECT_RULES := ExpansionProfileProjectRules.RULES

var _storage_path: String
var _persistence_enabled: bool
var _completed_discoveries := {}
var _unlocked_capabilities := {}
var _material_inventory := {}
var _completed_projects := {}
var _banked_tool_target_ids := {}
var _companion_profile := CompanionProfileState.new()
var _regional_journey_profile := SignalReefJourneyProfileState.new()
var _last_storage_report := {"status": "not_loaded"}
func _init(storage_path := DEFAULT_STORAGE_PATH, persistence_enabled := true) -> void:
	_storage_path = str(storage_path)
	_persistence_enabled = persistence_enabled

func load_profile() -> Dictionary:
	_reset_memory()
	if not _persistence_enabled:
		_last_storage_report = _report("memory")
		return _last_storage_report.duplicate(true)
	ExpansionProfileStorage.recover_interrupted_write(_storage_path)
	if not FileAccess.file_exists(_storage_path):
		_last_storage_report = _report("missing")
		return _last_storage_report.duplicate(true)
	var file := FileAccess.open(_storage_path, FileAccess.READ)
	if file == null:
		_last_storage_report = _report("read_error")
		return _last_storage_report.duplicate(true)
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or typeof(json.data) != TYPE_DICTIONARY:
		_last_storage_report = _report("invalid_json")
		return _last_storage_report.duplicate(true)
	var payload := json.data as Dictionary
	var migrations: Dictionary = ExpansionProfileMigrations.apply(payload, _migration_ids())
	var loaded_companion_version := int((payload.get("companion_profile", {}) as Dictionary).get("schema_version", 0)) if typeof(payload.get("companion_profile")) == TYPE_DICTIONARY else 0
	var failures := _validate_payload(payload)
	if not failures.is_empty():
		_last_storage_report = _report("invalid_schema", {"failures": failures})
		return _last_storage_report.duplicate(true)
	_load_ids(payload["completed_discoveries"], _completed_discoveries)
	_load_ids(payload["unlocked_capabilities"], _unlocked_capabilities)
	var loaded_version := int(payload.get("schema_version", 0))
	if loaded_version >= MATERIAL_SCHEMA_VERSION:
		for material_id in payload["material_inventory"]:
			_material_inventory[str(material_id)] = int(payload["material_inventory"][material_id])
		_load_ids(payload["completed_projects"], _completed_projects)
	if loaded_version >= COMPANION_SCHEMA_VERSION:
		_load_ids(payload["banked_tool_target_ids"], _banked_tool_target_ids)
		var companion_failures: Array[String] = _companion_profile.load_payload(payload["companion_profile"])
		if not companion_failures.is_empty():
			_last_storage_report = _report("invalid_schema", {"failures": companion_failures})
			return _last_storage_report.duplicate(true)
		if loaded_version >= SCHEMA_VERSION:
			var journey_failures: Array[String] = _regional_journey_profile.load_payload(payload["regional_journey_profile"])
			if not journey_failures.is_empty():
				_last_storage_report = _report("invalid_schema", {"failures": journey_failures})
				return _last_storage_report.duplicate(true)
	elif loaded_version >= TOOL_TARGET_SCHEMA_VERSION:
		_load_ids(payload["banked_tool_target_ids"], _banked_tool_target_ids)
	if has_capability(SURVEY_SCANNER_CAPABILITY_ID):
		_completed_discoveries[SURVEY_SCANNER_BLUEPRINT_ID] = true
		_completed_projects[SURVEY_SCANNER_PROJECT_ID] = true
	if has_capability(SALVAGE_CUTTER_CAPABILITY_ID) or has_completed_project(SALVAGE_CUTTER_PROJECT_ID):
		_completed_discoveries[SALVAGE_CUTTER_BLUEPRINT_ID] = true
	var status := "loaded"
	if loaded_version == LEGACY_SCHEMA_VERSION:
		status = "migrated_v1"
	elif loaded_version == MATERIAL_SCHEMA_VERSION:
		status = "migrated_v2"
	elif loaded_version == PROJECT_SCHEMA_VERSION:
		status = "migrated_v3"
	elif loaded_version == TOOL_TARGET_SCHEMA_VERSION:
		status = "migrated_v4"
	elif loaded_version == COMPANION_SCHEMA_VERSION:
		status = "migrated_companion_v%d_to_v3" % loaded_companion_version if loaded_companion_version != CompanionProfileState.PROFILE_SCHEMA_VERSION else "migrated_v5"
	elif loaded_version == SCHEMA_VERSION and loaded_companion_version != CompanionProfileState.PROFILE_SCHEMA_VERSION:
		status = "migrated_companion_v%d_to_v3" % loaded_companion_version
	elif bool(migrations.get("scanner_purchase", false)):
		status = "migrated_scanner_purchase"
	elif bool(migrations.get("wreck_navigation", false)):
		status = "migrated_wreck_navigation"
	var migration_changed: bool = loaded_version in [TOOL_TARGET_SCHEMA_VERSION, COMPANION_SCHEMA_VERSION] or (loaded_version == SCHEMA_VERSION and loaded_companion_version != CompanionProfileState.PROFILE_SCHEMA_VERSION) or bool(migrations.get("cutter_blueprint", false)) or bool(migrations.get("scanner_purchase", false)) or bool(migrations.get("wreck_navigation", false))
	if migration_changed and not save_profile():
		_last_storage_report = _report("migration_write_error")
		return _last_storage_report.duplicate(true)
	_last_storage_report = _report(status)
	return _last_storage_report.duplicate(true)
func save_profile() -> bool:
	if not _persistence_enabled:
		_last_storage_report = _report("saved_memory")
		return true
	var saved := ExpansionProfileStorage.write_atomic(_storage_path, _profile_payload())
	_last_storage_report = _report("saved" if saved else "write_error")
	return saved
func unlock_capability(capability_id: String, persist := true) -> Dictionary:
	if not SUPPORTED_CAPABILITY_IDS.has(capability_id):
		return {"changed": false, "reason": "unsupported_capability", "capability_id": capability_id}
	if has_capability(capability_id):
		return {"changed": false, "reason": "already_unlocked", "capability_id": capability_id}
	if capability_id in [SURVEY_SCANNER_CAPABILITY_ID, PROPULSION_FINS_CAPABILITY_ID, SALVAGE_CUTTER_CAPABILITY_ID, CURRENT_STABILIZER_CAPABILITY_ID, SHOCK_PROD_CAPABILITY_ID, SHOCK_PROD_CAPACITOR_CAPABILITY_ID, DIVE_LIGHT_CAPABILITY_ID, PRESSURE_SUIT_CAPABILITY_ID, CLOSED_CIRCUIT_REBREATHER_CAPABILITY_ID]:
		return {"changed": false, "reason": "project_transaction_required", "capability_id": capability_id}
	_unlocked_capabilities[capability_id] = true
	if persist and not save_profile():
		_unlocked_capabilities.erase(capability_id)
		return {"changed": false, "reason": "storage_error", "capability_id": capability_id}
	return {"changed": true, "reason": "unlocked", "capability_id": capability_id}


func complete_discovery(discovery_id: String, persist := true) -> Dictionary:
	if not SUPPORTED_DISCOVERY_IDS.has(discovery_id):
		return {"changed": false, "reason": "unsupported_discovery", "discovery_id": discovery_id}
	if has_completed_discovery(discovery_id):
		return {"changed": false, "reason": "already_completed", "discovery_id": discovery_id}
	_completed_discoveries[discovery_id] = true
	if persist and not save_profile():
		_completed_discoveries.erase(discovery_id)
		return {"changed": false, "reason": "storage_error", "discovery_id": discovery_id}
	return {"changed": true, "reason": "completed", "discovery_id": discovery_id}


func complete_discovery_reward(discovery_id: String, reward_id: String, persist := true) -> Dictionary:
	var primary_id := str(discovery_id)
	var secondary_id := str(reward_id).strip_edges()
	if secondary_id.is_empty() or secondary_id == primary_id:
		return complete_discovery(primary_id, persist)
	if not SUPPORTED_DISCOVERY_IDS.has(primary_id):
		return {"changed": false, "reason": "unsupported_discovery", "discovery_id": primary_id}
	if not SUPPORTED_DISCOVERY_IDS.has(secondary_id):
		return {"changed": false, "reason": "unsupported_discovery", "discovery_id": secondary_id}
	var discovery_snapshot := _completed_discoveries.duplicate(true)
	var changed := false
	if not has_completed_discovery(primary_id):
		_completed_discoveries[primary_id] = true
		changed = true
	if not has_completed_discovery(secondary_id):
		_completed_discoveries[secondary_id] = true
		changed = true
	if not changed:
		return {"changed": false, "reason": "already_completed", "discovery_id": primary_id, "reward_id": secondary_id}
	if persist and not save_profile():
		_completed_discoveries = discovery_snapshot
		return {"changed": false, "reason": "storage_error", "discovery_id": primary_id, "reward_id": secondary_id}
	return {"changed": true, "reason": "completed", "discovery_id": primary_id, "reward_id": secondary_id}


func deposit_materials(quantities: Dictionary, persist := true) -> Dictionary:
	var validation := _validate_material_delta(quantities)
	if not validation.is_empty():
		return {"changed": false, "reason": "invalid_materials", "failures": validation}
	var snapshot := _material_inventory.duplicate(true)
	for material_id in quantities:
		_material_inventory[material_id] = material_quantity(str(material_id)) + int(quantities[material_id])
	if persist and not save_profile():
		_material_inventory = snapshot
		return {"changed": false, "reason": "storage_error"}
	return {"changed": true, "reason": "deposited", "deposited": quantities.duplicate(true), "inventory": material_inventory()}


func complete_material_project(project_definition: Dictionary, persist := true) -> Dictionary:
	var failures := ExpansionProfileProjectRules.validate_definition(project_definition)
	if not failures.is_empty():
		return {"changed": false, "reason": "invalid_project", "failures": failures}
	var project_id := str(project_definition["id"])
	var capability_id := str(project_definition["unlocks_capability_id"])
	var project_complete := has_completed_project(project_id)
	var capability_unlocked := has_capability(capability_id)
	if project_complete or capability_unlocked:
		if project_complete and capability_unlocked:
			return {"changed": false, "reason": "already_completed", "project_id": project_id, "capability_id": capability_id}
		return {"changed": false, "reason": "inconsistent_profile", "project_id": project_id, "capability_id": capability_id}
	var required_discovery_id := str(project_definition.get("required_discovery_id", ""))
	if not required_discovery_id.is_empty() and not has_completed_discovery(required_discovery_id):
		return {"changed": false, "reason": "missing_discovery", "project_id": project_id}
	var required_project_id := str(project_definition.get("required_project_id", ""))
	if not required_project_id.is_empty() and not has_completed_project(required_project_id):
		return {
			"changed": false,
			"reason": "missing_project",
			"project_id": project_id,
			"required_project_id": required_project_id,
		}

	var required: Dictionary = project_definition["required_materials"]
	var missing := {}
	for material_key in required:
		var material_id := str(material_key)
		var required_quantity := int(required[material_key])
		var available := material_quantity(material_id)
		if available < required_quantity:
			missing[material_id] = required_quantity - available
	if not missing.is_empty():
		return {"changed": false, "reason": "insufficient_materials", "missing": missing}

	var material_snapshot := _material_inventory.duplicate(true)
	var project_snapshot := _completed_projects.duplicate(true)
	var capability_snapshot := _unlocked_capabilities.duplicate(true)
	for material_key in required:
		var material_id := str(material_key)
		var remaining := material_quantity(material_id) - int(required[material_key])
		if remaining > 0:
			_material_inventory[material_id] = remaining
		else:
			_material_inventory.erase(material_id)
	_completed_projects[project_id] = true
	_unlocked_capabilities[capability_id] = true
	if persist and not save_profile():
		_material_inventory = material_snapshot
		_completed_projects = project_snapshot
		_unlocked_capabilities = capability_snapshot
		return {"changed": false, "reason": "storage_error", "project_id": project_id}
	return {
		"changed": true,
		"reason": "completed",
		"project_id": project_id,
		"capability_id": capability_id,
		"consumed": required.duplicate(true),
		"inventory": material_inventory(),
	}


func has_capability(capability_id: String) -> bool:
	return bool(_unlocked_capabilities.get(capability_id, false))


func has_completed_discovery(discovery_id: String) -> bool:
	return bool(_completed_discoveries.get(discovery_id, false))


func has_completed_project(project_id: String) -> bool:
	return bool(_completed_projects.get(project_id, false))


func material_quantity(material_id: String) -> int:
	return int(_material_inventory.get(material_id, 0))


func material_inventory() -> Dictionary:
	return _material_inventory.duplicate(true)


func bank_tool_target(target_id: String, persist := true) -> Dictionary:
	if not SUPPORTED_BANKED_TOOL_TARGET_IDS.has(target_id):
		return {"changed": false, "reason": "unsupported_tool_target", "target_id": target_id}
	if has_banked_tool_target(target_id):
		return {"changed": false, "reason": "already_banked", "target_id": target_id}
	_banked_tool_target_ids[target_id] = true
	if persist and not save_profile():
		_banked_tool_target_ids.erase(target_id)
		return {"changed": false, "reason": "storage_error", "target_id": target_id}
	return {"changed": true, "reason": "banked", "target_id": target_id}


func has_banked_tool_target(target_id: String) -> bool:
	return bool(_banked_tool_target_ids.get(target_id, false))


func commit_companion_rescue(individual_id: String, species_id: String, callsign: String, persist := true) -> Dictionary:
	return _apply_companion_change("commit_rescue", [individual_id, species_id, callsign, true], persist)
func select_active_companion(individual_id: String, persist := true) -> Dictionary:
	return _apply_companion_change("select_active", [individual_id], persist)

func earn_companion_memory(memory_id: String, persist := true) -> Dictionary:
	return _apply_companion_change("earn_memory", [memory_id], persist)
func select_companion_adaptation(adaptation_id: String, persist := true) -> Dictionary:
	return _apply_companion_change("select_adaptation", [adaptation_id], persist)

func companion_report() -> Dictionary:
	return _companion_profile.report()

func has_committed_companion() -> bool:
	return _companion_profile.has_committed_companion()

func active_companion_available_on_sortie_launch() -> bool:
	return _companion_profile.has_launchable_active_companion()

func signal_reef_journey_report() -> Dictionary:
	return _regional_journey_profile.report()
func commit_signal_reef_journey(adaptation_id: String, map_id: String, entry_id: String, day_number: int, persist := true) -> Dictionary:
	var kite := _companion_individual(SignalReefJourneyProfileState.INDIVIDUAL_ID)
	if kite.is_empty():
		return {"changed": false, "reason": "companion_not_committed"}
	if str(kite.get("selected_adaptation_id", "")) != adaptation_id:
		return {"changed": false, "reason": "adaptation_not_selected"}
	return _apply_journey_change("commit", [SignalReefJourneyProfileState.JOURNEY_ID, SignalReefJourneyProfileState.COMMITMENT_EVENT_ID, SignalReefJourneyProfileState.INDIVIDUAL_ID, adaptation_id, map_id, entry_id, day_number], persist)
func advance_signal_reef_journey_day(day_number: int, persist := true) -> Dictionary:
	return _apply_journey_change("advance_day", [day_number], persist)

func report() -> Dictionary:
	return _report(str(_last_storage_report.get("status", "not_loaded")))


func last_storage_report() -> Dictionary:
	return _last_storage_report.duplicate(true)


func _profile_payload() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"completed_discoveries": _sorted_ids(_completed_discoveries),
		"unlocked_capabilities": _sorted_ids(_unlocked_capabilities),
		"material_inventory": _sorted_materials(),
		"completed_projects": _sorted_ids(_completed_projects),
		"banked_tool_target_ids": _sorted_ids(_banked_tool_target_ids),
		"companion_profile": _companion_profile.payload(),
		"regional_journey_profile": _regional_journey_profile.payload(),
	}


func _report(status: String, extra := {}) -> Dictionary:
	var value := _profile_payload()
	value["status"] = status
	for key in extra:
		value[key] = extra[key]
	return value


func _sorted_ids(source: Dictionary) -> Array:
	var ids := source.keys()
	ids.sort()
	return ids


func _sorted_materials() -> Dictionary:
	var values := {}
	var ids := _material_inventory.keys()
	ids.sort()
	for material_id in ids:
		if int(_material_inventory[material_id]) > 0:
			values[material_id] = int(_material_inventory[material_id])
	return values


func _validate_payload(payload: Dictionary) -> Array[String]:
	return ExpansionProfileSchema.validate_payload(payload, {
		"discoveries": SUPPORTED_DISCOVERY_IDS,
		"legacy_capabilities": LEGACY_CAPABILITY_IDS,
		"material_capabilities": MATERIAL_SCHEMA_CAPABILITY_IDS,
		"capabilities": SUPPORTED_CAPABILITY_IDS,
		"materials": SUPPORTED_MATERIAL_IDS,
		"empty_projects": {},
		"material_projects": MATERIAL_SCHEMA_PROJECT_IDS,
		"projects": SUPPORTED_PROJECT_IDS,
		"banked_targets": SUPPORTED_BANKED_TOOL_TARGET_IDS,
		"project_rules": PROJECT_RULES,
	}, _companion_profile, _regional_journey_profile)


func _validate_material_delta(value: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	if value.is_empty():
		return ["material deposit must not be empty"]
	for material_id in value:
		if not SUPPORTED_MATERIAL_IDS.has(str(material_id)):
			failures.append("unsupported material %s" % material_id)
		elif typeof(value[material_id]) != TYPE_INT or int(value[material_id]) <= 0:
			failures.append("material deposit %s must be a positive integer" % material_id)
	return failures


func _migration_ids() -> Dictionary:
	return {
		"survey_scanner_capability_id": SURVEY_SCANNER_CAPABILITY_ID,
		"survey_scanner_project_id": SURVEY_SCANNER_PROJECT_ID,
		"survey_scanner_blueprint_id": SURVEY_SCANNER_BLUEPRINT_ID,
		"salvage_cutter_capability_id": SALVAGE_CUTTER_CAPABILITY_ID,
		"salvage_cutter_project_id": SALVAGE_CUTTER_PROJECT_ID,
		"salvage_cutter_blueprint_id": SALVAGE_CUTTER_BLUEPRINT_ID,
		"anomaly_discovery_id": ANOMALY_DISCOVERY_ID,
		"southeast_wreck_discovery_id": SOUTHEAST_WRECK_DISCOVERY_ID,
		"southeast_wreck_navigation_data_id": SOUTHEAST_WRECK_NAVIGATION_DATA_ID,
	}


func _load_ids(values: Array, destination: Dictionary) -> void:
	for value in values:
		destination[str(value)] = true


func _reset_memory() -> void:
	_completed_discoveries = {}
	_unlocked_capabilities = {}
	_material_inventory = {}
	_completed_projects = {}
	_banked_tool_target_ids = {}
	_companion_profile.reset()
	_regional_journey_profile.reset()

func _apply_companion_change(method: String, arguments: Array, persist: bool) -> Dictionary:
	var snapshot := _companion_profile.payload()
	var result: Dictionary = _companion_profile.callv(method, arguments)
	if not bool(result.get("changed", false)) or not persist:
		return result
	if save_profile():
		return result
	_companion_profile.load_payload(snapshot)
	return {"changed": false, "reason": "storage_error"}

func _companion_individual(individual_id: String) -> Dictionary:
	for item in _companion_profile.individuals():
		if str(item.get("individual_id", "")) == individual_id: return item
	return {}
func _apply_journey_change(method: String, arguments: Array, persist: bool) -> Dictionary:
	var snapshot := _regional_journey_profile.payload()
	var result: Dictionary = _regional_journey_profile.callv(method, arguments)
	if not bool(result.get("changed", false)) or not persist: return result
	if save_profile(): return result
	_regional_journey_profile.load_payload(snapshot)
	return {"changed": false, "reason": "storage_error"}
