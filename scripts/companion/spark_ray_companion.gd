extends CharacterBody2D

const SparkRayFollowController := preload("res://scripts/companion/spark_ray_follow_controller.gd")

const MAX_SIMULATION_STEP := 1.0 / 30.0
const MOVEMENT_ACCELERATION := 760.0
const MOVEMENT_DECELERATION := 920.0
const MOUNTED_SWIM_SPEED := 235.0
const MOUNTED_ACCELERATION := 840.0
const MOUNTED_DECELERATION := 980.0
const FOLLOW_OFFSET := Vector2(54.0, 22.0)
const SPAWN_OFFSETS := [
	Vector2(-52.0, 24.0),
	Vector2(52.0, 24.0),
	Vector2(-52.0, -24.0),
	Vector2(52.0, -24.0),
]
const FACING_SPEED_THRESHOLD := 18.0
const FACING_COMMIT_SECONDS := 0.12

@onready var _presentation := $Presentation

var _world
var _player
var _position_allowed := Callable()
var _identity := {}
var _follow := SparkRayFollowController.new()
var _facing_sign := 1.0
var _pending_facing_sign := 1.0
var _pending_facing_seconds := 0.0
var _facing_change_count := 0
var _maximum_step_distance := 0.0


func configure(world, player, position_allowed: Callable, identity: Dictionary) -> void:
	_world = world
	_player = player
	_position_allowed = position_allowed
	_identity = identity.duplicate(true)
	_follow.reset()
	global_position = _spawn_position()
	velocity = Vector2.ZERO
	_sync_presentation()


func _physics_process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	if not _dependencies_valid():
		velocity = Vector2.ZERO
		return
	var remaining := maxf(0.0, delta)
	if remaining == 0.0:
		_advance_step(0.0)
	while remaining > 0.0:
		var step := minf(MAX_SIMULATION_STEP, remaining)
		_advance_step(step)
		remaining -= step


func set_external_control_active(active: bool) -> void:
	_follow.set_external_control_active(active)
	velocity = Vector2.ZERO
	_pending_facing_seconds = 0.0
	if _presentation != null:
		_presentation.set_mounted(active)
	_sync_presentation()


func move_under_external_control(direction: Vector2, delta: float, speed_multiplier := 1.0) -> Dictionary:
	if not _dependencies_valid() or not bool(_follow.report().get("external_control_active", false)):
		return {"changed": false, "reason": "external_control_inactive"}
	var safe_direction := direction.normalized() if direction.length() > 1.0 else direction
	var desired_velocity := safe_direction * MOUNTED_SWIM_SPEED * maxf(1.0, speed_multiplier)
	var change_rate := MOUNTED_ACCELERATION if desired_velocity != Vector2.ZERO else MOUNTED_DECELERATION
	velocity = velocity.move_toward(desired_velocity, change_rate * maxf(0.0, delta))
	var before := global_position
	var proposed := before + velocity * maxf(0.0, delta)
	var blocked_by_gate := not _segment_allowed(before, proposed)
	var blocked_by_terrain := false
	if delta > 0.0 and not blocked_by_gate:
		move_and_slide()
		blocked_by_terrain = get_slide_collision_count() > 0
	elif blocked_by_gate:
		velocity = Vector2.ZERO
	_maximum_step_distance = maxf(_maximum_step_distance, before.distance_to(global_position))
	_update_facing(delta)
	_sync_presentation()
	return {
		"changed": before.distance_to(global_position) > 0.01,
		"reason": "equipment_gate" if blocked_by_gate else "terrain" if blocked_by_terrain else "moved" if safe_direction != Vector2.ZERO else "idle",
		"position": global_position,
		"velocity": velocity,
		"direction": safe_direction,
		"blocked_by_gate": blocked_by_gate,
		"blocked_by_terrain": blocked_by_terrain,
	}


func request_recall() -> void:
	_follow.request_recall()
	_sync_presentation()


func force_readable_separation(direction: Vector2) -> void:
	_follow.force_readable_separation()
	velocity = Vector2.ZERO
	if _presentation != null:
		_presentation.set_mounted(false)
		_presentation.show_context_response("danger", direction, 1.1)
	_sync_presentation()


func show_glide_surge(direction: Vector2, duration: float) -> void:
	if _presentation != null:
		_presentation.show_glide_surge(direction, duration)


func can_handoff_control(maximum_distance := 96.0) -> bool:
	if not _dependencies_valid():
		return false
	var state := str(_follow.report().get("state", ""))
	return state not in [SparkRayFollowController.STATE_SEPARATED, SparkRayFollowController.STATE_RECOVERY] and global_position.distance_to(_player.global_position) <= maximum_distance


func recover_to_player() -> void:
	if not _dependencies_valid():
		return
	_follow.reset()
	velocity = Vector2.ZERO
	global_position = _spawn_position()
	_sync_presentation()


func show_context_response(context_kind: String, source_position: Vector2) -> bool:
	if _presentation == null:
		return false
	var direction := global_position.direction_to(source_position)
	return bool(_presentation.show_context_response(context_kind, direction))


func report() -> Dictionary:
	var value := _follow.report()
	value["identity"] = _identity.duplicate(true)
	value["position"] = global_position
	value["velocity"] = velocity
	value["facing_sign"] = _facing_sign
	value["facing_change_count"] = _facing_change_count
	value["maximum_step_distance"] = _maximum_step_distance
	value["can_handoff_control"] = can_handoff_control()
	value["presentation"] = _presentation.report() if _presentation != null else {}
	return value


func _advance_step(delta: float) -> void:
	var follow_target := _follow_target()
	var movement: Dictionary = _follow.step(
		global_position,
		_player.global_position,
		follow_target,
		_world,
		_position_allowed,
		delta
	)
	if bool(movement.get("external_control_active", false)):
		_presentation.advance(delta)
		_sync_presentation()
		return
	var direction: Vector2 = movement.get("direction", Vector2.ZERO)
	var speed := float(movement.get("speed", 0.0))
	var desired_velocity := direction * speed
	var change_rate := MOVEMENT_ACCELERATION if desired_velocity != Vector2.ZERO else MOVEMENT_DECELERATION
	velocity = velocity.move_toward(desired_velocity, change_rate * delta)
	var before := global_position
	var proposed := before + velocity * delta
	if delta <= 0.0:
		pass
	elif _is_position_allowed(proposed):
		move_and_slide()
	else:
		velocity = Vector2.ZERO
	_maximum_step_distance = maxf(_maximum_step_distance, before.distance_to(global_position))
	_update_facing(delta)
	_presentation.advance(delta)
	_sync_presentation()


func _follow_target() -> Vector2:
	var player_position: Vector2 = _player.global_position
	if global_position.distance_to(player_position) > SparkRayFollowController.FOLLOW_DISTANCE:
		return player_position
	var player_facing := 1.0
	if _player.has_method("get_facing_sign"):
		player_facing = float(_player.get_facing_sign())
	var candidate := player_position + Vector2(-FOLLOW_OFFSET.x * player_facing, FOLLOW_OFFSET.y)
	if _is_open_position(candidate) and _is_position_allowed(candidate):
		return candidate
	return player_position


func _spawn_position() -> Vector2:
	if not _dependencies_valid():
		return global_position
	var player_position: Vector2 = _player.global_position
	for offset in SPAWN_OFFSETS:
		var candidate := player_position + (offset as Vector2)
		if _spawn_candidate_allowed(player_position, candidate):
			return candidate
	return player_position


func _spawn_candidate_allowed(player_position: Vector2, candidate: Vector2) -> bool:
	if not _is_open_position(candidate) or not _is_position_allowed(candidate):
		return false
	if _world.has_method("has_clear_terrain_line") and not _world.has_clear_terrain_line(player_position, candidate):
		return false
	var sample_count := maxi(1, int(ceil(player_position.distance_to(candidate) / 8.0)))
	for index in range(sample_count + 1):
		if not _is_position_allowed(player_position.lerp(candidate, float(index) / float(sample_count))):
			return false
	return true


func _is_open_position(position: Vector2) -> bool:
	if _world == null or not _world.has_method("find_open_path"):
		return true
	return not _world.find_open_path(position, position).is_empty()


func _is_position_allowed(position: Vector2) -> bool:
	return not _position_allowed.is_valid() or bool(_position_allowed.call(position))


func _segment_allowed(start: Vector2, target: Vector2) -> bool:
	var distance := start.distance_to(target)
	var sample_count := maxi(1, int(ceil(distance / 8.0)))
	for index in range(sample_count + 1):
		if not _is_position_allowed(start.lerp(target, float(index) / float(sample_count))):
			return false
	return true


func _update_facing(delta: float) -> void:
	if absf(velocity.x) < FACING_SPEED_THRESHOLD:
		_pending_facing_seconds = 0.0
		_pending_facing_sign = _facing_sign
		return
	var candidate := 1.0 if velocity.x > 0.0 else -1.0
	if candidate == _facing_sign:
		_pending_facing_seconds = 0.0
		_pending_facing_sign = candidate
		return
	if candidate != _pending_facing_sign:
		_pending_facing_sign = candidate
		_pending_facing_seconds = 0.0
		return
	_pending_facing_seconds += maxf(0.0, delta)
	if _pending_facing_seconds < FACING_COMMIT_SECONDS:
		return
	_facing_sign = candidate
	_facing_change_count += 1
	_pending_facing_seconds = 0.0


func _sync_presentation() -> void:
	if _presentation == null:
		return
	var path_points: Array = _follow.report().get("path_points", [])
	var local_path: Array = []
	for point in path_points:
		local_path.append((point as Vector2) - global_position)
	_presentation.sync(str(_follow.report().get("state", "near")), _facing_sign, local_path)


func _dependencies_valid() -> bool:
	return _world != null and is_instance_valid(_world) and _player != null and is_instance_valid(_player)
