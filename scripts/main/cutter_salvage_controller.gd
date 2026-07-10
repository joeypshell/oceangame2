extends RefCounted

const ExpansionProfileState := preload("res://scripts/main/expansion_profile_state.gd")
const CUTTER_INTERACTION := "cutter_salvage"

var _profile
var _active_id := ""
var _progress_seconds := 0.0
var _required_seconds := 0.0
var _label := ""
var _banked_target_ids := {}


func _init(profile_state) -> void:
	_profile = profile_state


func reset() -> void:
	_active_id = ""
	_progress_seconds = 0.0
	_required_seconds = 0.0
	_label = ""


func on_map_loaded(world) -> void:
	reset()
	apply_banked_to_world(world)


func mark_banked(salvage_ids: Array) -> void:
	for salvage_id in salvage_ids:
		var target_id := str(salvage_id)
		if target_id == ExpansionProfileState.SALVAGE_CUTTER_TARGET_ID:
			_banked_target_ids[target_id] = true


func apply_banked_to_world(world) -> void:
	if world == null or not world.has_method("collect_tool_target"):
		return
	for target_id in _banked_target_ids:
		world.collect_tool_target(str(target_id))


func available_target_count(world) -> int:
	if world == null or not world.has_method("get_tool_targets"):
		return 0
	var count := 0
	for target in world.get_tool_targets():
		if not bool(_banked_target_ids.get(str(target.get("id", "")), false)):
			count += 1
	return count


func is_target_banked(target_id: String) -> bool:
	return bool(_banked_target_ids.get(target_id, false))


func has_cutter() -> bool:
	return _profile != null and _profile.has_capability(ExpansionProfileState.SALVAGE_CUTTER_CAPABILITY_ID)


func update(target: Dictionary, delta: float, occupied_cargo: int, cargo_capacity: int) -> Dictionary:
	if target.is_empty() or str(target.get("interaction", "")) != CUTTER_INTERACTION:
		var was_active := not _active_id.is_empty()
		reset()
		return {"state": "canceled", "note": "Cutter interrupted"} if was_active else {"state": "none"}
	if not has_cutter():
		reset()
		return {"state": "locked", "id": str(target.get("id", "")), "note": "%s | Cutter required" % _title_label(_display_label(target))}
	if occupied_cargo >= cargo_capacity:
		reset()
		return {"state": "blocked", "id": str(target.get("id", "")), "note": "Cargo full - bank salvage at boat"}

	var target_id := str(target.get("id", ""))
	if target_id.is_empty():
		reset()
		return {"state": "none"}
	if target_id != _active_id:
		_active_id = target_id
		_progress_seconds = 0.0
		_required_seconds = maxf(0.01, float(target.get("interaction_seconds", 0.01)))
		_label = _display_label(target)

	_progress_seconds = minf(_required_seconds, _progress_seconds + maxf(0.0, delta))
	var progress_ratio := clampf(_progress_seconds / _required_seconds, 0.0, 1.0)
	var note := "Cutting %s\n%d%% %s" % [_label, int(round(progress_ratio * 100.0)), _progress_bar(progress_ratio)]
	if _progress_seconds >= _required_seconds:
		var result := {
			"state": "complete",
			"id": _active_id,
			"label": _label,
			"note": note,
			"progress_ratio": progress_ratio,
		}
		reset()
		return result
	return {
		"state": "progress",
		"id": _active_id,
		"label": _label,
		"note": note,
		"progress_ratio": progress_ratio,
	}


func report() -> Dictionary:
	var banked_ids := _banked_target_ids.keys()
	banked_ids.sort()
	return {
		"active_id": _active_id,
		"progress_seconds": _progress_seconds,
		"required_seconds": _required_seconds,
		"progress_ratio": clampf(_progress_seconds / _required_seconds, 0.0, 1.0) if _required_seconds > 0.0 else 0.0,
		"cutter_unlocked": has_cutter(),
		"banked_target_ids": banked_ids,
	}


func _display_label(target: Dictionary) -> String:
	var label := str(target.get("interaction_label", "")).replace("_", " ").strip_edges()
	if label.is_empty():
		label = str(target.get("id", "sealed wreck")).trim_prefix("salvage_").replace("_", " ")
	return label


func _title_label(label: String) -> String:
	return label.substr(0, 1).to_upper() + label.substr(1) if not label.is_empty() else "Sealed wreck"


func _progress_bar(progress_ratio: float) -> String:
	var filled_segments := int(round(clampf(progress_ratio, 0.0, 1.0) * 6.0))
	var segments := ""
	for index in range(6):
		segments += "=" if index < filled_segments else "-"
	return "[%s]" % segments
