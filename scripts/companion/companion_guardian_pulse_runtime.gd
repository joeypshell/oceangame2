extends RefCounted

const INDIVIDUAL_ID := "spark_ray_juvenile_01"
const ADAPTATION_ID := "guardian_pulse"
const ACTION_ID := "guardian_pulse_action"
const PAYOFF_ID := "spark_ray_guardian_eel_01"
const CHARGE_DURATION := 0.45
const COOLDOWN_DURATION := 2.4
const PULSE_RANGE_PX := 156.0
const PULSE_HALF_ANGLE_DEGREES := 35.0
const COMMAND_CONTEXT_RANGE_PX := 224.0
const SHARED_RANGE_PX := 240.0

var _world
var _player
var _profile
var _companion
var _hostiles
var _has_upgrade := Callable()
var _has_capability := Callable()
var _aim_provider := Callable()
var _status_sink := Callable()
var _active := false
var _role := ""
var _elapsed_seconds := 0.0
var _cooldown_seconds := 0.0
var _direction := Vector2.RIGHT
var _origin := Vector2.ZERO
var _target_id := ""
var _target_position := Vector2.ZERO
var _completed_this_sortie := false
var _success_count := 0
var _last_result := "idle"
var _last_denial := ""
var _last_miss := ""
var _last_recoil_distance := 0.0
var _last_health_before := -1
var _last_health_after := -1


func bind_status_sink(status_sink: Callable) -> void:
	_status_sink = status_sink


func bind_aim_provider(aim_provider: Callable) -> void:
	_aim_provider = aim_provider


func bind_map(
	world,
	player,
	profile,
	companion,
	hostiles,
	has_upgrade: Callable,
	has_capability: Callable
) -> void:
	_reset_transient("map_bound")
	_world = world
	_player = player
	_profile = profile
	_companion = companion
	_hostiles = hostiles
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
	_hostiles = null
	_has_upgrade = Callable()
	_has_capability = Callable()


func reset(reason := "reset") -> void:
	_reset_transient(reason)


func actions(context: String) -> Array:
	if not _has_guardian_pulse():
		return []
	if context not in ["independent_palette", "mounted_hotbar"]:
		return []
	if context == "independent_palette" and not _near_authored_target(COMMAND_CONTEXT_RANGE_PX) and not _active:
		return []
	var role := "independent" if context == "independent_palette" else "mounted"
	return [_action_record(_availability(role))]


func dispatch(role: String, action_id: String) -> Dictionary:
	if action_id != ACTION_ID:
		return _result(false, "action_unavailable")
	var availability := _availability(role)
	if not bool(availability.get("allowed", false)):
		return _deny(str(availability.get("reason", "action_unavailable")))
	_active = true
	_role = role
	_elapsed_seconds = 0.0
	_last_denial = ""
	_last_miss = ""
	_last_result = "charging"
	_direction = _aim_direction(role)
	_origin = _companion.global_position
	_target_id = str(_payoff().get("target_id", ""))
	_target_position = _target_state().get("position", _origin + _direction * PULSE_RANGE_PX)
	_set_companion_pulse(true, 0.0, "charging")
	_notify("%s charges Guardian Pulse | aim %s" % [_callsign(), _direction_label(_direction)])
	return _result(true, "charging")


func advance(delta: float, mounted: bool) -> Dictionary:
	var safe_delta := maxf(0.0, delta)
	_cooldown_seconds = maxf(0.0, _cooldown_seconds - safe_delta)
	if not _active:
		return report()
	var cancellation := _cancellation_reason(mounted)
	if not cancellation.is_empty():
		_cancel(cancellation, true)
		return report()
	_elapsed_seconds = minf(CHARGE_DURATION, _elapsed_seconds + safe_delta)
	_set_companion_pulse(true, _progress(), "charging")
	if _elapsed_seconds >= CHARGE_DURATION:
		_discharge()
	return report()


func report() -> Dictionary:
	var payoff := _payoff()
	return {
		"adaptation_id": ADAPTATION_ID if _has_guardian_pulse() else "",
		"payoff_id": str(payoff.get("id", "")),
		"target_id": str(payoff.get("target_id", "")),
		"active": _active,
		"role": _role,
		"progress": _progress(),
		"charge_duration": CHARGE_DURATION,
		"cooldown_seconds": _cooldown_seconds,
		"cooldown_duration": COOLDOWN_DURATION,
		"range_px": PULSE_RANGE_PX,
		"half_angle_degrees": PULSE_HALF_ANGLE_DEGREES,
		"direction": _direction,
		"target_position": _target_position,
		"completed_this_sortie": _completed_this_sortie,
		"success_count": _success_count,
		"last_result": _last_result,
		"last_denial": _last_denial,
		"last_miss": _last_miss,
		"last_recoil_distance": _last_recoil_distance,
		"last_health_before": _last_health_before,
		"last_health_after": _last_health_after,
	}


func _availability(role: String) -> Dictionary:
	if role not in ["independent", "mounted"]:
		return {"allowed": false, "reason": "invalid_role"}
	if not _dependencies_valid():
		return {"allowed": false, "reason": "companion_unavailable"}
	if not _has_guardian_pulse():
		return {"allowed": false, "reason": "guardian_pulse_unavailable"}
	if _active:
		return {"allowed": false, "reason": "pulse_active"}
	if _cooldown_seconds > 0.0:
		return {"allowed": false, "reason": "pulse_cooling_down"}
	var payoff := _payoff()
	if payoff.is_empty():
		return {"allowed": false, "reason": "payoff_source_missing"}
	if not _has_required_access(payoff):
		return {"allowed": false, "reason": "need_shock_prod"}
	var target := _target_state()
	if target.is_empty():
		return {"allowed": false, "reason": "target_unavailable"}
	if str(target.get("phase", "")) == "defeated":
		return {"allowed": false, "reason": "target_defeated"}
	return {"allowed": true, "reason": "ready"}


func _cancellation_reason(mounted: bool) -> String:
	if not _dependencies_valid() or not _has_guardian_pulse():
		return "adaptation_unavailable"
	if (_role == "mounted") != mounted:
		return "mode_changed"
	if not _has_required_access(_payoff()):
		return "equipment_access_lost"
	if _role == "independent" and _player.global_position.distance_to(_companion.global_position) > SHARED_RANGE_PX:
		return "pair_separated"
	return ""


func _discharge() -> void:
	_active = false
	_elapsed_seconds = CHARGE_DURATION
	_cooldown_seconds = COOLDOWN_DURATION
	var target: Dictionary = _hostiles.directional_target(
		_origin,
		_direction,
		PULSE_RANGE_PX,
		PULSE_HALF_ANGLE_DEGREES,
		_target_id
	)
	if target.is_empty():
		_finish_miss(_targeting_miss_reason())
		return
	_target_position = target.get("position", _target_position)
	var interruption: Dictionary = _hostiles.apply_support_interrupt(_world, _target_id, _origin)
	if not bool(interruption.get("changed", false)):
		_finish_miss(str(interruption.get("reason", "miss")))
		return
	_completed_this_sortie = true
	_success_count += 1
	_last_result = "hit"
	_last_miss = ""
	_last_recoil_distance = float(interruption.get("recoil_distance", 0.0))
	_last_health_before = int(interruption.get("health_before", -1))
	_last_health_after = int(interruption.get("health", -1))
	_target_position = interruption.get("recoil_position", _target_position)
	_set_companion_pulse(false, 1.0, "hit")
	_notify(
		"Guardian Pulse hit | eel interrupted, health %d/%d | recovery %.1fs" % [
			_last_health_after,
			int(interruption.get("max_health", _last_health_after)),
			float(interruption.get("recovery_seconds", 0.0)),
		]
	)


func _finish_miss(reason: String) -> void:
	_last_result = "miss:%s" % reason
	_last_miss = reason
	_last_recoil_distance = 0.0
	var state := _target_state()
	_last_health_before = int(state.get("health", -1))
	_last_health_after = _last_health_before
	_set_companion_pulse(false, 1.0, "miss")
	_notify("Guardian Pulse miss | %s" % _reason_label(reason))


func _cancel(reason: String, notify: bool) -> void:
	if not _active:
		return
	_active = false
	_last_result = "cancelled:%s" % reason
	_set_companion_pulse(false, _progress(), "cancelled")
	if notify:
		_notify("Guardian Pulse cancelled | %s" % _reason_label(reason))


func _deny(reason: String) -> Dictionary:
	_last_denial = reason
	_last_result = "denied:%s" % reason
	_set_companion_pulse(false, 0.0, "cooldown" if reason == "pulse_cooling_down" else "denied")
	_notify("Guardian Pulse unavailable | %s" % _reason_label(reason))
	return _result(false, reason)


func _action_record(availability: Dictionary) -> Dictionary:
	var reason := str(availability.get("reason", "action_unavailable"))
	return {
		"id": ACTION_ID,
		"label": "%s | Guardian pulse" % _callsign(),
		"enabled": bool(availability.get("allowed", false)),
		"reason": reason,
		"denial": _reason_label(reason),
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


func _target_state() -> Dictionary:
	if _hostiles == null or not _hostiles.has_method("state_for"):
		return {}
	return _hostiles.state_for(str(_payoff().get("target_id", "")))


func _near_authored_target(maximum_distance: float) -> bool:
	if _world == null or _player == null or not _world.has_method("get_hostile_encounters"):
		return false
	var target_id := str(_payoff().get("target_id", ""))
	for source in _world.get_hostile_encounters():
		if str(source.get("id", "")) != target_id:
			continue
		var territory: Rect2 = source.get("territory_rect", Rect2())
		var center: Vector2 = source.get("home_center", Vector2.ZERO)
		return territory.grow(24.0).has_point(_player.global_position) or center.distance_to(_player.global_position) <= maximum_distance
	return false


func _targeting_miss_reason() -> String:
	var state := _target_state()
	if state.is_empty():
		return "no_target"
	if str(state.get("phase", "")) == "defeated":
		return "target_defeated"
	var offset: Vector2 = state.get("position", Vector2.ZERO) - _origin
	if offset.length() > PULSE_RANGE_PX:
		return "out_of_range"
	if offset.length() > 0.01:
		var minimum_dot := cos(deg_to_rad(PULSE_HALF_ANGLE_DEGREES))
		if offset.normalized().dot(_direction) < minimum_dot:
			return "wrong_direction"
	return "no_target"


func _has_required_access(payoff: Dictionary) -> bool:
	if payoff.is_empty():
		return false
	for access_id in payoff.get("required_access_ids", []):
		var normalized := str(access_id)
		if not (
			(_has_upgrade.is_valid() and bool(_has_upgrade.call(normalized)))
			or (_has_capability.is_valid() and bool(_has_capability.call(normalized)))
		):
			return false
	return true


func _has_guardian_pulse() -> bool:
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


func _aim_direction(role: String) -> Vector2:
	if _aim_provider.is_valid():
		var provided = _aim_provider.call(role)
		if provided is Vector2 and (provided as Vector2) != Vector2.ZERO:
			return (provided as Vector2).normalized()
	var facing := float(_companion.report().get("facing_sign", 1.0)) if _companion != null else 1.0
	return Vector2(1.0 if facing >= 0.0 else -1.0, 0.0)


func _sync_companion_adaptation() -> void:
	if _companion != null and is_instance_valid(_companion) and _companion.has_method("apply_identity"):
		_companion.apply_identity(_individual())


func _set_companion_pulse(active: bool, progress: float, cue_state: String) -> void:
	if _companion != null and is_instance_valid(_companion) and _companion.has_method("set_guardian_pulse"):
		var target_distance := PULSE_RANGE_PX
		var state := _target_state()
		if not state.is_empty():
			target_distance = clampf(
				_companion.global_position.distance_to(state.get("position", _target_position)),
				12.0,
				PULSE_RANGE_PX
			)
		_companion.set_guardian_pulse(
			active,
			_direction,
			PULSE_RANGE_PX,
			target_distance,
			progress,
			cue_state
		)


func _reset_transient(reason: String) -> void:
	if _active:
		_cancel(reason, false)
	else:
		_set_companion_pulse(false, 0.0, "idle")
	_active = false
	_role = ""
	_elapsed_seconds = 0.0
	_cooldown_seconds = 0.0
	_completed_this_sortie = false
	_success_count = 0
	_last_result = reason
	_last_denial = ""
	_last_miss = ""
	_last_recoil_distance = 0.0
	_last_health_before = -1
	_last_health_after = -1


func _dependencies_valid() -> bool:
	return (
		_world != null and is_instance_valid(_world)
		and _player != null and is_instance_valid(_player)
		and _companion != null and is_instance_valid(_companion)
		and _hostiles != null
	)


func _progress() -> float:
	return clampf(_elapsed_seconds / CHARGE_DURATION, 0.0, 1.0)


func _direction_label(direction: Vector2) -> String:
	if absf(direction.x) >= absf(direction.y):
		return "east" if direction.x >= 0.0 else "west"
	return "south" if direction.y >= 0.0 else "north"


func _reason_label(reason: String) -> String:
	match reason:
		"need_shock_prod":
			return "Shock Prod required"
		"pulse_cooling_down":
			return "recovering %.1fs" % _cooldown_seconds
		"out_of_range":
			return "target out of range"
		"wrong_direction":
			return "face the territorial eel"
		"not_threatening":
			return "wait for warning or lunge"
		"pair_separated":
			return "stay near your companion"
		"target_defeated":
			return "territory already clear"
		"no_target", "target_unavailable":
			return "no contracted target"
	return reason.replace("_", " ")


func _notify(note: String) -> void:
	if _status_sink.is_valid():
		_status_sink.call(note)


func _result(changed: bool, reason: String) -> Dictionary:
	var value := report()
	value["changed"] = changed
	value["reason"] = reason
	return value
