extends RefCounted

const TARGET_OBJECTIVE_ID := "deep_cache_route_objective"
const FALLBACK_DISPLAY_NAME := "Deep cache"

var _objective := {}
var _required_target_ids: Array[String] = []


func reset(route_objectives: Array) -> void:
	_objective = {}
	_required_target_ids = []
	for objective in route_objectives:
		if typeof(objective) != TYPE_DICTIONARY:
			continue
		if str(objective.get("id", "")) != TARGET_OBJECTIVE_ID:
			continue
		_objective = objective.duplicate(true)
		_required_target_ids = _required_targets(_objective)
		return


func has_objective() -> bool:
	return not _objective.is_empty() and not _required_target_ids.is_empty()


func overlay_text(held_ids: Array, banked_ids: Array) -> String:
	if not has_objective():
		return ""

	var held_count := _count_required(held_ids)
	var banked_count := _count_required(banked_ids)
	var total_count := _required_target_ids.size()
	if banked_count >= total_count:
		return "Objective complete: %s" % _display_name()
	if held_count + banked_count <= 0:
		return ""
	if held_count + banked_count >= total_count:
		return "Objective: %s %d/%d - bank" % [_display_name(), total_count, total_count]
	if banked_count > 0:
		return "Objective: %s %d/%d banked" % [_display_name(), banked_count, total_count]
	return "Objective: %s %d/%d" % [_display_name(), held_count + banked_count, total_count]


func result_text(banked_ids: Array) -> String:
	if not has_objective():
		return ""
	var state := "complete" if _count_required(banked_ids) >= _required_target_ids.size() else "incomplete"
	return "Objective: %s %s" % [_display_name(), state]


func _required_targets(objective: Dictionary) -> Array[String]:
	var targets: Array[String] = []
	for target_id in objective.get("required_banked_targets", []):
		var id := str(target_id).strip_edges()
		if id.is_empty() or targets.has(id):
			continue
		targets.append(id)
	return targets


func _count_required(ids: Array) -> int:
	var count := 0
	for id_value in ids:
		if _required_target_ids.has(str(id_value)):
			count += 1
	return count


func _display_name() -> String:
	var label := str(_objective.get("label", FALLBACK_DISPLAY_NAME)).strip_edges()
	if label.is_empty():
		label = FALLBACK_DISPLAY_NAME
	if label.to_lower().ends_with(" route"):
		label = label.substr(0, label.length() - " route".length())
	return label
