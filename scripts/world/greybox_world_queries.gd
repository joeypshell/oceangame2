extends RefCounted


func get_hazard_centers(hazard_entities: Array, tile_size: int) -> Array:
	var centers := []
	for entity in hazard_entities:
		centers.append({
			"id": str(entity.get("id", "hazard")),
			"center": entity_center(entity, tile_size),
		})
	return centers


func get_marker_zone(map_data: Dictionary, marker_id: String) -> Dictionary:
	for zone in map_data.get("zones", []):
		if zone.get("type", "") == "marker" and str(zone.get("id", "")) == marker_id:
			return zone
	return {}


func zone_at(zones: Array, position: Vector2, tile_size: int) -> Dictionary:
	for zone in zones:
		if rect_from_item(zone, tile_size).has_point(position):
			return zone
	return {}


func get_entry_position(spawn_positions_by_id: Dictionary, entry_id: String, fallback: Vector2) -> Vector2:
	var id := entry_id.strip_edges()
	if not id.is_empty() and spawn_positions_by_id.has(id):
		return spawn_positions_by_id[id]
	return fallback


func get_nearest_hazard_within(
	position: Vector2,
	radius_px: float,
	hazard_entities: Array,
	moving_hazards: Array,
	tile_size: int
) -> Dictionary:
	var nearest := {}
	var nearest_distance := radius_px
	for entity in hazard_entities:
		var center := entity_center(entity, tile_size)
		var distance := position.distance_to(center)
		if distance <= radius_px and (nearest.is_empty() or distance < nearest_distance):
			nearest = {
				"id": str(entity.get("id", "hazard")),
				"center": center,
				"distance": distance,
			}
			nearest_distance = distance
	for hazard in moving_hazards:
		var center := hazard["center"] as Vector2
		var distance := position.distance_to(center)
		if distance <= radius_px and (nearest.is_empty() or distance < nearest_distance):
			nearest = {
				"id": str(hazard.get("id", "moving_hazard")),
				"center": center,
				"distance": distance,
				"moving": true,
				"display_label": str(hazard.get("display_label", "")),
			}
			nearest_distance = distance
	return nearest


func get_hazard_near(
	position: Vector2,
	radius_px: float,
	hazard_entities: Array,
	moving_hazards: Array,
	tile_size: int
) -> String:
	for entity in hazard_entities:
		if position.distance_to(entity_center(entity, tile_size)) <= radius_px:
			return str(entity.get("id", "hazard"))
	for hazard in moving_hazards:
		if position.distance_to(hazard["center"]) <= radius_px:
			return str(hazard.get("id", "moving_hazard"))
	return ""


func find_open_path(
	start_position: Vector2,
	target_position: Vector2,
	map_tile_size: Vector2i,
	tile_size: int,
	solid_cells: Dictionary
) -> Array:
	var start := position_to_cell(start_position, tile_size, map_tile_size)
	var target := position_to_cell(target_position, tile_size, map_tile_size)
	if solid_cells.has(start) or solid_cells.has(target):
		return []

	var queue: Array[Vector2i] = [start]
	var cursor := 0
	var came_from := {start: start}
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		if cell == target:
			break

		for neighbor in [
			cell + Vector2i.RIGHT,
			cell + Vector2i.LEFT,
			cell + Vector2i.DOWN,
			cell + Vector2i.UP,
		]:
			if neighbor.x < 0 or neighbor.y < 0 or neighbor.x >= map_tile_size.x or neighbor.y >= map_tile_size.y:
				continue
			if solid_cells.has(neighbor) or came_from.has(neighbor):
				continue
			came_from[neighbor] = cell
			queue.append(neighbor)

	if not came_from.has(target):
		return []

	var cells: Array[Vector2i] = []
	var current := target
	while current != start:
		cells.append(current)
		current = came_from[current]
	cells.append(start)
	cells.reverse()

	var path := []
	for cell in cells:
		path.append(cell_center(cell, tile_size))
	return path


func has_clear_terrain_line(
	start_position: Vector2,
	end_position: Vector2,
	map_tile_size: Vector2i,
	tile_size: int,
	solid_cells: Dictionary
) -> bool:
	if tile_size <= 0 or map_tile_size.x <= 0 or map_tile_size.y <= 0:
		return false
	var map_pixel_size := Vector2(map_tile_size) * float(tile_size)
	if not Rect2(Vector2.ZERO, map_pixel_size).has_point(start_position):
		return false
	if not Rect2(Vector2.ZERO, map_pixel_size).has_point(end_position):
		return false

	var start_grid := start_position / float(tile_size)
	var end_grid := end_position / float(tile_size)
	var ray := end_grid - start_grid
	var cell := Vector2i(floori(start_grid.x), floori(start_grid.y))
	var end_cell := Vector2i(floori(end_grid.x), floori(end_grid.y))
	if solid_cells.has(cell) or solid_cells.has(end_cell):
		return false
	if cell == end_cell:
		return true

	var step_x := signi(int(signf(ray.x)))
	var step_y := signi(int(signf(ray.y)))
	var delta_x := absf(1.0 / ray.x) if not is_zero_approx(ray.x) else INF
	var delta_y := absf(1.0 / ray.y) if not is_zero_approx(ray.y) else INF
	var next_x := float(cell.x + 1) if step_x > 0 else float(cell.x)
	var next_y := float(cell.y + 1) if step_y > 0 else float(cell.y)
	var max_x := (next_x - start_grid.x) / ray.x if step_x != 0 else INF
	var max_y := (next_y - start_grid.y) / ray.y if step_y != 0 else INF

	# Traverse every touched cell; exact corner crossings inspect both neighbors.
	while cell != end_cell:
		if absf(max_x - max_y) <= 0.000001:
			var horizontal := cell + Vector2i(step_x, 0)
			var vertical := cell + Vector2i(0, step_y)
			if not _open_line_cell(horizontal, map_tile_size, solid_cells):
				return false
			if not _open_line_cell(vertical, map_tile_size, solid_cells):
				return false
			cell += Vector2i(step_x, step_y)
			max_x += delta_x
			max_y += delta_y
		elif max_x < max_y:
			cell.x += step_x
			max_x += delta_x
		else:
			cell.y += step_y
			max_y += delta_y
		if not _open_line_cell(cell, map_tile_size, solid_cells):
			return false
	return true


func _open_line_cell(cell: Vector2i, map_tile_size: Vector2i, solid_cells: Dictionary) -> bool:
	return (
		cell.x >= 0
		and cell.y >= 0
		and cell.x < map_tile_size.x
		and cell.y < map_tile_size.y
		and not solid_cells.has(cell)
	)


func get_extraction_center(
	extraction_zones: Array,
	boat_entities: Array,
	spawn_position: Vector2,
	tile_size: int
) -> Vector2:
	if extraction_zones.is_empty():
		if not boat_entities.is_empty():
			return boat_entry_center(boat_entities[0], tile_size)
		return spawn_position
	return rect_center(extraction_zones[0], tile_size)


func is_inside_extraction(
	position: Vector2,
	extraction_zones: Array,
	boat_entities: Array,
	tile_size: int
) -> bool:
	for zone in extraction_zones:
		if rect_from_item(zone, tile_size).has_point(position):
			return true
	for boat in boat_entities:
		if entity_rect_from_item(boat, tile_size).has_point(position):
			return true
	return false


func is_inside_boat(position: Vector2, boat_entities: Array, tile_size: int) -> bool:
	for boat in boat_entities:
		if entity_rect_from_item(boat, tile_size).has_point(position):
			return true
	return false


func is_at_open_surface(
	position: Vector2,
	map_tile_size: Vector2i,
	solid_cells: Dictionary,
	boat_entities: Array,
	tile_size: int
) -> bool:
	if boat_entities.is_empty() or map_tile_size.x <= 0 or map_tile_size.y <= 0:
		return false
	var cell := position_to_cell(position, tile_size, map_tile_size)
	return cell.y == 0 and not solid_cells.has(cell)


func get_open_surface_centers(
	map_tile_size: Vector2i,
	solid_cells: Dictionary,
	boat_entities: Array,
	tile_size: int
) -> Array:
	var centers := []
	if boat_entities.is_empty() or map_tile_size.x <= 0 or map_tile_size.y <= 0:
		return centers
	for x in range(map_tile_size.x):
		var cell := Vector2i(x, 0)
		if not solid_cells.has(cell):
			centers.append(cell_center(cell, tile_size))
	return centers


func rect_center(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2(
		(float(item["x"]) + float(item["w"]) * 0.5) * tile_size,
		(float(item["y"]) + float(item["h"]) * 0.5) * tile_size
	)


func point_center(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2((float(item["x"]) + 0.5) * tile_size, (float(item["y"]) + 0.5) * tile_size)


func moving_hazard_initial_center(hazard: Dictionary, tile_size: int) -> Vector2:
	return point_center({"x": int(hazard.get("x", 0)), "y": int(hazard.get("y", 0))}, tile_size)


func rect_size(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)


func rect_from_item(item: Dictionary, tile_size: int) -> Rect2:
	return Rect2(
		Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size),
		rect_size(item, tile_size)
	)


func entity_rect_from_item(item: Dictionary, tile_size: int) -> Rect2:
	return Rect2(
		Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size),
		Vector2(
			float(item.get("w", 1)) * tile_size,
			float(item.get("h", 1)) * tile_size
		)
	)


func entity_center(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2((float(item["x"]) + 0.5) * tile_size, (float(item["y"]) + 0.5) * tile_size)


func position_to_cell(position: Vector2, tile_size: int, map_tile_size: Vector2i) -> Vector2i:
	return Vector2i(
		clampi(int(floor(position.x / tile_size)), 0, map_tile_size.x - 1),
		clampi(int(floor(position.y / tile_size)), 0, map_tile_size.y - 1)
	)


func cell_center(cell: Vector2i, tile_size: int) -> Vector2:
	return Vector2((float(cell.x) + 0.5) * tile_size, (float(cell.y) + 0.5) * tile_size)


func boat_entry_center(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2(
		(float(item.get("entry_x", item["x"])) + 0.5) * tile_size,
		(float(item.get("entry_y", item["y"])) + 0.5) * tile_size
	)
