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
		target["scan_anchor_world"] = _scan_anchor_world(target, tile_size, rect.get_center())
		target["state"] = "locked"
		_targets.append(target)
		var target_id := str(target.get("id", "SurveyTarget"))
		var marker := _add_marker(parent, target, target["scan_anchor_world"])
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


func _add_marker(parent: Node2D, target: Dictionary, center: Vector2) -> Node2D:
	var target_id := str(target.get("id", "SurveyTarget"))
	var root := Node2D.new()
	root.name = target_id
	root.position = center
	root.z_index = 15
	parent.add_child(root)
	if str(target.get("scan_presentation_id", "")) == "salvage_cutter_blueprint_case":
		_add_salvage_cutter_blueprint_case(root)
	else:
		_add_signal_marker(root)
	root.modulate = STATE_COLORS["locked"]
	return root


func _add_signal_marker(root: Node2D) -> void:
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


func _add_salvage_cutter_blueprint_case(root: Node2D) -> void:
	var shadow := Polygon2D.new()
	shadow.name = "ArtifactShadow"
	shadow.polygon = PackedVector2Array([
		Vector2(-23, -13), Vector2(23, -13), Vector2(23, 15), Vector2(-23, 15),
	])
	shadow.position = Vector2(3, 4)
	shadow.color = Color(0.02, 0.08, 0.11, 0.52)
	root.add_child(shadow)

	var body := Polygon2D.new()
	body.name = "MaintenanceCase"
	body.polygon = PackedVector2Array([
		Vector2(-24, -14), Vector2(24, -14), Vector2(24, 14), Vector2(-24, 14),
	])
	body.color = Color(0.18, 0.29, 0.32, 1.0)
	root.add_child(body)

	var outline := Line2D.new()
	outline.name = "CaseOutline"
	outline.points = PackedVector2Array([
		Vector2(-24, -14), Vector2(24, -14), Vector2(24, 14), Vector2(-24, 14), Vector2(-24, -14),
	])
	outline.default_color = Color(0.56, 0.72, 0.70, 1.0)
	outline.width = 2.0
	root.add_child(outline)

	var lid := Line2D.new()
	lid.name = "CaseLid"
	lid.points = PackedVector2Array([Vector2(-23, -4), Vector2(23, -4)])
	lid.default_color = Color(0.08, 0.17, 0.20, 1.0)
	lid.width = 3.0
	root.add_child(lid)

	var handle := Line2D.new()
	handle.name = "CaseHandle"
	handle.points = PackedVector2Array([Vector2(-8, -14), Vector2(-8, -19), Vector2(8, -19), Vector2(8, -14)])
	handle.default_color = Color(0.37, 0.51, 0.52, 1.0)
	handle.width = 3.0
	root.add_child(handle)

	var plan := Polygon2D.new()
	plan.name = "BlueprintPanel"
	plan.polygon = PackedVector2Array([
		Vector2(-13, 0), Vector2(13, 0), Vector2(13, 10), Vector2(-13, 10),
	])
	plan.color = Color(0.12, 0.69, 0.72, 0.96)
	root.add_child(plan)

	var schematic := Line2D.new()
	schematic.name = "CutterSchematic"
	schematic.points = PackedVector2Array([
		Vector2(-9, 7), Vector2(-3, 3), Vector2(5, 3), Vector2(10, 7),
	])
	schematic.default_color = Color(1.0, 0.82, 0.30, 1.0)
	schematic.width = 2.0
	root.add_child(schematic)


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


func _scan_anchor_world(target: Dictionary, tile_size: int, fallback: Vector2) -> Vector2:
	var anchor = target.get("scan_anchor", {})
	if typeof(anchor) != TYPE_DICTIONARY:
		return fallback
	return Vector2(float(anchor.get("x", 0)) + 0.5, float(anchor.get("y", 0)) + 0.5) * tile_size


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
