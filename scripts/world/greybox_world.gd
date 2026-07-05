extends Node2D

const COLOR_WATER := Color(0.08, 0.72, 0.92, 1.0)
const COLOR_GRID := Color(0.85, 0.98, 1.0, 0.22)
const COLOR_SOLID := Color(0.15, 0.20, 0.25, 1.0)
const COLOR_BASE := Color(0.95, 0.78, 0.48, 0.92)
const COLOR_BOAT := Color(0.96, 0.66, 0.20, 0.92)
const COLOR_BACKGROUND := Color(0.08, 0.39, 0.58, 0.18)
const COLOR_MARKER := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_SALVAGE := Color(1.0, 0.80, 0.22, 1.0)
const COLOR_HAZARD := Color(1.0, 0.22, 0.34, 1.0)
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
			var base := _rect_polygon(zone, Color(1.0, 0.92, 0.68, 0.30))
			base.name = zone.get("id", "Base")
			base.z_index = 5
			_marker_root.add_child(base)
		elif zone.get("type", "") == "marker":
			var marker := _rect_polygon(zone, COLOR_MARKER)
			marker.name = zone.get("id", "Marker")
			marker.z_index = 4
			_marker_root.add_child(marker)


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
				_add_marker("LegacyPlayerStart", center, COLOR_MARKER, 18.0)
				continue
			spawn_position = center
			_add_marker("PlayerStart", center, COLOR_MARKER, 28.0)
		elif entity_type == "salvage":
			_salvage_entities.append(entity)
			var salvage_id := str(entity.get("id", "Salvage"))
			_salvage_nodes_by_id[salvage_id] = _add_diamond(salvage_id, center, COLOR_SALVAGE, 16.0)
		elif entity_type == "hazard":
			_add_marker(entity.get("id", "Hazard"), center, COLOR_HAZARD, 18.0)


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


func _add_boat_marker(marker_name: String, item: Dictionary) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.z_index = 7
	_marker_root.add_child(root)

	var rect := _entity_rect_from_item(item)
	var hull := Polygon2D.new()
	hull.name = "Hull"
	hull.position = rect.position
	hull.color = COLOR_BOAT
	hull.polygon = PackedVector2Array([
		Vector2(0, rect.size.y * 0.28),
		Vector2(rect.size.x, rect.size.y * 0.28),
		Vector2(rect.size.x * 0.82, rect.size.y),
		Vector2(rect.size.x * 0.18, rect.size.y),
	])
	root.add_child(hull)

	var entry_marker := _add_marker("%sEntry" % marker_name, _boat_entry_center(item), COLOR_BASE, 16.0)
	entry_marker.z_index = 8
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


func _rect_center(item: Dictionary) -> Vector2:
	return Vector2(
		(float(item["x"]) + float(item["w"]) * 0.5) * tile_size,
		(float(item["y"]) + float(item["h"]) * 0.5) * tile_size
	)


func _rect_size(item: Dictionary) -> Vector2:
	return Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)


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


func _boat_entry_center(item: Dictionary) -> Vector2:
	return Vector2(
		(float(item.get("entry_x", item["x"])) + 0.5) * tile_size,
		(float(item.get("entry_y", item["y"])) + 0.5) * tile_size
	)
