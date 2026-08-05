extends RefCounted

const INDIVIDUAL_ID := "spark_ray_juvenile_01"
const ADAPTATION_ID := "anchor_fins"
const ACTION_ID := "anchor_brace"
const PAYOFF_ID := "spark_ray_anchor_current_01"
const BRACE_DURATION := 1.5
const COOLDOWN_DURATION := 3.0
const TARGET_MARGIN_PX := 20.0
const COMMAND_CONTEXT_RANGE_PX := 180.0
const COMPANION_RANGE_PX := 128.0
const CANCEL_DISTANCE_PX := 24.0

var _world
var _player
var _profile
var _companion
var _has_upgrade := Callable()
var _has_capability := Callable()
var _status_sink := Callable()
var _active := false
var _role := ""
var _elapsed_seconds := 0.0
var _cooldown_seconds := 0.0
var _direction := Vector2.UP
var _player_anchor := Vector2.ZERO
var _companion_anchor := Vector2.ZERO
var _progress_bucket := -1
var _completed_this_sortie := false
var _success_count := 0
var _last_result := "idle"
var _last_denial := ""


func bind_status_sink(status_sink: Callable) -> void:
	_status_sink = status_sink


func bind_map(
	world,
	player,
	profile,
	companion,
	has_upgrade: Callable,
	has_capability: Callable
) -> void:
	_reset_transient("map_bound")
	_world = world
	_player = player
	_profile = profile
	_companion = companion
	_has_upgrade = has_upgrade
	_has_capability = has_capability


func bind_companion(companion) -> void:
	_companion = companion
	_sync_companion_adaptation()


func clear_map() -> void:
	_reset_transient("map_clear")
	_world = null
	_player = null
	_profile = null
	_companion = null
	_has_upgrade = Callable()
	_has_capability = Callable()


func reset(reason := "reset") -> void:
	_reset_transient(reason)


func actions(context: String) -> Array:
	if not _has_anchor_fins():
		return []
	if (
		context == "independent_palette"
		and not _near_authored_target(COMMAND_CONTEXT_RANGE_PX)
		and not _active
	):
		return []
	if context not in ["independent_palette", "mounted_hotbar"]:
		return []
	var role := "independent" if context == "independent_palette" else "mounted"
	var availability := _availability(role)
	return [_action_record(availability)]


func dispatch(role: String, action_id: String) -> Dictionary:
	if action_id != ACTION_ID:
		return _result(false, "action_unavailable")
	var availability := _availability(role)
	if not bool(availability.get("allowed", false)):
		return _deny(str(availability.get("reason", "action_unavailable")))
	_active = true
	_role = role
	_elapsed_seconds = 0.0
	_progress_bucket = -1
	_last_denial = ""
	_last_result = "engaged"
	var gate := _target_gate()
	_direction = _direction_vector(str(gate.get("current_direction", "up")))
	_player_anchor = _player.global_position
	_companion_anchor = _companion.global_position
	_set_companion_brace(true, 0.0, "engaged")
	_notify("%s braces the current | hold position" % _callsign())
	return _result(true, "engaged")


func advance(delta: float, mounted: bool) -> Dictionary:
	_cooldown_seconds = maxf(0.0, _cooldown_seconds - maxf(0.0, delta))
	if not _active:
		return report()
	var cancellation := _active_cancellation_reason(mounted)
	if not cancellation.is_empty():
		_cancel(cancellation, true)
		return report()
	_player.global_position = _player_anchor
	_companion.global_position = _companion_anchor
	_elapsed_seconds = minf(BRACE_DURATION, _elapsed_seconds + maxf(0.0, delta))
	var progress := _progress()
	_set_companion_brace(true, progress, "engaged")
	var bucket := mini(3, int(floor(progress * 4.0)))
	if bucket != _progress_bucket:
		_progress_bucket = bucket
		_notify("Anchor brace %d%% | holding against %s flow" % [int(round(progress * 100.0)), _direction_label(_direction)])
	if _elapsed_seconds >= BRACE_DURATION:
		_complete()
	return report()


func report() -> Dictionary:
	var payoff := _payoff()
	return {
		"adaptation_id": ADAPTATION_ID if _has_anchor_fins() else "",
		"payoff_id": str(payoff.get("id", "")),
		"target_id": str(payoff.get("target_id", "")),
		"active": _active,
		"role": _role,
		"progress": _progress(),
		"duration_seconds": BRACE_DURATION,
		"cooldown_seconds": _cooldown_seconds,
		"cooldown_duration": COOLDOWN_DURATION,
		"completed_this_sortie": _completed_this_sortie,
		"success_count": _success_count,
		"last_result": _last_result,
		"last_denial": _last_denial,
		"direction": _direction,
		"follow_up": "deeper_signal_reef_response" if _completed_this_sortie else "",
	}


func _availability(role: String) -> Dictionary:
	if role not in ["independent", "mounted"]:
		return {"allowed": false, "reason": "invalid_role"}
	if not _dependencies_valid():
		return {"allowed": false, "reason": "companion_unavailable"}
	if not _has_anchor_fins():
		return {"allowed": false, "reason": "anchor_fins_unavailable"}
	if _active:
		return {"allowed": false, "reason": "brace_active"}
	if _cooldown_seconds > 0.0:
		return {"allowed": false, "reason": "brace_cooling_down"}
	var payoff := _payoff()
	if payoff.is_empty():
		return {"allowed": false, "reason": "payoff_source_missing"}
	if not _has_required_access(payoff):
		return {"allowed": false, "reason": "need_propulsion_fins"}
	if str(_target_gate().get("id", "")) != str(payoff.get("target_id", "")):
		return {"allowed": false, "reason": "reach_target_current"}
	if role == "independent" and not _independent_pair_ready():
		return {"allowed": false, "reason": "companion_not_in_current"}
	return {"allowed": true, "reason": "ready"}


func _active_cancellation_reason(mounted: bool) -> String:
	if not _dependencies_valid() or not _has_anchor_fins():
		return "adaptation_unavailable"
	if (_role == "mounted") != mounted:
		return "mode_changed"
	if not _has_required_access(_payoff()):
		return "equipment_access_lost"
	if str(_target_gate().get("id", "")) != str(_payoff().get("target_id", "")):
		return "left_current"
	if _player.global_position.distance_to(_player_anchor) > CANCEL_DISTANCE_PX:
		return "moved_away"
	if _companion.global_position.distance_to(_companion_anchor) > CANCEL_DISTANCE_PX:
		return "companion_moved_away"
	return ""


func _complete() -> void:
	_active = false
	_elapsed_seconds = BRACE_DURATION
	_cooldown_seconds = COOLDOWN_DURATION
	_completed_this_sortie = true
	_success_count += 1
	_last_result = "success"
	_set_companion_brace(false, 1.0, "success")
	_notify("Current held | a deeper Signal Reef response answers")


func _cancel(reason: String, notify: bool) -> void:
	if not _active:
		return
	_active = false
	_last_result = "cancelled:%s" % reason
	_set_companion_brace(false, _progress(), "cancelled")
	if notify:
		_notify("Anchor brace cancelled | hold position in the marked current")


func _deny(reason: String) -> Dictionary:
	_last_denial = reason
	_last_result = "denied:%s" % reason
	_set_companion_brace(false, 0.0, "cooldown" if reason == "brace_cooling_down" else "denied")
	_notify(_denial_note(reason))
	return _result(false, reason)


func _action_record(availability: Dictionary) -> Dictionary:
	var reason := str(availability.get("reason", "action_unavailable"))
	return {
		"id": ACTION_ID,
		"label": "%s | Anchor brace" % _callsign(),
		"enabled": bool(availability.get("allowed", false)),
		"reason": reason,
		"denial": _denial_label(reason),
		"cooldown_seconds": _cooldown_seconds,
		"cooldown_duration": COOLDOWN_DURATION,
	}


func _payoff() -> Dictionary:
	if _world == null or not _world.has_method("get_creature_adaptation_payoffs"):
		return {}
	for payoff in _world.get_creature_adaptation_payoffs():
		if str(payoff.get("id", "")) == PAYOFF_ID and str(payoff.get("adaptation_id", "")) == ADAPTATION_ID:
			return payoff
	return {}


func _target_gate() -> Dictionary:
	if _world == null or _player == null or not _world.has_method("get_current_gate_at"):
		return {}
	return _world.get_current_gate_at(_player.global_position)


func _near_authored_target(maximum_distance: float) -> bool:
	var payoff := _payoff()
	if payoff.is_empty() or _world == null or not _world.has_method("get_current_gates") or _player == null:
		return false
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) != str(payoff.get("target_id", "")):
			continue
		var rect: Rect2 = gate.get("rect", Rect2())
		var center: Vector2 = gate.get("center", Vector2.ZERO)
		return (
			rect.grow(TARGET_MARGIN_PX).has_point(_player.global_position)
			or center.distance_to(_player.global_position) <= maximum_distance
		)
	return false


func _independent_pair_ready() -> bool:
	var state := str(_companion.report().get("state", ""))
	var companion_gate: Dictionary = _world.get_current_gate_at(_companion.global_position)
	return (
		state not in ["separated", "recovery"]
		and str(companion_gate.get("id", "")) == str(_payoff().get("target_id", ""))
		and _companion.global_position.distance_to(_player.global_position) <= COMPANION_RANGE_PX
	)


func _has_required_access(payoff: Dictionary) -> bool:
	if payoff.is_empty():
		return false
	for access_id in payoff.get("required_access_ids", []):
		var normalized := str(access_id)
		var allowed := (
			(_has_upgrade.is_valid() and bool(_has_upgrade.call(normalized)))
			or (_has_capability.is_valid() and bool(_has_capability.call(normalized)))
		)
		if not allowed:
			return false
	return true


func _has_anchor_fins() -> bool:
	var individual := _individual()
	return str(individual.get("individual_id", "")) == INDIVIDUAL_ID and str(individual.get("selected_adaptation_id", "")) == ADAPTATION_ID


func _individual() -> Dictionary:
	if _profile == null or not _profile.has_method("companion_report"):
		return {}
	var companion_report: Dictionary = _profile.companion_report()
	var individual: Dictionary = companion_report.get("individual", {})
	if str(companion_report.get("active_individual_id", "")) != str(individual.get("individual_id", "")):
		return {}
	return individual


func _callsign() -> String:
	return str(_individual().get("callsign", "Spark Ray"))


func _sync_companion_adaptation() -> void:
	if _companion != null and is_instance_valid(_companion) and _companion.has_method("apply_identity"):
		_companion.apply_identity(_individual())


func _set_companion_brace(active: bool, progress: float, cue_state: String) -> void:
	if _companion != null and is_instance_valid(_companion) and _companion.has_method("set_anchor_brace"):
		_companion.set_anchor_brace(active, _direction, progress, cue_state)


func _reset_transient(reason: String) -> void:
	if _active:
		_cancel(reason, false)
	_active = false
	_role = ""
	_elapsed_seconds = 0.0
	_cooldown_seconds = 0.0
	_progress_bucket = -1
	_completed_this_sortie = false
	_success_count = 0
	_last_result = reason
	_last_denial = ""


func _dependencies_valid() -> bool:
	return (
		_world != null
		and is_instance_valid(_world)
		and _player != null
		and is_instance_valid(_player)
		and _companion != null
		and is_instance_valid(_companion)
	)


func _progress() -> float:
	return clampf(_elapsed_seconds / BRACE_DURATION, 0.0, 1.0)


func _direction_vector(direction: String) -> Vector2:
	match direction:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"down":
			return Vector2.DOWN
	return Vector2.UP


func _direction_label(direction: Vector2) -> String:
	if absf(direction.x) > absf(direction.y):
		return "east" if direction.x > 0.0 else "west"
	return "downward" if direction.y > 0.0 else "upward"


func _denial_label(reason: String) -> String:
	match reason:
		"need_propulsion_fins":
			return "propulsion fins required"
		"reach_target_current":
			return "reach east current"
		"companion_not_in_current":
			return "bring companion closer"
		"brace_cooling_down":
			return "recovering"
		"brace_active":
			return "already bracing"
	return reason.replace("_", " ")


func _denial_note(reason: String) -> String:
	match reason:
		"need_propulsion_fins":
			return "Anchor Fins cannot replace diver propulsion fins"
		"reach_target_current":
			return "Anchor brace needs the marked east Signal Reef current"
		"companion_not_in_current":
			return "Bring %s into the current before bracing" % _callsign()
		"brace_cooling_down":
			return "Anchor Fins recovering | %.1fs" % _cooldown_seconds
	return "Anchor brace unavailable | %s" % _denial_label(reason)


func _notify(note: String) -> void:
	if _status_sink.is_valid():
		_status_sink.call(note)


func _result(changed: bool, reason: String) -> Dictionary:
	var value := report()
	value["changed"] = changed
	value["reason"] = reason
	return value
