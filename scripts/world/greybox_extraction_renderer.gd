extends RefCounted

const COLOR_BASE := Color(0.95, 0.78, 0.48, 0.92)
const COLOR_BOAT := Color(0.96, 0.66, 0.20, 0.92)
const COLOR_BOAT_DARK := Color(0.22, 0.16, 0.10, 1.0)
const COLOR_BOAT_LIGHT := Color(1.0, 0.86, 0.40, 1.0)
const COLOR_BOAT_GLASS := Color(0.36, 0.91, 0.96, 0.88)
const COLOR_RELAY_BODY := Color(0.18, 0.31, 0.36, 1.0)
const COLOR_RELAY_DARK := Color(0.08, 0.17, 0.21, 1.0)
const COLOR_RELAY_LIGHT := Color(0.96, 0.86, 0.48, 1.0)
const COLOR_RELAY_GLASS := Color(0.28, 0.92, 0.98, 0.92)


func add_relay_extraction_prop(parent: Node2D, marker_name: String, rect: Rect2) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.position = rect.position
	root.z_index = 6
	parent.add_child(root)

	var field := _add_local_polygon(root, "RelayReturnField", _rect_points(rect.size), Color(1.0, 0.92, 0.52, 0.13))
	field.position = rect.size * 0.5
	field.z_index = 0

	var field_edge := _add_local_line(root, "RelayReturnFieldEdge", _rect_outline_points(rect.size), Color(1.0, 0.92, 0.52, 0.42), 2.0)
	field_edge.z_index = 1

	var center := rect.size * 0.5
	var dock_size := Vector2(minf(rect.size.x * 0.72, 188.0), minf(rect.size.y * 0.20, 34.0))
	var dock := _add_local_polygon(root, "RelayDock", _rect_points(dock_size), Color(0.10, 0.22, 0.26, 0.82))
	dock.position = center + Vector2(0, rect.size.y * 0.22)
	dock.z_index = 2

	var dock_edge := _add_local_line(root, "RelayDockEdge", _closed_rect_points(dock_size), Color(0.55, 0.76, 0.78, 0.72), 2.0)
	dock_edge.position = dock.position
	dock_edge.z_index = 3

	var hull_size := Vector2(minf(rect.size.x * 0.46, 132.0), minf(rect.size.y * 0.34, 52.0))
	var hull_center := center + Vector2(0, -rect.size.y * 0.05)
	var glow := _add_local_polygon(root, "RelayGlow", _ellipse_points(hull_size.x * 0.72, hull_size.y * 0.78, 24), Color(0.28, 0.92, 0.98, 0.20))
	glow.position = hull_center
	glow.z_index = 2

	var tail := _add_local_polygon(root, "RelayTailFin", PackedVector2Array([
		hull_center + Vector2(-hull_size.x * 0.42, -hull_size.y * 0.18),
		hull_center + Vector2(-hull_size.x * 0.72, 0),
		hull_center + Vector2(-hull_size.x * 0.42, hull_size.y * 0.18),
	]), COLOR_RELAY_DARK)
	tail.z_index = 4

	var body_shadow := _add_local_polygon(root, "RelayBodyShadow", _ellipse_points(hull_size.x * 0.52, hull_size.y * 0.42, 24), COLOR_RELAY_DARK)
	body_shadow.position = hull_center + Vector2(4, 4)
	body_shadow.z_index = 3

	var body := _add_local_polygon(root, "RelayBody", _ellipse_points(hull_size.x * 0.50, hull_size.y * 0.40, 24), COLOR_RELAY_BODY)
	body.position = hull_center
	body.z_index = 5

	var window := _add_local_polygon(root, "RelayWindow", _ellipse_points(hull_size.x * 0.16, hull_size.y * 0.22, 16), COLOR_RELAY_GLASS)
	window.position = hull_center + Vector2(hull_size.x * 0.20, -hull_size.y * 0.02)
	window.z_index = 6

	var beacon := _add_local_line(root, "RelayBeacon", PackedVector2Array([
		hull_center + Vector2(0, -hull_size.y * 0.70),
		hull_center + Vector2(0, -hull_size.y * 1.15),
	]), COLOR_RELAY_LIGHT, 3.0)
	beacon.z_index = 6

	var beacon_light := _add_local_polygon(root, "RelayBeaconLight", _circle_points(7.0, 12), COLOR_RELAY_LIGHT)
	beacon_light.position = hull_center + Vector2(0, -hull_size.y * 1.18)
	beacon_light.z_index = 7
	return root


func add_relay_spawn_cue(parent: Node2D, marker_name: String, center: Vector2) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.position = center
	root.z_index = 10
	parent.add_child(root)

	var glow := _add_local_polygon(root, "RelayEntryGlow", _circle_points(30.0, 18), Color(0.28, 0.92, 0.98, 0.18))
	glow.z_index = 0

	var ring := _add_local_line(root, "RelayEntryRing", PackedVector2Array([
		Vector2(0, -18),
		Vector2(18, 0),
		Vector2(0, 18),
		Vector2(-18, 0),
		Vector2(0, -18),
	]), COLOR_RELAY_GLASS, 2.0)
	ring.z_index = 1

	var chevron := _add_local_polygon(root, "RelayEntryChevron", PackedVector2Array([
		Vector2(-6, -10),
		Vector2(10, 0),
		Vector2(-6, 10),
		Vector2(-1, 0),
	]), COLOR_RELAY_LIGHT)
	chevron.z_index = 2
	return root


func add_boat_marker(parent: Node2D, marker_name: String, rect: Rect2, entry_local: Vector2, asset_lookup) -> Node2D:
	var root := Node2D.new()
	root.name = marker_name
	root.position = rect.position
	root.z_index = 7
	parent.add_child(root)

	var return_field := _add_local_polygon(root, "ExtractionField", _rect_points(rect.size), Color(1.0, 0.92, 0.68, 0.16))
	return_field.position = rect.size * 0.5
	return_field.z_index = 0

	if not _add_boat_sprite(root, rect, asset_lookup):
		_add_procedural_boat_body(root, rect, entry_local)

	var hatch := _add_local_polygon(root, "EntryHatch", _rect_points(Vector2(30, 10)), COLOR_BASE)
	hatch.position = Vector2(entry_local.x, rect.size.y * 0.38)
	hatch.z_index = 5

	var tether_bottom := rect.size.y * 3.8
	var entry_glow := _add_local_line(root, "EntryGlow", PackedVector2Array([
		Vector2(entry_local.x, rect.size.y * 0.46),
		Vector2(entry_local.x, tether_bottom),
	]), Color(1.0, 0.92, 0.52, 0.30), 16.0)
	entry_glow.z_index = 3

	var tether_left := entry_local.x - 6.0
	var tether_right := entry_local.x + 6.0
	var entry_tether_left := _add_local_line(root, "EntryTetherLeft", PackedVector2Array([
		Vector2(tether_left, rect.size.y * 0.46),
		Vector2(tether_left, tether_bottom),
	]), COLOR_BASE, 2.0)
	entry_tether_left.z_index = 5

	var entry_tether_right := _add_local_line(root, "EntryTetherRight", PackedVector2Array([
		Vector2(tether_right, rect.size.y * 0.46),
		Vector2(tether_right, tether_bottom),
	]), COLOR_BASE, 3.0)
	entry_tether_right.z_index = 5

	for rung_index in range(1, 7):
		var rung_y := rect.size.y * 0.55 + float(rung_index) * 14.0
		if rung_y >= tether_bottom:
			break
		var rung := _add_local_line(root, "EntryTetherRung%s" % rung_index, PackedVector2Array([
			Vector2(tether_left, rung_y),
			Vector2(tether_right, rung_y),
		]), COLOR_BOAT_LIGHT, 2.0)
		rung.z_index = 6
	return root


func _add_boat_sprite(root: Node2D, rect: Rect2, asset_lookup) -> bool:
	if asset_lookup == null:
		return false

	var texture: Texture2D = asset_lookup.load_png_texture(asset_lookup.boat_spawn_texture_path())
	if texture == null:
		return false

	var texture_size: Vector2 = texture.get_size()
	if texture_size == Vector2.ZERO:
		return false

	var sprite := Sprite2D.new()
	sprite.name = "BoatSprite"
	sprite.texture = texture
	sprite.centered = true
	sprite.position = Vector2(rect.size.x * 0.5, rect.size.y * 0.58)
	sprite.scale = Vector2(rect.size.x / texture_size.x, (rect.size.y * 1.46) / texture_size.y)
	sprite.z_index = 2
	root.add_child(sprite)
	return true


func _add_procedural_boat_body(root: Node2D, rect: Rect2, entry_local: Vector2) -> void:
	var hull_shadow := _add_local_polygon(root, "HullShadow", PackedVector2Array([
		Vector2(rect.size.x * 0.05, rect.size.y * 0.36),
		Vector2(rect.size.x * 0.95, rect.size.y * 0.36),
		Vector2(rect.size.x * 0.82, rect.size.y * 1.24),
		Vector2(rect.size.x * 0.18, rect.size.y * 1.24),
	]), COLOR_BOAT_DARK)
	hull_shadow.z_index = 1

	var hull := _add_local_polygon(root, "Hull", PackedVector2Array([
		Vector2(rect.size.x * 0.02, rect.size.y * 0.16),
		Vector2(rect.size.x * 0.98, rect.size.y * 0.16),
		Vector2(rect.size.x * 0.84, rect.size.y * 1.04),
		Vector2(rect.size.x * 0.16, rect.size.y * 1.04),
	]), COLOR_BOAT)
	hull.z_index = 2

	var rim := _add_local_line(root, "DeckRim", PackedVector2Array([
		Vector2(rect.size.x * 0.08, rect.size.y * 0.20),
		Vector2(rect.size.x * 0.92, rect.size.y * 0.20),
	]), COLOR_BOAT_LIGHT, 3.0)
	rim.z_index = 4

	var cabin_width := minf(rect.size.x * 0.30, 72.0)
	var cabin_center_x := clampf(entry_local.x + 58.0, cabin_width * 0.5 + 8.0, rect.size.x - cabin_width * 0.5 - 8.0)
	var cabin := _add_local_polygon(root, "Cabin", _rect_points(Vector2(cabin_width, rect.size.y * 0.54)), Color(0.90, 0.79, 0.57, 0.96))
	cabin.position = Vector2(cabin_center_x, rect.size.y * 0.36)
	cabin.z_index = 3

	var cabin_window := _add_local_polygon(root, "CabinWindow", _rect_points(Vector2(cabin_width * 0.45, rect.size.y * 0.20)), COLOR_BOAT_GLASS)
	cabin_window.position = cabin.position + Vector2(0, -rect.size.y * 0.02)
	cabin_window.z_index = 4


func _add_local_polygon(parent: Node2D, polygon_name: String, points: PackedVector2Array, color: Color) -> Polygon2D:
	var poly := Polygon2D.new()
	poly.name = polygon_name
	poly.color = color
	poly.polygon = points
	parent.add_child(poly)
	return poly


func _add_local_line(parent: Node2D, line_name: String, points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.name = line_name
	line.points = points
	line.default_color = color
	line.width = width
	parent.add_child(line)
	return line


func _rect_points(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array([
		Vector2(-half.x, -half.y),
		Vector2(half.x, -half.y),
		Vector2(half.x, half.y),
		Vector2(-half.x, half.y),
	])


func _closed_rect_points(size: Vector2) -> PackedVector2Array:
	var points := _rect_points(size)
	points.append(points[0])
	return points


func _rect_outline_points(size: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		Vector2.ZERO,
		Vector2(size.x, 0),
		size,
		Vector2(0, size.y),
		Vector2.ZERO,
	])


func _circle_points(radius: float, steps: int, offset := Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(offset + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _ellipse_points(radius_x: float, radius_y: float, steps: int, offset := Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(offset + Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
