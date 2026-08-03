extends RefCounted

const CUTTER_BLUEPRINT_PRESENTATION_ID := "salvage_cutter_blueprint_case"
const WRECK_RELAY_PRESENTATION_ID := "northwest_wreck_relay_console"
const WEST_TRANSPONDER_PRESENTATION_ID := "western_chasm_navigation_transponder"
const ABYSS_TRANSPONDER_PRESENTATION_ID := "abyssal_shelf_navigation_transponder"
const STATE_COLORS := {
	"locked": Color(0.28, 0.72, 0.76, 0.46),
	"available": Color(0.18, 0.96, 0.88, 0.92),
	"active": Color(1.0, 0.88, 0.36, 1.0),
	"pending": Color(1.0, 0.66, 0.24, 0.82),
	"completed": Color(0.52, 0.84, 0.82, 0.48),
}

var _targets: Array = []
var _nodes_by_id := {}
var _completion_badges_by_id := {}


func build(parent: Node2D, source_targets: Array, tile_size: int, show_debug: bool) -> void:
	_targets = []
	_nodes_by_id = {}
	_completion_badges_by_id = {}
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
		if _is_navigation_transponder(target):
			_completion_badges_by_id[target_id] = _add_completed_badge(
				parent,
				target_id,
				target["scan_anchor_world"]
			)
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
		_set_transponder_signal_visible(marker, normalized != "completed")
	if _completion_badges_by_id.has(target_id):
		(_completion_badges_by_id[target_id] as Node2D).visible = normalized == "completed"


func _add_marker(parent: Node2D, target: Dictionary, center: Vector2) -> Node2D:
	var target_id := str(target.get("id", "SurveyTarget"))
	var root := Node2D.new()
	root.name = target_id
	root.position = center
	root.z_index = 15
	parent.add_child(root)
	match str(target.get("scan_presentation_id", "")):
		CUTTER_BLUEPRINT_PRESENTATION_ID:
			_add_salvage_cutter_blueprint_case(root)
		WRECK_RELAY_PRESENTATION_ID:
			_add_northwest_wreck_relay_console(root)
		WEST_TRANSPONDER_PRESENTATION_ID:
			_add_western_chasm_transponder(root)
		ABYSS_TRANSPONDER_PRESENTATION_ID:
			_add_abyssal_shelf_transponder(root)
	root.modulate = STATE_COLORS["locked"]
	return root


func _add_northwest_wreck_relay_console(root: Node2D) -> void:
	var shadow := Polygon2D.new()
	shadow.name = "RelayShadow"
	shadow.polygon = PackedVector2Array([
		Vector2(-28, -19), Vector2(25, -19), Vector2(29, -14),
		Vector2(29, 19), Vector2(-28, 19),
	])
	shadow.position = Vector2(3, 4)
	shadow.color = Color(0.01, 0.06, 0.08, 0.58)
	root.add_child(shadow)

	var body := Polygon2D.new()
	body.name = "RelayConsole"
	body.polygon = PackedVector2Array([
		Vector2(-28, -15), Vector2(-23, -20), Vector2(22, -20),
		Vector2(28, -14), Vector2(28, 18), Vector2(-28, 18),
	])
	body.color = Color(0.10, 0.23, 0.26, 1.0)
	root.add_child(body)

	var outline := Line2D.new()
	outline.name = "RelayFrame"
	outline.points = PackedVector2Array([
		Vector2(-28, -15), Vector2(-23, -20), Vector2(22, -20),
		Vector2(28, -14), Vector2(28, 18), Vector2(-28, 18),
		Vector2(-28, -15),
	])
	outline.default_color = Color(0.52, 0.74, 0.72, 1.0)
	outline.width = 2.0
	root.add_child(outline)

	var screen := Polygon2D.new()
	screen.name = "RelaySignalScreen"
	screen.polygon = PackedVector2Array([
		Vector2(-18, -11), Vector2(12, -11), Vector2(12, 7), Vector2(-18, 7),
	])
	screen.color = Color(0.04, 0.48, 0.53, 0.98)
	root.add_child(screen)

	var signal_trace := Line2D.new()
	signal_trace.name = "RelaySignalTrace"
	signal_trace.points = PackedVector2Array([
		Vector2(-14, 1), Vector2(-9, 1), Vector2(-6, -5),
		Vector2(-2, 5), Vector2(2, -2), Vector2(8, -2),
	])
	signal_trace.default_color = Color(1.0, 0.83, 0.28, 1.0)
	signal_trace.width = 2.0
	root.add_child(signal_trace)

	var antenna := Line2D.new()
	antenna.name = "RelayAntenna"
	antenna.points = PackedVector2Array([
		Vector2(15, -20), Vector2(15, -29), Vector2(22, -35),
	])
	antenna.default_color = Color(0.52, 0.74, 0.72, 1.0)
	antenna.width = 3.0
	root.add_child(antenna)

	var beacon := Polygon2D.new()
	beacon.name = "RelayBeacon"
	beacon.polygon = PackedVector2Array([
		Vector2(22, -40), Vector2(27, -35), Vector2(22, -30), Vector2(17, -35),
	])
	beacon.color = Color(1.0, 0.72, 0.24, 1.0)
	root.add_child(beacon)

	var feet := Line2D.new()
	feet.name = "RelayFeet"
	feet.points = PackedVector2Array([
		Vector2(-18, 18), Vector2(-18, 23), Vector2(-25, 23),
		Vector2(-18, 23), Vector2(18, 23), Vector2(18, 18),
		Vector2(18, 23), Vector2(25, 23),
	])
	feet.default_color = Color(0.26, 0.42, 0.43, 1.0)
	feet.width = 3.0
	root.add_child(feet)


func _add_western_chasm_transponder(root: Node2D) -> void:
	var shadow := Polygon2D.new()
	shadow.name = "WesternTransponderShadow"
	shadow.polygon = PackedVector2Array([
		Vector2(-34, -10), Vector2(17, -14), Vector2(31, -4),
		Vector2(22, 16), Vector2(-29, 14), Vector2(-38, 4),
	])
	shadow.position = Vector2(3, 4)
	shadow.color = Color(0.01, 0.06, 0.08, 0.58)
	root.add_child(shadow)

	var body := Polygon2D.new()
	body.name = "CurrentScouredTransponder"
	body.polygon = PackedVector2Array([
		Vector2(-34, -10), Vector2(17, -14), Vector2(31, -4),
		Vector2(22, 16), Vector2(-29, 14), Vector2(-38, 4),
	])
	body.color = Color(0.09, 0.28, 0.31, 1.0)
	root.add_child(body)

	var frame := Line2D.new()
	frame.name = "ScouredTransponderFrame"
	frame.points = PackedVector2Array([
		Vector2(-34, -10), Vector2(17, -14), Vector2(31, -4),
		Vector2(22, 16), Vector2(-29, 14), Vector2(-38, 4), Vector2(-34, -10),
	])
	frame.default_color = Color(0.48, 0.78, 0.75, 1.0)
	frame.width = 2.0
	root.add_child(frame)

	var coordinate_trace := Line2D.new()
	coordinate_trace.name = "WestCoordinateTrace"
	coordinate_trace.points = PackedVector2Array([
		Vector2(-23, 5), Vector2(-15, -4), Vector2(-7, 5),
		Vector2(1, -4), Vector2(10, 5), Vector2(18, -2),
	])
	coordinate_trace.default_color = Color(1.0, 0.82, 0.26, 1.0)
	coordinate_trace.width = 3.0
	root.add_child(coordinate_trace)

	var current_vane := Line2D.new()
	current_vane.name = "CurrentVane"
	current_vane.points = PackedVector2Array([
		Vector2(-34, -4), Vector2(-48, -4), Vector2(-57, -11),
		Vector2(-48, -4), Vector2(-57, 3),
	])
	current_vane.default_color = Color(0.39, 0.63, 0.64, 1.0)
	current_vane.width = 3.0
	root.add_child(current_vane)

	var beacon := Polygon2D.new()
	beacon.name = "WestCoordinateBeacon"
	beacon.polygon = PackedVector2Array([
		Vector2(22, -12), Vector2(29, -5), Vector2(22, 2), Vector2(15, -5),
	])
	beacon.color = Color(0.20, 0.94, 0.86, 1.0)
	root.add_child(beacon)


func _add_abyssal_shelf_transponder(root: Node2D) -> void:
	var shadow := Polygon2D.new()
	shadow.name = "AbyssalTransponderShadow"
	shadow.polygon = PackedVector2Array([
		Vector2(-18, -27), Vector2(15, -27), Vector2(28, -15), Vector2(28, 14),
		Vector2(16, 27), Vector2(-17, 27), Vector2(-29, 13), Vector2(-29, -14),
	])
	shadow.position = Vector2(3, 4)
	shadow.color = Color(0.01, 0.05, 0.09, 0.62)
	root.add_child(shadow)

	var body := Polygon2D.new()
	body.name = "PressureCrushedTransponder"
	body.polygon = shadow.polygon
	body.color = Color(0.12, 0.20, 0.34, 1.0)
	root.add_child(body)

	var pressure_ring := Line2D.new()
	pressure_ring.name = "PressureBrace"
	pressure_ring.points = PackedVector2Array([
		Vector2(-18, -27), Vector2(15, -27), Vector2(28, -15), Vector2(28, 14),
		Vector2(16, 27), Vector2(-17, 27), Vector2(-29, 13), Vector2(-29, -14), Vector2(-18, -27),
	])
	pressure_ring.default_color = Color(0.45, 0.70, 0.79, 1.0)
	pressure_ring.width = 3.0
	root.add_child(pressure_ring)

	var coordinate_core := Polygon2D.new()
	coordinate_core.name = "EastCoordinateCore"
	coordinate_core.polygon = PackedVector2Array([
		Vector2(0, -13), Vector2(13, 0), Vector2(0, 13), Vector2(-13, 0),
	])
	coordinate_core.color = Color(0.06, 0.62, 0.70, 1.0)
	root.add_child(coordinate_core)

	var coordinate_trace := Line2D.new()
	coordinate_trace.name = "EastCoordinateTrace"
	coordinate_trace.points = PackedVector2Array([
		Vector2(-9, 2), Vector2(-4, -5), Vector2(1, 5), Vector2(7, -4),
	])
	coordinate_trace.default_color = Color(1.0, 0.82, 0.26, 1.0)
	coordinate_trace.width = 3.0
	root.add_child(coordinate_trace)

	var crush_crack := Line2D.new()
	crush_crack.name = "PressureCrack"
	crush_crack.points = PackedVector2Array([
		Vector2(-20, -18), Vector2(-10, -8), Vector2(-15, 1), Vector2(-5, 10), Vector2(-9, 20),
	])
	crush_crack.default_color = Color(0.68, 0.86, 0.88, 0.82)
	crush_crack.width = 2.0
	root.add_child(crush_crack)


func _is_navigation_transponder(target: Dictionary) -> bool:
	return str(target.get("scan_presentation_id", "")) in [
		WEST_TRANSPONDER_PRESENTATION_ID,
		ABYSS_TRANSPONDER_PRESENTATION_ID,
	]


func _add_completed_badge(parent: Node2D, target_id: String, center: Vector2) -> Node2D:
	var badge := Node2D.new()
	badge.name = "%sCompletedBadge" % target_id
	badge.position = center + Vector2(0.0, -27.0)
	badge.z_index = 18
	badge.visible = false
	parent.add_child(badge)

	var back := Polygon2D.new()
	back.name = "ScanCompleteBack"
	back.polygon = _circle_points(12.0, 16)
	back.color = Color(0.02, 0.12, 0.15, 0.96)
	badge.add_child(back)
	var ring := Line2D.new()
	ring.name = "ScanCompleteRing"
	ring.points = _circle_points(10.0, 16, true)
	ring.default_color = Color(0.30, 1.0, 0.88, 1.0)
	ring.width = 2.5
	ring.antialiased = true
	badge.add_child(ring)
	var check := Line2D.new()
	check.name = "ScanCompleteCheck"
	check.points = PackedVector2Array([Vector2(-5, 0), Vector2(-1, 5), Vector2(7, -6)])
	check.default_color = Color(0.84, 1.0, 0.96, 1.0)
	check.width = 3.0
	check.antialiased = true
	badge.add_child(check)
	return badge


func _set_transponder_signal_visible(marker: Node2D, visible: bool) -> void:
	for node_name in ["WestCoordinateTrace", "WestCoordinateBeacon", "EastCoordinateTrace", "EastCoordinateCore"]:
		var signal_node := marker.get_node_or_null(node_name) as CanvasItem
		if signal_node != null:
			signal_node.visible = visible


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
	if typeof(anchor) != TYPE_DICTIONARY or anchor.is_empty():
		return fallback
	return Vector2(float(anchor.get("x", 0)) + 0.5, float(anchor.get("y", 0)) + 0.5) * tile_size


func _circle_points(radius: float, steps: int, close := false) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps + (1 if close else 0)):
		var angle := TAU * float(index % steps) / float(steps)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points
