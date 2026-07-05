extends Node2D

const COLOR_WATER := Color(0.08, 0.72, 0.92, 1.0)
const COLOR_GRID := Color(0.85, 0.98, 1.0, 0.22)
const COLOR_SOLID := Color(0.15, 0.20, 0.25, 1.0)
const COLOR_BASE := Color(0.95, 0.78, 0.48, 0.92)
const COLOR_BACKGROUND := Color(0.08, 0.39, 0.58, 0.18)
const COLOR_MARKER := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_SALVAGE := Color(1.0, 0.80, 0.22, 1.0)
const COLOR_HAZARD := Color(1.0, 0.22, 0.34, 1.0)

@export var map_path := "res://maps/cave_salvage_test_01.greybox.json"

var tile_size := 32
var map_tile_size := Vector2i.ZERO
var map_pixel_size := Vector2.ZERO
var spawn_position := Vector2.ZERO
var camera_tests: Array = []

var _built := false
var _solid_layer: TileMapLayer
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

	tile_size = int(map_data["units"]["tile_size_px"])
	map_tile_size = Vector2i(int(map_data["units"]["width_tiles"]), int(map_data["units"]["height_tiles"]))
	map_pixel_size = Vector2(map_tile_size * tile_size)
	camera_tests = map_data.get("camera_tests", [])

	_marker_root = Node2D.new()
	_marker_root.name = "Markers"
	add_child(_marker_root)

	_collision_root = Node2D.new()
	_collision_root.name = "Collision"
	add_child(_collision_root)

	_build_background(map_data.get("background", []))
	_build_tilemap(map_data)
	_build_collision(map_data.get("terrain", []))
	_build_zones(map_data.get("zones", []))
	_build_entities(map_data.get("entities", []))
	queue_redraw()


func _draw() -> void:
	if map_pixel_size == Vector2.ZERO:
		return

	draw_rect(Rect2(Vector2.ZERO, map_pixel_size), COLOR_WATER)
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
	add_child(_solid_layer)

	for terrain in map_data.get("terrain", []):
		if terrain.get("type", "") == "solid":
			_fill_tile_rect(_solid_layer, terrain, Vector2i(0, 0))

	for zone in map_data.get("zones", []):
		if zone.get("type", "") == "base":
			_fill_tile_rect(_solid_layer, zone, Vector2i(1, 0))


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


func _build_background(items: Array) -> void:
	for item in items:
		var poly := _rect_polygon(item, COLOR_BACKGROUND)
		poly.name = item.get("id", "Background")
		poly.z_index = -20
		add_child(poly)


func _build_zones(zones: Array) -> void:
	for zone in zones:
		if zone.get("type", "") == "base":
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
	for entity in entities:
		var entity_type := str(entity.get("type", ""))
		var center := _entity_center(entity)

		if entity_type == "spawn":
			spawn_position = center
			_add_marker("PlayerStart", center, COLOR_MARKER, 28.0)
		elif entity_type == "salvage":
			_add_diamond(entity.get("id", "Salvage"), center, COLOR_SALVAGE, 16.0)
		elif entity_type == "hazard":
			_add_marker(entity.get("id", "Hazard"), center, COLOR_HAZARD, 18.0)


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


func _add_marker(marker_name: String, center: Vector2, color: Color, radius: float) -> void:
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


func _add_diamond(marker_name: String, center: Vector2, color: Color, radius: float) -> void:
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


func _rect_center(item: Dictionary) -> Vector2:
	return Vector2(
		(float(item["x"]) + float(item["w"]) * 0.5) * tile_size,
		(float(item["y"]) + float(item["h"]) * 0.5) * tile_size
	)


func _rect_size(item: Dictionary) -> Vector2:
	return Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)


func _entity_center(item: Dictionary) -> Vector2:
	return Vector2((float(item["x"]) + 0.5) * tile_size, (float(item["y"]) + 0.5) * tile_size)
