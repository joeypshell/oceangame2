extends RefCounted

const NAV_STEP_PX := 16
const COLLISION_MARGIN_PX := 2.0
const HAZARD_CLEARANCE_PX := 96.0
const HOSTILE_CLEARANCE_PX := 64.0
const INTERACTION_CLEARANCE_PX := 8.0

var _grid := AStarGrid2D.new()
var _grid_size := Vector2i.ZERO
var _map_pixel_size := Vector2.ZERO
var _blocked_point_count := 0


func build(world, player_body_size: Vector2, collection_radius: float, collectible_material_id := "") -> Dictionary:
	_map_pixel_size = world.map_pixel_size
	_grid_size = Vector2i(
		int(floor(_map_pixel_size.x / NAV_STEP_PX)) + 1,
		int(floor(_map_pixel_size.y / NAV_STEP_PX)) + 1
	)
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(Vector2i.ZERO, _grid_size)
	_grid.cell_size = Vector2(NAV_STEP_PX, NAV_STEP_PX)
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()
	_blocked_point_count = 0

	var body_half := player_body_size * 0.5 + Vector2.ONE * COLLISION_MARGIN_PX
	_block_outside_map(body_half)
	var parity: Dictionary = world.get_runtime_parity_report()
	for collision_rect in parity.get("collision_rects", []):
		var rect := Rect2(
			Vector2(float(collision_rect["x"]), float(collision_rect["y"])) * world.tile_size,
			Vector2(float(collision_rect["w"]), float(collision_rect["h"])) * world.tile_size
		)
		_block_expanded_rect(rect, body_half)

	for hazard in world.get_hazard_centers():
		_block_circle(hazard.get("center", Vector2.ZERO), HAZARD_CLEARANCE_PX)
	for hazard in world.get_moving_hazards():
		_block_patrol(hazard.get("path", []), HAZARD_CLEARANCE_PX)
	for hostile in world.get_hostile_encounters():
		var territory: Rect2 = hostile.get("territory_rect", Rect2())
		_block_expanded_rect(territory, Vector2.ONE * HOSTILE_CLEARANCE_PX)
	for gate in world.get_current_gates():
		var gate_rect: Rect2 = gate.get("rect", Rect2())
		_block_expanded_rect(gate_rect, body_half + Vector2.ONE * INTERACTION_CLEARANCE_PX)
	for candidate in world.get_material_candidates():
		if str(candidate.get("id", "")) == collectible_material_id:
			continue
		_block_circle(
			candidate.get("center", Vector2.ZERO),
			collection_radius + INTERACTION_CLEARANCE_PX * 2.0
		)

	return {
		"nav_step_px": NAV_STEP_PX,
		"grid_size": _grid_size,
		"blocked_points": _blocked_point_count,
		"body_size": player_body_size,
	}


func path_between(start_position: Vector2, target_position: Vector2) -> PackedVector2Array:
	var start_id := _nearest_open_id(_grid_id(start_position))
	var target_id := _nearest_open_id(_grid_id(target_position))
	if start_id.x < 0 or target_id.x < 0:
		return PackedVector2Array()
	var ids := _grid.get_id_path(start_id, target_id)
	var points := PackedVector2Array()
	for point_id in ids:
		points.append(Vector2(point_id) * NAV_STEP_PX)
	return points


func path_distance(path: PackedVector2Array) -> float:
	var distance := 0.0
	for index in range(1, path.size()):
		distance += path[index - 1].distance_to(path[index])
	return distance


func marker_center(world, marker_id: String) -> Vector2:
	var marker: Dictionary = world.get_marker_zone(marker_id)
	if marker.is_empty():
		return Vector2(-1.0, -1.0)
	return Vector2(
		(float(marker["x"]) + float(marker.get("w", 1)) * 0.5) * world.tile_size,
		(float(marker["y"]) + float(marker.get("h", 1)) * 0.5) * world.tile_size
	)


func _block_outside_map(body_half: Vector2) -> void:
	var first_clear := Vector2i(
		int(ceil(body_half.x / NAV_STEP_PX)),
		int(ceil(body_half.y / NAV_STEP_PX))
	)
	var last_clear := Vector2i(
		int(floor((_map_pixel_size.x - body_half.x) / NAV_STEP_PX)),
		int(floor((_map_pixel_size.y - body_half.y) / NAV_STEP_PX))
	)
	_block_index_rect(Vector2i.ZERO, Vector2i(first_clear.x - 1, _grid_size.y - 1))
	_block_index_rect(Vector2i(last_clear.x + 1, 0), _grid_size - Vector2i.ONE)
	_block_index_rect(Vector2i.ZERO, Vector2i(_grid_size.x - 1, first_clear.y - 1))
	_block_index_rect(Vector2i(0, last_clear.y + 1), _grid_size - Vector2i.ONE)


func _block_expanded_rect(rect: Rect2, expansion: Vector2) -> void:
	if rect.size == Vector2.ZERO:
		return
	var lower := rect.position - expansion
	var upper := rect.end + expansion
	var first := Vector2i(
		int(floor(lower.x / NAV_STEP_PX)) + 1,
		int(floor(lower.y / NAV_STEP_PX)) + 1
	)
	var last := Vector2i(
		int(ceil(upper.x / NAV_STEP_PX)) - 1,
		int(ceil(upper.y / NAV_STEP_PX)) - 1
	)
	_block_index_rect(first, last)


func _block_circle(center: Vector2, radius: float) -> void:
	var first := _grid_id(center - Vector2.ONE * radius) - Vector2i.ONE
	var last := _grid_id(center + Vector2.ONE * radius) + Vector2i.ONE
	var radius_squared := radius * radius
	for y in range(maxi(0, first.y), mini(_grid_size.y - 1, last.y) + 1):
		for x in range(maxi(0, first.x), mini(_grid_size.x - 1, last.x) + 1):
			var point_id := Vector2i(x, y)
			if (Vector2(point_id) * NAV_STEP_PX).distance_squared_to(center) <= radius_squared:
				_block_point(point_id)


func _block_patrol(path: Array, radius: float) -> void:
	if path.is_empty():
		return
	for index in range(path.size() - 1):
		var start: Vector2 = path[index]
		var end: Vector2 = path[index + 1]
		var sample_count := maxi(1, int(ceil(start.distance_to(end) / NAV_STEP_PX)))
		for sample in range(sample_count + 1):
			_block_circle(start.lerp(end, float(sample) / float(sample_count)), radius)
	if path.size() == 1:
		_block_circle(path[0], radius)


func _block_index_rect(first: Vector2i, last: Vector2i) -> void:
	var min_x := maxi(0, first.x)
	var min_y := maxi(0, first.y)
	var max_x := mini(_grid_size.x - 1, last.x)
	var max_y := mini(_grid_size.y - 1, last.y)
	if min_x > max_x or min_y > max_y:
		return
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			_block_point(Vector2i(x, y))


func _block_point(point_id: Vector2i) -> void:
	if not _grid.is_point_solid(point_id):
		_grid.set_point_solid(point_id)
		_blocked_point_count += 1


func _grid_id(position: Vector2) -> Vector2i:
	return Vector2i(
		int(round(position.x / NAV_STEP_PX)),
		int(round(position.y / NAV_STEP_PX))
	)


func _nearest_open_id(origin: Vector2i) -> Vector2i:
	if _in_bounds(origin) and not _grid.is_point_solid(origin):
		return origin
	for radius in range(1, 5):
		for y in range(origin.y - radius, origin.y + radius + 1):
			for x in range(origin.x - radius, origin.x + radius + 1):
				var candidate := Vector2i(x, y)
				if _in_bounds(candidate) and not _grid.is_point_solid(candidate):
					return candidate
	return Vector2i(-1, -1)


func _in_bounds(point_id: Vector2i) -> bool:
	return (
		point_id.x >= 0
		and point_id.y >= 0
		and point_id.x < _grid_size.x
		and point_id.y < _grid_size.y
	)
