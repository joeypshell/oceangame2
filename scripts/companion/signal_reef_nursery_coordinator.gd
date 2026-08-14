extends Node

const JOURNEY_ID := "signal_reef_nursery_journey_01"
const INDIVIDUAL_ID := "spark_ray_juvenile_01"
const ANCHOR_ADAPTATION_ID := "anchor_fins"
const GUARDIAN_ADAPTATION_ID := "guardian_pulse"
const ANCHOR_ACTION_ID := "anchor_brace"
const GUARDIAN_ACTION_ID := "guardian_pulse_action"
const ANCHOR_ACTIVE := "anchor_active"
const GUARDIAN_ACTIVE := "guardian_active"
const UNRESOLVED := "unresolved"
const SHELTERED_PENDING_RETURN := "sheltered_pending_return"
const COMMITTED_WAITING_NEXT_DAY := "committed_waiting_next_day"
const RESTORED := "restored"
const COMMIT_ENTRY_ID := "surface_boat_entry"
const ANCHOR_RANGE_PX := 180.0
const GUARDIAN_RANGE_PX := 224.0

var _world
var _player
var _profile
var _anchor_runtime
var _guardian_runtime
var _has_upgrade := Callable()
var _status_sink := Callable()
var _contexts := {}
var _observed_successes := {}
var _pending_adaptation_id := ""
var _last_result := "idle"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func bind_status_sink(status_sink: Callable) -> void:
	_status_sink = status_sink


func bind_map(world, player, profile, anchor_runtime, guardian_runtime, has_upgrade: Callable) -> void:
	clear_map()
	_world = world
	_player = player
	_profile = profile
	_anchor_runtime = anchor_runtime
	_guardian_runtime = guardian_runtime
	_has_upgrade = has_upgrade
	_load_contexts()
	_anchor_runtime.bind_context_provider(Callable(self, "context_for_action"))
	_guardian_runtime.bind_context_provider(Callable(self, "context_for_action"))
	_observed_successes = {
		ANCHOR_ACTION_ID: int(_anchor_runtime.report().get("success_count", 0)),
		GUARDIAN_ACTION_ID: int(_guardian_runtime.report().get("success_count", 0)),
	}
	_sync_profile_state()


func clear_map() -> void:
	if _anchor_runtime != null:
		_anchor_runtime.bind_context_provider(Callable())
	if _guardian_runtime != null:
		_guardian_runtime.bind_context_provider(Callable())
	_world = null
	_player = null
	_profile = null
	_anchor_runtime = null
	_guardian_runtime = null
	_has_upgrade = Callable()
	_contexts.clear()
	_observed_successes.clear()
	_pending_adaptation_id = ""
	_last_result = "map_clear"


func reset_uncommitted(reason := "reset") -> void:
	if _world != null and _world.has_method("reset_signal_reef_nursery_uncommitted"):
		_world.reset_signal_reef_nursery_uncommitted()
	_pending_adaptation_id = ""
	_last_result = reason
	_sync_success_counts()


func commit_at_boat(at_boat: bool, day_number: int) -> Dictionary:
	if _profile == null or not _profile.has_method("commit_signal_reef_journey"):
		return _result(false, "profile_unavailable")
	if not at_boat:
		return _result(false, "not_at_boat")
	var profile_state := str(_profile_report().get("state", UNRESOLVED))
	if profile_state in [COMMITTED_WAITING_NEXT_DAY, RESTORED]:
		_sync_profile_state()
		return _result(false, "already_committed")
	if _pending_adaptation_id.is_empty() or _nursery_state() != SHELTERED_PENDING_RETURN:
		return _result(false, "nothing_pending")
	var result: Dictionary = _profile.commit_signal_reef_journey(
		_pending_adaptation_id,
		str(_world.map_id) if _world != null else "",
		COMMIT_ENTRY_ID,
		day_number
	)
	if bool(result.get("changed", false)) or str(result.get("reason", "")) == "already_committed":
		_pending_adaptation_id = ""
		_sync_profile_state()
	if bool(result.get("changed", false)):
		result["note"] = "Signal Reef nursery remembered | Return after nightfall"
		_notify(str(result["note"]))
	return result


func advance_day(day_number: int) -> Dictionary:
	if _profile == null or not _profile.has_method("advance_signal_reef_journey_day"):
		return _result(false, "profile_unavailable")
	var result: Dictionary = _profile.advance_signal_reef_journey_day(day_number)
	_sync_profile_state()
	if bool(result.get("changed", false)):
		result["note"] = "Signal Reef nursery restored | Revisit with Kite"
		_notify(str(result["note"]))
	return result


func context_for_action(action_id: String) -> Dictionary:
	var context: Dictionary = _contexts.get(action_id, {})
	if context.is_empty() or not _matches_active_kite(context):
		return {}
	if _nursery_state() != UNRESOLVED:
		return {}
	if not _near_context(context):
		return {}
	var denial := _access_denial_reason(context)
	if denial == "need_dive_light" and not _signal_reef_discovered():
		return {}
	return _runtime_context(context)


func advance(_delta := 0.0) -> Dictionary:
	_observe_action(ANCHOR_ACTION_ID, _anchor_runtime)
	_observe_action(GUARDIAN_ACTION_ID, _guardian_runtime)
	return report()


func report() -> Dictionary:
	var nursery := _nursery_report()
	var profile_journey := _profile_report()
	return {
		"configured": not _contexts.is_empty() and bool(nursery.get("configured", false)),
		"journey_id": JOURNEY_ID,
		"state": str(nursery.get("state", "unavailable")),
		"shelter_progress": float(nursery.get("shelter_progress", 0.0)),
		"pending": not _pending_adaptation_id.is_empty(),
		"pending_adaptation_id": _pending_adaptation_id,
		"last_result": _last_result,
		"profile_state": str(profile_journey.get("state", UNRESOLVED)),
		"committed_day_number": int(profile_journey.get("committed_day_number", 0)),
		"restoration_day_number": int(profile_journey.get("restoration_day_number", 0)),
		"noncompletion_reason": _noncompletion_reason(),
		"active_context_id": str((_contexts.get(_action_for_adaptation(_pending_adaptation_id), {}) as Dictionary).get("id", "")),
	}


func _process(delta: float) -> void:
	advance(delta)


func _observe_action(action_id: String, runtime) -> void:
	if runtime == null:
		return
	var action_report: Dictionary = runtime.report()
	var successes := int(action_report.get("success_count", 0))
	var previous := int(_observed_successes.get(action_id, 0))
	_observed_successes[action_id] = successes
	if successes <= previous or _nursery_state() != UNRESOLVED:
		return
	var context: Dictionary = _contexts.get(action_id, {})
	if str(action_report.get("payoff_id", "")) != str(context.get("id", "")):
		return
	var adaptation_id := str(context.get("required_adaptation_id", ""))
	var state := ANCHOR_ACTIVE if adaptation_id == ANCHOR_ADAPTATION_ID else GUARDIAN_ACTIVE
	if _world.set_signal_reef_nursery_state(state, 0.0):
		_pending_adaptation_id = adaptation_id
		_last_result = "nursery_response_started"
		_notify(
			"Kite forms a stable current lee | follow the filter skates"
			if adaptation_id == ANCHOR_ADAPTATION_ID
			else "Kite displaces the jellyfish pressure | follow the filter skates"
		)


func _load_contexts() -> void:
	if _world == null or not _world.has_method("get_companion_contexts"):
		return
	for value in _world.get_companion_contexts():
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var context := value as Dictionary
		if str(context.get("journey_id", "")) == JOURNEY_ID:
			_contexts[str(context.get("action_id", ""))] = context.duplicate(true)


func _matches_active_kite(context: Dictionary) -> bool:
	if _profile == null or not _profile.has_method("companion_report"):
		return false
	var companion: Dictionary = _profile.companion_report()
	var individual: Dictionary = companion.get("individual", {})
	return (
		str(companion.get("active_individual_id", "")) == INDIVIDUAL_ID
		and str(individual.get("individual_id", "")) == INDIVIDUAL_ID
		and str(individual.get("selected_adaptation_id", "")) == str(context.get("required_adaptation_id", ""))
	)


func _runtime_context(context: Dictionary) -> Dictionary:
	var value := context.duplicate(true)
	value["access_denial_reason"] = _access_denial_reason(context)
	return value


func _access_denial_reason(context: Dictionary) -> String:
	for value in context.get("required_access_ids", []):
		var access_id := str(value)
		var has_access: bool = (
			(_has_upgrade.is_valid() and bool(_has_upgrade.call(access_id)))
			or (_profile != null and _profile.has_method("has_capability") and bool(_profile.has_capability(access_id)))
		)
		if not has_access:
			return "need_dive_light" if access_id == "dive_light_1" else "need_propulsion_fins" if access_id == "propulsion_fins" else "need_%s" % access_id
	return ""


func _signal_reef_discovered() -> bool:
	return _profile != null and _profile.has_method("has_completed_discovery") and bool(_profile.has_completed_discovery("lower_right_signal_reef_discovery"))


func _noncompletion_reason() -> String:
	if _contexts.is_empty():
		return "source_unavailable"
	if _profile == null or not _profile.has_method("companion_report"):
		return "profile_unavailable"
	var companion: Dictionary = _profile.companion_report()
	var individual: Dictionary = companion.get("individual", {})
	if str(companion.get("active_individual_id", "")) != INDIVIDUAL_ID:
		return "kite_not_active"
	var adaptation_id := str(individual.get("selected_adaptation_id", ""))
	if adaptation_id.is_empty():
		return "kite_unadapted"
	if not _pending_adaptation_id.is_empty():
		return ""
	var action_id := _action_for_adaptation(adaptation_id)
	if action_id.is_empty():
		return "adaptation_not_supported"
	var context: Dictionary = _contexts.get(action_id, {})
	var access_denial := _access_denial_reason(context)
	return access_denial if not access_denial.is_empty() else "reach_%s_context" % adaptation_id


func _near_context(context: Dictionary) -> bool:
	if _world == null or _player == null or not is_instance_valid(_player):
		return false
	if str(context.get("action_id", "")) == ANCHOR_ACTION_ID:
		for gate in _world.get_current_gates():
			if str(gate.get("id", "")) == str(context.get("target_id", "")):
				var rect: Rect2 = gate.get("rect", Rect2())
				return rect.grow(20.0).has_point(_player.global_position) or rect.get_center().distance_to(_player.global_position) <= ANCHOR_RANGE_PX
		return false
	var pressure_center: Vector2 = _nursery_report().get("pressure_center", Vector2.ZERO)
	return pressure_center != Vector2.ZERO and pressure_center.distance_to(_player.global_position) <= GUARDIAN_RANGE_PX


func _nursery_report() -> Dictionary:
	if _world == null or not _world.has_method("get_signal_reef_nursery_report"):
		return {"configured": false}
	return _world.get_signal_reef_nursery_report()


func _nursery_state() -> String:
	return str(_nursery_report().get("state", "unavailable"))


func _profile_report() -> Dictionary:
	if _profile == null or not _profile.has_method("signal_reef_journey_report"):
		return {"state": UNRESOLVED}
	return _profile.signal_reef_journey_report()


func _sync_profile_state() -> void:
	if _world == null or not _world.has_method("set_signal_reef_nursery_state"):
		return
	var state := str(_profile_report().get("state", UNRESOLVED))
	if state in [COMMITTED_WAITING_NEXT_DAY, RESTORED]:
		_world.set_signal_reef_nursery_state(state)
		_last_result = "profile_%s" % state


func _result(changed: bool, reason: String) -> Dictionary:
	var value := report()
	value["changed"] = changed
	value["reason"] = reason
	return value


func _sync_success_counts() -> void:
	_observed_successes[ANCHOR_ACTION_ID] = int(_anchor_runtime.report().get("success_count", 0)) if _anchor_runtime != null else 0
	_observed_successes[GUARDIAN_ACTION_ID] = int(_guardian_runtime.report().get("success_count", 0)) if _guardian_runtime != null else 0


func _action_for_adaptation(adaptation_id: String) -> String:
	return ANCHOR_ACTION_ID if adaptation_id == ANCHOR_ADAPTATION_ID else GUARDIAN_ACTION_ID if adaptation_id == GUARDIAN_ADAPTATION_ID else ""


func _notify(note: String) -> void:
	if _status_sink.is_valid():
		_status_sink.call(note)
