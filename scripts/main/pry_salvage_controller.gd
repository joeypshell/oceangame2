extends RefCounted

const PRY_INTERACTION := "pry_salvage"

var _active_id := ""
var _progress_seconds := 0.0
var _required_seconds := 0.0
var _completed_stages := 0
var _total_stages := 1
var _label := ""
var _completed_stages_by_id := {}


func reset() -> void:
	_active_id = ""
	_progress_seconds = 0.0
	_required_seconds = 0.0
	_completed_stages = 0
	_total_stages = 1
	_label = ""
	_completed_stages_by_id = {}


func is_active() -> bool:
	return not _active_id.is_empty()


func update(nearby_salvage: Dictionary, delta: float) -> Dictionary:
	if nearby_salvage.is_empty() or str(nearby_salvage.get("interaction", "instant")) != PRY_INTERACTION:
		return _cancel_current_action()

	var salvage_id := str(nearby_salvage.get("id", ""))
	if salvage_id.is_empty():
		return _cancel_current_action()

	if salvage_id != _active_id:
		_start_target(nearby_salvage)

	var remaining_delta := maxf(0.0, delta)
	while remaining_delta > 0.0 and _completed_stages < _total_stages:
		var needed_seconds := maxf(0.0, _required_seconds - _progress_seconds)
		var consumed_seconds := minf(needed_seconds, remaining_delta)
		_progress_seconds += consumed_seconds
		remaining_delta -= consumed_seconds
		if _progress_seconds < _required_seconds:
			break
		_completed_stages += 1
		_completed_stages_by_id[_active_id] = _completed_stages
		_progress_seconds = 0.0

	if _completed_stages >= _total_stages:
		var result := {
			"state": "complete",
			"id": _active_id,
			"label": _label,
			"stages": _total_stages,
			"note": "Prying %s\nStage %d/%d complete" % [_label, _total_stages, _total_stages],
		}
		_completed_stages_by_id.erase(_active_id)
		_clear_current_target()
		return result

	return {
		"state": "progress",
		"id": _active_id,
		"label": _label,
		"note": _progress_note(),
		"completed_stages": _completed_stages,
		"stages": _total_stages,
		"progress_ratio": _stage_progress_ratio(),
	}


func _start_target(salvage: Dictionary) -> void:
	_active_id = str(salvage.get("id", ""))
	_progress_seconds = 0.0
	_required_seconds = maxf(0.01, float(salvage.get("interaction_seconds", 0.01)))
	_total_stages = max(1, int(salvage.get("pry_stages", 1)))
	_completed_stages = clampi(int(_completed_stages_by_id.get(_active_id, 0)), 0, _total_stages)
	_label = _display_label(salvage)


func _cancel_current_action() -> Dictionary:
	if not is_active():
		return {"state": "none"}

	var result := {"state": "canceled", "id": _active_id, "note": _cancel_note()}
	_clear_current_target()
	return result


func _clear_current_target() -> void:
	_active_id = ""
	_progress_seconds = 0.0
	_required_seconds = 0.0
	_completed_stages = 0
	_total_stages = 1
	_label = ""


func _cancel_note() -> String:
	if _completed_stages > 0:
		return "Pry interrupted %d/%d saved" % [_completed_stages, _total_stages]
	return "Pry interrupted"


func _progress_note() -> String:
	var current_stage := clampi(_completed_stages + 1, 1, _total_stages)
	var progress_percent := int(round(_stage_progress_ratio() * 100.0))
	return "Prying %s\nStage %d/%d %d%% %s" % [
		_label,
		current_stage,
		_total_stages,
		progress_percent,
		_progress_bar(_stage_progress_ratio()),
	]


func _stage_progress_ratio() -> float:
	if _required_seconds <= 0.0:
		return 0.0
	return clampf(_progress_seconds / _required_seconds, 0.0, 1.0)


func _display_label(salvage: Dictionary) -> String:
	var label := str(salvage.get("interaction_label", ""))
	if label.is_empty():
		label = str(salvage.get("id", "salvage"))
		if label.begins_with("salvage_"):
			label = label.substr("salvage_".length())
		label = label.replace("_", " ")
	else:
		label = label.replace("_", " ")
	return label


func _progress_bar(progress_ratio: float) -> String:
	var filled_segments := int(round(clampf(progress_ratio, 0.0, 1.0) * 6.0))
	var segments := ""
	for index in range(6):
		segments += "=" if index < filled_segments else "-"
	return "[%s]" % segments
