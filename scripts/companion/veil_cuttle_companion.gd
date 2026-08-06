extends CharacterBody2D

const VeilCuttleFollowController := preload("res://scripts/companion/veil_cuttle_follow_controller.gd")

const MAX_SIMULATION_STEP := 1.0 / 30.0
const MOVEMENT_ACCELERATION := 620.0
const MOVEMENT_DECELERATION := 780.0
const FOLLOW_OFFSET := Vector2(38.0, 18.0)
const SPAWN_OFFSETS := [
	Vector2(-42.0, 18.0),
	Vector2(42.0, 18.0),
	Vector2(-42.0, -18.0),
	Vector2(42.0, -18.0),
]
const FACING_SPEED_THRESHOLD := 12.0
const FACING_COMMIT_SECONDS := 0.14

@onready var _presentation := $Presentation
@onready var _drift_projection := $DriftProjection

var _world
var _player
var _position_allowed := Callable()
var _identity := {}
var _follow := VeilCuttleFollowController.new()
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
	if _presentation != null:
		_presentation.set_identity(str(_identity.get("callsign", "Mica")))
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
	_follow.request_recall()
	_sync_presentation()


func force_readable_separation(direction: Vector2) -> void:
	_follow.force_readable_separation()
	velocity = Vector2.ZERO
	show_reveal_trace(direction, 96.0, 72.0, "denied")
	_sync_presentation()


func recover_to_player() -> void:
	if not _dependencies_valid():
		return
	_follow.reset()
	velocity = Vector2.ZERO
	global_position = _spawn_position()
	_sync_presentation()


func can_receive_command(maximum_distance := 96.0) -> bool:
	if not _dependencies_valid():
		return false
	var state := str(_follow.report().get("state", ""))
	return state not in [VeilCuttleFollowController.STATE_SEPARATED, VeilCuttleFollowController.STATE_RECOVERY] and global_position.distance_to(_player.global_position) <= maximum_distance


func show_reveal_trace(direction: Vector2, range_px: float, target_distance: float, cue_state: String) -> void:
	if _presentation != null:
		_presentation.show_reveal_trace(direction, range_px, target_distance, cue_state)


func show_migration_trace(
	path_points: Array,
	current_center: Vector2,
	movement_direction: Vector2,
	cue_state: String
) -> void:
	if _presentation == null:
		return
	var local_path := []
	for point in path_points:
		local_path.append((point as Vector2) - global_position)
	_presentation.show_migration_trace(
		local_path,
		current_center - global_position,
		movement_direction,
		cue_state
	)


func clear_reveal_preview() -> void:
	if _presentation != null:
		_presentation.clear_reveal_preview()


func set_ecology_interest(active: bool) -> void:
	if _presentation != null:
		_presentation.set_ecology_interest(active)


func show_drift_projection(
	path_points: Array,
	current_center: Vector2,
	movement_direction: Vector2,
	approaching: bool
) -> void:
	if _drift_projection != null:
		_drift_projection.show_projection(path_points, current_center, movement_direction, approaching)


func clear_drift_projection() -> void:
	if _drift_projection != null:
		_drift_projection.clear_projection()


func report() -> Dictionary:
	var value := _follow.report()
	value["identity"] = _identity.duplicate(true)
	value["species_id"] = "veil_cuttle"
	value["position"] = global_position
	value["velocity"] = velocity
	value["facing_sign"] = _facing_sign
	value["facing_change_count"] = _facing_change_count
	value["maximum_step_distance"] = _maximum_step_distance
	value["can_receive_command"] = can_receive_command()
	value["mounted"] = false
	value["presentation"] = _presentation.report() if _presentation != null else {}
	value["drift_projection"] = _drift_projection.report() if _drift_projection != null else {}
	return value


func _advance_step(delta: float) -> void:
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


func _follow_target() -> Vector2:
	var player_position: Vector2 = _player.global_position
	if global_position.distance_to(player_position) > VeilCuttleFollowController.HOVER_DISTANCE:
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
	_presentation.sync(str(_follow.report().get("state", "hover")), _facing_sign, local_path)


func _dependencies_valid() -> bool:
	return _world != null and is_instance_valid(_world) and _player != null and is_instance_valid(_player)
