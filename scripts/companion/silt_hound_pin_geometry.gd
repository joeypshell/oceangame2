extends RefCounted

# Planted center leaves the existing 24.3px fin silhouette above the floor.
const FLOOR_REACH := 24.5
const CONTACT_HALF_EXTENTS := Vector2(34, 16)


static func planted_point(world, cell: Dictionary) -> Vector2:
	return Vector2((float(cell["x"]) + 0.5) * world.tile_size, (float(cell["y"]) + 1.0) * world.tile_size - FLOOR_REACH)


static func anchor_valid(world, companion, point: Vector2, player) -> bool:
	if not body_clear(world, companion, point, player):
		return false
	for offset in [-12.0, 0.0, 12.0]:
		var start := point + Vector2(offset, 0)
		var query := PhysicsRayQueryParameters2D.create(start, start + Vector2.DOWN * 26.0, 1, [companion.get_rid(), player.get_rid()])
		var hit: Dictionary = world.get_world_2d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or absf(start.distance_to(hit["position"]) - FLOOR_REACH) > 1.0:
			return false
	return true


static func approach_clear(world, companion, point: Vector2, player) -> bool:
	if not companion.excavate_path_allowed(point) or not body_clear(world, companion, companion.global_position, player) or not body_clear(world, companion, point, player):
		return false
	var query := _body_query(companion, companion.global_position, player)
	query.motion = point - companion.global_position
	var fractions: PackedFloat32Array = world.get_world_2d().direct_space_state.cast_motion(query)
	return fractions[0] >= 1.0


static func body_clear(world, companion, point: Vector2, player) -> bool:
	return world.get_world_2d().direct_space_state.intersect_shape(_body_query(companion, point, player), 1).is_empty()


static func contact_clear(world, companion, target: Vector2, player) -> bool:
	# Conservative eel torso core (36x12) against Marl's 32x20 body.
	# Unlike the damage radius, this excludes distant tail/fin-only contacts.
	var offset: Vector2 = (target - companion.global_position).abs()
	return offset.x <= CONTACT_HALF_EXTENTS.x and offset.y <= CONTACT_HALF_EXTENTS.y and clear_line(world, companion, player, companion.global_position, target)


static func clear_line(world, companion, player, from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1, [companion.get_rid(), player.get_rid()])
	return world.has_clear_terrain_line(from, to) and world.get_world_2d().direct_space_state.intersect_ray(query).is_empty()


static func _body_query(companion, point: Vector2, player) -> PhysicsShapeQueryParameters2D:
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = companion.get_node("CollisionShape2D").shape
	query.transform = Transform2D(0.0, point)
	query.collision_mask = 1
	query.exclude = [companion.get_rid(), player.get_rid()]
	return query
