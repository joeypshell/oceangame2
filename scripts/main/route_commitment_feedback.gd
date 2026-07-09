extends RefCounted

const TARGET_OBJECTIVE_ID := "deep_cache_route_objective"
const OBJECTIVE_STEP_CUE_MARKER_ID := "deep_cache_first_step_cue"
const FALLBACK_DISPLAY_NAME := "Deep cache"
const FALLBACK_STEP_LABEL := "Lower loop"

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


func overlay_text(held_ids: Array, banked_ids: Array, show_start_cue := false) -> String:
	if not has_objective():
		return ""

	var held_count := _count_required(held_ids)
	var banked_count := _count_required(banked_ids)
	var total_count := _required_target_ids.size()
	if banked_count >= total_count:
		return "Objective complete: %s" % _display_name()
	if held_count + banked_count <= 0:
		if show_start_cue:
			return "Objective: %s 0/%d" % [_display_name(), total_count]
		return ""
	if held_count + banked_count >= total_count:
		return "Objective: %s %d/%d - bank" % [_display_name(), total_count, total_count]
	if banked_count > 0:
		return "Objective: %s %d/%d banked" % [_display_name(), banked_count, total_count]
	return "Objective: %s %d/%d" % [_display_name(), held_count + banked_count, total_count]


func objective_step_cue_text(world, player_position: Vector2, held_ids: Array, banked_ids: Array, show_step_cue := true) -> String:
	if not show_step_cue or not has_objective():
		return ""
	if world == null or not world.has_method("get_marker_zone"):
		return ""
	if world.has_method("is_inside_extraction") and world.is_inside_extraction(player_position):
		return ""

	var marker: Dictionary = world.get_marker_zone(OBJECTIVE_STEP_CUE_MARKER_ID)
	if not _is_valid_objective_step_marker(world, marker):
		return ""
	if not _marker_contains_position(marker, player_position, float(world.tile_size)):
		return ""

	var target_id := str(marker.get("target_id", "")).strip_edges()
	if _has_id(held_ids, target_id) or _has_id(banked_ids, target_id):
		return ""
	if world.has_method("is_salvage_collected") and world.is_salvage_collected(target_id):
		return ""
	if _count_required(held_ids) + _count_required(banked_ids) >= _required_target_ids.size():
		return ""

	return "Objective route: %s" % _step_label(marker)


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


func _has_id(ids: Array, target_id: String) -> bool:
	for id_value in ids:
		if str(id_value) == target_id:
			return true
	return false


func _is_valid_objective_step_marker(world, marker: Dictionary) -> bool:
	if marker.is_empty() or not bool(marker.get("objective_step_cue", false)):
		return false
	if str(marker.get("objective_id", "")).strip_edges() != TARGET_OBJECTIVE_ID:
		return false
	if str(marker.get("route_context", "")).strip_edges() != str(_objective.get("route_context", "")).strip_edges():
		return false
	var target_id := str(marker.get("target_id", "")).strip_edges()
	if target_id.is_empty() or not _required_target_ids.has(target_id):
		return false
	if not _objective_supports_marker(str(marker.get("id", "")).strip_edges()):
		return false
	return _target_exists(world, target_id)


func _objective_supports_marker(marker_id: String) -> bool:
	if marker_id.is_empty():
		return false
	for id_value in _objective.get("supporting_marker_ids", []):
		if str(id_value) == marker_id:
			return true
	return false


func _target_exists(world, target_id: String) -> bool:
	if not world.has_method("get_salvage_centers"):
		return true
	for salvage in world.get_salvage_centers():
		if str(salvage.get("id", "")) == target_id:
			return true
	return false


func _marker_contains_position(marker: Dictionary, position: Vector2, tile_size: float) -> bool:
	if tile_size <= 0.0:
		return false
	var marker_rect := Rect2(
		Vector2(float(marker.get("x", 0)), float(marker.get("y", 0))) * tile_size,
		Vector2(float(marker.get("w", 0)), float(marker.get("h", 0))) * tile_size
	)
	return marker_rect.has_point(position)


func _step_label(marker: Dictionary) -> String:
	var label := str(marker.get("objective_step_label", FALLBACK_STEP_LABEL)).strip_edges()
	return label if not label.is_empty() else FALLBACK_STEP_LABEL


func _display_name() -> String:
	var label := str(_objective.get("label", FALLBACK_DISPLAY_NAME)).strip_edges()
	if label.is_empty():
		label = FALLBACK_DISPLAY_NAME
	if label.to_lower().ends_with(" route"):
		label = label.substr(0, label.length() - " route".length())
	return label
