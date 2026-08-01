extends RefCounted

const WreckNetworkInvestigationState := preload("res://scripts/main/wreck_network_investigation_state.gd")

var _profile
var _state := WreckNetworkInvestigationState.new()
var _configured := false
var _fragment_labels := {}
var _last_note := ""
var _last_result := ""


func _init(profile_state) -> void:
	_profile = profile_state


func on_map_loaded(world) -> Dictionary:
	_state = WreckNetworkInvestigationState.new()
	_configured = false
	_fragment_labels.clear()
	_last_note = ""
	_last_result = ""
	if world == null or not world.has_method("get_wreck_network_investigations"):
		return report()
	var sources: Array = world.get_wreck_network_investigations()
	if sources.size() != 1 or typeof(sources[0]) != TYPE_DICTIONARY:
		return report()
	_configured = true
	_build_fragment_labels(world)
	return _state.configure(sources[0], _profile)


func report() -> Dictionary:
	if not _configured:
		return {
			"status": "unavailable",
			"source_valid": false,
			"analysis_ready": false,
			"completed": false,
			"committed_fragment_ids": [],
			"remaining_fragment_ids": [],
		}
	return _state.report()


func requires_analysis() -> bool:
	return bool(report().get("analysis_ready", false))


func on_discovery_committed(discovery_id: String) -> Dictionary:
	var current := report()
	if not current.get("required_fragment_ids", []).has(discovery_id):
		return {"changed": false, "status": "unrelated"}
	var remaining: Array = current.get("remaining_fragment_ids", [])
	if remaining.is_empty():
		_last_note = "Wreck fragments 2/2 | Analyze at night"
	else:
		_last_note = "Wreck fragment committed | Remaining: %s" % _fragment_label(str(remaining[0]))
	return {
		"changed": true,
		"status": str(current.get("status", "fragments_required")),
		"note": _last_note,
		"state": current,
	}


func try_analyze(runtime_phase: String, persist := true) -> Dictionary:
	if not _configured:
		return {"changed": false, "status": "unavailable"}
	var result: Dictionary = _state.try_analyze(runtime_phase, persist)
	var status := str(result.get("status", "invalid_source"))
	match status:
		"analysis_completed":
			_last_note = "%s | %s" % [
				str(result.get("result_label", "Wreck network triangulated")),
				str(result.get("next_lead_label", "")),
			]
			_last_result = "%s\n%s" % [
				str(result.get("result_label", "Wreck network triangulated")),
				str(result.get("next_lead_label", "")),
			]
		"already_completed":
			_last_note = "Wreck network already triangulated"
		"fragments_missing":
			_last_note = objective_line()
		"wrong_phase":
			_last_note = "Analyze wreck network during night debrief"
		"prerequisite_required":
			_last_note = "Wreck network source unresolved"
		"storage_error":
			_last_note = "Wreck network analysis could not be saved"
		_:
			_last_note = "Wreck network analysis unavailable"
	if not _last_note.is_empty():
		result["note"] = _last_note
	if not _last_result.is_empty():
		result["result_text"] = _last_result
	return result


func objective_line() -> String:
	var current := report()
	if not bool(current.get("prerequisite_completed", false)) or bool(current.get("completed", false)):
		return ""
	var committed: Array = current.get("committed_fragment_ids", [])
	var remaining: Array = current.get("remaining_fragment_ids", [])
	if remaining.is_empty():
		return "Wreck fragments 2/2 | Analyze at night"
	if committed.is_empty():
		return ""
	return "Wreck fragments %d/2 | Remaining: %s" % [
		committed.size(),
		_fragment_label(str(remaining[0])),
	]


func debrief_lines() -> Array[String]:
	var current := report()
	var lines: Array[String] = []
	if bool(current.get("completed", false)):
		if not _last_result.is_empty():
			for line in _last_result.split("\n"):
				if not str(line).is_empty():
					lines.append(str(line))
		return lines
	if bool(current.get("analysis_ready", false)):
		lines.append("Wreck fragments 2/2")
		lines.append("Q/USE: %s" % str(current.get("analysis_label", "Triangulate wreck network")))
		return lines
	var objective := objective_line()
	if not objective.is_empty():
		lines.append(objective)
	return lines


func result_text() -> String:
	return _last_result


func is_status_note(note: String) -> bool:
	return note.begins_with("Wreck fragment") or note.begins_with("Wreck network")


func _build_fragment_labels(world) -> void:
	if not world.has_method("get_regional_journeys") or not world.has_method("get_survey_targets"):
		return
	var surveys: Array = world.get_survey_targets()
	for value in world.get_regional_journeys():
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var journey := value as Dictionary
		var survey := _record_by_id(surveys, str(journey.get("survey_target_id", "")))
		var discovery_id := str(survey.get("discovery_id", ""))
		var lead = journey.get("expedition_lead", {})
		if discovery_id.is_empty() or typeof(lead) != TYPE_DICTIONARY:
			continue
		var label := str(lead.get("label", "")).strip_edges()
		if not label.is_empty():
			_fragment_labels[discovery_id] = label


func _fragment_label(discovery_id: String) -> String:
	if _fragment_labels.has(discovery_id):
		return str(_fragment_labels[discovery_id])
	return discovery_id.replace("_discovery", "").replace("_", " ").capitalize()


func _record_by_id(records: Array, record_id: String) -> Dictionary:
	for value in records:
		if typeof(value) == TYPE_DICTIONARY and str(value.get("id", "")) == record_id:
			return (value as Dictionary).duplicate(true)
	return {}
