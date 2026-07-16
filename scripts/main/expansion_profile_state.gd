extends RefCounted

const ProgressionContract := preload("res://scripts/main/progression_contract.gd")
const ExpansionProfileProjectRules := preload("res://scripts/main/expansion_profile_project_rules.gd")
const ExpansionProfileStorage := preload("res://scripts/main/expansion_profile_storage.gd")
const SCHEMA_VERSION := 4
const PROJECT_SCHEMA_VERSION := 3
const MATERIAL_SCHEMA_VERSION := 2
const LEGACY_SCHEMA_VERSION := 1
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
const MINERAL_TRACE_RESEARCH_ID := "upper_right_mineral_trace_research"
const SIGNAL_REEF_DISCOVERY_ID := "lower_right_signal_reef_discovery"
const DEEP_HARMONIC_DISCOVERY_ID := "signal_reef_deep_harmonic_discovery"
const ABYSSAL_HARMONIC_DISCOVERY_ID := "abyssal_basin_harmonic_source_discovery"
const SOUTHEAST_WRECK_DISCOVERY_ID := "southeast_wreck_archive_discovery"
const DIVE_LIGHT_CAPABILITY_ID := ProgressionContract.DIVE_LIGHT_CAPABILITY_ID
const DIVE_LIGHT_PROJECT_ID := "dive_light_1_project"
const DIVE_LIGHT_TARGET_ID := "signal_reef_deep_harmonic_survey"
const PRESSURE_SUIT_CAPABILITY_ID := ProgressionContract.PRESSURE_SUIT_CAPABILITY_ID
const PRESSURE_SUIT_PROJECT_ID := "pressure_suit_1_project"
const SALVAGE_CUTTER_PROJECT_ID := "salvage_cutter_project"
const SALVAGE_CUTTER_TARGET_ID := "salvage_sealed_wreck_cache"
const SOUTHEAST_WRECK_RECORDER_ID := "southeast_wreck_recorder"
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
const LEGACY_PROFILE_KEYS := {"schema_version": true, "completed_discoveries": true, "unlocked_capabilities": true}
const PROJECT_PROFILE_KEYS := {
	"schema_version": true,
	"completed_discoveries": true,
	"unlocked_capabilities": true,
	"material_inventory": true,
	"completed_projects": true,
}
const PROFILE_KEYS := {
	"schema_version": true,
	"completed_discoveries": true,
	"unlocked_capabilities": true,
	"material_inventory": true,
	"completed_projects": true,
	"banked_tool_target_ids": true,
}
const LEGACY_CAPABILITY_IDS := {SURVEY_SCANNER_CAPABILITY_ID: true}
const MATERIAL_SCHEMA_CAPABILITY_IDS := {SURVEY_SCANNER_CAPABILITY_ID: true, SALVAGE_CUTTER_CAPABILITY_ID: true}
const SUPPORTED_CAPABILITY_IDS := {SURVEY_SCANNER_CAPABILITY_ID: true, PROPULSION_FINS_CAPABILITY_ID: true, SALVAGE_CUTTER_CAPABILITY_ID: true, CURRENT_STABILIZER_CAPABILITY_ID: true, SHOCK_PROD_CAPABILITY_ID: true, SHOCK_PROD_CAPACITOR_CAPABILITY_ID: true, DIVE_LIGHT_CAPABILITY_ID: true, PRESSURE_SUIT_CAPABILITY_ID: true}
const SUPPORTED_DISCOVERY_IDS := {PROPULSION_FINS_BLUEPRINT_ID: true, SURVEY_SCANNER_BLUEPRINT_ID: true, ANOMALY_DISCOVERY_ID: true, MINERAL_TRACE_RESEARCH_ID: true, SIGNAL_REEF_DISCOVERY_ID: true, DEEP_HARMONIC_DISCOVERY_ID: true, ABYSSAL_HARMONIC_DISCOVERY_ID: true, SOUTHEAST_WRECK_DISCOVERY_ID: true}
const SUPPORTED_MATERIAL_IDS := {TITANIUM_MATERIAL_ID: true, RUBBER_MATERIAL_ID: true, COIL_MATERIAL_ID: true, INSULATING_GEL_MATERIAL_ID: true, EEL_ELECTROCYTE_MATERIAL_ID: true}
const MATERIAL_SCHEMA_PROJECT_IDS := {SALVAGE_CUTTER_PROJECT_ID: true}
const SUPPORTED_PROJECT_IDS := {PROPULSION_FINS_PROJECT_ID: true, SURVEY_SCANNER_PROJECT_ID: true, SALVAGE_CUTTER_PROJECT_ID: true, CURRENT_STABILIZER_PROJECT_ID: true, SHOCK_PROD_PROJECT_ID: true, SHOCK_PROD_CAPACITOR_PROJECT_ID: true, DIVE_LIGHT_PROJECT_ID: true, PRESSURE_SUIT_PROJECT_ID: true}
const SUPPORTED_BANKED_TOOL_TARGET_IDS := {SOUTHEAST_WRECK_RECORDER_ID: true}
const PROJECT_RULES := ExpansionProfileProjectRules.RULES

var _storage_path: String
var _persistence_enabled: bool
var _completed_discoveries := {}
var _unlocked_capabilities := {}
var _material_inventory := {}
var _completed_projects := {}
var _banked_tool_target_ids := {}
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
	var scanner_migrated := _migrate_scanner_purchase_payload(payload)
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
	if loaded_version >= SCHEMA_VERSION:
		_load_ids(payload["banked_tool_target_ids"], _banked_tool_target_ids)
	if has_capability(SURVEY_SCANNER_CAPABILITY_ID):
		_completed_discoveries[SURVEY_SCANNER_BLUEPRINT_ID] = true
		_completed_projects[SURVEY_SCANNER_PROJECT_ID] = true
	var status := "loaded"
	if loaded_version == LEGACY_SCHEMA_VERSION:
		status = "migrated_v1"
	elif loaded_version == MATERIAL_SCHEMA_VERSION:
		status = "migrated_v2"
	elif loaded_version == PROJECT_SCHEMA_VERSION:
		status = "migrated_v3"
	elif scanner_migrated:
		status = "migrated_scanner_purchase"
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
	if capability_id in [SURVEY_SCANNER_CAPABILITY_ID, PROPULSION_FINS_CAPABILITY_ID, SALVAGE_CUTTER_CAPABILITY_ID, CURRENT_STABILIZER_CAPABILITY_ID, SHOCK_PROD_CAPABILITY_ID, SHOCK_PROD_CAPACITOR_CAPABILITY_ID, DIVE_LIGHT_CAPABILITY_ID, PRESSURE_SUIT_CAPABILITY_ID]:
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
	var failures := _validate_material_project_definition(project_definition)
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
	var schema = payload.get("schema_version")
	if schema == LEGACY_SCHEMA_VERSION:
		return _validate_version(payload, LEGACY_PROFILE_KEYS, LEGACY_CAPABILITY_IDS, {}, false)
	if schema == MATERIAL_SCHEMA_VERSION:
		return _validate_version(
			payload,
			PROJECT_PROFILE_KEYS,
			MATERIAL_SCHEMA_CAPABILITY_IDS,
			MATERIAL_SCHEMA_PROJECT_IDS,
			true
		)
	if schema == PROJECT_SCHEMA_VERSION:
		return _validate_version(payload, PROJECT_PROFILE_KEYS, SUPPORTED_CAPABILITY_IDS, SUPPORTED_PROJECT_IDS, true)
	if schema == SCHEMA_VERSION:
		var failures := _validate_version(payload, PROFILE_KEYS, SUPPORTED_CAPABILITY_IDS, SUPPORTED_PROJECT_IDS, true)
		failures.append_array(_validate_id_array(payload.get("banked_tool_target_ids"), SUPPORTED_BANKED_TOOL_TARGET_IDS, "banked_tool_target_ids"))
		return failures
	return ["unsupported schema_version"]


func _validate_version(
	payload: Dictionary,
	allowed_keys: Dictionary,
	capabilities: Dictionary,
	projects: Dictionary,
	include_materials: bool
) -> Array[String]:
	var failures: Array[String] = []
	for required_key in allowed_keys:
		if not payload.has(required_key):
			failures.append("missing %s" % required_key)
	for key in payload:
		if not allowed_keys.has(str(key)):
			failures.append("unsupported field %s" % key)
	failures.append_array(_validate_id_array(payload.get("completed_discoveries"), SUPPORTED_DISCOVERY_IDS, "completed_discoveries"))
	failures.append_array(_validate_id_array(payload.get("unlocked_capabilities"), capabilities, "unlocked_capabilities"))
	if include_materials:
		failures.append_array(_validate_material_inventory(payload.get("material_inventory")))
		failures.append_array(_validate_id_array(payload.get("completed_projects"), projects, "completed_projects"))
		failures.append_array(_validate_project_capability_pair(payload, projects))
	return failures


func _validate_id_array(value, supported_ids: Dictionary, field: String) -> Array[String]:
	var failures: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return ["%s must be an array" % field]
	var seen := {}
	for item in value:
		if typeof(item) != TYPE_STRING or not supported_ids.has(str(item)):
			failures.append("%s contains unsupported id %s" % [field, str(item)])
		elif seen.has(str(item)):
			failures.append("%s contains duplicate id %s" % [field, str(item)])
		else:
			seen[str(item)] = true
	return failures


func _validate_material_inventory(value) -> Array[String]:
	if typeof(value) != TYPE_DICTIONARY:
		return ["material_inventory must be an object"]
	var failures: Array[String] = []
	for material_id in value:
		if not SUPPORTED_MATERIAL_IDS.has(str(material_id)):
			failures.append("material_inventory contains unsupported id %s" % material_id)
		elif not _is_nonnegative_integer_value(value[material_id]):
			failures.append("material_inventory %s must be a non-negative integer" % material_id)
	return failures


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


func _validate_material_project_definition(project_definition: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	var project_id := str(project_definition.get("id", ""))
	var rules: Dictionary = PROJECT_RULES.get(project_id, {})
	if rules.is_empty():
		failures.append("unsupported project id")
		return failures
	if str(project_definition.get("required_discovery_id", "")) != str(rules.get("required_discovery_id", "")):
		failures.append("unsupported project discovery")
	if str(project_definition.get("unlocks_capability_id", "")) != str(rules["capability_id"]):
		failures.append("unsupported project capability")
	if str(project_definition.get("required_project_id", "")) != str(rules["required_project_id"]):
		failures.append("unsupported project prerequisite")
	var authored_target_fields := []
	for target_field in ["target_id", "target_gate_id", "target_hostile_id"]:
		if project_definition.has(target_field):
			authored_target_fields.append(target_field)
	if authored_target_fields.size() != 1 or str(project_definition.get(str(rules["target_field"]), "")) != str(rules["target_id"]):
		failures.append("unsupported project target")
	if str(project_definition.get("build_phase", "")) != "night_debrief":
		failures.append("unsupported project build phase")
	if str(project_definition.get("capability_effect", "")) != str(rules.get("capability_effect", "")):
		failures.append("unsupported project capability effect")
	var required = project_definition.get("required_materials")
	if typeof(required) != TYPE_DICTIONARY:
		failures.append("project required_materials must be an object")
		return failures
	var expected: Dictionary = rules["required_materials"]
	if required.size() != expected.size():
		failures.append("project recipe has unsupported materials")
	for material_id in expected:
		var quantity = required.get(material_id)
		if not _is_nonnegative_integer_value(quantity) or int(quantity) != int(expected[material_id]):
			failures.append("project recipe %s must equal %d" % [material_id, expected[material_id]])
	return failures


func _validate_project_capability_pair(payload: Dictionary, supported_projects: Dictionary) -> Array[String]:
	var capabilities = payload.get("unlocked_capabilities")
	var projects = payload.get("completed_projects")
	if typeof(capabilities) != TYPE_ARRAY or typeof(projects) != TYPE_ARRAY:
		return []
	var failures: Array[String] = []
	for project_id in supported_projects:
		var rules: Dictionary = PROJECT_RULES[project_id]
		var capability_id := str(rules["capability_id"])
		if capabilities.has(capability_id) != projects.has(project_id):
			failures.append("%s capability and project must be completed together" % capability_id)
		var required_project_id := str(rules["required_project_id"])
		if projects.has(project_id) and not required_project_id.is_empty() and not projects.has(required_project_id):
			failures.append("%s requires completed %s" % [project_id, required_project_id])
	return failures


func _migrate_scanner_purchase_payload(payload: Dictionary) -> bool:
	if typeof(payload.get("completed_discoveries")) != TYPE_ARRAY or typeof(payload.get("unlocked_capabilities")) != TYPE_ARRAY or typeof(payload.get("completed_projects")) != TYPE_ARRAY:
		return false
	var schema_version := int(payload.get("schema_version", 0))
	if (schema_version != PROJECT_SCHEMA_VERSION and schema_version != SCHEMA_VERSION) or not payload.get("unlocked_capabilities", []).has(SURVEY_SCANNER_CAPABILITY_ID) or payload.get("completed_projects", []).has(SURVEY_SCANNER_PROJECT_ID):
		return false
	if not payload["completed_discoveries"].has(SURVEY_SCANNER_BLUEPRINT_ID):
		payload["completed_discoveries"].append(SURVEY_SCANNER_BLUEPRINT_ID)
	payload["completed_projects"].append(SURVEY_SCANNER_PROJECT_ID)
	return true


func _load_ids(values: Array, destination: Dictionary) -> void:
	for value in values:
		destination[str(value)] = true


func _is_nonnegative_integer_value(value) -> bool:
	if typeof(value) not in [TYPE_INT, TYPE_FLOAT]:
		return false
	var number := float(value)
	return number >= 0.0 and is_equal_approx(number, float(int(number)))


func _reset_memory() -> void:
	_completed_discoveries = {}
	_unlocked_capabilities = {}
	_material_inventory = {}
	_completed_projects = {}
	_banked_tool_target_ids = {}
