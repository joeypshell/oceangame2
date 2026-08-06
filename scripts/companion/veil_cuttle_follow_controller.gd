extends RefCounted

const STATE_HOVER := "hover"
const STATE_INVESTIGATE := "investigate"
const STATE_FOLLOW := "follow"
const STATE_CATCH_UP := "catch_up"
const STATE_SEPARATED := "separated"
const STATE_RECOVERY := "recovery"

const HOVER_DISTANCE := 62.0
const FOLLOW_DISTANCE := 170.0
const SEPARATED_DISTANCE := 430.0
const WORRIED_SECONDS := 0.65
const INVESTIGATION_WAIT_SECONDS := 1.7
const INVESTIGATION_SECONDS := 0.95
const INVESTIGATION_REACHED_DISTANCE := 10.0
const PATH_REPLAN_SECONDS := 0.22
const WAYPOINT_REACHED_DISTANCE := 12.0
const PATH_LOOKAHEAD_POINTS := 10
const GATE_SAMPLE_DISTANCE := 8.0

const INVESTIGATE_SPEED := 105.0
const FOLLOW_SPEED := 150.0
const CATCH_UP_SPEED := 220.0
const RECOVERY_SPEED := 255.0
const INVESTIGATION_OFFSETS := [
	Vector2(48.0, -28.0),
	Vector2(-34.0, 40.0),
	Vector2(42.0, 34.0),
]

var _state := STATE_HOVER
var _path: Array = []
var _path_index := 0
var _replan_seconds := 0.0
var _separated_seconds := 0.0
var _path_blocked_by_gate := false
var _forced_separation_seconds := 0.0
var _investigation_wait_seconds := INVESTIGATION_WAIT_SECONDS
var _investigation_seconds := 0.0
var _investigation_target := Vector2.ZERO
var _investigation_index := 0
var _investigation_count := 0


func reset() -> void:
	_state = STATE_HOVER
	_path.clear()
	_path_index = 0
	_replan_seconds = 0.0
	_separated_seconds = 0.0
	_path_blocked_by_gate = false
	_forced_separation_seconds = 0.0
	_investigation_wait_seconds = INVESTIGATION_WAIT_SECONDS
	_investigation_seconds = 0.0
	_investigation_target = Vector2.ZERO


func request_recall() -> void:
	_abort_investigation()
	_replan_seconds = 0.0
	_separated_seconds = WORRIED_SECONDS
	if _state == STATE_SEPARATED:
		_state = STATE_RECOVERY


func force_readable_separation(duration := WORRIED_SECONDS) -> void:
	_abort_investigation()
	_forced_separation_seconds = maxf(0.1, duration)
	_state = STATE_SEPARATED
	_path.clear()
	_path_index = 0
	_replan_seconds = 0.0


func step(
	current_position: Vector2,
	player_position: Vector2,
	follow_target: Vector2,
	world,
	position_allowed: Callable,
	delta: float
) -> Dictionary:
	var safe_delta := maxf(0.0, delta)
	var distance := current_position.distance_to(player_position)
	if _forced_separation_seconds > 0.0:
		_forced_separation_seconds = maxf(0.0, _forced_separation_seconds - safe_delta)
		_state = STATE_SEPARATED
		return _movement_result(Vector2.ZERO, 0.0, distance)

	var desired_state := _distance_state(distance)
	if _state == STATE_RECOVERY and distance > FOLLOW_DISTANCE:
		desired_state = STATE_RECOVERY
	if desired_state == STATE_SEPARATED:
		_separated_seconds += safe_delta
	else:
		_separated_seconds = 0.0

	if desired_state == STATE_HOVER:
		return _near_step(current_position, player_position, world, position_allowed, safe_delta, distance)

	_abort_investigation()
	var movement_target := player_position if desired_state in [STATE_CATCH_UP, STATE_SEPARATED, STATE_RECOVERY] else follow_target
	_replan_seconds = maxf(0.0, _replan_seconds - safe_delta)
	if _replan_seconds <= 0.0 or _path_index >= _path.size():
		_plan_path(current_position, movement_target, world, position_allowed)
		_replan_seconds = PATH_REPLAN_SECONDS
	if _path.is_empty():
		_state = STATE_SEPARATED
		return _movement_result(Vector2.ZERO, 0.0, distance)
	if desired_state == STATE_SEPARATED and _separated_seconds < WORRIED_SECONDS:
		_state = STATE_SEPARATED
		return _movement_result(Vector2.ZERO, 0.0, distance)

	_state = STATE_RECOVERY if desired_state in [STATE_SEPARATED, STATE_RECOVERY] else desired_state
	return _movement_to_next_waypoint(current_position, distance, _speed_for_state(_state))


func report() -> Dictionary:
	return {
		"state": _state,
		"path_points": _remaining_path(),
		"path_point_count": maxi(0, _path.size() - _path_index),
		"path_blocked_by_gate": _path_blocked_by_gate,
		"separated_seconds": _separated_seconds,
		"forced_separation_seconds": _forced_separation_seconds,
		"investigation_active": _investigation_seconds > 0.0,
		"investigation_target": _investigation_target,
		"investigation_count": _investigation_count,
	}


func _near_step(
	current_position: Vector2,
	player_position: Vector2,
	world,
	position_allowed: Callable,
	delta: float,
	distance: float
) -> Dictionary:
	if _investigation_seconds > 0.0:
		_investigation_seconds = maxf(0.0, _investigation_seconds - delta)
		if (
			_investigation_seconds == 0.0
			or player_position.distance_to(_investigation_target) > HOVER_DISTANCE + 4.0
			or current_position.distance_to(_investigation_target) <= INVESTIGATION_REACHED_DISTANCE
		):
			_finish_investigation()
		else:
			_state = STATE_INVESTIGATE
			_replan_seconds = maxf(0.0, _replan_seconds - delta)
			if _replan_seconds <= 0.0 or _path_index >= _path.size():
				_plan_path(current_position, _investigation_target, world, position_allowed)
				_replan_seconds = PATH_REPLAN_SECONDS
			if not _path.is_empty():
				return _movement_to_next_waypoint(current_position, distance, INVESTIGATE_SPEED)

	_investigation_wait_seconds = maxf(0.0, _investigation_wait_seconds - delta)
	if _investigation_wait_seconds <= 0.0 and _start_investigation(player_position, world, position_allowed):
		_state = STATE_INVESTIGATE
		_plan_path(current_position, _investigation_target, world, position_allowed)
		if not _path.is_empty():
			return _movement_to_next_waypoint(current_position, distance, INVESTIGATE_SPEED)
	_state = STATE_HOVER
	_path.clear()
	_path_index = 0
	_path_blocked_by_gate = false
	return _movement_result(Vector2.ZERO, 0.0, distance)


func _start_investigation(player_position: Vector2, world, position_allowed: Callable) -> bool:
	for attempt in range(INVESTIGATION_OFFSETS.size()):
		var index := (_investigation_index + attempt) % INVESTIGATION_OFFSETS.size()
		var candidate := player_position + (INVESTIGATION_OFFSETS[index] as Vector2)
		if _has_clear_allowed_segment(player_position, candidate, world, position_allowed):
			_investigation_index = (index + 1) % INVESTIGATION_OFFSETS.size()
			_investigation_target = candidate
			_investigation_seconds = INVESTIGATION_SECONDS
			_investigation_count += 1
			_replan_seconds = 0.0
			return true
	_investigation_wait_seconds = INVESTIGATION_WAIT_SECONDS
	return false


func _finish_investigation() -> void:
	_investigation_seconds = 0.0
	_investigation_target = Vector2.ZERO
	_investigation_wait_seconds = INVESTIGATION_WAIT_SECONDS
	_path.clear()
	_path_index = 0


func _abort_investigation() -> void:
	if _investigation_seconds > 0.0:
		_finish_investigation()


func _distance_state(distance: float) -> String:
	if distance <= HOVER_DISTANCE:
		return STATE_HOVER
	if distance <= FOLLOW_DISTANCE:
		return STATE_FOLLOW
	if distance <= SEPARATED_DISTANCE:
		return STATE_CATCH_UP
	return STATE_SEPARATED


func _speed_for_state(state: String) -> float:
	if state == STATE_FOLLOW:
		return FOLLOW_SPEED
	if state == STATE_CATCH_UP:
		return CATCH_UP_SPEED
	if state == STATE_RECOVERY:
		return RECOVERY_SPEED
	return 0.0


func _movement_to_next_waypoint(current_position: Vector2, distance: float, speed: float) -> Dictionary:
	var waypoint := _next_waypoint(current_position)
	if waypoint == current_position:
		return _movement_result(Vector2.ZERO, 0.0, distance)
	return _movement_result(current_position.direction_to(waypoint), speed, distance)


func _movement_result(direction: Vector2, speed: float, distance: float) -> Dictionary:
	var value := report()
	value["direction"] = direction
	value["speed"] = speed
	value["distance_to_player"] = distance
	return value


func _plan_path(start: Vector2, target: Vector2, world, position_allowed: Callable) -> void:
	_path.clear()
	_path_index = 0
	_path_blocked_by_gate = false
	if world == null or not is_instance_valid(world):
		return
	if _has_clear_allowed_segment(start, target, world, position_allowed):
		_path.append(target)
		return
	if not world.has_method("find_open_path"):
		return
	var source_path: Array = world.find_open_path(start, target)
	if source_path.is_empty():
		return
	var allowed_path: Array = []
	for point in source_path:
		var waypoint := point as Vector2
		if not _position_allowed(waypoint, position_allowed):
			_path_blocked_by_gate = true
			break
		allowed_path.append(waypoint)
	if allowed_path.size() <= 1:
		return
	_path = _simplify_path(start, allowed_path.slice(1), world, position_allowed)


func _simplify_path(start: Vector2, source_path: Array, world, position_allowed: Callable) -> Array:
	var simplified: Array = []
	var anchor := start
	var cursor := 0
	while cursor < source_path.size():
		var farthest := cursor
		var limit: int = mini(source_path.size() - 1, cursor + PATH_LOOKAHEAD_POINTS)
		for candidate_index in range(limit, cursor - 1, -1):
			if _has_clear_allowed_segment(anchor, source_path[candidate_index] as Vector2, world, position_allowed):
				farthest = candidate_index
				break
		var selected := source_path[farthest] as Vector2
		simplified.append(selected)
		anchor = selected
		cursor = farthest + 1
	return simplified


func _next_waypoint(current_position: Vector2) -> Vector2:
	while _path_index < _path.size():
		var waypoint := _path[_path_index] as Vector2
		if current_position.distance_to(waypoint) > WAYPOINT_REACHED_DISTANCE:
			return waypoint
		_path_index += 1
	return current_position


func _has_clear_allowed_segment(start: Vector2, target: Vector2, world, position_allowed: Callable) -> bool:
	if world == null or not world.has_method("has_clear_terrain_line") or not world.has_clear_terrain_line(start, target):
		return false
	var sample_count := maxi(1, int(ceil(start.distance_to(target) / GATE_SAMPLE_DISTANCE)))
	for index in range(sample_count + 1):
		if not _position_allowed(start.lerp(target, float(index) / float(sample_count)), position_allowed):
			return false
	return true


func _position_allowed(position: Vector2, position_allowed: Callable) -> bool:
	return not position_allowed.is_valid() or bool(position_allowed.call(position))


func _remaining_path() -> Array:
	if _path_index >= _path.size():
		return []
	return _path.slice(_path_index).duplicate()
