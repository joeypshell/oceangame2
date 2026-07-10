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
