extends RefCounted

const DEFAULT_PROMPT := "Moving hazard - wait"

var _elapsed_seconds := 0.0
var _hazards: Array = []
var _warning_hazard := {}
var _active_condition_ids: Array[String] = []


func reset(world = null, active_condition_ids = null, preserve_phase := false) -> void:
	if not preserve_phase:
		_elapsed_seconds = 0.0
	_warning_hazard = {}
	_hazards = []
	if active_condition_ids != null:
		_active_condition_ids = []
		for condition_id in active_condition_ids:
			_active_condition_ids.append(str(condition_id))
	if world != null and world.has_method("configure_moving_hazards"):
		world.configure_moving_hazards(_active_condition_ids)
	if world != null and world.has_method("get_moving_hazards"):
		_hazards = world.get_moving_hazards()
		_apply_positions(world)


func update(world, player_position: Vector2, warning_radius: float, delta: float) -> Dictionary:
	_warning_hazard = {}
	if world == null or _hazards.is_empty():
		return {}

	_elapsed_seconds += maxf(0.0, delta)
	_apply_positions(world)

	var nearest := _nearest_hazard(player_position, warning_radius)
	if nearest.is_empty():
		return {}
	_warning_hazard = nearest
	return {
		"id": str(nearest.get("id", "moving_hazard")),
		"center": nearest.get("center", Vector2.ZERO),
		"distance": float(nearest.get("distance", warning_radius)),
		"prompt": warning_prompt(),
	}


func warning_prompt() -> String:
	if _warning_hazard.is_empty():
		return ""
	var label := str(_warning_hazard.get("display_label", "")).strip_edges()
	if label.is_empty():
		return DEFAULT_PROMPT
	return "%s - wait" % label.replace("_", " ")


func warning_id() -> String:
	return str(_warning_hazard.get("id", ""))


func hazard_at(position: Vector2, radius: float) -> Dictionary:
	return _nearest_hazard(position, radius)


func hazard_by_id(hazard_id: String) -> Dictionary:
	for hazard in _hazards:
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


func snapshot() -> Array:
	var values := []
	for hazard in _hazards:
		var source := hazard as Dictionary
		var value: Dictionary = source.duplicate(true)
		var center := _position_for_hazard(source)
		var next_center := _position_for_hazard_at(source, _elapsed_seconds + 0.05)
		value["center"] = center
		value["movement_direction"] = center.direction_to(next_center)
		values.append(value)
	return values


func snapshot_for(hazard_id: String) -> Dictionary:
	for hazard in snapshot():
		if str(hazard.get("id", "")) == hazard_id:
			return (hazard as Dictionary).duplicate(true)
	return {}


func _apply_positions(world) -> void:
	if world == null or not world.has_method("set_moving_hazard_center"):
		return
	for hazard in _hazards:
		var center := _position_for_hazard(hazard)
		hazard["center"] = center
		world.set_moving_hazard_center(str(hazard.get("id", "moving_hazard")), center)


func _nearest_hazard(position: Vector2, radius: float) -> Dictionary:
	var nearest := {}
	var nearest_distance := radius
	for hazard in _hazards:
		var center: Vector2 = hazard.get("center", _position_for_hazard(hazard))
		var distance := position.distance_to(center)
		if distance <= radius and (nearest.is_empty() or distance < nearest_distance):
			nearest = hazard.duplicate(true)
			nearest["center"] = center
			nearest["distance"] = distance
			nearest_distance = distance
	return nearest


func _position_for_hazard(hazard: Dictionary) -> Vector2:
	return _position_for_hazard_at(hazard, _elapsed_seconds)


func _position_for_hazard_at(hazard: Dictionary, elapsed_seconds: float) -> Vector2:
	var path: Array = hazard.get("path", [])
	if path.size() < 2:
		return hazard.get("center", Vector2.ZERO)
	var speed := maxf(1.0, float(hazard.get("speed_px_per_second", 1.0)))
	var phase_seconds := maxf(0.0, float(hazard.get("phase_offset_seconds", 0.0)))
	var segment_lengths := _segment_lengths(path)
	var total_length := 0.0
	for length in segment_lengths:
		total_length += float(length)
	if total_length <= 0.0:
		return path[0]

	var distance := fposmod((elapsed_seconds + phase_seconds) * speed, total_length * 2.0)
	if distance > total_length:
		distance = total_length * 2.0 - distance

	for index in range(segment_lengths.size()):
		var segment_length := float(segment_lengths[index])
		if segment_length <= 0.0:
			continue
		if distance <= segment_length:
			var start: Vector2 = path[index]
			var end: Vector2 = path[index + 1]
			return start.lerp(end, distance / segment_length)
		distance -= segment_length
	return path[path.size() - 1]


func _segment_lengths(path: Array) -> Array:
	var lengths := []
	for index in range(path.size() - 1):
		var start: Vector2 = path[index]
		var end: Vector2 = path[index + 1]
		lengths.append(start.distance_to(end))
	return lengths
