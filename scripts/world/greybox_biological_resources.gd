extends RefCounted

const COLOR_BODY := Color(0.18, 0.54, 0.46, 1.0)
const COLOR_TIP := Color(0.66, 0.94, 0.52, 1.0)
const COLOR_GLOW := Color(0.74, 1.0, 0.66, 0.72)
const COLOR_HARVEST := Color(0.98, 0.88, 0.35, 0.94)
const COLOR_DEBUG := Color(0.72, 1.0, 0.45, 0.82)

var _sources: Array[Dictionary] = []
var _nodes_by_id := {}
var _states_by_id := {}


func build(parent: Node2D, sources: Array, hostiles: Array, tile_size: int, show_debug: bool) -> void:
	_sources = []
	_nodes_by_id = {}
	_states_by_id = {}
	var hostiles_by_id := {}
	for hostile in hostiles:
		if typeof(hostile) == TYPE_DICTIONARY:
			hostiles_by_id[str(hostile.get("id", ""))] = hostile
	for raw_source in sources:
		if typeof(raw_source) != TYPE_DICTIONARY:
			continue
		var source: Dictionary = raw_source.duplicate(true)
		var source_id := str(source.get("id", ""))
		if source_id.is_empty():
			continue
		var center := _initial_center(source, hostiles_by_id, tile_size)
		source["center"] = center
		_sources.append(source)
		var root := _add_passive_source(parent, source_id, center) if str(source.get("source_role", "")) == "passive_sample" else _add_hostile_harvest(parent, source_id, center)
		_nodes_by_id[source_id] = root
		set_state(source_id, center, "locked" if str(source.get("source_role", "")) == "passive_sample" else "hidden")
		if show_debug:
			_add_debug_marker(parent, source_id, center)


func sources() -> Array:
	var values := []
	for source in _sources:
		values.append(source.duplicate(true))
	return values


func set_state(source_id: String, center: Vector2, state: String) -> void:
	if not _nodes_by_id.has(source_id):
		return
	var root := _nodes_by_id[source_id] as Node2D
	if center != Vector2.INF:
		root.position = center
	var role := str(root.get_meta("source_role", ""))
	if role == "passive_sample":
		root.visible = true
		root.modulate = Color(0.55, 0.65, 0.62, 0.58) if state == "depleted" else Color(0.62, 0.72, 0.68, 0.76) if state == "locked" else Color.WHITE
		(root.get_node("SampleRing") as Line2D).visible = state == "available"
	else:
		root.visible = state == "available"
	_states_by_id[source_id] = state


func report() -> Dictionary:
	var ids := _nodes_by_id.keys()
	ids.sort()
	return {
		"rendered_ids": ids,
		"rendered_count": ids.size(),
		"states": _states_by_id.duplicate(true),
	}


func _initial_center(source: Dictionary, hostiles_by_id: Dictionary, tile_size: int) -> Vector2:
	if str(source.get("source_role", "")) == "passive_sample":
		return Vector2(float(source.get("x", 0)) + 0.5, float(source.get("y", 0)) + 0.5) * tile_size
	var hostile: Dictionary = hostiles_by_id.get(str(source.get("hostile_id", "")), {})
	return Vector2(float(hostile.get("x", 0)) + 0.5, float(hostile.get("y", 0)) + 0.5) * tile_size


func _add_passive_source(parent: Node2D, source_id: String, center: Vector2) -> Node2D:
	var root := _root(parent, source_id, center, "passive_sample")
	_add_polygon(root, "Base", PackedVector2Array([
		Vector2(-16, 12), Vector2(-12, -2), Vector2(-7, -10), Vector2(0, -5),
		Vector2(7, -11), Vector2(12, -2), Vector2(16, 12),
	]), COLOR_BODY)
	for offset in [-12.0, -6.0, 0.0, 6.0, 12.0]:
		var tendril := _add_line(root, "Tendril%s" % int(offset + 12.0), PackedVector2Array([
			Vector2(offset * 0.5, -4), Vector2(offset, -17), Vector2(offset * 0.7, -27),
		]), COLOR_TIP, 3.0)
		tendril.antialiased = true
	_add_polygon(root, "Glow", _circle_points(8.0, 18, Vector2(0, -4)), COLOR_GLOW)
	var ring_points := _circle_points(24.0, 30)
	ring_points.append(ring_points[0])
	var ring := _add_line(root, "SampleRing", ring_points, COLOR_GLOW, 2.0)
	ring.visible = false
	return root


func _add_hostile_harvest(parent: Node2D, source_id: String, center: Vector2) -> Node2D:
	var root := _root(parent, source_id, center, "hostile_harvest")
	var ring_points := _circle_points(24.0, 30)
	ring_points.append(ring_points[0])
	_add_line(root, "HarvestRing", ring_points, COLOR_HARVEST, 3.0)
	_add_polygon(root, "Component", PackedVector2Array([
		Vector2(0, -10), Vector2(9, 0), Vector2(0, 10), Vector2(-9, 0),
	]), COLOR_HARVEST)
	root.visible = false
	return root


func _root(parent: Node2D, source_id: String, center: Vector2, role: String) -> Node2D:
	var root := Node2D.new()
	root.name = source_id
	root.position = center
	root.z_index = 14
	root.set_meta("source_role", role)
	parent.add_child(root)
	return root


func _add_debug_marker(parent: Node2D, source_id: String, center: Vector2) -> void:
	var points := PackedVector2Array([
		center + Vector2(-18, -18), center + Vector2(18, -18), center + Vector2(18, 18),
		center + Vector2(-18, 18), center + Vector2(-18, -18),
	])
	var line := _add_line(parent, "%sDebug" % source_id, points, COLOR_DEBUG, 2.0)
	line.z_index = 23


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
