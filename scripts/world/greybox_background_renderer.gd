extends RefCounted

const COLOR_BACKGROUND := Color(0.08, 0.39, 0.58, 0.18)
const BACKGROUND_ART_ALPHA := 0.26


func build_background(parent: Node2D, items: Array, tile_size: int, asset_lookup) -> void:
	for item in items:
		var poly := _rect_polygon(item, tile_size, COLOR_BACKGROUND)
		poly.name = item.get("id", "Background")
		parent.add_child(poly)

		var sprite_name := "%sArt" % item.get("id", "Background")
		var sprite := _add_texture_rect(parent, asset_lookup.background_rocks_texture_path(), item, tile_size, sprite_name, asset_lookup)
		if sprite == null:
			sprite = _add_texture_rect(parent, asset_lookup.background_rocks_fallback_texture_path(), item, tile_size, sprite_name, asset_lookup)
		if sprite != null:
			sprite.modulate = Color(1.0, 1.0, 1.0, BACKGROUND_ART_ALPHA)


func _add_texture_rect(parent: Node2D, texture_path: String, item: Dictionary, tile_size: int, sprite_name: String, asset_lookup) -> Sprite2D:
	if asset_lookup == null:
		return null
	var texture: Texture2D = asset_lookup.load_png_texture(texture_path)
	if texture == null:
		return null

	var texture_size: Vector2 = texture.get_size()
	if texture_size == Vector2.ZERO:
		push_warning("Terrain art texture has no size: %s" % texture_path)
		return null

	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.position = _rect_center(item, tile_size)
	sprite.scale = _rect_size(item, tile_size) / texture_size
	parent.add_child(sprite)
	return sprite


func _rect_polygon(item: Dictionary, tile_size: int, color: Color) -> Polygon2D:
	var size := _rect_size(item, tile_size)
	var poly := Polygon2D.new()
	poly.color = color
	poly.polygon = PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0),
		size,
		Vector2(0, size.y),
	])
	poly.position = Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size)
	return poly


func _rect_center(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2(
		(float(item["x"]) + float(item["w"]) * 0.5) * tile_size,
		(float(item["y"]) + float(item["h"]) * 0.5) * tile_size
	)


func _rect_size(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)
