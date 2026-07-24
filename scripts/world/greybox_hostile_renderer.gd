extends RefCounted

const COLOR_BODY := Color(0.08, 0.24, 0.28, 1.0)
const COLOR_BELLY := Color(0.18, 0.56, 0.58, 1.0)
const COLOR_FIN := Color(0.96, 0.36, 0.30, 1.0)
const COLOR_EYE := Color(1.0, 0.90, 0.38, 1.0)
const COLOR_WARNING := Color(1.0, 0.62, 0.24, 0.82)
const COLOR_LUNGE := Color(1.0, 0.24, 0.28, 0.94)
const COLOR_DEBUG := Color(1.0, 0.44, 0.30, 0.58)
const COLOR_HEALTH_BACK := Color(0.02, 0.08, 0.10, 0.90)
const COLOR_HEALTH_FILL := Color(0.20, 0.88, 0.62, 1.0)
const COLOR_HEALTH_LOW := Color(1.0, 0.38, 0.25, 1.0)
const DEFEAT_LINGER_SECONDS := 0.24

var _nodes_by_id := {}


func build(parent: Node2D, encounters: Array, tile_size: int, show_debug: bool) -> void:
	_nodes_by_id = {}
	for encounter in encounters:
		if typeof(encounter) != TYPE_DICTIONARY:
			continue
		var hostile_id := str(encounter.get("id", "hostile"))
		var warning_radius := float(encounter.get("warning_radius_tiles", 4.0)) * float(tile_size)
		var root := _add_eel(
			parent,
			hostile_id,
			_point_center(encounter, tile_size),
			warning_radius,
			int(encounter.get("health", 3))
		)
		_nodes_by_id[hostile_id] = root
		if show_debug:
			_add_territory_outline(parent, hostile_id, encounter.get("territory", {}), tile_size)


func set_state(hostile_id: String, center: Vector2, phase: String, health: int) -> void:
	if not _nodes_by_id.has(hostile_id):
		return
	var root := _nodes_by_id[hostile_id] as Node2D
	if phase in ["lunge", "returning"] and absf(center.x - root.position.x) > 0.1:
		root.scale.x = 1.0 if center.x > root.position.x else -1.0
	root.position = center
	var defeat_timer := root.get_node("DefeatTimer") as Timer
	if phase == "defeated" and bool(root.get_meta("defeat_linger_complete", false)):
		root.visible = false
		return
	root.visible = true
	if phase != "defeated":
		root.set_meta("defeat_linger_complete", false)
		defeat_timer.stop()
	var warning_ring := root.get_node("WarningRing") as Line2D
	var attack_streak := root.get_node("AttackStreak") as Line2D
	var health_bar := root.get_node("HealthBar") as Node2D
	var max_health := maxi(1, int(root.get_meta("max_health", 3)))
	var health_ratio := clampf(float(health) / float(max_health), 0.0, 1.0)
	health_bar.visible = phase in ["warning", "lunge", "recovery", "defeated"] or health < max_health
	health_bar.scale.x = root.scale.x
	_set_health_fill(health_bar.get_node("Fill") as Polygon2D, health, max_health)
	warning_ring.visible = phase in ["warning", "lunge"]
	warning_ring.default_color = COLOR_LUNGE if phase == "lunge" else COLOR_WARNING
	attack_streak.visible = phase == "lunge"
	root.modulate = Color(1.0, 0.72, 0.72, 1.0) if health == 1 else Color.WHITE
	if phase == "defeated" and defeat_timer.is_stopped():
		defeat_timer.start()


func report() -> Dictionary:
	var health_bars := {}
	for hostile_id in _nodes_by_id:
		var root := _nodes_by_id[hostile_id] as Node2D
		var health_bar := root.get_node("HealthBar") as Node2D
		health_bars[hostile_id] = {
			"visible": health_bar.visible,
			"root_visible": root.visible,
			"health": int(health_bar.get_meta("health", 0)),
			"max_health": int(root.get_meta("max_health", 0)),
			"defeat_linger_complete": bool(root.get_meta("defeat_linger_complete", false)),
		}
	return {
		"rendered_ids": _nodes_by_id.keys(),
		"rendered_count": _nodes_by_id.size(),
		"health_bars": health_bars,
	}


func _add_eel(
	parent: Node2D,
	hostile_id: String,
	center: Vector2,
	warning_radius: float,
	max_health: int
) -> Node2D:
	var root := Node2D.new()
	root.name = hostile_id
	root.position = center
	root.z_index = 13
	root.set_meta("max_health", maxi(1, max_health))
	root.set_meta("defeat_linger_complete", false)
	parent.add_child(root)

	_add_polygon(root, "Body", PackedVector2Array([
		Vector2(-28, 0), Vector2(-17, -10), Vector2(4, -12),
		Vector2(24, -5), Vector2(31, 0), Vector2(22, 6),
		Vector2(2, 11), Vector2(-18, 8),
	]), COLOR_BODY)
	_add_polygon(root, "Belly", PackedVector2Array([
		Vector2(-18, 2), Vector2(4, -5), Vector2(22, -1),
		Vector2(7, 6), Vector2(-12, 7),
	]), COLOR_BELLY)
	_add_polygon(root, "Tail", PackedVector2Array([
		Vector2(-25, 0), Vector2(-38, -12), Vector2(-34, 1), Vector2(-39, 13),
	]), COLOR_FIN)
	_add_polygon(root, "Fin", PackedVector2Array([
		Vector2(-1, -8), Vector2(8, -20), Vector2(13, -7),
	]), COLOR_FIN)
	_add_polygon(root, "Eye", _circle_points(3.0, 10, Vector2(20, -4)), COLOR_EYE)

	var warning_points := _circle_points(warning_radius, 48)
	warning_points.append(warning_points[0])
	var warning_ring := _add_line(root, "WarningRing", warning_points, COLOR_WARNING, 2.0)
	warning_ring.visible = false
	var attack_streak := _add_line(root, "AttackStreak", PackedVector2Array([
		Vector2(-46, -8), Vector2(-31, 0), Vector2(-46, 8),
	]), COLOR_LUNGE, 3.0)
	attack_streak.visible = false
	_add_health_bar(root, maxi(1, max_health))
	_add_defeat_timer(root)
	return root


func _add_health_bar(root: Node2D, max_health: int) -> void:
	var bar := Node2D.new()
	bar.name = "HealthBar"
	bar.position = Vector2(0.0, -30.0)
	bar.visible = false
	bar.set_meta("health", max_health)
	root.add_child(bar)
	_add_polygon(bar, "Back", PackedVector2Array([
		Vector2(-24, -4), Vector2(24, -4), Vector2(24, 4), Vector2(-24, 4),
	]), COLOR_HEALTH_BACK)
	_add_polygon(bar, "Fill", PackedVector2Array(), COLOR_HEALTH_FILL)
	_set_health_fill(bar.get_node("Fill") as Polygon2D, max_health, max_health)


func _set_health_fill(fill: Polygon2D, health: int, max_health: int) -> void:
	var clamped := clampf(float(health) / float(maxi(1, max_health)), 0.0, 1.0)
	var right_edge := lerpf(-21.0, 21.0, clamped)
	fill.polygon = PackedVector2Array([
		Vector2(-21, -2), Vector2(right_edge, -2),
		Vector2(right_edge, 2), Vector2(-21, 2),
	])
	fill.color = COLOR_HEALTH_LOW if clamped <= 0.34 else COLOR_HEALTH_FILL
	var bar := fill.get_parent() as Node2D
	bar.set_meta("health", maxi(0, health))


func _add_defeat_timer(root: Node2D) -> void:
	var timer := Timer.new()
	timer.name = "DefeatTimer"
	timer.one_shot = true
	timer.wait_time = DEFEAT_LINGER_SECONDS
	timer.timeout.connect(Callable(self, "_finish_defeat_linger").bind(root))
	root.add_child(timer)


func _finish_defeat_linger(root: Node2D) -> void:
	if not is_instance_valid(root):
		return
	root.set_meta("defeat_linger_complete", true)
	root.visible = false


func _add_territory_outline(parent: Node2D, hostile_id: String, territory, tile_size: int) -> void:
	if typeof(territory) != TYPE_DICTIONARY:
		return
	var rect := Rect2(
		Vector2(float(territory.get("x", 0)), float(territory.get("y", 0))) * tile_size,
		Vector2(float(territory.get("w", 0)), float(territory.get("h", 0))) * tile_size
	)
	var line := _add_line(parent, "%sTerritory" % hostile_id, PackedVector2Array([
		rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
		Vector2(rect.position.x, rect.end.y), rect.position,
	]), COLOR_DEBUG, 2.0)
	line.z_index = 22


func _point_center(item: Dictionary, tile_size: int) -> Vector2:
	return Vector2(float(item.get("x", 0)) + 0.5, float(item.get("y", 0)) + 0.5) * tile_size


func _add_polygon(parent: Node2D, node_name: String, points: PackedVector2Array, color: Color) -> Polygon2D:
	var polygon := Polygon2D.new()
	polygon.name = node_name
	polygon.polygon = points
	polygon.color = color
	parent.add_child(polygon)
	return polygon


func _add_line(parent: Node2D, node_name: String, points: PackedVector2Array, color: Color, width: float) -> Line2D:
	var line := Line2D.new()
	line.name = node_name
	line.points = points
	line.default_color = color
	line.width = width
	parent.add_child(line)
	return line


func _circle_points(radius: float, steps: int, offset := Vector2.ZERO) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(offset + Vector2(cos(angle), sin(angle)) * radius)
	return points
