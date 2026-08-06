extends RefCounted

const AVAILABLE := "available"
const RELEASING := "releasing"
const PENDING := "pending"
const COMMITTED := "committed"
const VALID_STATES := {
	AVAILABLE: true,
	RELEASING: true,
	PENDING: true,
	COMMITTED: true,
}

var _rescues: Array[Dictionary] = []
var _nodes_by_id := {}


func build(parent: Node2D, source_rescues: Array, tile_size: int, show_debug: bool) -> void:
	_rescues = []
	_nodes_by_id = {}
	for value in source_rescues:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var rescue: Dictionary = (value as Dictionary).duplicate(true)
		rescue["center"] = _center(rescue, tile_size)
		rescue["state"] = AVAILABLE
		_rescues.append(rescue)
		var rescue_id := str(rescue.get("id", "CreatureRescue"))
		_nodes_by_id[rescue_id] = _add_rescue_marker(parent, rescue)
		if show_debug:
			_add_debug_label(parent, rescue)


func rescues() -> Array:
	var values := []
	for rescue in _rescues:
		values.append(rescue.duplicate(true))
	return values


func rescue_near(position: Vector2, radius_px: float) -> Dictionary:
	for rescue in _rescues:
		if str(rescue.get("state", AVAILABLE)) not in [AVAILABLE, RELEASING]:
			continue
		if position.distance_to(rescue.get("center", Vector2.ZERO)) <= radius_px:
			return rescue.duplicate(true)
	return {}


func set_state(rescue_id: String, state: String) -> bool:
	if not VALID_STATES.has(state):
		return false
	for index in range(_rescues.size()):
		var rescue: Dictionary = _rescues[index]
		if str(rescue.get("id", "")) != rescue_id:
			continue
		rescue["state"] = state
		_rescues[index] = rescue
		_apply_node_state(rescue_id, state)
		return true
	return false


func report() -> Dictionary:
	var states := {}
	for rescue in _rescues:
		states[str(rescue.get("id", ""))] = str(rescue.get("state", AVAILABLE))
	return {"rescue_count": _rescues.size(), "states": states}


func _add_rescue_marker(parent: Node2D, rescue: Dictionary) -> Node2D:
	var rescue_id := str(rescue.get("id", "CreatureRescue"))
	var root := Node2D.new()
	root.name = rescue_id
	root.position = rescue.get("center", Vector2.ZERO)
	root.z_index = 17
	parent.add_child(root)

	var glow := Polygon2D.new()
	glow.name = "JuvenileGlow"
	glow.polygon = _ellipse_points(31.0, 19.0, 24)
	glow.color = Color(0.10, 0.91, 0.91, 0.16)
	root.add_child(glow)

	var left_wing := Polygon2D.new()
	left_wing.name = "JuvenileLeftWing"
	left_wing.polygon = PackedVector2Array([
		Vector2(-4, -4), Vector2(-35, -14), Vector2(-24, 1), Vector2(-35, 15), Vector2(-4, 6),
	])
	left_wing.color = Color(0.10, 0.34, 0.42, 1.0)
	root.add_child(left_wing)

	var right_wing := Polygon2D.new()
	right_wing.name = "JuvenileRightWing"
	right_wing.polygon = PackedVector2Array([
		Vector2(4, -4), Vector2(34, -13), Vector2(24, 1), Vector2(34, 14), Vector2(4, 6),
	])
	right_wing.color = Color(0.10, 0.34, 0.42, 1.0)
	root.add_child(right_wing)

	var body := Polygon2D.new()
	body.name = "JuvenileBody"
	body.polygon = _ellipse_points(15.0, 9.0, 20)
	body.color = Color(0.21, 0.64, 0.68, 1.0)
	root.add_child(body)

	var core := Polygon2D.new()
	core.name = "JuvenileCore"
	core.polygon = _ellipse_points(6.0, 4.0, 16)
	core.position = Vector2(3, 0)
	core.color = Color(0.76, 1.0, 0.92, 1.0)
	root.add_child(core)

	var cable := Line2D.new()
	cable.name = "MaintenanceCable"
	cable.points = PackedVector2Array([
		Vector2(-39, -20), Vector2(-19, -8), Vector2(3, -15), Vector2(22, -5),
		Vector2(39, -17), Vector2(25, 3), Vector2(37, 19), Vector2(12, 11),
		Vector2(-8, 18), Vector2(-27, 7), Vector2(-40, 20),
	])
	cable.default_color = Color(1.0, 0.70, 0.24, 1.0)
	cable.width = 3.0
	cable.antialiased = true
	root.add_child(cable)

	var cutter_notch := Line2D.new()
	cutter_notch.name = "CutterNotch"
	cutter_notch.points = PackedVector2Array([Vector2(30, -10), Vector2(37, -3), Vector2(30, 4)])
	cutter_notch.default_color = Color(0.77, 1.0, 0.96, 1.0)
	cutter_notch.width = 2.0
	root.add_child(cutter_notch)
	return root


func _apply_node_state(rescue_id: String, state: String) -> void:
	if not _nodes_by_id.has(rescue_id):
		return
	var node := _nodes_by_id[rescue_id] as Node2D
	node.visible = state in [AVAILABLE, RELEASING]
	node.modulate = Color(1.0, 0.82, 0.42, 1.0) if state == RELEASING else Color.WHITE


func _add_debug_label(parent: Node2D, rescue: Dictionary) -> void:
	var label := Label.new()
	label.name = "%sDebugLabel" % str(rescue.get("id", "CreatureRescue"))
	label.text = "CREATURE RESCUE"
	label.position = rescue.get("center", Vector2.ZERO) + Vector2(20, -30)
	label.add_theme_color_override("font_color", Color(0.70, 1.0, 0.94, 0.96))
	label.z_index = 24
	parent.add_child(label)


func _center(rescue: Dictionary, tile_size: int) -> Vector2:
	return Vector2(float(rescue.get("x", 0)) + 0.5, float(rescue.get("y", 0)) + 0.5) * tile_size


func _ellipse_points(radius_x: float, radius_y: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
