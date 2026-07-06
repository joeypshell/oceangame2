extends Node2D

const COLOR_WATER := Color(0.08, 0.72, 0.92, 1.0)
const COLOR_GRID := Color(0.85, 0.98, 1.0, 0.22)
const COLOR_SOLID := Color(0.15, 0.20, 0.25, 1.0)
const COLOR_BASE := Color(0.95, 0.78, 0.48, 0.92)
const COLOR_BOAT := Color(0.96, 0.66, 0.20, 0.92)
const COLOR_BOAT_DARK := Color(0.22, 0.16, 0.10, 1.0)
const COLOR_BOAT_LIGHT := Color(1.0, 0.86, 0.40, 1.0)
const COLOR_BOAT_GLASS := Color(0.36, 0.91, 0.96, 0.88)
const COLOR_RELAY_BODY := Color(0.18, 0.31, 0.36, 1.0)
const COLOR_RELAY_DARK := Color(0.08, 0.17, 0.21, 1.0)
const COLOR_RELAY_LIGHT := Color(0.96, 0.86, 0.48, 1.0)
const COLOR_RELAY_GLASS := Color(0.28, 0.92, 0.98, 0.92)
const COLOR_BACKGROUND := Color(0.08, 0.39, 0.58, 0.18)
const COLOR_MARKER := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_SALVAGE := Color(1.0, 0.80, 0.22, 1.0)
const COLOR_SALVAGE_DARK := Color(0.48, 0.30, 0.11, 1.0)
const COLOR_SALVAGE_METAL := Color(0.72, 0.83, 0.78, 1.0)
const COLOR_HAZARD := Color(1.0, 0.22, 0.34, 1.0)
const COLOR_HAZARD_DARK := Color(0.40, 0.04, 0.10, 1.0)
const COLOR_HAZARD_LIGHT := Color(1.0, 0.58, 0.66, 1.0)
const COLOR_DEBUG_ROUTE := Color(0.90, 0.98, 1.0, 0.26)
const COLOR_DEBUG_ROUTE_EDGE := Color(0.90, 0.98, 1.0, 0.88)
const COLOR_DEBUG_ENTRY := Color(0.72, 1.0, 0.72, 0.88)
const COLOR_DEBUG_EXTRACTION := Color(1.0, 0.92, 0.52, 0.90)
const SOURCE_LAYER_ALPHA := 0.08
const BACKGROUND_ART_ALPHA := 0.26

const CAVE_TILESET_TEXTURE := "res://assets/terrain_tiles/cave_tileset_v1.png"
const BACKGROUND_ROCKS_TEXTURE := "res://assets/terrain/background_rocks_01.png"
const CAVE_TILESET_TEXTURE_RESOURCE := preload("res://assets/terrain_tiles/cave_tileset_v1.png")
const BACKGROUND_ROCKS_TEXTURE_RESOURCE := preload("res://assets/terrain/background_rocks_01.png")
const CAVE_TILESET_COLUMNS := 8
const CAVE_TILESET_ROWS := 5
const TERRAIN_SOURCE_ID := 0
const MASK_TOP := 1
const MASK_RIGHT := 2
const MASK_BOTTOM := 4
const MASK_LEFT := 8
const FILL_COORDS := [Vector2i(0, 0), Vector2i(0, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2)]
const TOP_COORDS := [Vector2i(1, 0), Vector2i(0, 3), Vector2i(1, 3)]
const RIGHT_COORDS := [Vector2i(2, 0), Vector2i(6, 3), Vector2i(7, 3)]
const BOTTOM_COORDS := [Vector2i(4, 0), Vector2i(2, 3), Vector2i(3, 3)]
const LEFT_COORDS := [Vector2i(0, 1), Vector2i(4, 3), Vector2i(5, 3)]
const TOP_RIGHT_OUTER_COORDS := [Vector2i(3, 0), Vector2i(0, 4)]
const LEFT_TOP_OUTER_COORDS := [Vector2i(1, 1), Vector2i(1, 4)]
const RIGHT_BOTTOM_OUTER_COORDS := [Vector2i(6, 0), Vector2i(2, 4)]
const BOTTOM_LEFT_OUTER_COORDS := [Vector2i(4, 1), Vector2i(3, 4)]
const ISOLATED_COORDS := [Vector2i(7, 1), Vector2i(4, 4), Vector2i(5, 4)]
const INNER_TOP_LEFT_COORD := Vector2i(1, 2)
const INNER_TOP_RIGHT_COORD := Vector2i(2, 2)
const INNER_BOTTOM_LEFT_COORD := Vector2i(3, 2)
const INNER_BOTTOM_RIGHT_COORD := Vector2i(4, 2)
const NO_SPECIAL_COORD := Vector2i(-1, -1)

@export var map_path := "res://maps/cave_salvage_test_01.greybox.json"
@export var show_debug_overlay := false

var tile_size := 32
var map_tile_size := Vector2i.ZERO
var map_pixel_size := Vector2.ZERO
var map_id := ""
var map_version := ""
var spawn_position := Vector2.ZERO
var camera_tests: Array = []

var _built := false
var _map_data := {}
var _salvage_entities: Array = []
var _hazard_entities: Array = []
var _extraction_zones: Array = []
var _boat_entities: Array = []
var _collected_salvage := {}
var _salvage_nodes_by_id := {}
var _background_root: Node2D
var _solid_layer: TileMapLayer
var _terrain_layer: TileMapLayer
var _marker_root: Node2D
var _collision_root: Node2D


func _ready() -> void:
	load_greybox()


func load_greybox() -> void:
	if _built:
		return
	_built = true

	var map_data := _load_map_data()
	if map_data.is_empty():
		return

	_map_data = map_data
	map_id = str(map_data.get("id", "unknown_map"))
	map_version = _display_version(map_data.get("version", ""))
	tile_size = int(map_data["units"]["tile_size_px"])
	map_tile_size = Vector2i(int(map_data["units"]["width_tiles"]), int(map_data["units"]["height_tiles"]))
	map_pixel_size = Vector2(map_tile_size * tile_size)
	camera_tests = map_data.get("camera_tests", [])
	_salvage_entities = []
	_hazard_entities = []
	_extraction_zones = []
	_boat_entities = []
	_collected_salvage = {}
	_salvage_nodes_by_id = {}

	_background_root = Node2D.new()
	_background_root.name = "BackgroundArt"
	add_child(_background_root)
	_build_background(map_data.get("background", []))

	_build_tilemap(map_data)
	_build_cave_terrain_layer(map_data.get("terrain", []))

	_collision_root = Node2D.new()
	_collision_root.name = "Collision"
	add_child(_collision_root)
	_build_collision(map_data.get("terrain", []))

	_marker_root = Node2D.new()
	_marker_root.name = "Markers"
	add_child(_marker_root)
	_build_zones(map_data.get("zones", []))
	_build_entities(map_data.get("entities", []))
	queue_redraw()


func get_map_label() -> String:
	if map_version.is_empty():
		return map_id
	return "%s v%s" % [map_id, map_version]


func _display_version(value) -> String:
	if typeof(value) == TYPE_FLOAT and is_equal_approx(value, float(int(value))):
		return str(int(value))
	return str(value)


func get_total_salvage_count() -> int:
	return _salvage_entities.size()


func get_salvage_centers() -> Array:
	var centers := []
	for entity in _salvage_entities:
		centers.append({
			"id": str(entity.get("id", "salvage")),
			"center": _entity_center(entity),
		})
	return centers


func get_hazard_centers() -> Array:
	var centers := []
	for entity in _hazard_entities:
		centers.append({
			"id": str(entity.get("id", "hazard")),
			"center": _entity_center(entity),
		})
	return centers


func get_hazard_near(position: Vector2, radius_px: float) -> String:
	for entity in _hazard_entities:
		if position.distance_to(_entity_center(entity)) <= radius_px:
			return str(entity.get("id", "hazard"))
	return ""


func find_open_path(start_position: Vector2, target_position: Vector2) -> Array:
	var start := _position_to_cell(start_position)
	var target := _position_to_cell(target_position)
	var solid_cells := _solid_cells_from_terrain(_map_data.get("terrain", []))
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
		path.append(_cell_center(cell))
	return path


func get_extraction_center() -> Vector2:
	if _extraction_zones.is_empty():
		if not _boat_entities.is_empty():
			return _boat_entry_center(_boat_entities[0])
		return spawn_position
	return _rect_center(_extraction_zones[0])


func collect_salvage_near(position: Vector2, radius_px: float) -> String:
	for entity in _salvage_entities:
		var salvage_id := str(entity.get("id", "salvage"))
		if _collected_salvage.get(salvage_id, false):
			continue
		if position.distance_to(_entity_center(entity)) > radius_px:
			continue

		_collected_salvage[salvage_id] = true
		if _salvage_nodes_by_id.has(salvage_id):
			var salvage_node := _salvage_nodes_by_id[salvage_id] as Node2D
			salvage_node.visible = false
		return salvage_id
	return ""


func reset_salvage() -> void:
	_collected_salvage = {}
	for salvage_id in _salvage_nodes_by_id.keys():
		var salvage_node := _salvage_nodes_by_id[salvage_id] as Node2D
		salvage_node.visible = true


func restore_salvage(salvage_ids: Array) -> void:
	for salvage_id in salvage_ids:
		var id := str(salvage_id)
		_collected_salvage.erase(id)
		if _salvage_nodes_by_id.has(id):
			var salvage_node := _salvage_nodes_by_id[id] as Node2D
			salvage_node.visible = true


func is_inside_extraction(position: Vector2) -> bool:
	for zone in _extraction_zones:
		if _rect_from_item(zone).has_point(position):
			return true
	for boat in _boat_entities:
		if _entity_rect_from_item(boat).has_point(position):
			return true
	return false


func get_runtime_parity_report() -> Dictionary:
	return {
		"map_path": map_path,
		"map_id": map_id,
		"map_version": map_version,
		"tile_size_px": tile_size,
		"width_tiles": map_tile_size.x,
		"height_tiles": map_tile_size.y,
		"terrain_cells": _sorted_cell_arrays(_terrain_layer.get_used_cells()),
		"collision_rects": _collision_rects_from_runtime(),
		"collision_cells": _sorted_cell_arrays(_collision_cells_from_runtime()),
	}


func _draw() -> void:
	if map_pixel_size == Vector2.ZERO:
		return

	draw_rect(Rect2(Vector2.ZERO, map_pixel_size), COLOR_WATER)
	if not show_debug_overlay:
		return

	for x in range(0, int(map_pixel_size.x) + 1, tile_size):
		draw_line(Vector2(x, 0), Vector2(x, map_pixel_size.y), COLOR_GRID)
	for y in range(0, int(map_pixel_size.y) + 1, tile_size):
		draw_line(Vector2(0, y), Vector2(map_pixel_size.x, y), COLOR_GRID)


func _load_map_data() -> Dictionary:
	var file := FileAccess.open(map_path, FileAccess.READ)
	if file == null:
		push_error("Unable to open greybox map: %s" % map_path)
		return {}

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Greybox map did not parse as a dictionary: %s" % map_path)
		return {}

	return parsed


func _build_tilemap(map_data: Dictionary) -> void:
	_solid_layer = TileMapLayer.new()
	_solid_layer.name = "SourceTileMapLayer"
	_solid_layer.tile_set = _create_greybox_tileset()
	_solid_layer.modulate = Color(1.0, 1.0, 1.0, SOURCE_LAYER_ALPHA)
	_solid_layer.visible = show_debug_overlay
	add_child(_solid_layer)

	for terrain in map_data.get("terrain", []):
		if terrain.get("type", "") == "solid":
			_fill_tile_rect(_solid_layer, terrain, Vector2i(0, 0))

	for zone in map_data.get("zones", []):
		if zone.get("type", "") == "base":
			_fill_tile_rect(_solid_layer, zone, Vector2i(1, 0))


func _build_cave_terrain_layer(terrain_items: Array) -> void:
	_terrain_layer = TileMapLayer.new()
	_terrain_layer.name = "CaveTerrainTileMapLayer"
	_terrain_layer.tile_set = _create_cave_tileset()
	add_child(_terrain_layer)

	var solid_cells := _solid_cells_from_terrain(terrain_items)
	for cell in solid_cells.keys():
		_terrain_layer.set_cell(cell, TERRAIN_SOURCE_ID, _terrain_atlas_coords(cell, solid_cells))


func _create_cave_tileset() -> TileSet:
	var texture := _load_png_texture(CAVE_TILESET_TEXTURE)
	if texture == null:
		push_error("Unable to create cave TileSet; missing texture %s" % CAVE_TILESET_TEXTURE)
		return TileSet.new()

	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	for y in range(CAVE_TILESET_ROWS):
		for x in range(CAVE_TILESET_COLUMNS):
			source.create_tile(Vector2i(x, y))

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)
	tile_set.add_source(source, TERRAIN_SOURCE_ID)
	return tile_set


func _solid_cells_from_terrain(terrain_items: Array) -> Dictionary:
	var solid_cells := {}
	for item in terrain_items:
		if item.get("type", "") != "solid":
			continue
		for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
			for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
				solid_cells[Vector2i(x, y)] = true
	return solid_cells


func _terrain_atlas_coords(cell: Vector2i, solid_cells: Dictionary) -> Vector2i:
	var mask := 0
	if not _is_solid_cell(cell + Vector2i.UP, solid_cells):
		mask |= MASK_TOP
	if not _is_solid_cell(cell + Vector2i.RIGHT, solid_cells):
		mask |= MASK_RIGHT
	if not _is_solid_cell(cell + Vector2i.DOWN, solid_cells):
		mask |= MASK_BOTTOM
	if not _is_solid_cell(cell + Vector2i.LEFT, solid_cells):
		mask |= MASK_LEFT

	if mask == 0:
		var inner_coord := _inner_corner_atlas_coords(cell, solid_cells)
		if inner_coord != NO_SPECIAL_COORD:
			return inner_coord
		return _variant_coord(cell, FILL_COORDS)

	if mask == MASK_TOP:
		return _variant_coord(cell, TOP_COORDS)
	if mask == MASK_RIGHT:
		return _variant_coord(cell, RIGHT_COORDS)
	if mask == MASK_BOTTOM:
		return _variant_coord(cell, BOTTOM_COORDS)
	if mask == MASK_LEFT:
		return _variant_coord(cell, LEFT_COORDS)
	if mask == (MASK_TOP | MASK_RIGHT):
		return _variant_coord(cell, TOP_RIGHT_OUTER_COORDS)
	if mask == (MASK_LEFT | MASK_TOP):
		return _variant_coord(cell, LEFT_TOP_OUTER_COORDS)
	if mask == (MASK_RIGHT | MASK_BOTTOM):
		return _variant_coord(cell, RIGHT_BOTTOM_OUTER_COORDS)
	if mask == (MASK_BOTTOM | MASK_LEFT):
		return _variant_coord(cell, BOTTOM_LEFT_OUTER_COORDS)
	if mask == (MASK_TOP | MASK_RIGHT | MASK_BOTTOM | MASK_LEFT):
		return _variant_coord(cell, ISOLATED_COORDS)
	return Vector2i(mask % CAVE_TILESET_COLUMNS, mask / CAVE_TILESET_COLUMNS)


func _variant_coord(cell: Vector2i, coords: Array) -> Vector2i:
	var index: int = abs((cell.x * 31 + cell.y * 17) % coords.size())
	return coords[index]


func _inner_corner_atlas_coords(cell: Vector2i, solid_cells: Dictionary) -> Vector2i:
	if not _is_solid_cell(cell + Vector2i.UP + Vector2i.LEFT, solid_cells):
		return INNER_TOP_LEFT_COORD
	if not _is_solid_cell(cell + Vector2i.UP + Vector2i.RIGHT, solid_cells):
		return INNER_TOP_RIGHT_COORD
	if not _is_solid_cell(cell + Vector2i.DOWN + Vector2i.LEFT, solid_cells):
		return INNER_BOTTOM_LEFT_COORD
	if not _is_solid_cell(cell + Vector2i.DOWN + Vector2i.RIGHT, solid_cells):
		return INNER_BOTTOM_RIGHT_COORD
	return NO_SPECIAL_COORD


func _is_solid_cell(cell: Vector2i, solid_cells: Dictionary) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= map_tile_size.x or cell.y >= map_tile_size.y:
		return true
	return solid_cells.has(cell)


func _create_greybox_tileset() -> TileSet:
	var image := Image.create(tile_size * 2, tile_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.fill_rect(Rect2i(0, 0, tile_size, tile_size), COLOR_SOLID)
	image.fill_rect(Rect2i(tile_size, 0, tile_size, tile_size), COLOR_BASE)

	var texture := ImageTexture.create_from_image(image)
	var source := TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(tile_size, tile_size)
	source.create_tile(Vector2i(0, 0))
	source.create_tile(Vector2i(1, 0))

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(tile_size, tile_size)
	tile_set.add_source(source, 0)
	return tile_set


func _fill_tile_rect(layer: TileMapLayer, item: Dictionary, atlas_coords: Vector2i) -> void:
	for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
		for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
			layer.set_cell(Vector2i(x, y), 0, atlas_coords)


func _build_collision(terrain_items: Array) -> void:
	for item in terrain_items:
		if item.get("type", "") != "solid":
			continue

		var body := StaticBody2D.new()
		body.name = "%sCollision" % item.get("id", "Terrain")
		body.position = _rect_center(item)

		var shape := RectangleShape2D.new()
		shape.size = _rect_size(item)

		var collision := CollisionShape2D.new()
		collision.shape = shape
		body.add_child(collision)
		_collision_root.add_child(body)


func _collision_rects_from_runtime() -> Array:
	var rects := []
	if _collision_root == null:
		return rects

	for body_node in _collision_root.get_children():
		if not body_node is StaticBody2D:
			continue
		var body := body_node as StaticBody2D
		for shape_node in body.get_children():
			if not shape_node is CollisionShape2D:
				continue
			var collision := shape_node as CollisionShape2D
			if not collision.shape is RectangleShape2D:
				continue
			var rectangle := collision.shape as RectangleShape2D
			var size := rectangle.size
			var center := body.position + collision.position
			rects.append({
				"id": body.name,
				"x": int(round((center.x - size.x * 0.5) / tile_size)),
				"y": int(round((center.y - size.y * 0.5) / tile_size)),
				"w": int(round(size.x / tile_size)),
				"h": int(round(size.y / tile_size)),
			})

	rects.sort_custom(func(a, b): return int(a["x"]) < int(b["x"]) if int(a["y"]) == int(b["y"]) else int(a["y"]) < int(b["y"]))
	return rects


func _collision_cells_from_runtime() -> Array:
	var cells := []
	for rect in _collision_rects_from_runtime():
		for y in range(int(rect["y"]), int(rect["y"]) + int(rect["h"])):
			for x in range(int(rect["x"]), int(rect["x"]) + int(rect["w"])):
				cells.append(Vector2i(x, y))
	return cells


func _sorted_cell_arrays(cells: Array) -> Array:
	var sorted_cells := cells.duplicate()
	sorted_cells.sort_custom(func(a, b): return a.x < b.x if a.y == b.y else a.y < b.y)

	var output := []
	for cell in sorted_cells:
		output.append([cell.x, cell.y])
	return output


func _build_background(items: Array) -> void:
	for item in items:
		var poly := _rect_polygon(item, COLOR_BACKGROUND)
		poly.name = item.get("id", "Background")
		_background_root.add_child(poly)

		var sprite_name := "%sArt" % item.get("id", "Background")
		var sprite := _add_texture_rect(_background_root, BACKGROUND_ROCKS_TEXTURE, item, sprite_name)
		if sprite != null:
			sprite.modulate = Color(1.0, 1.0, 1.0, BACKGROUND_ART_ALPHA)


func _build_zones(zones: Array) -> void:
	for zone in zones:
		if zone.get("type", "") == "base":
			_extraction_zones.append(zone)
			var base := _add_relay_extraction_prop(str(zone.get("id", "Base")), zone)
			if show_debug_overlay:
				_add_rect_outline(zone, "%sDebugOutline" % base.name, COLOR_DEBUG_EXTRACTION, 3.0, 22)
				_add_debug_label("EXTRACTION", _rect_from_item(zone).position + Vector2(6, 6), COLOR_DEBUG_EXTRACTION)
		elif zone.get("type", "") == "marker":
			var marker := _rect_polygon(zone, COLOR_MARKER)
			marker.name = zone.get("id", "Marker")
			marker.z_index = 4
			_marker_root.add_child(marker)
			if show_debug_overlay:
				marker.color = COLOR_DEBUG_ROUTE
				_add_rect_outline(zone, "%sDebugOutline" % marker.name, COLOR_DEBUG_ROUTE_EDGE, 2.0, 21)
				_add_debug_label("ROUTE", _rect_from_item(zone).position + Vector2(6, 6), COLOR_DEBUG_ROUTE_EDGE)


func _build_entities(entities: Array) -> void:
	var has_boat_spawn := _has_entity_type(entities, "boat_spawn")
	for entity in entities:
		var entity_type := str(entity.get("type", ""))
		var center := _entity_center(entity)

		if entity_type == "boat_spawn":
			_boat_entities.append(entity)
			spawn_position = _boat_entry_center(entity)
			_add_boat_marker(str(entity.get("id", "BoatSpawn")), entity)
		elif entity_type == "spawn":
			if has_boat_spawn:
				var legacy_marker := _add_marker("LegacyPlayerStart", center, COLOR_MARKER, 18.0)
				if show_debug_overlay:
					legacy_marker.color = COLOR_DEBUG_ENTRY
					_add_debug_label("LEGACY SPAWN", center + Vector2(18, -22), COLOR_DEBUG_ENTRY)
				continue
			spawn_position = center
			var spawn_in_extraction := is_inside_extraction(center)
			var spawn_marker: Node2D
			if spawn_in_extraction:
				spawn_marker = _add_relay_spawn_cue("PlayerStartRelayCue", center)
			else:
				spawn_marker = _add_marker("PlayerStart", center, COLOR_MARKER, 28.0)
			if show_debug_overlay:
				if spawn_in_extraction:
					var debug_spawn := _add_diamond("PlayerStartDebug", center, COLOR_DEBUG_ENTRY, 16.0)
					debug_spawn.z_index = 23
				elif spawn_marker is Polygon2D:
					(spawn_marker as Polygon2D).color = COLOR_DEBUG_ENTRY
				_add_debug_label("SPAWN", center + Vector2(18, -22), COLOR_DEBUG_ENTRY)
		elif entity_type == "salvage":
			_salvage_entities.append(entity)
			var salvage_id := str(entity.get("id", "Salvage"))
			var salvage_node := _add_salvage_prop(salvage_id, center, str(entity.get("kind", "crate")))
			_salvage_nodes_by_id[salvage_id] = salvage_node
			if show_debug_overlay:
				var debug_marker := _add_local_polygon(salvage_node, "DebugDiamond", _diamond_points(16.0), Color(1.0, 0.80, 0.22, 0.35))
				debug_marker.z_index = 20
				_add_debug_label("SALVAGE", center + Vector2(18, -22), COLOR_SALVAGE)
		elif entity_type == "hazard":
			_hazard_entities.append(entity)
			var hazard_id := str(entity.get("id", "Hazard"))
			var hazard_node := _add_hazard_prop(hazard_id, center, str(entity.get("kind", "mine")))
			if show_debug_overlay:
				var debug_marker := _add_local_polygon(hazard_node, "DebugMarker", _rect_points(Vector2(18, 18)), Color(1.0, 0.22, 0.34, 0.35))
				debug_marker.z_index = 20
				_add_debug_label("HAZARD", center + Vector2(18, -22), COLOR_HAZARD)


func _has_entity_type(entities: Array, entity_type: String) -> bool:
	for entity in entities:
		if str(entity.get("type", "")) == entity_type:
			return true
	return false


func _rect_polygon(item: Dictionary, color: Color) -> Polygon2D:
	var size := _rect_size(item)
	var poly := Polygon2D.new()
	poly.position = Vector2(int(item["x"]) * tile_size, int(item["y"]) * tile_size)
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0),
		size,
		Vector2(0, size.y),
	])
	return poly


func _add_texture_rect(parent: Node2D, texture_path: String, item: Dictionary, sprite_name: String) -> Sprite2D:
	var texture := _load_png_texture(texture_path)
	if texture == null:
		return null

	var texture_size := texture.get_size()
	if texture_size == Vector2.ZERO:
		push_warning("Terrain art texture has no size: %s" % texture_path)
		return null

	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = _rect_center(item)
	sprite.scale = _rect_size(item) / texture_size
	parent.add_child(sprite)
	return sprite


func _load_png_texture(texture_path: String) -> Texture2D:
	var packaged_texture := _packaged_texture(texture_path)
	if packaged_texture != null:
		return packaged_texture

	var resource := load(texture_path)
	if resource is Texture2D:
		return resource

	var file := FileAccess.open(texture_path, FileAccess.READ)
	if file == null:
		push_warning("Unable to open terrain art texture: %s" % texture_path)
		return null

	var image := Image.new()
	var error := image.load_png_from_buffer(file.get_buffer(file.get_length()))
	if error != OK:
		push_warning("Unable to decode terrain art texture: %s" % texture_path)
		return null

	return ImageTexture.create_from_image(image)


func _packaged_texture(texture_path: String) -> Texture2D:
	match texture_path:
		CAVE_TILESET_TEXTURE:
			return CAVE_TILESET_TEXTURE_RESOURCE
		BACKGROUND_ROCKS_TEXTURE:
			return BACKGROUND_ROCKS_TEXTURE_RESOURCE
		_:
			return null


func _add_marker(marker_name: String, center: Vector2, color: Color, radius: float) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = marker_name
	poly.position = center
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(-radius, -radius),
		Vector2(radius, -radius),
		Vector2(radius, radius),
		Vector2(-radius, radius),
	])
	_marker_root.add_child(poly)
	return poly


func _add_relay_extraction_prop(marker_name: String, item: Dictionary) -> Node2D:
	var rect := _rect_from_item(item)
	var root := Node2D.new()
	root.name = marker_name
	root.position = rect.position
	root.z_index = 6
	_marker_root.add_child(root)

	var field := _add_local_polygon(root, "RelayReturnField", _rect_points(rect.size), Color(1.0, 0.92, 0.52, 0.13))
	field.position = rect.size * 0.5
	field.z_index = 0

	var field_edge := _add_local_line(root, "RelayReturnFieldEdge", _rect_outline_points(rect.size), Color(1.0, 0.92, 0.52, 0.42), 2.0)
	field_edge.z_index = 1

	var center := rect.size * 0.5
	var dock_size := Vector2(minf(rect.size.x * 0.72, 188.0), minf(rect.size.y * 0.20, 34.0))
	var dock := _add_local_polygon(root, "RelayDock", _rect_points(dock_size), Color(0.10, 0.22, 0.26, 0.82))
	dock.position = center + Vector2(0, rect.size.y * 0.22)
	dock.z_index = 2

	var dock_edge := _add_local_line(root, "RelayDockEdge", _closed_rect_points(dock_size), Color(0.55, 0.76, 0.78, 0.72), 2.0)
	dock_edge.position = dock.position
	dock_edge.z_index = 3

	var hull_size := Vector2(minf(rect.size.x * 0.46, 132.0), minf(rect.size.y * 0.34, 52.0))
	var hull_center := center + Vector2(0, -rect.size.y * 0.05)
	var glow := _add_local_polygon(root, "RelayGlow", _ellipse_points(hull_size.x * 0.72, hull_size.y * 0.78, 24), Color(0.28, 0.92, 0.98, 0.20))
	glow.position = hull_center
	glow.z_index = 2

	var tail := _add_local_polygon(root, "RelayTailFin", PackedVector2Array([
		hull_center + Vector2(-hull_size.x * 0.42, -hull_size.y * 0.18),
		hull_center + Vector2(-hull_size.x * 0.72, 0),
		hull_center + Vector2(-hull_size.x * 0.42, hull_size.y * 0.18),
	]), COLOR_RELAY_DARK)
	tail.z_index = 4

	var body_shadow := _add_local_polygon(root, "RelayBodyShadow", _ellipse_points(hull_size.x * 0.52, hull_size.y * 0.42, 24), COLOR_RELAY_DARK)
	body_shadow.position = hull_center + Vector2(4, 4)
	body_shadow.z_index = 3

	var body := _add_local_polygon(root, "RelayBody", _ellipse_points(hull_size.x * 0.50, hull_size.y * 0.40, 24), COLOR_RELAY_BODY)
	body.position = hull_center
	body.z_index = 5

	var window := _add_local_polygon(root, "RelayWindow", _ellipse_points(hull_size.x * 0.16, hull_size.y * 0.22, 16), COLOR_RELAY_GLASS)
	window.position = hull_center + Vector2(hull_size.x * 0.20, -hull_size.y * 0.02)
	window.z_index = 6

	var beacon := _add_local_line(root, "RelayBeacon", PackedVector2Array([
		hull_center + Vector2(0, -hull_size.y * 0.70),
		hull_center + Vector2(0, -hull_size.y * 1.15),
	]), COLOR_RELAY_LIGHT, 3.0)
	beacon.z_index = 6

	var beacon_light := _add_local_polygon(root, "RelayBeaconLight", _circle_points(7.0, 12), COLOR_RELAY_LIGHT)
	beacon_light.position = hull_center + Vector2(0, -hull_size.y * 1.18)
	beacon_light.z_index = 7
	return root


func _add_relay_spawn_cue(marker_name: String, center: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.position = center
	root.z_index = 10
	_marker_root.add_child(root)

	var glow := _add_local_polygon(root, "RelayEntryGlow", _circle_points(30.0, 18), Color(0.28, 0.92, 0.98, 0.18))
	glow.z_index = 0

	var ring := _add_local_line(root, "RelayEntryRing", PackedVector2Array([
		Vector2(0, -18),
		Vector2(18, 0),
		Vector2(0, 18),
		Vector2(-18, 0),
		Vector2(0, -18),
	]), COLOR_RELAY_GLASS, 2.0)
	ring.z_index = 1

	var chevron := _add_local_polygon(root, "RelayEntryChevron", PackedVector2Array([
		Vector2(-6, -10),
		Vector2(10, 0),
		Vector2(-6, 10),
		Vector2(-1, 0),
	]), COLOR_RELAY_LIGHT)
	chevron.z_index = 2
	return root


func _add_boat_marker(marker_name: String, item: Dictionary) -> Node2D:
	var rect := _entity_rect_from_item(item)
	var entry_local := _boat_entry_center(item) - rect.position

	var root := Node2D.new()
	root.name = marker_name
	root.position = rect.position
	root.z_index = 7
	_marker_root.add_child(root)

	var return_field := _add_local_polygon(root, "ExtractionField", _rect_points(rect.size), Color(1.0, 0.92, 0.68, 0.16))
	return_field.position = rect.size * 0.5
	return_field.z_index = 0

	var hull_shadow := _add_local_polygon(root, "HullShadow", PackedVector2Array([
		Vector2(rect.size.x * 0.05, rect.size.y * 0.36),
		Vector2(rect.size.x * 0.95, rect.size.y * 0.36),
		Vector2(rect.size.x * 0.82, rect.size.y * 1.24),
		Vector2(rect.size.x * 0.18, rect.size.y * 1.24),
	]), COLOR_BOAT_DARK)
	hull_shadow.z_index = 1

	var hull := _add_local_polygon(root, "Hull", PackedVector2Array([
		Vector2(rect.size.x * 0.02, rect.size.y * 0.16),
		Vector2(rect.size.x * 0.98, rect.size.y * 0.16),
		Vector2(rect.size.x * 0.84, rect.size.y * 1.04),
		Vector2(rect.size.x * 0.16, rect.size.y * 1.04),
	]), COLOR_BOAT)
	hull.z_index = 2

	var rim := _add_local_line(root, "DeckRim", PackedVector2Array([
		Vector2(rect.size.x * 0.08, rect.size.y * 0.20),
		Vector2(rect.size.x * 0.92, rect.size.y * 0.20),
	]), COLOR_BOAT_LIGHT, 3.0)
	rim.z_index = 4

	var cabin_width := minf(rect.size.x * 0.30, 72.0)
	var cabin_center_x := clampf(entry_local.x + 58.0, cabin_width * 0.5 + 8.0, rect.size.x - cabin_width * 0.5 - 8.0)
	var cabin := _add_local_polygon(root, "Cabin", _rect_points(Vector2(cabin_width, rect.size.y * 0.54)), Color(0.90, 0.79, 0.57, 0.96))
	cabin.position = Vector2(cabin_center_x, rect.size.y * 0.36)
	cabin.z_index = 3

	var cabin_window := _add_local_polygon(root, "CabinWindow", _rect_points(Vector2(cabin_width * 0.45, rect.size.y * 0.20)), COLOR_BOAT_GLASS)
	cabin_window.position = cabin.position + Vector2(0, -rect.size.y * 0.02)
	cabin_window.z_index = 4

	var hatch := _add_local_polygon(root, "EntryHatch", _rect_points(Vector2(30, 10)), COLOR_BASE)
	hatch.position = Vector2(entry_local.x, rect.size.y * 0.38)
	hatch.z_index = 5

	var tether_bottom := rect.size.y * 3.8
	var entry_glow := _add_local_line(root, "EntryGlow", PackedVector2Array([
		Vector2(entry_local.x, rect.size.y * 0.46),
		Vector2(entry_local.x, tether_bottom),
	]), Color(1.0, 0.92, 0.52, 0.30), 16.0)
	entry_glow.z_index = 3

	var tether_left := entry_local.x - 6.0
	var tether_right := entry_local.x + 6.0
	var entry_tether_left := _add_local_line(root, "EntryTetherLeft", PackedVector2Array([
		Vector2(tether_left, rect.size.y * 0.46),
		Vector2(tether_left, tether_bottom),
	]), COLOR_BASE, 2.0)
	entry_tether_left.z_index = 5

	var entry_tether_right := _add_local_line(root, "EntryTetherRight", PackedVector2Array([
		Vector2(tether_right, rect.size.y * 0.46),
		Vector2(tether_right, tether_bottom),
	]), COLOR_BASE, 3.0)
	entry_tether_right.z_index = 5

	for rung_index in range(1, 7):
		var rung_y := rect.size.y * 0.55 + float(rung_index) * 14.0
		if rung_y >= tether_bottom:
			break
		var rung := _add_local_line(root, "EntryTetherRung%s" % rung_index, PackedVector2Array([
			Vector2(tether_left, rung_y),
			Vector2(tether_right, rung_y),
		]), COLOR_BOAT_LIGHT, 2.0)
		rung.z_index = 6

	if show_debug_overlay:
		var debug_rect := _add_local_line(root, "DebugBoatExtractionRect", _rect_outline_points(rect.size), COLOR_DEBUG_EXTRACTION, 3.0)
		debug_rect.z_index = 22
		var debug_entry := _add_local_polygon(root, "DebugEntryCell", _diamond_points(14.0), COLOR_DEBUG_ENTRY)
		debug_entry.position = entry_local
		debug_entry.z_index = 23
		_add_debug_label("BOAT / RETURN", rect.position + Vector2(6, rect.size.y + 8), COLOR_DEBUG_EXTRACTION)
		_add_debug_label("ENTRY", rect.position + entry_local + Vector2(18, -20), COLOR_DEBUG_ENTRY)
	return root


func _add_diamond(marker_name: String, center: Vector2, color: Color, radius: float) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = marker_name
	poly.position = center
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius, 0),
		Vector2(0, radius),
		Vector2(-radius, 0),
	])
	_marker_root.add_child(poly)
	return poly


func _add_salvage_prop(marker_name: String, center: Vector2, kind: String) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.position = center
	root.z_index = 8
	_marker_root.add_child(root)

	match kind:
		"wreck_fragment":
			_add_wreck_fragment_prop(root)
		"relic":
			_add_relic_prop(root)
		_:
			_add_crate_prop(root)
	return root


func _add_crate_prop(root: Node2D) -> void:
	_add_local_polygon(root, "CrateBody", _rect_points(Vector2(24, 20)), Color(0.82, 0.52, 0.20, 1.0))
	_add_local_line(root, "CrateOutline", _closed_rect_points(Vector2(24, 20)), COLOR_SALVAGE_DARK, 2.0)
	_add_local_line(root, "CrateBandHorizontal", PackedVector2Array([Vector2(-12, 0), Vector2(12, 0)]), COLOR_SALVAGE_DARK, 2.0)
	_add_local_line(root, "CrateBandVertical", PackedVector2Array([Vector2(0, -10), Vector2(0, 10)]), COLOR_SALVAGE_DARK, 2.0)
	_add_local_polygon(root, "CrateGlint", PackedVector2Array([Vector2(5, -8), Vector2(10, -8), Vector2(10, -4), Vector2(5, -4)]), COLOR_SALVAGE)


func _add_wreck_fragment_prop(root: Node2D) -> void:
	_add_local_polygon(root, "FragmentBody", PackedVector2Array([
		Vector2(-15, -7),
		Vector2(12, -11),
		Vector2(17, 1),
		Vector2(-9, 9),
	]), COLOR_SALVAGE_METAL)
	_add_local_polygon(root, "FragmentRust", PackedVector2Array([
		Vector2(-13, -5),
		Vector2(-2, -7),
		Vector2(0, 3),
		Vector2(-10, 6),
	]), Color(0.73, 0.39, 0.17, 1.0))
	_add_local_line(root, "FragmentEdge", PackedVector2Array([
		Vector2(-15, -7),
		Vector2(12, -11),
		Vector2(17, 1),
		Vector2(-9, 9),
		Vector2(-15, -7),
	]), Color(0.16, 0.23, 0.25, 1.0), 2.0)
	_add_local_polygon(root, "FragmentGlint", PackedVector2Array([Vector2(7, -8), Vector2(13, -9), Vector2(14, -5), Vector2(8, -4)]), COLOR_SALVAGE)


func _add_relic_prop(root: Node2D) -> void:
	_add_local_polygon(root, "RelicGlow", _circle_points(13.0, 16), Color(0.24, 0.94, 0.90, 0.38))
	_add_local_polygon(root, "RelicCore", _circle_points(8.0, 16), Color(0.10, 0.70, 0.72, 1.0))
	_add_local_line(root, "RelicBand", PackedVector2Array([Vector2(-12, 4), Vector2(12, 4)]), COLOR_SALVAGE_DARK, 2.0)
	_add_local_polygon(root, "RelicGold", PackedVector2Array([
		Vector2(-7, -11),
		Vector2(7, -11),
		Vector2(9, -6),
		Vector2(-9, -6),
	]), COLOR_SALVAGE)


func _add_hazard_prop(marker_name: String, center: Vector2, kind: String) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.position = center
	root.z_index = 8
	_marker_root.add_child(root)

	match kind:
		"jellyfish":
			_add_jellyfish_prop(root)
		_:
			_add_mine_prop(root)
	return root


func _add_mine_prop(root: Node2D) -> void:
	_add_local_polygon(root, "MineSpikes", _star_points(10.0, 18.0, 8), COLOR_HAZARD_DARK)
	_add_local_polygon(root, "MineBody", _circle_points(11.0, 18), COLOR_HAZARD)
	_add_local_polygon(root, "MineHighlight", _circle_points(4.0, 10, Vector2(-4, -4)), COLOR_HAZARD_LIGHT)


func _add_jellyfish_prop(root: Node2D) -> void:
	_add_local_polygon(root, "JellyBell", PackedVector2Array([
		Vector2(-14, 1),
		Vector2(-11, -8),
		Vector2(-4, -13),
		Vector2(5, -13),
		Vector2(12, -8),
		Vector2(15, 1),
		Vector2(9, 7),
		Vector2(3, 3),
		Vector2(-3, 7),
		Vector2(-9, 3),
	]), COLOR_HAZARD)
	_add_local_line(root, "JellyTentacleLeft", PackedVector2Array([Vector2(-7, 5), Vector2(-10, 13), Vector2(-7, 18)]), COLOR_HAZARD_LIGHT, 2.0)
	_add_local_line(root, "JellyTentacleCenter", PackedVector2Array([Vector2(0, 5), Vector2(2, 13), Vector2(0, 20)]), COLOR_HAZARD_LIGHT, 2.0)
	_add_local_line(root, "JellyTentacleRight", PackedVector2Array([Vector2(7, 5), Vector2(10, 13), Vector2(7, 18)]), COLOR_HAZARD_LIGHT, 2.0)
	_add_local_polygon(root, "JellyHighlight", _circle_points(3.0, 8, Vector2(-4, -6)), COLOR_HAZARD_LIGHT)


func _add_local_polygon(parent: Node2D, polygon_name: String, points: PackedVector2Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = polygon_name
	poly.color = color
	poly.polygon = points
	parent.add_child(poly)
	return poly


func _add_local_line(parent: Node2D, line_name: String, points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.points = points
	line.default_color = color
	line.width = width
	parent.add_child(line)
	return line


func _rect_points(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


func _closed_rect_points(size: Vector2) -> PackedVector2Array:
	var points := _rect_points(size)
	points.append(points[0])
	return points


func _rect_outline_points(size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0),
		size,
		Vector2(0, size.y),
		Vector2.ZERO,
	])


func _diamond_points(radius: float) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2(0, -radius),
		Vector2(radius, 0),
		Vector2(0, radius),
		Vector2(-radius, 0),
	])


func _circle_points(radius: float, steps: int, offset := Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(offset + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _ellipse_points(radius_x: float, radius_y: float, steps: int, offset := Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(offset + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _star_points(inner_radius: float, outer_radius: float, spikes: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(spikes * 2):
		var radius := outer_radius if index % 2 == 0 else inner_radius
		var angle := -PI * 0.5 + TAU * float(index) / float(spikes * 2)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _rect_center(item: Dictionary) -> Vector2:
	return Vector2(
		(float(item["x"]) + float(item["w"]) * 0.5) * tile_size,
		(float(item["y"]) + float(item["h"]) * 0.5) * tile_size
	)


func _rect_size(item: Dictionary) -> Vector2:
	return Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)


func _add_rect_outline(item: Dictionary, outline_name: String, color: Color, width: float, z_index: int) -> Line2D:
	var line := Line2D.new()
	line.name = outline_name
	line.position = _rect_from_item(item).position
	line.points = _rect_outline_points(_rect_size(item))
	line.default_color = color
	line.width = width
	line.z_index = z_index
	_marker_root.add_child(line)
	return line


func _add_debug_label(label_text: String, position: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.name = "DebugLabel"
	label.text = label_text
	label.position = position
	label.z_index = 30
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.84))
	label.add_theme_constant_override("outline_size", 4)
	_marker_root.add_child(label)
	return label


func _rect_from_item(item: Dictionary) -> Rect2:
	return Rect2(
		Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size),
		_rect_size(item)
	)


func _entity_rect_from_item(item: Dictionary) -> Rect2:
	return Rect2(
		Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size),
		Vector2(
			float(item.get("w", 1)) * tile_size,
			float(item.get("h", 1)) * tile_size
		)
	)


func _entity_center(item: Dictionary) -> Vector2:
	return Vector2((float(item["x"]) + 0.5) * tile_size, (float(item["y"]) + 0.5) * tile_size)


func _position_to_cell(position: Vector2) -> Vector2i:
	return Vector2i(
		clampi(int(floor(position.x / tile_size)), 0, map_tile_size.x - 1),
		clampi(int(floor(position.y / tile_size)), 0, map_tile_size.y - 1)
	)


func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2((float(cell.x) + 0.5) * tile_size, (float(cell.y) + 0.5) * tile_size)


func _boat_entry_center(item: Dictionary) -> Vector2:
	return Vector2(
		(float(item.get("entry_x", item["x"])) + 0.5) * tile_size,
		(float(item.get("entry_y", item["y"])) + 0.5) * tile_size
	)
