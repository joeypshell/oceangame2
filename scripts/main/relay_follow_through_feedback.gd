extends RefCounted

const TRIGGER_DESTINATION_PAYOFF_BANKED := "destination_payoff_banked"

var _objectives: Array = []
var _completed_objective_ids: Array[String] = []


func reset(world) -> void:
	_objectives = []
	_completed_objective_ids = []
	if world == null or not world.has_method("get_relay_follow_through_objectives"):
		return
	for objective in world.get_relay_follow_through_objectives():
		if typeof(objective) == TYPE_DICTIONARY:
			_objectives.append(objective.duplicate(true))


func banked_feedback(banked_ids: Array[String]) -> String:
	for objective in _objectives:
		if str(objective.get("trigger", "")).strip_edges() != TRIGGER_DESTINATION_PAYOFF_BANKED:
			continue
		var objective_id := str(objective.get("id", "")).strip_edges()
		var target_id := str(objective.get("target_id", "")).strip_edges()
		if objective_id.is_empty() or target_id.is_empty() or not banked_ids.has(target_id):
			continue
		if not _completed_objective_ids.has(objective_id):
			_completed_objective_ids.append(objective_id)
		return _label_text(objective, "label")
	return ""


func result_text(banked_ids: Array[String]) -> String:
	for objective in _objectives:
		var objective_id := str(objective.get("id", "")).strip_edges()
		var target_id := str(objective.get("target_id", "")).strip_edges()
		if objective_id.is_empty() or target_id.is_empty():
			continue
		if _completed_objective_ids.has(objective_id) or banked_ids.has(target_id):
			return _label_text(objective, "result_label")
	return ""


func _label_text(objective: Dictionary, field: String) -> String:
	var label := str(objective.get(field, "")).strip_edges()
	if label.is_empty() and field == "result_label":
		label = str(objective.get("label", "")).strip_edges()
	return label
