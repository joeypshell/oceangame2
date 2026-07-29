extends RefCounted

const COLOR_MARKER := Color(1.0, 1.0, 1.0, 0.10)
const COLOR_DEBUG_ROUTE := Color(0.90, 0.98, 1.0, 0.26)
const COLOR_DEBUG_ROUTE_EDGE := Color(0.90, 0.98, 1.0, 0.88)
const COLOR_RELAY := Color(0.32, 0.96, 1.0, 0.92)
const COLOR_RELAY_GLOW := Color(0.18, 0.88, 1.0, 0.16)
const COLOR_THRESHOLD := Color(1.0, 0.72, 0.24, 0.92)
const COLOR_THRESHOLD_FILL := Color(1.0, 0.55, 0.12, 0.10)


func add_route_marker(parent: Node2D, item: Dictionary, tile_size: int, show_debug_overlay: bool, debug_renderer) -> Polygon2D:
	var marker := _rect_polygon(item, tile_size, COLOR_MARKER)
	marker.name = item.get("id", "Marker")
	marker.z_index = 4
	parent.add_child(marker)
	if bool(item.get("route_guidance_marker", false)):
		marker.visible = false
		_add_guidance_affordance(marker, item, tile_size)

	if show_debug_overlay:
		marker.color = COLOR_DEBUG_ROUTE
		var rect := _rect_from_item(item, tile_size)
		if debug_renderer != null:
			debug_renderer.add_rect_outline(parent, rect, "%sDebugOutline" % marker.name, COLOR_DEBUG_ROUTE_EDGE, 2.0, 21)
			debug_renderer.add_debug_label(parent, "ROUTE", rect.position + Vector2(6, 6), COLOR_DEBUG_ROUTE_EDGE)
	return marker


func _add_guidance_affordance(marker: Polygon2D, item: Dictionary, tile_size: int) -> void:
	match str(item.get("guidance_kind", "")):
		"relay_beacon":
			marker.color = COLOR_RELAY_GLOW
			_add_relay_beacon(marker, _rect_size(item, tile_size) * 0.5)
		"oxygen_threshold":
			marker.color = COLOR_THRESHOLD_FILL
			_add_oxygen_threshold(marker, _rect_size(item, tile_size))


func _add_relay_beacon(parent: Node2D, center: Vector2) -> void:
	var stem := Line2D.new()
	stem.name = "RelayStem"
	stem.points = PackedVector2Array([center + Vector2(0, 18), center + Vector2(0, -12)])
	stem.default_color = COLOR_RELAY
	stem.width = 3.0
	parent.add_child(stem)

	var glow := Polygon2D.new()
	glow.name = "RelayGlow"
	glow.position = center + Vector2(0, -14)
	glow.color = COLOR_RELAY_GLOW
	glow.polygon = PackedVector2Array([
		Vector2(0, -22),
		Vector2(22, 0),
		Vector2(0, 22),
		Vector2(-22, 0),
	])
	parent.add_child(glow)

	var diamond := Line2D.new()
	diamond.name = "RelayDiamond"
	diamond.position = glow.position
	diamond.points = PackedVector2Array([
		Vector2(0, -12),
		Vector2(12, 0),
		Vector2(0, 12),
		Vector2(-12, 0),
		Vector2(0, -12),
	])
	diamond.default_color = COLOR_RELAY
	diamond.width = 3.0
	parent.add_child(diamond)

	var core := Polygon2D.new()
	core.name = "RelayCore"
	core.position = glow.position
	core.color = COLOR_RELAY
	core.polygon = PackedVector2Array([
		Vector2(0, -4),
		Vector2(4, 0),
		Vector2(0, 4),
		Vector2(-4, 0),
	])
	parent.add_child(core)


func _add_oxygen_threshold(parent: Node2D, size: Vector2) -> void:
	var frame := Line2D.new()
	frame.name = "OxygenThresholdFrame"
	frame.points = PackedVector2Array([
		Vector2(2, 2),
		Vector2(size.x - 2, 2),
		Vector2(size.x - 2, size.y - 2),
		Vector2(2, size.y - 2),
		Vector2(2, 2),
	])
	frame.default_color = COLOR_THRESHOLD
	frame.width = 3.0
	parent.add_child(frame)

	for index in range(3):
		var x := size.x * float(index + 1) / 4.0
		var center_y := size.y * 0.5
		var chevron := Line2D.new()
		chevron.name = "RetreatChevron%d" % (index + 1)
		chevron.points = PackedVector2Array([
			Vector2(x + 10, center_y - 12),
			Vector2(x - 2, center_y),
			Vector2(x + 10, center_y + 12),
		])
		chevron.default_color = COLOR_THRESHOLD
		chevron.width = 4.0
		parent.add_child(chevron)


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
