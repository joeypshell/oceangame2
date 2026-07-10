extends RefCounted

const STATE_COLORS := {
	"locked": Color(0.28, 0.72, 0.76, 0.46),
	"available": Color(0.18, 0.96, 0.88, 0.92),
	"active": Color(1.0, 0.88, 0.36, 1.0),
	"pending": Color(1.0, 0.66, 0.24, 0.82),
	"completed": Color(0.52, 0.84, 0.82, 0.48),
}

var _targets: Array = []
var _nodes_by_id := {}


func build(parent: Node2D, source_targets: Array, tile_size: int, show_debug: bool) -> void:
	_targets = []
	_nodes_by_id = {}
	for source in source_targets:
		if typeof(source) != TYPE_DICTIONARY:
			continue
		var target: Dictionary = source.duplicate(true)
		var rect := _target_rect(target, tile_size)
		target["rect"] = rect
		target["center"] = rect.get_center()
		target["state"] = "locked"
		_targets.append(target)
		var target_id := str(target.get("id", "SurveyTarget"))
		var marker := _add_marker(parent, target_id, rect.get_center())
		_nodes_by_id[target_id] = marker
		if show_debug:
			_add_debug_outline(parent, target_id, rect)


func get_targets() -> Array:
	var values := []
	for target in _targets:
		values.append(target.duplicate(true))
	return values


func target_at(position: Vector2) -> Dictionary:
	for target in _targets:
		var rect: Rect2 = target.get("rect", Rect2())
		if rect.has_point(position):
			return target.duplicate(true)
	return {}


func set_target_state(target_id: String, state: String) -> void:
	var normalized := state if STATE_COLORS.has(state) else "locked"
	for target in _targets:
		if str(target.get("id", "")) == target_id:
			target["state"] = normalized
			break
	if _nodes_by_id.has(target_id):
		var marker := _nodes_by_id[target_id] as Node2D
		marker.modulate = STATE_COLORS[normalized]


func _add_marker(parent: Node2D, target_id: String, center: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = target_id
	root.position = center
	root.z_index = 15
	parent.add_child(root)

	var haze := Polygon2D.new()
	haze.name = "SurveyHaze"
	haze.polygon = _ellipse_points(34.0, 22.0, 24)
	haze.color = Color(0.18, 0.96, 0.88, 0.22)
	root.add_child(haze)
	var outer := Line2D.new()
	outer.name = "SurveyRing"
	outer.points = _closed_ellipse_points(30.0, 17.0, 24)
	outer.default_color = Color.WHITE
	outer.width = 3.0
	root.add_child(outer)
	var inner := Line2D.new()
	inner.name = "SurveyCore"
	inner.points = _closed_ellipse_points(12.0, 8.0, 20)
	inner.default_color = Color.WHITE
	inner.width = 2.0
	root.add_child(inner)
	var axis := Line2D.new()
	axis.name = "SurveyAxis"
	axis.points = PackedVector2Array([Vector2(-40, 0), Vector2(40, 0)])
	axis.default_color = Color(0.85, 1.0, 0.98, 0.7)
	axis.width = 2.0
	root.add_child(axis)
	root.modulate = STATE_COLORS["locked"]
	return root


func _add_debug_outline(parent: Node2D, target_id: String, rect: Rect2) -> void:
	var outline := Line2D.new()
	outline.name = "%sDebugOutline" % target_id
	outline.points = PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
		rect.position,
	])
	outline.default_color = Color(0.18, 0.96, 0.88, 0.72)
	outline.width = 3.0
	outline.z_index = 23
	parent.add_child(outline)
	var label := Label.new()
	label.name = "%sDebugLabel" % target_id
	label.text = "SURVEY"
	label.position = rect.position + Vector2(6, -20)
	label.add_theme_color_override("font_color", Color(0.78, 1.0, 0.96, 0.94))
	label.z_index = 24
	parent.add_child(label)


func _target_rect(target: Dictionary, tile_size: int) -> Rect2:
	return Rect2(
		Vector2(float(target.get("x", 0)), float(target.get("y", 0))) * tile_size,
		Vector2(float(target.get("w", 1)), float(target.get("h", 1))) * tile_size
	)


func _ellipse_points(radius_x: float, radius_y: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points


func _closed_ellipse_points(radius_x: float, radius_y: float, steps: int) -> PackedVector2Array:
	var points := _ellipse_points(radius_x, radius_y, steps)
	points.append(points[0])
	return points
