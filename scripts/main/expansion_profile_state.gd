extends RefCounted

const SCHEMA_VERSION := 1
const SURVEY_SCANNER_CAPABILITY_ID := "survey_scanner_1"
const ANOMALY_DISCOVERY_ID := "lower_right_anomaly_discovery"
const DEFAULT_STORAGE_PATH := "user://oceangame2_profile.json"
const ALLOWED_PROFILE_KEYS := {
	"schema_version": true,
	"completed_discoveries": true,
	"unlocked_capabilities": true,
}
const SUPPORTED_CAPABILITY_IDS := {SURVEY_SCANNER_CAPABILITY_ID: true}
const SUPPORTED_DISCOVERY_IDS := {ANOMALY_DISCOVERY_ID: true}

var _storage_path: String
var _completed_discoveries := {}
var _unlocked_capabilities := {}
var _last_storage_report := {"status": "not_loaded"}


func _init(storage_path := DEFAULT_STORAGE_PATH) -> void:
	_storage_path = str(storage_path)


func load_profile() -> Dictionary:
	_reset_memory()
	_recover_interrupted_write()
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
	var failures := _validate_payload(payload)
	if not failures.is_empty():
		_last_storage_report = _report("invalid_schema", {"failures": failures})
		return _last_storage_report.duplicate(true)

	for discovery_id in payload["completed_discoveries"]:
		_completed_discoveries[str(discovery_id)] = true
	for capability_id in payload["unlocked_capabilities"]:
		_unlocked_capabilities[str(capability_id)] = true
	_last_storage_report = _report("loaded")
	return _last_storage_report.duplicate(true)


func save_profile() -> bool:
	var saved := _write_atomic(_profile_payload())
	_last_storage_report = _report("saved" if saved else "write_error")
	return saved


func unlock_capability(capability_id: String, persist := true) -> Dictionary:
	if not SUPPORTED_CAPABILITY_IDS.has(capability_id):
		return {"changed": false, "reason": "unsupported_capability", "capability_id": capability_id}
	if has_capability(capability_id):
		return {"changed": false, "reason": "already_unlocked", "capability_id": capability_id}
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


func has_capability(capability_id: String) -> bool:
	return bool(_unlocked_capabilities.get(capability_id, false))


func has_completed_discovery(discovery_id: String) -> bool:
	return bool(_completed_discoveries.get(discovery_id, false))


func report() -> Dictionary:
	return _report(str(_last_storage_report.get("status", "not_loaded")))


func last_storage_report() -> Dictionary:
	return _last_storage_report.duplicate(true)


func _profile_payload() -> Dictionary:
	return {
		"schema_version": SCHEMA_VERSION,
		"completed_discoveries": _sorted_ids(_completed_discoveries),
		"unlocked_capabilities": _sorted_ids(_unlocked_capabilities),
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


func _validate_payload(payload: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	for required_key in ALLOWED_PROFILE_KEYS:
		if not payload.has(required_key):
			failures.append("missing %s" % required_key)
	for key in payload:
		if not ALLOWED_PROFILE_KEYS.has(str(key)):
			failures.append("unsupported field %s" % key)
	if payload.get("schema_version") != SCHEMA_VERSION:
		failures.append("unsupported schema_version")
	failures.append_array(_validate_id_array(payload.get("completed_discoveries"), SUPPORTED_DISCOVERY_IDS, "completed_discoveries"))
	failures.append_array(_validate_id_array(payload.get("unlocked_capabilities"), SUPPORTED_CAPABILITY_IDS, "unlocked_capabilities"))
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


func _write_atomic(payload: Dictionary) -> bool:
	var temp_path := "%s.tmp" % _storage_path
	var backup_path := "%s.bak" % _storage_path
	var target_absolute := ProjectSettings.globalize_path(_storage_path)
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	DirAccess.make_dir_recursive_absolute(target_absolute.get_base_dir())
	_remove_if_exists(temp_absolute)

	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	file.close()

	var had_original := FileAccess.file_exists(_storage_path)
	if had_original:
		_remove_if_exists(backup_absolute)
		if DirAccess.rename_absolute(target_absolute, backup_absolute) != OK:
			_remove_if_exists(temp_absolute)
			return false
	if DirAccess.rename_absolute(temp_absolute, target_absolute) != OK:
		if had_original:
			DirAccess.rename_absolute(backup_absolute, target_absolute)
		_remove_if_exists(temp_absolute)
		return false
	_remove_if_exists(backup_absolute)
	return true


func _recover_interrupted_write() -> void:
	var temp_path := "%s.tmp" % _storage_path
	var backup_path := "%s.bak" % _storage_path
	var target_absolute := ProjectSettings.globalize_path(_storage_path)
	var temp_absolute := ProjectSettings.globalize_path(temp_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(_storage_path):
		_remove_if_exists(temp_absolute)
		_remove_if_exists(backup_absolute)
	elif FileAccess.file_exists(backup_path):
		DirAccess.rename_absolute(backup_absolute, target_absolute)
		_remove_if_exists(temp_absolute)
	elif FileAccess.file_exists(temp_path):
		DirAccess.rename_absolute(temp_absolute, target_absolute)


func _remove_if_exists(absolute_path: String) -> void:
	if FileAccess.file_exists(absolute_path):
		DirAccess.remove_absolute(absolute_path)


func _reset_memory() -> void:
	_completed_discoveries = {}
	_unlocked_capabilities = {}
