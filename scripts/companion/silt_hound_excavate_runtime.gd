extends RefCounted

const ACTION_ID := "excavate"
const CONTEXT_ID := "silt_hound_excavate_context_01"
const TARGET_ID := "silt_hound_buried_titanium_01"
const SPECIES_ID := "silt_hound"
const INDIVIDUAL_ID := "silt_hound_juvenile_01"

const STATE_IDLE := "idle"
const STATE_APPROACHING := "approaching"
const STATE_ANTICIPATING := "anticipating"
const STATE_DIGGING := "digging"
const STATE_IMPACT := "impact"
const STATE_REVEALED := "revealed"
const STATE_CANCELED := "canceled"

const PLAYER_CONTEXT_RADIUS_PX := 104.0
const PLAYER_CANCEL_RADIUS_PX := 160.0
const COMPANION_CONTEXT_RADIUS_PX := 132.0
const APPROACH_TIMEOUT_SECONDS := 6.0
const ANTICIPATION_SECONDS := 0.55
const DIG_SECONDS := 1.15
const IMPACT_SECONDS := 0.28

var _world
var _player
var _companion
var _status_sink := Callable()
var _state := STATE_IDLE
var _phase_seconds := 0.0
var _progress := 0.0
var _busy := false
var _completion_guard := false
var _reveal_count := 0
var _last_reason := "ready"
var _visited_states: Array[String] = []


func bind_interface(status_sink: Callable) -> void:
	_status_sink = status_sink


func bind_map(world, player, companion) -> void:
	clear_map()
	_world = world
	_player = player
	_companion = companion
	_state = STATE_IDLE
	_last_reason = "ready"


func clear_map() -> void:
	reset_transient("map_clear")
	_world = null
	_player = null
	_companion = null


func command() -> Dictionary:
	var availability := _availability()
	if not bool(availability.get("in_context", false)):
		return {}
	var enabled := str(availability.get("reason", "")) == "ready"
	return {
		"id": ACTION_ID,
		"label": "Excavate",
		"enabled": enabled,
		"reason": availability.get("reason", "command_unavailable"),
		"denial": _denial_text(str(availability.get("reason", "command_unavailable"))),
		"target_id": TARGET_ID,
	}


func dispatch(command_id: String) -> Dictionary:
	if command_id != ACTION_ID:
		return _result(false, "command_unavailable")
	var availability := _availability()
	var reason := str(availability.get("reason", "command_unavailable"))
	if reason != "ready":
		_last_reason = reason
		_notify("Excavate unavailable | %s" % _denial_text(reason))
		return _result(false, reason)
	var target: Vector2 = availability.get("target", Vector2.ZERO)
	if not _companion.has_method("begin_excavate_approach") or not bool(_companion.begin_excavate_approach(target)):
		_last_reason = "path_blocked"
		_notify("Excavate unavailable | %s" % _denial_text(_last_reason))
		return _result(false, _last_reason)
	_busy = true
	_completion_guard = false
	_phase_seconds = 0.0
	_progress = 0.0
	_visited_states = []
	_set_phase(STATE_APPROACHING, 0.0)
	_notify("Marl moves to the buried deposit")
	return _result(true, "started")


func advance(delta: float) -> Dictionary:
	if not _busy:
		return report()
	var live_reason := _live_invalid_reason()
	if not live_reason.is_empty():
		return cancel_active(live_reason)
	var step := maxf(0.0, delta)
	_phase_seconds += step
	match _state:
		STATE_APPROACHING:
			if _companion.has_method("excavate_target_reached") and bool(_companion.excavate_target_reached()):
				_set_phase(STATE_ANTICIPATING, 0.0)
				_notify("Marl braces over the mound")
			elif _phase_seconds >= APPROACH_TIMEOUT_SECONDS:
				return cancel_active("path_blocked")
		STATE_ANTICIPATING:
			_update_phase_progress(ANTICIPATION_SECONDS)
			if _phase_seconds >= ANTICIPATION_SECONDS:
				_set_phase(STATE_DIGGING, 0.0)
		STATE_DIGGING:
			_update_phase_progress(DIG_SECONDS)
			if _phase_seconds >= DIG_SECONDS:
				if _completion_guard or not _world.reveal_buried_material_candidate(TARGET_ID):
					return cancel_active(_source_failure_reason())
				_completion_guard = true
				_reveal_count += 1
				_set_phase(STATE_IMPACT, 0.0)
		STATE_IMPACT:
			_update_phase_progress(IMPACT_SECONDS)
			if _phase_seconds >= IMPACT_SECONDS:
				_busy = false
				_state = STATE_REVEALED
				_progress = 1.0
				_last_reason = "revealed"
				_record_state(STATE_REVEALED)
				_world.set_buried_material_state(TARGET_ID, "opened", 1.0)
				if _companion.has_method("complete_excavate_action"):
					_companion.complete_excavate_action()
				_notify("Marl uncovered titanium scrap")
	return report()


func cancel_active(reason := "canceled") -> Dictionary:
	if not _busy:
		return _result(false, "not_busy")
	_busy = false
	_state = STATE_CANCELED
	_progress = 0.0
	_phase_seconds = 0.0
	_completion_guard = false
	_last_reason = reason
	_record_state(STATE_CANCELED)
	if _world != null and is_instance_valid(_world) and _world.has_method("conceal_buried_material_candidate"):
		_world.conceal_buried_material_candidate(TARGET_ID)
	if _companion != null and is_instance_valid(_companion) and _companion.has_method("cancel_excavate_action"):
		_companion.cancel_excavate_action()
	_notify("Marl stopped excavating | %s" % _denial_text(reason))
	return _result(true, reason)


func reset_transient(reason := "reset") -> void:
	if _busy:
		cancel_active(reason)
	elif _companion != null and is_instance_valid(_companion) and _companion.has_method("cancel_excavate_action"):
		_companion.cancel_excavate_action()
	if _world != null and is_instance_valid(_world) and _world.has_method("conceal_buried_material_candidate"):
		_world.conceal_buried_material_candidate(TARGET_ID)
	_state = STATE_IDLE
	_phase_seconds = 0.0
	_progress = 0.0
	_busy = false
	_completion_guard = false
	_last_reason = reason


func report() -> Dictionary:
	return {
		"action_id": ACTION_ID,
		"context_id": CONTEXT_ID,
		"target_id": TARGET_ID,
		"state": _state,
		"busy": _busy,
		"progress": _progress,
		"phase_seconds": _phase_seconds,
		"completion_guard": _completion_guard,
		"reveal_count": _reveal_count,
		"last_reason": _last_reason,
		"visited_states": _visited_states.duplicate(),
		"availability": _availability(),
	}


func _availability() -> Dictionary:
	if not _dependencies_valid():
		return {"reason": "companion_unavailable", "in_context": false}
	if not _context_matches_source():
		return {"reason": "context_missing", "in_context": false}
	var companion_report: Dictionary = _companion.report()
	var identity: Dictionary = companion_report.get("identity", {})
	if str(companion_report.get("species_id", "")) != SPECIES_ID or str(identity.get("individual_id", "")) != INDIVIDUAL_ID:
		return {"reason": "wrong_companion", "in_context": false}
	var source: Dictionary = _world.get_material_candidate_state(TARGET_ID)
	if not bool(source.get("exists", false)) or not bool(source.get("buried", false)):
		return {"reason": "target_missing", "in_context": false}
	if not bool(source.get("active", false)):
		return {"reason": "target_inactive", "in_context": false}
	if bool(source.get("depleted", false)):
		return {"reason": "target_depleted", "in_context": false}
	if bool(source.get("revealed", false)) or _state == STATE_REVEALED:
		return {"reason": "target_revealed", "in_context": false}
	var target: Vector2 = source.get("candidate", {}).get("center", Vector2.ZERO)
	if _player.global_position.distance_to(target) > PLAYER_CONTEXT_RADIUS_PX:
		return {"reason": "target_out_of_range", "in_context": false, "target": target}
	if _busy:
		return {"reason": "busy", "in_context": true, "target": target}
	if _companion.global_position.distance_to(target) > COMPANION_CONTEXT_RADIUS_PX:
		return {"reason": "companion_out_of_range", "in_context": false, "target": target}
	if _companion.has_method("can_receive_command") and not bool(_companion.can_receive_command(COMPANION_CONTEXT_RADIUS_PX)):
		return {"reason": "companion_unavailable", "in_context": false, "target": target}
	if not _companion.has_method("excavate_path_allowed") or not bool(_companion.excavate_path_allowed(target)):
		return {"reason": "path_blocked", "in_context": false, "target": target}
	return {"reason": "ready", "in_context": true, "target": target}


func _live_invalid_reason() -> String:
	if not _dependencies_valid() or not _context_matches_source():
		return "context_invalid"
	if not bool(_companion.report().get("excavate", {}).get("active", false)):
		return "companion_unavailable"
	var source: Dictionary = _world.get_material_candidate_state(TARGET_ID)
	if not bool(source.get("active", false)):
		return "target_inactive"
	if bool(source.get("depleted", false)):
		return "target_depleted"
	var target: Vector2 = source.get("candidate", {}).get("center", Vector2.ZERO)
	if _player.global_position.distance_to(target) > PLAYER_CANCEL_RADIUS_PX:
		return "target_out_of_range"
	if _state == STATE_APPROACHING and not bool(_companion.excavate_path_allowed(target)):
		return "path_blocked"
	return ""


func _context_matches_source() -> bool:
	if not _world.has_method("get_companion_contexts"):
		return false
	for value in _world.get_companion_contexts():
		var context := value as Dictionary
		if str(context.get("id", "")) != CONTEXT_ID:
			continue
		return (
			str(context.get("species_id", "")) == SPECIES_ID
			and str(context.get("individual_id", "")) == INDIVIDUAL_ID
			and str(context.get("action_id", "")) == ACTION_ID
			and str(context.get("target_id", "")) == TARGET_ID
		)
	return false


func _set_phase(state: String, progress: float) -> void:
	_state = state
	_phase_seconds = 0.0
	_progress = clampf(progress, 0.0, 1.0)
	_last_reason = state
	_record_state(state)
	_project_phase()


func _update_phase_progress(duration: float) -> void:
	_progress = clampf(_phase_seconds / maxf(duration, 0.001), 0.0, 1.0)
	_project_phase()


func _project_phase() -> void:
	if _companion != null and is_instance_valid(_companion) and _companion.has_method("set_excavate_phase"):
		_companion.set_excavate_phase(_state, _progress)
	if _world == null or not is_instance_valid(_world) or not _world.has_method("set_buried_material_state"):
		return
	var mound_state := "disturbed" if _state == STATE_APPROACHING else _state
	_world.set_buried_material_state(TARGET_ID, mound_state, _progress)


func _source_failure_reason() -> String:
	var source: Dictionary = _world.get_material_candidate_state(TARGET_ID) if _world != null else {}
	if bool(source.get("depleted", false)):
		return "target_depleted"
	if bool(source.get("revealed", false)):
		return "target_revealed"
	return "reveal_failed"


func _record_state(state: String) -> void:
	if _visited_states.is_empty() or _visited_states[-1] != state:
		_visited_states.append(state)


func _result(changed: bool, reason: String) -> Dictionary:
	var value := report()
	value["changed"] = changed
	value["reason"] = reason
	return value


func _denial_text(reason: String) -> String:
	match reason:
		"busy":
			return "already digging"
		"companion_out_of_range", "companion_unavailable":
			return "Marl is too far away"
		"target_out_of_range":
			return "move closer to the mound"
		"path_blocked":
			return "Marl cannot reach the mound"
		"target_revealed", "target_depleted":
			return "deposit already opened"
		"target_inactive":
			return "deposit is not active today"
		"target_missing":
			return "buried deposit is missing"
		"context_missing", "context_invalid":
			return "excavation source is invalid"
		"wrong_companion", "active_companion_changed":
			return "Marl must be active"
		"oxygen_failure":
			return "the dive ended"
		"hazard", "combat_defeat":
			return "danger interrupted the dig"
		"retry", "failure", "reset":
			return "the attempt reset"
		"reload":
			return "reload reset the mound"
		"next_day":
			return "the new day reset the mound"
		_:
			return "excavation unavailable"


func _notify(note: String) -> void:
	if _status_sink.is_valid() and not note.is_empty():
		_status_sink.call(note)


func _dependencies_valid() -> bool:
	return (
		_world != null
		and is_instance_valid(_world)
		and _player != null
		and is_instance_valid(_player)
		and _companion != null
		and is_instance_valid(_companion)
	)
