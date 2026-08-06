extends RefCounted

const SurveyInteractionController := preload("res://scripts/main/survey_interaction_controller.gd")
const ECOLOGICAL_TRACE_TYPE := "ecological_trace"
const ECOLOGICAL_HOLD_SECONDS := 1.5

var _interaction := SurveyInteractionController.new()
var _completion_sink := Callable()
var _active_target := {}


func bind_completion_sink(completion_sink: Callable) -> void:
	_completion_sink = completion_sink


func activate(world, target: Dictionary) -> Dictionary:
	if not _requires_hold(target):
		return _complete(world, target)
	_active_target = target.duplicate(true)
	var result: Dictionary = _interaction.activate(_timed_target(target))
	result["reason"] = "activated"
	result["note"] = "%s 0%% | Hold Space/USE" % _label(target)
	result["source_id"] = str(target.get("source_id", ""))
	return result


func update(world, target: Dictionary, delta: float) -> Dictionary:
	if not is_active():
		return {}
	if target.is_empty() or str(target.get("id", "")) != active_target_id():
		var canceled: Dictionary = _interaction.update({}, delta)
		_active_target = {}
		canceled["reason"] = "canceled"
		return canceled
	var result: Dictionary = _interaction.update(_timed_target(target), delta)
	if str(result.get("state", "")) == "complete":
		_active_target = {}
		return _complete(world, target)
	result["reason"] = str(result.get("state", "progress"))
	result["source_id"] = str(target.get("source_id", ""))
	return result


func cancel() -> Dictionary:
	if not is_active():
		return {"changed": false, "reason": "idle"}
	var target_id := active_target_id()
	_interaction.reset()
	_active_target = {}
	return {"changed": true, "reason": "canceled", "target_id": target_id}


func reset() -> void:
	_interaction.reset()
	_active_target = {}


func is_active() -> bool:
	return not _active_target.is_empty()


func active_target_id() -> String:
	return str(_active_target.get("id", ""))


func report() -> Dictionary:
	var value: Dictionary = _interaction.report()
	value["identification"] = true
	value["source_id"] = str(_active_target.get("source_id", ""))
	value["scan_subject_label"] = _label(_active_target) if is_active() else ""
	return value


func _complete(world, target: Dictionary) -> Dictionary:
	var source_id := str(target.get("source_id", ""))
	var ecology_result := {}
	if _requires_hold(target):
		if world == null or not world.has_method("set_ecological_trace_state"):
			return _result(false, "world_unavailable", target)
		if not _completion_sink.is_valid():
			return _result(false, "observation_state_unavailable", target)
		ecology_result = _completion_sink.call(source_id)
		var ecology_reason := str(ecology_result.get("reason", ""))
		if ecology_reason not in ["observation_pending", "already_pending", "already_committed"]:
			var denied := _result(false, ecology_reason if not ecology_reason.is_empty() else "observation_rejected", target)
			denied["ecology"] = ecology_result.duplicate(true)
			denied["note"] = str(ecology_result.get("note", ""))
			return denied
		if not world.set_ecological_trace_state(source_id, "identified"):
			return _result(false, "state_update_failed", target)
	var value := _result(bool(ecology_result.get("changed", false)), "identified", target)
	value["ecology"] = ecology_result.duplicate(true)
	value["note"] = str(ecology_result.get("note", ""))
	return value


func _timed_target(target: Dictionary) -> Dictionary:
	var value := target.duplicate(true)
	value["interaction_seconds"] = ECOLOGICAL_HOLD_SECONDS
	value["interaction_label"] = _label(target)
	return value


func _requires_hold(target: Dictionary) -> bool:
	return str(target.get("source_type", "")) == ECOLOGICAL_TRACE_TYPE


func _label(target: Dictionary) -> String:
	return str(target.get("scan_subject_label", "Ecological trace"))


func _result(changed: bool, reason: String, target: Dictionary) -> Dictionary:
	return {
		"changed": changed,
		"state": reason,
		"reason": reason,
		"target_id": str(target.get("id", "")),
		"source_id": str(target.get("source_id", "")),
		"identified": reason == "identified",
	}
