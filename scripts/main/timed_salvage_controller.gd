extends RefCounted

const TIMED_INTERACTION := "timed_salvage"

var _active_id := ""
var _progress_seconds := 0.0
var _required_seconds := 0.0
var _label := ""


func reset() -> void:
	_active_id = ""
	_progress_seconds = 0.0
	_required_seconds = 0.0
	_label = ""


func is_active() -> bool:
	return not _active_id.is_empty()


func update(nearby_salvage: Dictionary, delta: float) -> Dictionary:
	if nearby_salvage.is_empty() or str(nearby_salvage.get("interaction", "instant")) != TIMED_INTERACTION:
		var was_active := is_active()
		reset()
		return {"state": "canceled", "note": "Salvage interrupted"} if was_active else {"state": "none"}

	var salvage_id := str(nearby_salvage.get("id", ""))
	if salvage_id.is_empty():
		reset()
		return {"state": "none"}

	var required_seconds := maxf(0.01, float(nearby_salvage.get("interaction_seconds", 0.01)))
	if salvage_id != _active_id:
		_active_id = salvage_id
		_progress_seconds = 0.0
		_required_seconds = required_seconds
		_label = _display_label(nearby_salvage)

	_progress_seconds = minf(_required_seconds, _progress_seconds + maxf(0.0, delta))
	var progress_ratio := clampf(_progress_seconds / _required_seconds, 0.0, 1.0)
	var progress_percent := int(round(progress_ratio * 100.0))
	var note := "Salvaging %s\n%d%% %s" % [_label, progress_percent, _progress_bar(progress_ratio)]

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
