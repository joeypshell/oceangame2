extends RefCounted

const PHASE_HOME := "home"
const PHASE_WARNING := "warning"
const PHASE_LUNGE := "lunge"
const PHASE_RECOVERY := "recovery"
const PHASE_RETURNING := "returning"
const PHASE_DEFEATED := "defeated"
const RETURN_SPEED_FACTOR := 0.75

var _states := {}
var _defeated_ids := {}
var _current_prompt := ""


func on_map_loaded(world, preserve_day_state := false) -> void:
	if not preserve_day_state:
		_defeated_ids = {}
	_load_sources(world)


func reset_for_failure(world) -> void:
	_defeated_ids = {}
	_load_sources(world)


func update(world, player_position: Vector2, delta: float) -> Dictionary:
	_current_prompt = ""
	var event := {}
	for hostile_id in _sorted_state_ids():
		var state: Dictionary = _states[hostile_id]
		var next_event := _update_state(state, player_position, maxf(0.0, delta))
		_states[hostile_id] = state
		_sync_visual(world, state)
		if event.is_empty() and not next_event.is_empty():
			event = next_event
		if _current_prompt.is_empty():
			_current_prompt = _prompt_for_event(next_event, state, player_position)
	return event


func prompt() -> String:
	return _current_prompt


func attack_target(player_position: Vector2, facing_sign: float, range_px: float) -> Dictionary:
	var nearest := {}
	var nearest_distance := maxf(0.0, range_px)
	var facing := 1.0 if facing_sign >= 0.0 else -1.0
	for hostile_id in _sorted_state_ids():
		var state: Dictionary = _states[hostile_id]
		if str(state.get("phase", "")) == PHASE_DEFEATED:
			continue
		var offset: Vector2 = state.get("position", Vector2.ZERO) - player_position
		var distance := offset.length()
		if distance > range_px or offset.x * facing < -8.0:
			continue
		if nearest.is_empty() or distance < nearest_distance:
			nearest = {"id": hostile_id, "distance": distance, "phase": state.get("phase", PHASE_HOME)}
			nearest_distance = distance
	return nearest


func apply_weapon_hit(world, hostile_id: String, damage: int) -> Dictionary:
	if damage <= 0 or not _states.has(hostile_id):
		return {"changed": false, "reason": "invalid_target", "defeated": false}
	var state: Dictionary = _states[hostile_id]
	if str(state.get("phase", "")) == PHASE_DEFEATED:
		return {"changed": false, "reason": "already_defeated", "defeated": true}
	state["health"] = maxi(0, int(state.get("health", 0)) - damage)
	var defeated := int(state["health"]) == 0
	if defeated:
		state["phase"] = PHASE_DEFEATED
		state["phase_seconds"] = 0.0
		_defeated_ids[hostile_id] = true
		_current_prompt = str(state.get("defeated_label", "Territory clear for today"))
	_states[hostile_id] = state
	_sync_visual(world, state)
	return {
		"changed": true,
		"reason": "defeated" if defeated else "damaged",
		"id": hostile_id,
		"health": int(state["health"]),
		"defeated": defeated,
	}


func report() -> Dictionary:
	var state_reports := []
	for hostile_id in _sorted_state_ids():
		var state: Dictionary = _states[hostile_id]
		state_reports.append({
			"id": hostile_id,
			"phase": str(state.get("phase", PHASE_HOME)),
			"health": int(state.get("health", 0)),
			"max_health": int(state.get("max_health", 0)),
			"position": state.get("position", Vector2.ZERO),
			"home_center": state.get("home_center", Vector2.ZERO),
			"phase_seconds": float(state.get("phase_seconds", 0.0)),
		})
	return {"states": state_reports, "defeated_ids": _defeated_ids.keys(), "prompt": _current_prompt}


func state_for(hostile_id: String) -> Dictionary:
	if not _states.has(hostile_id):
		return {}
	return (_states[hostile_id] as Dictionary).duplicate(true)


func _load_sources(world) -> void:
	_states = {}
	_current_prompt = ""
	if world == null or not world.has_method("get_hostile_encounters"):
		return
	for source in world.get_hostile_encounters():
		if typeof(source) != TYPE_DICTIONARY:
			continue
		var hostile_id := str(source.get("id", ""))
		if hostile_id.is_empty():
			continue
		var state: Dictionary = source.duplicate(true)
		state["home_center"] = source.get("home_center", Vector2.ZERO)
		state["position"] = state["home_center"]
		state["lunge_target"] = state["home_center"]
		state["max_health"] = int(source.get("health", 3))
		state["health"] = 0 if bool(_defeated_ids.get(hostile_id, false)) else int(state["max_health"])
		state["phase"] = PHASE_DEFEATED if bool(_defeated_ids.get(hostile_id, false)) else PHASE_HOME
		state["phase_seconds"] = 0.0
		state["contact_consumed"] = false
		_states[hostile_id] = state
		_sync_visual(world, state)


func _update_state(state: Dictionary, player_position: Vector2, delta: float) -> Dictionary:
	match str(state.get("phase", PHASE_HOME)):
		PHASE_HOME:
			if _player_threatens(state, player_position):
				state["phase"] = PHASE_WARNING
				state["phase_seconds"] = float(state.get("warning_seconds", 0.75))
				return _event(state, "warning")
		PHASE_WARNING:
			if not _player_threatens(state, player_position):
				state["phase"] = PHASE_RETURNING
				state["phase_seconds"] = 0.0
				return _event(state, "retreat")
			state["phase_seconds"] = maxf(0.0, float(state.get("phase_seconds", 0.0)) - delta)
			if float(state["phase_seconds"]) <= 0.0:
				state["phase"] = PHASE_LUNGE
				state["phase_seconds"] = float(state.get("lunge_seconds", 0.45))
				state["lunge_target"] = _clamp_to_territory(player_position, state.get("territory_rect", Rect2()))
				state["contact_consumed"] = false
				return _event(state, "lunge")
		PHASE_LUNGE:
			state["phase_seconds"] = maxf(0.0, float(state.get("phase_seconds", 0.0)) - delta)
			state["position"] = (state.get("position", Vector2.ZERO) as Vector2).move_toward(
				state.get("lunge_target", Vector2.ZERO),
				float(state.get("lunge_speed_px_per_second", 1.0)) * delta
			)
			var contact_event := _contact_event(state, player_position)
			if float(state["phase_seconds"]) <= 0.0 or (state.get("position", Vector2.ZERO) as Vector2).is_equal_approx(state.get("lunge_target", Vector2.ZERO)):
				state["phase"] = PHASE_RECOVERY
				state["phase_seconds"] = float(state.get("recovery_seconds", 1.25))
			return contact_event
		PHASE_RECOVERY:
			state["phase_seconds"] = maxf(0.0, float(state.get("phase_seconds", 0.0)) - delta)
			if float(state["phase_seconds"]) <= 0.0:
				state["phase"] = PHASE_RETURNING
		PHASE_RETURNING:
			state["position"] = (state.get("position", Vector2.ZERO) as Vector2).move_toward(
				state.get("home_center", Vector2.ZERO),
				float(state.get("lunge_speed_px_per_second", 1.0)) * RETURN_SPEED_FACTOR * delta
			)
			if (state.get("position", Vector2.ZERO) as Vector2).is_equal_approx(state.get("home_center", Vector2.ZERO)):
				state["phase"] = PHASE_HOME
	return {}


func _contact_event(state: Dictionary, player_position: Vector2) -> Dictionary:
	if bool(state.get("contact_consumed", false)):
		return {}
	if (state.get("position", Vector2.ZERO) as Vector2).distance_to(player_position) > float(state.get("contact_radius_px", 0.0)):
		return {}
	state["contact_consumed"] = true
	var result := _event(state, "contact")
	result["damage"] = int(state.get("contact_damage", 1))
	return result


func _player_threatens(state: Dictionary, player_position: Vector2) -> bool:
	var territory: Rect2 = state.get("territory_rect", Rect2())
	var position: Vector2 = state.get("position", Vector2.ZERO)
	return territory.has_point(player_position) and position.distance_to(player_position) <= float(state.get("warning_radius_px", 0.0))


func _prompt_for_state(state: Dictionary, player_position: Vector2) -> String:
	var phase := str(state.get("phase", PHASE_HOME))
	if phase == PHASE_WARNING:
		return str(state.get("warning_label", "Territorial eel - watch the lunge"))
	if phase == PHASE_LUNGE:
		return str(state.get("retreat_label", "Eel territory - retreat or evade"))
	if phase == PHASE_RECOVERY and (state.get("territory_rect", Rect2()) as Rect2).has_point(player_position):
		return "Eel recovering - opening"
	return ""


func _prompt_for_event(event: Dictionary, state: Dictionary, player_position: Vector2) -> String:
	if str(event.get("kind", "")) == "retreat":
		return str(state.get("retreat_label", "Eel territory - retreat or evade"))
	return _prompt_for_state(state, player_position)


func _event(state: Dictionary, kind: String) -> Dictionary:
	return {"kind": kind, "id": str(state.get("id", "hostile")), "phase": str(state.get("phase", PHASE_HOME))}


func _sync_visual(world, state: Dictionary) -> void:
	if world == null or not world.has_method("set_hostile_visual_state"):
		return
	world.set_hostile_visual_state(
		str(state.get("id", "hostile")),
		state.get("position", Vector2.ZERO),
		str(state.get("phase", PHASE_HOME)),
		int(state.get("health", 0))
	)


func _clamp_to_territory(position: Vector2, territory: Rect2) -> Vector2:
	if territory.size == Vector2.ZERO:
		return position
	return Vector2(
		clampf(position.x, territory.position.x, territory.end.x),
		clampf(position.y, territory.position.y, territory.end.y)
	)


func _sorted_state_ids() -> Array:
	var ids := _states.keys()
	ids.sort()
	return ids
