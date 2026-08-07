extends RefCounted

const ACTION_ID := "reveal_trace"
const TARGET_ID := "southwest_bloom_migration_trace"
const SPECIES_ID := "veil_cuttle"
const COOLDOWN_SECONDS := 1.8

var _world
var _player
var _companion
var _moving_hazards
var _status_sink := Callable()
var _cooldown_seconds := 0.0
var _last_result := {}


func bind_interface(status_sink: Callable) -> void:
	_status_sink = status_sink


func bind_map(world, player, companion, moving_hazards = null) -> void:
	_world = world
	_player = player
	_companion = companion
	_moving_hazards = moving_hazards
	_cooldown_seconds = 0.0
	_last_result = {}


func clear_map() -> void:
	end_preview()
	_world = null
	_player = null
	_companion = null
	_moving_hazards = null
	_cooldown_seconds = 0.0
	_last_result = {}


func advance(delta: float) -> void:
	_cooldown_seconds = maxf(0.0, _cooldown_seconds - maxf(0.0, delta))


func reset_transient(_reason := "reset") -> void:
	end_preview()
	if _world != null and _world.has_method("set_ecological_trace_state"):
		_world.set_ecological_trace_state(TARGET_ID, "hidden")
	_cooldown_seconds = 0.0
	_last_result = {}


func action() -> Dictionary:
	var reason := _availability_reason()
	return {
		"id": ACTION_ID,
		"label": "Reveal Trace",
		"enabled": reason not in ["unavailable", "recall_first", "cooldown"],
		"reason": reason,
		"denial": _denial_label(reason),
	}


func preview() -> Dictionary:
	var trace := _authored_trace()
	var hazard := _linked_hazard(trace)
	var direction := _facing_direction()
	var range_px := _default_range_px()
	var distance := range_px
	if not trace.is_empty() and not hazard.is_empty() and _companion_valid():
		var center: Vector2 = trace.get("center", _companion.global_position + direction * range_px)
		direction = _companion.global_position.direction_to(center)
		range_px = _trace_range_px(trace)
		distance = minf(range_px, _companion.global_position.distance_to(center))
	_show(direction, range_px, distance, "aiming", hazard)
	return {"direction": direction, "range_px": range_px, "target_distance": distance}


func end_preview() -> void:
	if _companion_valid() and _companion.has_method("clear_reveal_preview"):
		_companion.clear_reveal_preview()


func dispatch(action_id: String) -> Dictionary:
	if action_id != ACTION_ID:
		return _result(false, "action_unavailable")
	var reason := _availability_reason()
	var trace := _authored_trace()
	var hazard := _linked_hazard(trace)
	var range_px := _trace_range_px(trace) if not trace.is_empty() else _default_range_px()
	var direction := _facing_direction()
	var distance := range_px
	if not trace.is_empty() and _companion_valid():
		var center: Vector2 = trace.get("center", _companion.global_position + direction * range_px)
		direction = _companion.global_position.direction_to(center)
		distance = _companion.global_position.distance_to(center)
	if reason != "ready":
		_show(direction, range_px, minf(range_px, distance), "cooldown" if reason == "cooldown" else "miss", hazard)
		var denied := _result(false, reason, trace)
		_notify("Reveal Trace unavailable | %s" % _denial_label(reason))
		return denied

	var trace_id := str(trace.get("id", ""))
	if not _world.set_ecological_trace_state(trace_id, "revealed"):
		return _result(false, "state_update_failed", trace)
	_cooldown_seconds = COOLDOWN_SECONDS
	_show(direction, range_px, distance, "revealed", hazard)
	_last_result = _result(true, "revealed", trace)
	_notify("Mica revealed an ecological trace | Scanner required")
	return _last_result.duplicate(true)


func report() -> Dictionary:
	return {
		"action_id": ACTION_ID,
		"target_id": TARGET_ID,
		"cooldown_seconds": _cooldown_seconds,
		"availability_reason": _availability_reason(),
		"last_result": _last_result.duplicate(true),
		"identified": false,
		"reward_granted": false,
		"progression_changed": false,
	}


func discovery_lead() -> Dictionary:
	var trace := _authored_trace()
	if _availability_reason() != "ready" or trace.is_empty() or not _companion_valid():
		return {"active": false}
	var center: Vector2 = trace.get("center", _companion.global_position)
	return {
		"active": true,
		"direction": _companion.global_position.direction_to(center),
		"distance": _companion.global_position.distance_to(center),
		"target_id": str(trace.get("id", "")),
	}


func _availability_reason() -> String:
	if not _dependencies_valid():
		return "unavailable"
	if _companion.has_method("can_receive_command") and not bool(_companion.can_receive_command()):
		return "recall_first"
	if _cooldown_seconds > 0.0:
		return "cooldown"
	var trace := _authored_trace()
	if trace.is_empty():
		return "no_authored_trace"
	if _linked_hazard(trace).is_empty():
		return "inactive_subject"
	if str(trace.get("state", "hidden")) != "hidden":
		return "already_revealed"
	var center: Vector2 = trace.get("center", Vector2.ZERO)
	if _companion.global_position.distance_to(center) > _trace_range_px(trace):
		return "out_of_range"
	if not _world.has_method("has_clear_terrain_line") or not _world.has_clear_terrain_line(_companion.global_position, center):
		return "occluded"
	return "ready"


func _authored_trace() -> Dictionary:
	if _world == null or not _world.has_method("get_ecological_traces"):
		return {}
	for trace in _world.get_ecological_traces():
		if (
			str(trace.get("id", "")) == TARGET_ID
			and str(trace.get("species_id", "")) == SPECIES_ID
			and str(trace.get("action_id", "")) == ACTION_ID
		):
			return trace
	return {}


func _trace_range_px(trace: Dictionary) -> float:
	var tile_size := float(_world.get("tile_size")) if _world != null else 32.0
	return maxf(tile_size, float(trace.get("reveal_radius_tiles", 1.0)) * tile_size)


func _linked_hazard(trace: Dictionary) -> Dictionary:
	if trace.is_empty():
		return {}
	var hazard_id := str(trace.get("moving_hazard_id", ""))
	if _moving_hazards != null and _moving_hazards.has_method("snapshot_for"):
		return _moving_hazards.snapshot_for(hazard_id)
	if _world != null and _world.has_method("get_moving_hazards"):
		for hazard in _world.get_moving_hazards():
			if str(hazard.get("id", "")) == hazard_id:
				return (hazard as Dictionary).duplicate(true)
	return {}


func _default_range_px() -> float:
	var tile_size := float(_world.get("tile_size")) if _world != null else 32.0
	return tile_size * 6.0


func _facing_direction() -> Vector2:
	if _companion_valid():
		return Vector2(float(_companion.report().get("facing_sign", 1.0)), 0.0)
	return Vector2.RIGHT


func _show(
	direction: Vector2,
	range_px: float,
	target_distance: float,
	state: String,
	hazard: Dictionary
) -> void:
	if not _companion_valid():
		return
	if not hazard.is_empty() and _companion.has_method("show_migration_trace"):
		_companion.show_migration_trace(
			hazard.get("path", []),
			hazard.get("center", Vector2.ZERO),
			hazard.get("movement_direction", Vector2.ZERO),
			state
		)
	elif _companion.has_method("show_reveal_trace"):
		_companion.show_reveal_trace(direction, range_px, target_distance, state)


func _result(changed: bool, reason: String, trace := {}) -> Dictionary:
	var value := {
		"changed": changed,
		"reason": reason,
		"action_id": ACTION_ID,
		"target_id": str(trace.get("id", "")),
		"revealed": changed,
		"identified": false,
		"reward_ids": (trace.get("reward_ids", []) as Array).duplicate(),
		"progression_effect": str(trace.get("progression_effect", "none")),
		"gate_access_changed": false,
	}
	_last_result = value.duplicate(true)
	return value


func _denial_label(reason: String) -> String:
	match reason:
		"recall_first":
			return "recall Mica first"
		"cooldown":
			return "settling"
		"out_of_range", "no_authored_trace":
			return "no nearby trace"
		"inactive_subject":
			return "linked migration inactive"
		"occluded":
			return "trace obscured"
		"already_revealed":
			return "trace already visible"
	return "unavailable"


func _notify(note: String) -> void:
	if _status_sink.is_valid() and not note.is_empty():
		_status_sink.call(note)


func _companion_valid() -> bool:
	return _companion != null and is_instance_valid(_companion)


func _dependencies_valid() -> bool:
	return (
		_world != null
		and is_instance_valid(_world)
		and _player != null
		and is_instance_valid(_player)
		and _companion_valid()
		and _world.has_method("set_ecological_trace_state")
	)
