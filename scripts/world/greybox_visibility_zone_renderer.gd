extends RefCounted

const COLOR_DIM_ZONE := Color(0.02, 0.08, 0.13, 0.22)
const COLOR_DARK_ZONE := Color(0.01, 0.03, 0.08, 0.36)
const COLOR_DEBUG_VISIBILITY_EDGE := Color(0.48, 0.74, 1.0, 0.88)


func add_visibility_zone(parent: Node2D, item: Dictionary, tile_size: int, show_debug_overlay: bool, debug_renderer) -> Polygon2D:
	var zone := _rect_polygon(item, tile_size, _color_for_level(str(item.get("visibility_level", "dim"))))
	zone.name = str(item.get("id", "VisibilityZone"))
	zone.z_index = 9
	parent.add_child(zone)

	if show_debug_overlay:
		var rect := _rect_from_item(item, tile_size)
		if debug_renderer != null:
			debug_renderer.add_rect_outline(parent, rect, "%sDebugOutline" % zone.name, COLOR_DEBUG_VISIBILITY_EDGE, 2.0, 24)
			debug_renderer.add_debug_label(parent, "VISIBILITY", rect.position + Vector2(6, 28), COLOR_DEBUG_VISIBILITY_EDGE)
	return zone


func _color_for_level(level: String) -> Color:
	if level == "dark":
		return COLOR_DARK_ZONE
	return COLOR_DIM_ZONE


func _rect_polygon(item: Dictionary, tile_size: int, color: Color) -> Polygon2D:
	var size := _rect_size(item, tile_size)
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


func _rect_from_item(item: Dictionary, tile_size: int) -> Rect2:
	return Rect2(
		Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size),
		_rect_size(item, tile_size)
	)


func _rect_size(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)
