extends RefCounted

const COLOR_MARKER := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_DEBUG_ROUTE := Color(0.90, 0.98, 1.0, 0.26)
const COLOR_DEBUG_ROUTE_EDGE := Color(0.90, 0.98, 1.0, 0.88)


func add_route_marker(parent: Node2D, item: Dictionary, tile_size: int, show_debug_overlay: bool, debug_renderer) -> Polygon2D:
	var marker := _rect_polygon(item, tile_size, COLOR_MARKER)
	marker.name = item.get("id", "Marker")
	marker.z_index = 4
	parent.add_child(marker)

	if show_debug_overlay:
		marker.color = COLOR_DEBUG_ROUTE
		var rect := _rect_from_item(item, tile_size)
		if debug_renderer != null:
			debug_renderer.add_rect_outline(parent, rect, "%sDebugOutline" % marker.name, COLOR_DEBUG_ROUTE_EDGE, 2.0, 21)
			debug_renderer.add_debug_label(parent, "ROUTE", rect.position + Vector2(6, 6), COLOR_DEBUG_ROUTE_EDGE)
	return marker


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
