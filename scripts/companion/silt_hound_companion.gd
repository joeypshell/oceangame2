extends CharacterBody2D

const SiltHoundFollowController := preload("res://scripts/companion/silt_hound_follow_controller.gd")

const MAX_SIMULATION_STEP := 1.0 / 30.0
const MOVEMENT_ACCELERATION := 560.0
const MOVEMENT_DECELERATION := 720.0
const FOLLOW_OFFSET := Vector2(48.0, 30.0)
const SPAWN_OFFSETS := [
	Vector2(-50.0, 28.0),
	Vector2(50.0, 28.0),
	Vector2(-50.0, -24.0),
	Vector2(50.0, -24.0),
]
const FACING_SPEED_THRESHOLD := 11.0
const FACING_COMMIT_SECONDS := 0.15
const FLOOR_PROBE_DISTANCE := 48.0
const EXCAVATE_APPROACH_SPEED := 118.0
const EXCAVATE_STOP_DISTANCE := 34.0

@onready var _presentation := $Presentation

var _world
var _player
var _position_allowed := Callable()
var _identity := {}
var _follow := SiltHoundFollowController.new()
var _facing_sign := 1.0
var _pending_facing_sign := 1.0
var _pending_facing_seconds := 0.0
var _facing_change_count := 0
var _maximum_step_distance := 0.0
var _excavate_active := false
var _excavate_target := Vector2.ZERO
var _excavate_state := "idle"
var _excavate_progress := 0.0


func configure(world, player, position_allowed: Callable, identity: Dictionary) -> void:
	_world = world
	_player = player
	_position_allowed = position_allowed
	_identity = identity.duplicate(true)
	_follow.reset()
	global_position = _spawn_position()
	velocity = Vector2.ZERO
	if _presentation != null:
		_presentation.set_identity(str(_identity.get("callsign", "Marl")))
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


func request_recall() -> void:
	cancel_excavate_action()
	_follow.request_recall()
	_sync_presentation()


func force_readable_separation(direction: Vector2) -> void:
	_follow.force_readable_separation()
	velocity = Vector2.ZERO
	if _presentation != null:
		_presentation.show_context_response("danger", direction)
	_sync_presentation()


func recover_to_player() -> void:
	if not _dependencies_valid():
		return
	_follow.reset()
	cancel_excavate_action()
	velocity = Vector2.ZERO
	global_position = _spawn_position()
	_sync_presentation()


func can_receive_command(maximum_distance := 96.0) -> bool:
	if not _dependencies_valid():
		return false
	var state := str(_follow.report().get("state", ""))
	return state not in [SiltHoundFollowController.STATE_SEPARATED, SiltHoundFollowController.STATE_RECOVERY] and global_position.distance_to(_player.global_position) <= maximum_distance


func show_context_response(context_kind: String, source_position: Vector2) -> bool:
	if _presentation == null:
		return false
	return bool(_presentation.show_context_response(context_kind, global_position.direction_to(source_position)))


func begin_excavate_approach(target: Vector2) -> bool:
	if not excavate_path_allowed(target):
		return false
	_excavate_active = true
	_excavate_target = target
	_excavate_state = "approaching"
	_excavate_progress = 0.0
	_follow.reset()
	velocity = Vector2.ZERO
	_sync_presentation()
	return true


func set_excavate_phase(state: String, progress: float) -> void:
	if not _excavate_active:
		return
	_excavate_state = state
	_excavate_progress = clampf(progress, 0.0, 1.0)
	_sync_presentation()


func complete_excavate_action() -> void:
	_excavate_active = false
	_excavate_state = "revealed"
	_excavate_progress = 1.0
	velocity = Vector2.ZERO
	_follow.reset()
	_sync_presentation()


func cancel_excavate_action() -> void:
	_excavate_active = false
	_excavate_target = Vector2.ZERO
	_excavate_state = "idle"
	_excavate_progress = 0.0
	velocity = Vector2.ZERO
	_sync_presentation()


func excavate_target_reached() -> bool:
	return _excavate_active and global_position.distance_to(_excavate_target) <= EXCAVATE_STOP_DISTANCE


func excavate_path_allowed(target: Vector2) -> bool:
	if not _dependencies_valid() or not _is_open_position(target) or not _is_position_allowed(target):
		return false
	if _world.has_method("has_clear_terrain_line") and not _world.has_clear_terrain_line(global_position, target):
		return false
	var sample_count := maxi(1, int(ceil(global_position.distance_to(target) / 8.0)))
	for index in range(sample_count + 1):
		var sample := global_position.lerp(target, float(index) / float(sample_count))
		if not _is_open_position(sample) or not _is_position_allowed(sample):
			return false
	return true


func report() -> Dictionary:
	var value := _follow.report()
	value["identity"] = _identity.duplicate(true)
	value["species_id"] = "silt_hound"
	value["position"] = global_position
	value["velocity"] = velocity
	value["facing_sign"] = _facing_sign
	value["facing_change_count"] = _facing_change_count
	value["maximum_step_distance"] = _maximum_step_distance
	value["can_receive_command"] = can_receive_command()
	value["mounted"] = false
	value["floor_probe_distance"] = _floor_probe_distance()
	value["excavate"] = {
		"active": _excavate_active,
		"target": _excavate_target,
		"state": _excavate_state,
		"progress": _excavate_progress,
		"target_reached": excavate_target_reached(),
	}
	value["presentation"] = _presentation.report() if _presentation != null else {}
	return value


func _advance_step(delta: float) -> void:
	if _excavate_active:
		_advance_excavate_step(delta)
		return
	var movement: Dictionary = _follow.step(
		global_position,
		_player.global_position,
		_follow_target(),
		_world,
		_position_allowed,
		delta
	)
	var direction: Vector2 = movement.get("direction", Vector2.ZERO)
	var desired_velocity := direction * float(movement.get("speed", 0.0))
	var change_rate := MOVEMENT_ACCELERATION if desired_velocity != Vector2.ZERO else MOVEMENT_DECELERATION
	velocity = velocity.move_toward(desired_velocity, change_rate * delta)
	var before := global_position
	var proposed := before + velocity * delta
	if delta > 0.0 and _is_position_allowed(proposed):
		move_and_slide()
	elif delta > 0.0:
		velocity = Vector2.ZERO
	_maximum_step_distance = maxf(_maximum_step_distance, before.distance_to(global_position))
	_update_facing(delta)
	if _presentation != null:
		_presentation.advance(delta)
	_sync_presentation()


func _advance_excavate_step(delta: float) -> void:
	var direction := Vector2.ZERO
	if _excavate_state == "approaching" and not excavate_target_reached():
		direction = global_position.direction_to(_excavate_target)
	var desired_velocity := direction * EXCAVATE_APPROACH_SPEED
	var change_rate := MOVEMENT_ACCELERATION if desired_velocity != Vector2.ZERO else MOVEMENT_DECELERATION
	velocity = velocity.move_toward(desired_velocity, change_rate * delta)
	var before := global_position
	var proposed := before + velocity * delta
	if delta > 0.0 and _is_position_allowed(proposed) and _is_open_position(proposed):
		move_and_slide()
	elif delta > 0.0:
		velocity = Vector2.ZERO
	_maximum_step_distance = maxf(_maximum_step_distance, before.distance_to(global_position))
	_update_facing(delta)
	if _presentation != null:
		_presentation.advance(delta)
	_sync_presentation()


func _follow_target() -> Vector2:
	var player_position: Vector2 = _player.global_position
	if global_position.distance_to(player_position) > SiltHoundFollowController.FOLLOW_DISTANCE:
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


func _floor_probe_distance() -> float:
	if not is_inside_tree():
		return FLOOR_PROBE_DISTANCE
	var query := PhysicsRayQueryParameters2D.create(
		global_position,
		global_position + Vector2.DOWN * FLOOR_PROBE_DISTANCE,
		1,
		[get_rid()]
	)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	return global_position.distance_to(hit.get("position", global_position + Vector2.DOWN * FLOOR_PROBE_DISTANCE))


func _is_open_position(position: Vector2) -> bool:
	if _world == null or not _world.has_method("find_open_path"):
		return true
	return not _world.find_open_path(position, position).is_empty()


func _is_position_allowed(position: Vector2) -> bool:
	return not _position_allowed.is_valid() or bool(_position_allowed.call(position))


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
	if _pending_facing_seconds >= FACING_COMMIT_SECONDS:
		_facing_sign = candidate
		_facing_change_count += 1
		_pending_facing_seconds = 0.0


func _sync_presentation() -> void:
	if _presentation == null:
		return
	var local_path: Array = []
	for point in _follow.report().get("path_points", []):
		local_path.append((point as Vector2) - global_position)
	_presentation.sync(
		str(_follow.report().get("state", SiltHoundFollowController.STATE_FLOOR_ATTENTION)),
		_facing_sign,
		local_path,
		_floor_probe_distance(),
		velocity.length()
	)
	_presentation.set_excavate_state(_excavate_state, _excavate_progress)


func _dependencies_valid() -> bool:
	return _world != null and is_instance_valid(_world) and _player != null and is_instance_valid(_player)
