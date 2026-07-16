extends RefCounted

var _profile
var _tool_target_by_survey := {}
var _cleared_unbanked_ids := {}


func _init(profile_state) -> void:
	_profile = profile_state


func on_map_loaded(world) -> void:
	_tool_target_by_survey = {}
	_cleared_unbanked_ids = {}
	if world == null or not world.has_method("get_tool_targets"):
		return
	for value in world.get_tool_targets():
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var target := value as Dictionary
		var survey_id := str(target.get("unlocks_survey_target_id", "")).strip_edges()
		if not survey_id.is_empty():
			_tool_target_by_survey[survey_id] = target.duplicate(true)


func record_clearance(tool_target: Dictionary) -> Dictionary:
	var target_id := str(tool_target.get("id", "")).strip_edges()
	var survey_id := str(tool_target.get("unlocks_survey_target_id", "")).strip_edges()
	if target_id.is_empty() or survey_id.is_empty() or not bool(tool_target.get("durable_clearance", false)):
		return {"changed": false, "reason": "not_dependency_target"}
	var source: Dictionary = _tool_target_by_survey.get(survey_id, {})
	if str(source.get("id", "")) != target_id:
		return {"changed": false, "reason": "source_mismatch", "target_id": target_id, "survey_id": survey_id}
	var changed := not _cleared_unbanked_ids.has(target_id)
	_cleared_unbanked_ids[target_id] = true
	return {"changed": changed, "reason": "cleared", "target_id": target_id, "survey_id": survey_id}


func clear_unbanked() -> void:
	_cleared_unbanked_ids = {}


func is_survey_unlocked(survey_id: String) -> bool:
	var source: Dictionary = _tool_target_by_survey.get(survey_id, {})
	if source.is_empty():
		return true
	var target_id := str(source.get("id", ""))
	return (
		bool(_cleared_unbanked_ids.get(target_id, false))
		or (_profile != null and _profile.has_method("has_banked_tool_target") and _profile.has_banked_tool_target(target_id))
	)


func requirement_note(survey_id: String) -> String:
	var source: Dictionary = _tool_target_by_survey.get(survey_id, {})
	if source.is_empty():
		return ""
	var label := str(source.get("interaction_label", "wreck recorder")).replace("_", " ").strip_edges()
	if label.is_empty():
		label = "wreck recorder"
	return "%s | Cutter required" % (label.substr(0, 1).to_upper() + label.substr(1))


func report() -> Dictionary:
	var dependencies := {}
	for survey_id in _tool_target_by_survey:
		var source: Dictionary = _tool_target_by_survey[survey_id]
		dependencies[str(survey_id)] = {
			"tool_target_id": str(source.get("id", "")),
			"unlocked": is_survey_unlocked(str(survey_id)),
		}
	var cleared_ids := _cleared_unbanked_ids.keys()
	cleared_ids.sort()
	return {"dependencies": dependencies, "cleared_unbanked_ids": cleared_ids}
