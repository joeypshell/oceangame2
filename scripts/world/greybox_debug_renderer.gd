extends RefCounted

const COLOR_GRID := Color(0.85, 0.98, 1.0, 0.22)
const COLOR_SOLID := Color(0.15, 0.20, 0.25, 1.0)
const SOURCE_LAYER_ALPHA := 0.08


func draw_grid(canvas_item: CanvasItem, map_pixel_size: Vector2, tile_size: int) -> void:
	for x in range(0, int(map_pixel_size.x) + 1, tile_size):
		canvas_item.draw_line(Vector2(x, 0), Vector2(x, map_pixel_size.y), COLOR_GRID)
	for y in range(0, int(map_pixel_size.y) + 1, tile_size):
		canvas_item.draw_line(Vector2(0, y), Vector2(map_pixel_size.x, y), COLOR_GRID)


func build_source_layer(map_data: Dictionary, tile_size: int, show_debug_overlay: bool, base_color: Color) -> TileMapLayer:
	var solid_layer := TileMapLayer.new()
	solid_layer.name = "SourceTileMapLayer"
	solid_layer.tile_set = _create_greybox_tileset(tile_size, base_color)
	solid_layer.modulate = Color(1.0, 1.0, 1.0, SOURCE_LAYER_ALPHA)
	solid_layer.visible = show_debug_overlay

	for terrain in map_data.get("terrain", []):
		if terrain.get("type", "") == "solid":
			_fill_tile_rect(solid_layer, terrain, Vector2i(0, 0))

	for zone in map_data.get("zones", []):
		if zone.get("type", "") == "base":
			_fill_tile_rect(solid_layer, zone, Vector2i(1, 0))

	return solid_layer


func add_rect_outline(parent: Node2D, rect: Rect2, outline_name: String, color: Color, width: float, z_index: int) -> Line2D:
	var line := Line2D.new()
	line.name = outline_name
	line.position = rect.position
	line.points = _rect_outline_points(rect.size)
	line.default_color = color
	line.width = width
	line.z_index = z_index
	parent.add_child(line)
	return line


func add_debug_label(parent: Node2D, label_text: String, position: Vector2, color: Color) -> Label:
	var label := Label.new()
	label.name = "DebugLabel"
	label.text = label_text
	label.position = position
	label.z_index = 30
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.84))
	label.add_theme_constant_override("outline_size", 4)
	parent.add_child(label)
	return label


func _create_greybox_tileset(tile_size: int, base_color: Color) -> TileSet:
	var image := Image.create(tile_size * 2, tile_size, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	image.fill_rect(Rect2i(0, 0, tile_size, tile_size), COLOR_SOLID)
	image.fill_rect(Rect2i(tile_size, 0, tile_size, tile_size), base_color)

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


func _rect_outline_points(size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0),
		size,
		Vector2(0, size.y),
		Vector2.ZERO,
	])
