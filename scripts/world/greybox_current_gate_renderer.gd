extends RefCounted

const COLOR_WASH := Color(0.18, 0.78, 0.88, 0.07)
const COLOR_BOUNDARY := Color(0.52, 0.92, 0.96, 0.34)
const COLOR_FLOW := Color(0.72, 0.96, 1.0, 0.72)
const RELAY_WASH := Color(1.0, 0.66, 0.16, 0.11)
const RELAY_BOUNDARY := Color(1.0, 0.78, 0.28, 0.72)
const RELAY_FLOW := Color(1.0, 0.91, 0.52, 0.96)
const ARROW_COUNT := 3


func add_current_affordance(parent: Node2D, item: Dictionary, tile_size: int) -> Node2D:
	var rect := _rect_from_item(item, tile_size)
	var direction := _direction_vector(str(item.get("current_direction", "")))
	var role := str(item.get("current_affordance_role", "barrier"))
	var colors := _colors_for_role(role)
	var root := Node2D.new()
	root.name = "%sCurrentAffordance" % str(item.get("id", "CurrentGate"))
	root.position = rect.get_center()
	root.z_index = 7
	root.set_meta("current_direction", str(item.get("current_direction", "")))
	root.set_meta("current_affordance_role", role)
	root.set_meta("required_capability_id", str(item.get("required_capability_id", "")))
	root.set_meta("source_rect", rect)
	parent.add_child(root)

	_add_wash(root, rect.size, colors["wash"])
	_add_boundaries(root, rect.size, direction, colors["boundary"])
	_add_flow_arrows(root, rect.size, direction, colors["flow"])
	_add_role_badge(root, rect.size, role, colors["flow"])
	return root


func _add_wash(parent: Node2D, size: Vector2, color: Color) -> void:
	var half := size * 0.5
	var wash := Polygon2D.new()
	wash.name = "CurrentWash"
	wash.color = color
	wash.polygon = PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])
	parent.add_child(wash)


func _add_boundaries(parent: Node2D, size: Vector2, direction: Vector2, color: Color) -> void:
	var half := size * 0.5
	if absf(direction.x) >= absf(direction.y):
		_add_line(parent, "CurrentBoundaryA", [Vector2(-half.x, -half.y), Vector2(-half.x, half.y)], color, 2.0)
		_add_line(parent, "CurrentBoundaryB", [Vector2(half.x, -half.y), Vector2(half.x, half.y)], color, 2.0)
	else:
		_add_line(parent, "CurrentBoundaryA", [Vector2(-half.x, -half.y), Vector2(half.x, -half.y)], color, 2.0)
		_add_line(parent, "CurrentBoundaryB", [Vector2(-half.x, half.y), Vector2(half.x, half.y)], color, 2.0)


func _add_flow_arrows(parent: Node2D, size: Vector2, direction: Vector2, color: Color) -> void:
	if direction == Vector2.ZERO:
		return
	var perpendicular := Vector2(-direction.y, direction.x)
	var cross_span := size.y if absf(direction.x) > 0.0 else size.x
	var flow_span := size.x if absf(direction.x) > 0.0 else size.y
	var half_length := minf(18.0, flow_span * 0.28)
	for index in ARROW_COUNT:
		var cross_offset := (float(index) - 1.0) * cross_span * 0.27
		var offset := perpendicular * cross_offset
		var tail := offset - direction * half_length
		var tip := offset + direction * half_length
		var wing_center := tip - direction * 7.0
		_add_line(parent, "CurrentArrow%dShaft" % index, [tail, tip], color, 2.5)
		_add_line(
			parent,
			"CurrentArrow%dHead" % index,
			[wing_center + perpendicular * 5.0, tip, wing_center - perpendicular * 5.0],
			color,
			2.5
		)


func _add_role_badge(parent: Node2D, size: Vector2, role: String, color: Color) -> void:
	if role != "relay":
		return
	var top := -size.y * 0.5
	var badge_center := Vector2(0.0, top - 10.0)
	_add_line(parent, "RelayBeaconStem", [Vector2(0.0, top + 8.0), badge_center], color, 3.0)
	_add_line(parent, "RelayBeacon", [
		badge_center + Vector2(0.0, -9.0),
		badge_center + Vector2(9.0, 0.0),
		badge_center + Vector2(0.0, 9.0),
		badge_center + Vector2(-9.0, 0.0),
		badge_center + Vector2(0.0, -9.0),
	], color, 3.0)


func _colors_for_role(role: String) -> Dictionary:
	if role == "relay":
		return {"wash": RELAY_WASH, "boundary": RELAY_BOUNDARY, "flow": RELAY_FLOW}
	return {"wash": COLOR_WASH, "boundary": COLOR_BOUNDARY, "flow": COLOR_FLOW}


func _add_line(parent: Node2D, line_name: String, points: Array, color: Color, width: float) -> void:
	var line := Line2D.new()
	line.name = line_name
	line.points = PackedVector2Array(points)
	line.default_color = color
	line.width = width
	line.antialiased = true
	parent.add_child(line)


func _direction_vector(direction: String) -> Vector2:
	match direction:
		"left":
			return Vector2.LEFT
		"right":
			return Vector2.RIGHT
		"up":
			return Vector2.UP
		"down":
			return Vector2.DOWN
	return Vector2.ZERO


func _rect_from_item(item: Dictionary, tile_size: int) -> Rect2:
	return Rect2(
		Vector2(float(item["x"]) * tile_size, float(item["y"]) * tile_size),
		Vector2(float(item["w"]) * tile_size, float(item["h"]) * tile_size)
	)
