extends RefCounted

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


func build_layer(terrain_items: Array, tile_size: int, map_tile_size: Vector2i, asset_lookup) -> TileMapLayer:
	var terrain_layer := TileMapLayer.new()
	terrain_layer.name = "CaveTerrainTileMapLayer"
	terrain_layer.tile_set = _create_cave_tileset(tile_size, asset_lookup)

	var solid_cells := solid_cells_from_terrain(terrain_items)
	for cell in solid_cells.keys():
		terrain_layer.set_cell(cell, TERRAIN_SOURCE_ID, _terrain_atlas_coords(cell, solid_cells, map_tile_size))
	return terrain_layer


func solid_cells_from_terrain(terrain_items: Array) -> Dictionary:
	var solid_cells := {}
	for item in terrain_items:
		if item.get("type", "") != "solid":
			continue
		for y in range(int(item["y"]), int(item["y"]) + int(item["h"])):
			for x in range(int(item["x"]), int(item["x"]) + int(item["w"])):
				solid_cells[Vector2i(x, y)] = true
	return solid_cells


func _create_cave_tileset(tile_size: int, asset_lookup) -> TileSet:
	var texture: Texture2D = null
	if asset_lookup != null:
		texture = asset_lookup.cave_tileset_texture()
	if texture == null:
		var texture_path := "unknown"
		if asset_lookup != null:
			texture_path = str(asset_lookup.cave_tileset_texture_path())
		push_error("Unable to create cave TileSet; missing texture %s" % texture_path)
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


func _terrain_atlas_coords(cell: Vector2i, solid_cells: Dictionary, map_tile_size: Vector2i) -> Vector2i:
	var mask := 0
	if not _is_solid_cell(cell + Vector2i.UP, solid_cells, map_tile_size):
		mask |= MASK_TOP
	if not _is_solid_cell(cell + Vector2i.RIGHT, solid_cells, map_tile_size):
		mask |= MASK_RIGHT
	if not _is_solid_cell(cell + Vector2i.DOWN, solid_cells, map_tile_size):
		mask |= MASK_BOTTOM
	if not _is_solid_cell(cell + Vector2i.LEFT, solid_cells, map_tile_size):
		mask |= MASK_LEFT

	if mask == 0:
		var inner_coord := _inner_corner_atlas_coords(cell, solid_cells, map_tile_size)
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


func _inner_corner_atlas_coords(cell: Vector2i, solid_cells: Dictionary, map_tile_size: Vector2i) -> Vector2i:
	if not _is_solid_cell(cell + Vector2i.UP + Vector2i.LEFT, solid_cells, map_tile_size):
		return INNER_TOP_LEFT_COORD
	if not _is_solid_cell(cell + Vector2i.UP + Vector2i.RIGHT, solid_cells, map_tile_size):
		return INNER_TOP_RIGHT_COORD
	if not _is_solid_cell(cell + Vector2i.DOWN + Vector2i.LEFT, solid_cells, map_tile_size):
		return INNER_BOTTOM_LEFT_COORD
	if not _is_solid_cell(cell + Vector2i.DOWN + Vector2i.RIGHT, solid_cells, map_tile_size):
		return INNER_BOTTOM_RIGHT_COORD
	return NO_SPECIAL_COORD


func _is_solid_cell(cell: Vector2i, solid_cells: Dictionary, map_tile_size: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or cell.x >= map_tile_size.x or cell.y >= map_tile_size.y:
		return true
	return solid_cells.has(cell)
