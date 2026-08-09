extends RefCounted

const ACTION_ID := "read_drift"
const ADAPTATION_ID := "drift_lens"
const HOSTILE_RESPONSE_KIND := "companion_hostile_response"
const HOSTILE_EFFECT_KIND := "hostile_intent_read"
const HOSTILE_SUBJECT_KIND := "territorial_hostile"
const MOVING_SUBJECT_KIND := "moving_hazard"
const SUPPORTED_HAZARD_IDS := [
	"southwest_bloom_jellyfish_patrol",
	"deep_route_jellyfish_patrol",
]
const COMMAND_RANGE_PX := 384.0
const HOSTILE_CONTEXT_MARGIN_PX := 96.0
const APPROACH_WARNING_RANGE_PX := 220.0
const PROJECTION_SECONDS := 2.8
const COOLDOWN_SECONDS := 3.5

var _world
var _player
var _companion
var _moving_hazards
var _hostiles
var _status_sink := Callable()
var _projection_seconds := 0.0
var _cooldown_seconds := 0.0
var _target_id := ""
var _last_result := {}


func bind_interface(status_sink: Callable) -> void:
	_status_sink = status_sink


func bind_map(world, player, companion, moving_hazards, hostiles = null) -> void:
	clear_map()
	_world = world
	_player = player
	_companion = companion
	_moving_hazards = moving_hazards
	_hostiles = hostiles


func clear_map() -> void:
	_clear_projection()
	_world = null
	_player = null
	_companion = null
	_moving_hazards = null
	_hostiles = null
	_cooldown_seconds = 0.0
	_target_id = ""
	_last_result = {}


func reset_transient(_reason := "reset") -> void:
	_clear_projection()
	_cooldown_seconds = 0.0
	_target_id = ""
	_last_result = {}


func advance(delta: float) -> void:
	var safe_delta := maxf(0.0, delta)
	_cooldown_seconds = maxf(0.0, _cooldown_seconds - safe_delta)
	_projection_seconds = maxf(0.0, _projection_seconds - safe_delta)
	if _projection_seconds <= 0.0:
		_clear_projection()
		return
	var target := _snapshot_by_id(_target_id)
	if target.is_empty():
		_clear_projection()
		return
	_show_projection(target)


func is_learned() -> bool:
	return str(_identity().get("selected_adaptation_id", "")) == ADAPTATION_ID


func action() -> Dictionary:
	var target_state := _target_state()
	var reason := str(target_state.get("reason", "unavailable"))
	return {
		"id": ACTION_ID,
		"label": "Read Drift",
		"enabled": reason == "ready",
		"reason": reason,
		"denial": _denial_label(reason),
	}


func dispatch(action_id: String) -> Dictionary:
	if action_id != ACTION_ID:
		return _remember(_result(false, "action_unavailable"))
	var target_state := _target_state()
	var reason := str(target_state.get("reason", "unavailable"))
	var target: Dictionary = target_state.get("target", {})
	if reason != "ready":
		var denied := _result(false, reason, target)
		denied["note"] = "Read Drift unavailable | %s" % _denial_label(reason)
		_notify(str(denied["note"]))
		return _remember(denied)
	_target_id = str(target.get("id", ""))
	_projection_seconds = PROJECTION_SECONDS
	_cooldown_seconds = COOLDOWN_SECONDS
	_show_projection(target)
	var value := _result(true, "projected", target)
	value["projection_seconds"] = PROJECTION_SECONDS
	value["note"] = _result_note(target, bool(value.get("approaching", false)))
	_notify(str(value["note"]))
	return _remember(value)


func report() -> Dictionary:
	return {
		"action_id": ACTION_ID,
		"adaptation_id": ADAPTATION_ID,
		"learned": is_learned(),
		"target_id": _target_id,
		"projection_seconds": _projection_seconds,
		"cooldown_seconds": _cooldown_seconds,
		"availability_reason": str(_target_state().get("reason", "unavailable")),
		"last_result": _last_result.duplicate(true),
	}


func _target_state() -> Dictionary:
	if not _dependencies_valid() or not is_learned():
		return {"reason": "unavailable", "target": {}}
	if _companion.has_method("can_receive_command") and not bool(_companion.can_receive_command()):
		return {"reason": "recall_first", "target": {}}
	if _cooldown_seconds > 0.0:
		return {"reason": "cooldown", "target": _snapshot_by_id(_target_id)}
	var candidates := _eligible_snapshots()
	if candidates.is_empty():
		return {"reason": "no_subject", "target": {}}
	var nearest := _nearest(candidates)
	var center: Vector2 = nearest.get("center", Vector2.ZERO)
	if _companion.global_position.distance_to(center) > COMMAND_RANGE_PX:
		return {"reason": "out_of_range", "target": nearest}
	if _world.has_method("has_clear_terrain_line") and not _world.has_clear_terrain_line(_companion.global_position, center):
		return {"reason": "occluded", "target": nearest}
	return {"reason": "ready", "target": nearest}


func _eligible_snapshots() -> Array:
	var values := []
	values.append_array(_moving_hazard_snapshots())
	values.append_array(_hostile_intent_snapshots())
	return values


func _moving_hazard_snapshots() -> Array:
	var values := []
	if _moving_hazards == null or not _moving_hazards.has_method("snapshot"):
		return values
	for value in _moving_hazards.snapshot():
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var hazard := value as Dictionary
		if (
			SUPPORTED_HAZARD_IDS.has(str(hazard.get("id", "")))
			and str(hazard.get("kind", "")) == "jellyfish"
			and (hazard.get("path", []) as Array).size() >= 2
		):
			var snapshot := hazard.duplicate(true)
			snapshot["subject_kind"] = MOVING_SUBJECT_KIND
			snapshot["subject_priority"] = 1
			values.append(snapshot)
	return values


func _hostile_intent_snapshots() -> Array:
	var values := []
	if (
		_hostiles == null
		or not _hostiles.has_method("intent_snapshot_for")
		or not _world.has_method("get_companion_hostile_responses")
	):
		return values
	for value in _world.get_companion_hostile_responses():
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var relationship := value as Dictionary
		if str(relationship.get("kind", "")) != HOSTILE_RESPONSE_KIND or not _supports_active_mica(relationship):
			continue
		var hostile_id := str(relationship.get("hostile_id", ""))
		var snapshot: Dictionary = _hostiles.intent_snapshot_for(hostile_id, _player.global_position)
		if snapshot.is_empty() or bool(snapshot.get("defeated", false)):
			continue
		var territory: Rect2 = snapshot.get("territory_rect", Rect2())
		if territory.size == Vector2.ZERO or not territory.grow(HOSTILE_CONTEXT_MARGIN_PX).has_point(_player.global_position):
			continue
		snapshot["subject_kind"] = HOSTILE_SUBJECT_KIND
		snapshot["subject_priority"] = 0
		snapshot["center"] = snapshot.get("position", Vector2.ZERO)
		snapshot["path"] = []
		snapshot["display_label"] = str(snapshot.get("kind", "territorial eel")).replace("_", " ")
		snapshot["source_relationship_id"] = str(relationship.get("id", ""))
		snapshot["review_context_id"] = str(relationship.get("review_context_id", ""))
		values.append(snapshot)
	return values


func _supports_active_mica(relationship: Dictionary) -> bool:
	var identity := _identity()
	for value in relationship.get("responses", []):
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var response := value as Dictionary
		if (
			str(response.get("species_id", "")) == str(identity.get("species_id", ""))
			and str(response.get("individual_id", "")) == str(identity.get("individual_id", ""))
			and str(response.get("required_adaptation_id", "")) == ADAPTATION_ID
			and str(response.get("action_id", "")) == ACTION_ID
			and str(response.get("effect_kind", "")) == HOSTILE_EFFECT_KIND
			and str(response.get("mutation", "")) == "none"
		):
			return true
	return false


func _snapshot_by_id(hazard_id: String) -> Dictionary:
	for hazard in _eligible_snapshots():
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


func _nearest(candidates: Array) -> Dictionary:
	var nearest := {}
	var nearest_priority := 999
	var nearest_distance := INF
	for value in candidates:
		var subject := value as Dictionary
		var priority := int(subject.get("subject_priority", 1))
		var distance: float = _companion.global_position.distance_to(subject.get("center", Vector2.ZERO))
		if priority < nearest_priority or (priority == nearest_priority and distance < nearest_distance):
			nearest = subject.duplicate(true)
			nearest_priority = priority
			nearest_distance = distance
	return nearest


func _show_projection(target: Dictionary) -> void:
	if _companion == null or not _companion.has_method("show_drift_projection"):
		return
	_companion.show_drift_projection(
		target.get("path", []),
		target.get("center", Vector2.ZERO),
		target.get("movement_direction", Vector2.ZERO),
		_is_approaching(target),
		{
			"subject_kind": str(target.get("subject_kind", MOVING_SUBJECT_KIND)),
			"phase": str(target.get("phase", "")),
			"territory_rect": target.get("territory_rect", Rect2()),
			"projected_lunge_target": target.get("projected_lunge_target", target.get("center", Vector2.ZERO)),
			"phase_seconds": float(target.get("phase_seconds", 0.0)),
			"recovery_seconds": float(target.get("recovery_seconds", 0.0)),
		}
	)


func _clear_projection() -> void:
	_projection_seconds = 0.0
	if _companion != null and _companion.has_method("clear_drift_projection"):
		_companion.clear_drift_projection()


func _is_approaching(target: Dictionary) -> bool:
	if _player == null:
		return false
	var center: Vector2 = target.get("center", Vector2.ZERO)
	var direction: Vector2 = target.get("movement_direction", Vector2.ZERO)
	return (
		direction != Vector2.ZERO
		and center.distance_to(_player.global_position) <= APPROACH_WARNING_RANGE_PX
		and direction.dot(center.direction_to(_player.global_position)) >= 0.35
	)


func _result(changed: bool, reason: String, target := {}) -> Dictionary:
	return {
		"changed": changed,
		"reason": reason,
		"action_id": ACTION_ID,
		"target_id": str(target.get("id", "")),
		"subject_kind": str(target.get("subject_kind", "")),
		"path": (target.get("path", []) as Array).duplicate(true),
		"current_center": target.get("center", Vector2.ZERO),
		"movement_direction": target.get("movement_direction", Vector2.ZERO),
		"approaching": _is_approaching(target),
		"phase": str(target.get("phase", "")),
		"projected_lunge_target": target.get("projected_lunge_target", target.get("center", Vector2.ZERO)),
		"territory_rect": target.get("territory_rect", Rect2()),
		"phase_seconds": float(target.get("phase_seconds", 0.0)),
		"recovery_seconds": float(target.get("recovery_seconds", 0.0)),
		"source_relationship_id": str(target.get("source_relationship_id", "")),
		"review_context_id": str(target.get("review_context_id", "")),
		"hazard_changed": false,
		"hostile_changed": false,
		"access_changed": false,
		"reward_ids": [],
	}


func _result_note(target: Dictionary, approaching: bool) -> String:
	var label := str(target.get("display_label", "jellyfish patrol")).strip_edges()
	var direction: Vector2 = target.get("movement_direction", Vector2.ZERO)
	var direction_label := _direction_label(direction)
	if str(target.get("subject_kind", "")) == HOSTILE_SUBJECT_KIND:
		return "Mica reads %s | %s | Lunge %s | Recovery %.1fs" % [
			label,
			str(target.get("phase", "home")).replace("_", " ").to_upper(),
			direction_label,
			float(target.get("recovery_seconds", 0.0)),
		]
	return "Mica reads %s | Moving %s%s" % [
		label,
		direction_label,
		" | Approaching" if approaching else "",
	]


func _direction_label(direction: Vector2) -> String:
	if direction == Vector2.ZERO:
		return "holding"
	if absf(direction.x) >= absf(direction.y):
		return "east" if direction.x >= 0.0 else "west"
	return "south" if direction.y >= 0.0 else "north"


func _denial_label(reason: String) -> String:
	match reason:
		"recall_first":
			return "recall Mica first"
		"cooldown":
			return "lens settling"
		"no_subject":
			return "no readable drift or threat"
		"out_of_range":
			return "move closer to the subject"
		"occluded":
			return "subject obscured by terrain"
	return "Drift Lens unavailable"


func _identity() -> Dictionary:
	if _companion == null or not _companion.has_method("report"):
		return {}
	return _companion.report().get("identity", {}).duplicate(true)


func _dependencies_valid() -> bool:
	return (
		_world != null
		and is_instance_valid(_world)
		and _player != null
		and is_instance_valid(_player)
		and _companion != null
		and is_instance_valid(_companion)
	)


func _notify(note: String) -> void:
	if _status_sink.is_valid() and not note.is_empty():
		_status_sink.call(note)


func _remember(value: Dictionary) -> Dictionary:
	_last_result = value.duplicate(true)
	return value
