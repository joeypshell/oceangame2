extends RefCounted

const PROFILE_SCHEMA_VERSION := 3
const COLLECTION_PROFILE_SCHEMA_VERSION := 2
const LEGACY_PROFILE_SCHEMA_VERSION := 1
const CATALOG_PATH := "res://config/creature_catalog.json"
const MAX_INDIVIDUALS := 3
const FIRST_PROOF_INDIVIDUAL_ID := "spark_ray_juvenile_01"
const SECOND_PROOF_INDIVIDUAL_ID := "veil_cuttle_juvenile_01"
const THIRD_PROOF_INDIVIDUAL_ID := "silt_hound_juvenile_01"
const LEGACY_PROFILE_KEYS := {
	"schema_version": true,
	"individual": true,
	"active_individual_id": true,
}
const PROFILE_KEYS := {
	"schema_version": true,
	"individuals": true,
	"active_individual_id": true,
}
const INDIVIDUAL_KEYS := {
	"individual_id": true,
	"species_id": true,
	"callsign": true,
	"rescue_committed": true,
	"earned_memory_ids": true,
	"selected_adaptation_id": true,
}

var _catalog := {}
var _individuals := {}
var _active_individual_id := ""


func _init() -> void:
	_catalog = _load_catalog()


func reset() -> void:
	_individuals = {}
	_active_individual_id = ""


func load_payload(payload: Dictionary) -> Array[String]:
	var failures := validate_payload(payload)
	if not failures.is_empty():
		return failures
	reset()
	for value in _payload_individuals(payload):
		var individual := (value as Dictionary).duplicate(true)
		_individuals[str(individual["individual_id"])] = individual
	_active_individual_id = str(payload.get("active_individual_id", ""))
	return []


func payload() -> Dictionary:
	return {
		"schema_version": PROFILE_SCHEMA_VERSION,
		"individuals": individuals(),
		"active_individual_id": _active_individual_id,
	}


func report() -> Dictionary:
	var value := payload()
	value["individual"] = active_individual()
	value["committed_count"] = _individuals.size()
	value["rescue_committed"] = has_committed_companion()
	value["riding_available_on_sortie_launch"] = active_companion_ride_capable()
	return value


func commit_rescue(individual_id: String, species_id: String, callsign: String, select_active := true) -> Dictionary:
	var normalized_callsign := callsign.strip_edges()
	var catalog_individual := _catalog_individual(individual_id)
	if catalog_individual.is_empty():
		return _result(false, "unsupported_individual", {"individual_id": individual_id})
	if str(catalog_individual.get("species_id", "")) != species_id:
		return _result(false, "individual_species_mismatch", {"individual_id": individual_id, "species_id": species_id})
	if normalized_callsign.is_empty() or normalized_callsign.length() > 32:
		return _result(false, "invalid_callsign")
	if _individuals.has(individual_id):
		return _result(false, "already_committed", {"individual_id": individual_id})
	if _individuals.size() >= MAX_INDIVIDUALS:
		return _result(false, "companion_capacity_reached", {"individual_id": individual_id})
	_individuals[individual_id] = {
		"individual_id": individual_id,
		"species_id": species_id,
		"callsign": normalized_callsign,
		"rescue_committed": true,
		"earned_memory_ids": [],
		"selected_adaptation_id": "",
	}
	if select_active and _active_individual_id.is_empty():
		_active_individual_id = individual_id
	return _result(true, "committed", {
		"individual_id": individual_id,
		"active_individual_id": _active_individual_id,
	})


func select_active(individual_id: String) -> Dictionary:
	if not _individuals.has(individual_id):
		return _result(false, "companion_not_committed", {"individual_id": individual_id})
	if _active_individual_id == individual_id:
		return _result(false, "already_active", {"individual_id": individual_id})
	_active_individual_id = individual_id
	return _result(true, "selected", {"individual_id": individual_id})


func earn_memory(memory_id: String) -> Dictionary:
	var individual := active_individual()
	if individual.is_empty():
		return _result(false, "active_companion_not_selected", {"memory_id": memory_id})
	if not _species_id_list(str(individual["species_id"]), "memory_ids").has(memory_id):
		return _result(false, "unsupported_memory", {"memory_id": memory_id})
	var earned: Array = individual["earned_memory_ids"]
	if earned.has(memory_id):
		return _result(false, "already_earned", {"memory_id": memory_id})
	earned.append(memory_id)
	earned.sort()
	individual["earned_memory_ids"] = earned
	_individuals[_active_individual_id] = individual
	return _result(true, "earned", {"memory_id": memory_id})


func select_adaptation(adaptation_id: String) -> Dictionary:
	var individual := active_individual()
	if individual.is_empty():
		return _result(false, "active_companion_not_selected", {"adaptation_id": adaptation_id})
	if not _species_id_list(str(individual["species_id"]), "adaptation_ids").has(adaptation_id):
		return _result(false, "unsupported_adaptation", {"adaptation_id": adaptation_id})
	var selected := str(individual.get("selected_adaptation_id", ""))
	if selected == adaptation_id:
		return _result(false, "already_selected", {"adaptation_id": adaptation_id})
	if not selected.is_empty():
		return _result(false, "adaptation_already_selected", {"adaptation_id": adaptation_id})
	var required_memory := _adaptation_memory_id(adaptation_id)
	if required_memory.is_empty() or not (individual["earned_memory_ids"] as Array).has(required_memory):
		return _result(false, "missing_required_memory", {
			"adaptation_id": adaptation_id,
			"required_memory_id": required_memory,
		})
	individual["selected_adaptation_id"] = adaptation_id
	_individuals[_active_individual_id] = individual
	return _result(true, "selected", {"adaptation_id": adaptation_id})


func has_committed_companion() -> bool:
	return not _individuals.is_empty()


func has_committed_individual(individual_id: String) -> bool:
	return _individuals.has(individual_id)


func has_launchable_active_companion() -> bool:
	return not _active_individual_id.is_empty() and _individuals.has(_active_individual_id)


func active_companion_ride_capable() -> bool:
	var individual := active_individual()
	return not individual.is_empty() and bool(_species(str(individual["species_id"])).get("ride_capable", false))


func active_individual() -> Dictionary:
	if not _individuals.has(_active_individual_id):
		return {}
	return (_individuals[_active_individual_id] as Dictionary).duplicate(true)


func individuals() -> Array:
	var values := []
	for individual_id in _catalog_individual_ids():
		if _individuals.has(individual_id):
			values.append((_individuals[individual_id] as Dictionary).duplicate(true))
	return values


func validate_payload(payload: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	if _catalog.is_empty():
		failures.append("creature catalog could not be loaded")
	var schema := int(payload.get("schema_version", 0))
	if schema not in [LEGACY_PROFILE_SCHEMA_VERSION, COLLECTION_PROFILE_SCHEMA_VERSION, PROFILE_SCHEMA_VERSION]:
		return ["companion_profile schema_version must be 1, 2, or %d" % PROFILE_SCHEMA_VERSION]
	_append_key_failures(
		payload,
		LEGACY_PROFILE_KEYS if schema == LEGACY_PROFILE_SCHEMA_VERSION else PROFILE_KEYS,
		"companion_profile",
		failures
	)
	var active_id = payload.get("active_individual_id")
	if typeof(active_id) != TYPE_STRING:
		failures.append("companion_profile active_individual_id must be a string")
	var raw_individuals = payload.get("individual") if schema == LEGACY_PROFILE_SCHEMA_VERSION else payload.get("individuals")
	if schema == LEGACY_PROFILE_SCHEMA_VERSION:
		if typeof(raw_individuals) != TYPE_DICTIONARY:
			failures.append("companion_profile individual must be an object")
			return failures
		raw_individuals = [] if (raw_individuals as Dictionary).is_empty() else [raw_individuals]
	elif typeof(raw_individuals) != TYPE_ARRAY:
		failures.append("companion_profile individuals must be an array")
		return failures
	var schema_capacity := schema
	if (raw_individuals as Array).size() > schema_capacity:
		failures.append("companion_profile schema v%d supports at most %d individuals" % [schema, schema_capacity])
	var ids: Array[String] = []
	for index in range((raw_individuals as Array).size()):
		var value = raw_individuals[index]
		if typeof(value) != TYPE_DICTIONARY:
			failures.append("companion_profile individuals[%d] must be an object" % index)
			continue
		var individual := value as Dictionary
		_validate_individual(individual, "companion_profile individuals[%d]" % index, failures)
		var individual_id := str(individual.get("individual_id", ""))
		if ids.has(individual_id):
			failures.append("companion_profile contains duplicate individual_id %s" % individual_id)
		ids.append(individual_id)
	if schema == LEGACY_PROFILE_SCHEMA_VERSION and not ids.is_empty() and ids[0] != FIRST_PROOF_INDIVIDUAL_ID:
		failures.append("legacy companion_profile supports only %s" % FIRST_PROOF_INDIVIDUAL_ID)
	if schema == COLLECTION_PROFILE_SCHEMA_VERSION and ids.has(THIRD_PROOF_INDIVIDUAL_ID):
		failures.append("companion_profile schema v2 cannot contain the third proof individual")
	if schema >= COLLECTION_PROFILE_SCHEMA_VERSION and ids != _canonical_order(ids):
		failures.append("companion_profile individuals must use canonical catalog order")
	if typeof(active_id) == TYPE_STRING and not str(active_id).is_empty() and not ids.has(str(active_id)):
		failures.append("companion_profile active_individual_id must be empty or reference a committed individual")
	return failures


func _validate_individual(individual: Dictionary, label: String, failures: Array[String]) -> void:
	_append_key_failures(individual, INDIVIDUAL_KEYS, label, failures)
	var individual_id := str(individual.get("individual_id", ""))
	var catalog_individual := _catalog_individual(individual_id)
	var species_id = individual.get("species_id")
	var callsign = individual.get("callsign")
	if catalog_individual.is_empty():
		failures.append("%s contains unsupported individual_id %s" % [label, individual_id])
	elif species_id != catalog_individual.get("species_id"):
		failures.append("%s species_id does not match individual catalog" % label)
	if typeof(callsign) != TYPE_STRING or str(callsign).strip_edges().is_empty() or str(callsign).length() > 32:
		failures.append("%s callsign must be 1-32 non-whitespace characters" % label)
	if typeof(individual.get("rescue_committed")) != TYPE_BOOL or not bool(individual.get("rescue_committed", false)):
		failures.append("%s must be rescue_committed" % label)
	var memory_ids := _validate_id_array(
		individual.get("earned_memory_ids"),
		_species_id_list(str(species_id), "memory_ids"),
		"%s earned_memory_ids" % label,
		failures
	)
	var adaptation_id = individual.get("selected_adaptation_id")
	if typeof(adaptation_id) != TYPE_STRING:
		failures.append("%s selected_adaptation_id must be a string" % label)
	elif not str(adaptation_id).is_empty():
		if not _species_id_list(str(species_id), "adaptation_ids").has(str(adaptation_id)):
			failures.append("%s contains unsupported selected_adaptation_id %s" % [label, adaptation_id])
		elif not memory_ids.has(_adaptation_memory_id(str(adaptation_id))):
			failures.append("%s selected adaptation requires its earned memory" % label)


func _payload_individuals(payload: Dictionary) -> Array:
	if int(payload.get("schema_version", 0)) == LEGACY_PROFILE_SCHEMA_VERSION:
		var individual: Dictionary = payload.get("individual", {})
		return [] if individual.is_empty() else [individual]
	return payload.get("individuals", []) as Array


func _canonical_order(ids: Array[String]) -> Array[String]:
	var ordered: Array[String] = []
	for individual_id in _catalog_individual_ids():
		if ids.has(individual_id):
			ordered.append(individual_id)
	return ordered


func _catalog_individual(individual_id: String) -> Dictionary:
	for value in _catalog.get("individuals", []):
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == individual_id:
			return value as Dictionary
	return {}


func _catalog_individual_ids() -> Array[String]:
	var ids: Array[String] = []
	for value in _catalog.get("individuals", []):
		if typeof(value) == TYPE_DICTIONARY:
			ids.append(str(value.get("id", "")))
	return ids


func _species(species_id: String) -> Dictionary:
	for value in _catalog.get("species", []):
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == species_id:
			return value as Dictionary
	return {}


func _species_id_list(species_id: String, field: String) -> Array:
	return (_species(species_id).get(field, []) as Array).duplicate()


func _adaptation_memory_id(adaptation_id: String) -> String:
	for adaptation in _catalog.get("adaptations", []):
		if typeof(adaptation) == TYPE_DICTIONARY and str(adaptation.get("id", "")) == adaptation_id:
			return str(adaptation.get("required_memory_id", ""))
	return ""


func _validate_id_array(value, supported_ids: Array, label: String, failures: Array[String]) -> Array:
	var ids := []
	if typeof(value) != TYPE_ARRAY:
		failures.append("%s must be an array" % label)
		return ids
	for item in value:
		if typeof(item) != TYPE_STRING or not supported_ids.has(str(item)):
			failures.append("%s contains unsupported id %s" % [label, str(item)])
		elif ids.has(str(item)):
			failures.append("%s contains duplicate id %s" % [label, str(item)])
		else:
			ids.append(str(item))
	return ids


func _append_key_failures(value: Dictionary, allowed: Dictionary, label: String, failures: Array[String]) -> void:
	for required_key in allowed:
		if not value.has(required_key):
			failures.append("%s missing %s" % [label, required_key])
	for key in value:
		if not allowed.has(str(key)):
			failures.append("%s contains unsupported field %s" % [label, key])


func _result(changed: bool, reason: String, extra := {}) -> Dictionary:
	var value := {"changed": changed, "reason": reason}
	for key in extra:
		value[key] = extra[key]
	return value


func _load_catalog() -> Dictionary:
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {}
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or typeof(json.data) != TYPE_DICTIONARY:
		return {}
	return (json.data as Dictionary).duplicate(true)
