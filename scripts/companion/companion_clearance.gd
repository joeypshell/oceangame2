extends RefCounted

const BODY_SIZE := Vector2(26.0, 18.0)
const MOUNT_DISTANCE := 96.0
const HORIZONTAL_DISMOUNT_DISTANCE := 64.0
const VERTICAL_DISMOUNT_DISTANCE := 58.0


func mount_report(world, player, companion, position_allowed: Callable) -> Dictionary:
	if not _nodes_valid(world, player, companion):
		return _denied("companion_unavailable")
	if player.global_position.distance_to(companion.global_position) > MOUNT_DISTANCE:
		return _denied("move_closer")
	if companion.has_method("can_handoff_control") and not companion.can_handoff_control(MOUNT_DISTANCE):
		return _denied("companion_separated")
	if not _position_allowed(companion.global_position, position_allowed):
		return _denied("equipment_gate")
	if not _body_clear(world, companion.global_position, player, companion):
		return _denied("rider_clearance")
	return {"allowed": true, "reason": "ready", "position": companion.global_position}


func dismount_report(world, player, companion, position_allowed: Callable) -> Dictionary:
	if not _nodes_valid(world, player, companion):
		return _denied("companion_unavailable")
	for offset in _dismount_offsets(companion):
		var candidate: Vector2 = companion.global_position + (offset as Vector2)
		if not _position_allowed(candidate, position_allowed):
			continue
		if world.has_method("has_clear_terrain_line") and not world.has_clear_terrain_line(companion.global_position, candidate):
			continue
		if _body_clear(world, candidate, player, companion):
			return {"allowed": true, "reason": "ready", "position": candidate}
	return _denied("diver_clearance")


func emergency_dismount_position(world, player, companion, position_allowed: Callable) -> Vector2:
	var report := dismount_report(world, player, companion, position_allowed)
	if bool(report.get("allowed", false)):
		return report.get("position", companion.global_position)
	return companion.global_position if companion != null and is_instance_valid(companion) else player.global_position


func _dismount_offsets(companion) -> Array:
	var facing_sign := 1.0
	if companion.has_method("report"):
		facing_sign = 1.0 if float(companion.report().get("facing_sign", 1.0)) >= 0.0 else -1.0
	return [
		Vector2(HORIZONTAL_DISMOUNT_DISTANCE * facing_sign, 0.0),
		Vector2(0.0, VERTICAL_DISMOUNT_DISTANCE),
		Vector2(0.0, -VERTICAL_DISMOUNT_DISTANCE),
		Vector2(-HORIZONTAL_DISMOUNT_DISTANCE * facing_sign, 0.0),
	]


func _body_clear(world, position: Vector2, player, companion) -> bool:
	if world.has_method("find_open_path") and world.find_open_path(position, position).is_empty():
		return false
	var world_2d: World2D = world.get_world_2d()
	if world_2d == null:
		return true
	var shape := RectangleShape2D.new()
	shape.size = BODY_SIZE
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, position)
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [player.get_rid(), companion.get_rid()]
	return world_2d.direct_space_state.intersect_shape(query, 1).is_empty()


func _position_allowed(position: Vector2, position_allowed: Callable) -> bool:
	return not position_allowed.is_valid() or bool(position_allowed.call(position))


func _nodes_valid(world, player, companion) -> bool:
	return (
		world != null
		and is_instance_valid(world)
		and player != null
		and is_instance_valid(player)
		and companion != null
		and is_instance_valid(companion)
	)


func _denied(reason: String) -> Dictionary:
	return {"allowed": false, "reason": reason}
