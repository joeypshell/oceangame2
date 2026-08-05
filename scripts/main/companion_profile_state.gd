extends RefCounted

const PROFILE_SCHEMA_VERSION := 1
const CATALOG_PATH := "res://config/creature_catalog.json"
const FIRST_PROOF_INDIVIDUAL_ID := "spark_ray_juvenile_01"
const PROFILE_KEYS := {
	"schema_version": true,
	"individual": true,
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
var _individual := {}
var _active_individual_id := ""


func _init() -> void:
	_catalog = _load_catalog()


func reset() -> void:
	_individual = {}
	_active_individual_id = ""


func load_payload(payload: Dictionary) -> Array[String]:
	var failures := validate_payload(payload)
	if not failures.is_empty():
		return failures
	reset()
	var individual = payload.get("individual", {})
	if not individual.is_empty():
		_individual = (individual as Dictionary).duplicate(true)
	_active_individual_id = str(payload.get("active_individual_id", ""))
	return []


func payload() -> Dictionary:
	return {
		"schema_version": PROFILE_SCHEMA_VERSION,
		"individual": _canonical_individual(),
		"active_individual_id": _active_individual_id,
	}


func report() -> Dictionary:
	var value := payload()
	value["rescue_committed"] = has_committed_companion()
	value["riding_available_on_sortie_launch"] = has_launchable_active_companion()
	return value


func commit_rescue(individual_id: String, species_id: String, callsign: String, select_active := true) -> Dictionary:
	var normalized_callsign := callsign.strip_edges()
	if individual_id != FIRST_PROOF_INDIVIDUAL_ID:
		return _result(false, "unsupported_individual", {"individual_id": individual_id})
	if not _species_ids().has(species_id):
		return _result(false, "unsupported_species", {"species_id": species_id})
	if normalized_callsign.is_empty() or normalized_callsign.length() > 32:
		return _result(false, "invalid_callsign")
	if has_committed_companion():
		if str(_individual.get("individual_id", "")) == individual_id:
			return _result(false, "already_committed", {"individual_id": individual_id})
		return _result(false, "companion_already_committed", {"individual_id": individual_id})
	_individual = {
		"individual_id": individual_id,
		"species_id": species_id,
		"callsign": normalized_callsign,
		"rescue_committed": true,
		"earned_memory_ids": [],
		"selected_adaptation_id": "",
	}
	_active_individual_id = individual_id if select_active else ""
	return _result(true, "committed", {"individual_id": individual_id})


func select_active(individual_id: String) -> Dictionary:
	if not has_committed_companion() or str(_individual.get("individual_id", "")) != individual_id:
		return _result(false, "companion_not_committed", {"individual_id": individual_id})
	if _active_individual_id == individual_id:
		return _result(false, "already_active", {"individual_id": individual_id})
	_active_individual_id = individual_id
	return _result(true, "selected", {"individual_id": individual_id})


func earn_memory(memory_id: String) -> Dictionary:
	if not has_committed_companion():
		return _result(false, "companion_not_committed", {"memory_id": memory_id})
	if not _species_memory_ids(str(_individual["species_id"])).has(memory_id):
		return _result(false, "unsupported_memory", {"memory_id": memory_id})
	var earned: Array = _individual["earned_memory_ids"]
	if earned.has(memory_id):
		return _result(false, "already_earned", {"memory_id": memory_id})
	earned.append(memory_id)
	earned.sort()
	return _result(true, "earned", {"memory_id": memory_id})


func select_adaptation(adaptation_id: String) -> Dictionary:
	if not has_committed_companion():
		return _result(false, "companion_not_committed", {"adaptation_id": adaptation_id})
	if not _species_adaptation_ids(str(_individual["species_id"])).has(adaptation_id):
		return _result(false, "unsupported_adaptation", {"adaptation_id": adaptation_id})
	var selected := str(_individual.get("selected_adaptation_id", ""))
	if selected == adaptation_id:
		return _result(false, "already_selected", {"adaptation_id": adaptation_id})
	if not selected.is_empty():
		return _result(false, "adaptation_already_selected", {"adaptation_id": adaptation_id})
	var required_memory := _adaptation_memory_id(adaptation_id)
	if required_memory.is_empty() or not (_individual["earned_memory_ids"] as Array).has(required_memory):
		return _result(false, "missing_required_memory", {
			"adaptation_id": adaptation_id,
			"required_memory_id": required_memory,
		})
	_individual["selected_adaptation_id"] = adaptation_id
	return _result(true, "selected", {"adaptation_id": adaptation_id})


func has_committed_companion() -> bool:
	return not _individual.is_empty() and bool(_individual.get("rescue_committed", false))


func has_launchable_active_companion() -> bool:
	return has_committed_companion() and _active_individual_id == str(_individual.get("individual_id", ""))


func validate_payload(payload: Dictionary) -> Array[String]:
	var failures: Array[String] = []
	if _catalog.is_empty():
		failures.append("creature catalog could not be loaded")
	if payload.get("schema_version") != PROFILE_SCHEMA_VERSION:
		failures.append("companion_profile schema_version must be %d" % PROFILE_SCHEMA_VERSION)
	_append_key_failures(payload, PROFILE_KEYS, "companion_profile", failures)
	var active_id = payload.get("active_individual_id")
	if typeof(active_id) != TYPE_STRING:
		failures.append("companion_profile active_individual_id must be a string")
	var individual = payload.get("individual")
	if typeof(individual) != TYPE_DICTIONARY:
		failures.append("companion_profile individual must be an object")
		return failures
	if individual.is_empty():
		if typeof(active_id) == TYPE_STRING and not str(active_id).is_empty():
			failures.append("companion_profile cannot select an active individual before rescue commitment")
		return failures
	_append_key_failures(individual, INDIVIDUAL_KEYS, "companion_profile individual", failures)
	var individual_id = individual.get("individual_id")
	var species_id = individual.get("species_id")
	var callsign = individual.get("callsign")
	if individual_id != FIRST_PROOF_INDIVIDUAL_ID:
		failures.append("companion_profile contains unsupported individual_id %s" % str(individual_id))
	if typeof(species_id) != TYPE_STRING or not _species_ids().has(str(species_id)):
		failures.append("companion_profile contains unsupported species_id %s" % str(species_id))
	if typeof(callsign) != TYPE_STRING or str(callsign).strip_edges().is_empty() or str(callsign).length() > 32:
		failures.append("companion_profile callsign must be 1-32 non-whitespace characters")
	if typeof(individual.get("rescue_committed")) != TYPE_BOOL or not bool(individual.get("rescue_committed", false)):
		failures.append("companion_profile persisted individual must be rescue_committed")
	if typeof(active_id) == TYPE_STRING and str(active_id) not in ["", str(individual_id)]:
		failures.append("companion_profile active_individual_id must be empty or match the committed individual")
	var memory_ids := _validate_id_array(
		individual.get("earned_memory_ids"),
		_species_memory_ids(str(species_id)),
		"companion_profile earned_memory_ids",
		failures
	)
	var adaptation_id = individual.get("selected_adaptation_id")
	if typeof(adaptation_id) != TYPE_STRING:
		failures.append("companion_profile selected_adaptation_id must be a string")
	elif not str(adaptation_id).is_empty():
		if not _species_adaptation_ids(str(species_id)).has(str(adaptation_id)):
			failures.append("companion_profile contains unsupported selected_adaptation_id %s" % str(adaptation_id))
		elif not memory_ids.has(_adaptation_memory_id(str(adaptation_id))):
			failures.append("companion_profile selected adaptation requires its earned memory")
	return failures


func _canonical_individual() -> Dictionary:
	if _individual.is_empty():
		return {}
	return {
		"individual_id": str(_individual["individual_id"]),
		"species_id": str(_individual["species_id"]),
		"callsign": str(_individual["callsign"]),
		"rescue_committed": true,
		"earned_memory_ids": (_individual["earned_memory_ids"] as Array).duplicate(),
		"selected_adaptation_id": str(_individual["selected_adaptation_id"]),
	}


func _result(changed: bool, reason: String, extra := {}) -> Dictionary:
	var value := {"changed": changed, "reason": reason}
	for key in extra:
		value[key] = extra[key]
	return value


func _species_ids() -> Array:
	var ids := []
	for species in _catalog.get("species", []):
		if typeof(species) == TYPE_DICTIONARY:
			ids.append(str(species.get("id", "")))
	return ids


func _species_memory_ids(species_id: String) -> Array:
	return _species_id_list(species_id, "memory_ids")


func _species_adaptation_ids(species_id: String) -> Array:
	return _species_id_list(species_id, "adaptation_ids")


func _species_id_list(species_id: String, field: String) -> Array:
	for species in _catalog.get("species", []):
		if typeof(species) == TYPE_DICTIONARY and str(species.get("id", "")) == species_id:
			return (species.get(field, []) as Array).duplicate()
	return []


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
