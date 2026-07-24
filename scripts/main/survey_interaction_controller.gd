extends RefCounted

var _active_target_id := ""
var _elapsed_seconds := 0.0
var _required_seconds := 0.0


func activate(target: Dictionary) -> Dictionary:
	var target_id := str(target.get("id", "")).strip_edges()
	var required_seconds := float(target.get("interaction_seconds", 0.0))
	if target_id.is_empty() or required_seconds <= 0.0:
		reset()
		return {"state": "invalid"}
	var changed := target_id != _active_target_id
	if changed:
		_active_target_id = target_id
		_elapsed_seconds = 0.0
		_required_seconds = required_seconds
	return {
		"state": "activated",
		"changed": changed,
		"target_id": target_id,
		"elapsed_seconds": _elapsed_seconds,
		"interaction_seconds": _required_seconds,
		"progress": _elapsed_seconds / _required_seconds,
		"note": "Scanner active | Hold Q/USE and position",
	}


func update(target: Dictionary, delta: float) -> Dictionary:
	if target.is_empty():
		if _active_target_id.is_empty():
			return {"state": "idle"}
		var canceled_id := _active_target_id
		reset()
		return {"state": "canceled", "target_id": canceled_id, "note": "Survey interrupted"}

	var target_id := str(target.get("id", "")).strip_edges()
	var required_seconds := float(target.get("interaction_seconds", 0.0))
	if target_id.is_empty() or required_seconds <= 0.0:
		reset()
		return {"state": "invalid"}
	if target_id != _active_target_id:
		return {
			"state": "awaiting_activation",
			"target_id": target_id,
			"elapsed_seconds": 0.0,
			"interaction_seconds": required_seconds,
			"progress": 0.0,
			"note": "Hold Q/USE to scan: %s" % _display_label(target),
		}

	_elapsed_seconds = minf(_required_seconds, _elapsed_seconds + maxf(0.0, delta))
	var progress := _elapsed_seconds / _required_seconds
	var result := {
		"state": "progress",
		"target_id": target_id,
		"elapsed_seconds": _elapsed_seconds,
		"interaction_seconds": _required_seconds,
		"progress": progress,
		"note": "%s %d%% | Hold Q/USE" % [_display_label(target), int(floor(progress * 100.0))],
	}
	if _elapsed_seconds >= _required_seconds:
		result["state"] = "complete"
		result["note"] = "%s complete" % _display_label(target)
		reset()
	return result


func reset() -> void:
	_active_target_id = ""
	_elapsed_seconds = 0.0
	_required_seconds = 0.0


func report() -> Dictionary:
	return {
		"active_target_id": _active_target_id,
		"activated": not _active_target_id.is_empty(),
		"elapsed_seconds": _elapsed_seconds,
		"interaction_seconds": _required_seconds,
		"progress": _elapsed_seconds / _required_seconds if _required_seconds > 0.0 else 0.0,
	}


func _display_label(target: Dictionary) -> String:
	var label := str(target.get("interaction_label", "Survey anomaly")).strip_edges()
	return label if not label.is_empty() else "Survey anomaly"
