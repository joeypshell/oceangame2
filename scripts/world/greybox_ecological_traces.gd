extends RefCounted

const HIDDEN := "hidden"
const REVEALED := "revealed"
const IDENTIFIED := "identified"
const VALID_STATES := {HIDDEN: true, REVEALED: true, IDENTIFIED: true}

var _traces: Array[Dictionary] = []
var _nodes_by_id := {}


func build(
	parent: Node2D,
	source_traces: Array,
	source_hazards: Array,
	tile_size: int,
	show_debug: bool
) -> void:
	_traces = []
	_nodes_by_id = {}
	var hazards_by_id := _index_hazards(source_hazards)
	for value in source_traces:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var trace: Dictionary = (value as Dictionary).duplicate(true)
		trace["center"] = _center(trace, tile_size)
		trace["state"] = HIDDEN
		_traces.append(trace)
		var trace_id := str(trace.get("id", "EcologicalTrace"))
		_nodes_by_id[trace_id] = _add_trace_marker(parent, trace, hazards_by_id, tile_size)
		if show_debug:
			_add_debug_label(parent, trace)


func traces() -> Array:
	var values := []
	for trace in _traces:
		values.append(trace.duplicate(true))
	return values


func set_state(trace_id: String, state: String) -> bool:
	if not VALID_STATES.has(state):
		return false
	for index in range(_traces.size()):
		var trace: Dictionary = _traces[index]
		if str(trace.get("id", "")) != trace_id:
			continue
		trace["state"] = state
		_traces[index] = trace
		_apply_node_state(trace_id, state)
		return true
	return false


func report() -> Dictionary:
	var states := {}
	var revealed_ids := []
	for trace in _traces:
		var trace_id := str(trace.get("id", ""))
		var state := str(trace.get("state", HIDDEN))
		states[trace_id] = state
		if state in [REVEALED, IDENTIFIED]:
			revealed_ids.append(trace_id)
	return {"trace_count": _traces.size(), "states": states, "revealed_ids": revealed_ids}


func _add_trace_marker(
	parent: Node2D,
	trace: Dictionary,
	hazards_by_id: Dictionary,
	tile_size: int
) -> Node2D:
	var trace_id := str(trace.get("id", "EcologicalTrace"))
	var root := Node2D.new()
	root.name = trace_id
	root.position = trace.get("center", Vector2.ZERO)
	root.z_index = 16
	parent.add_child(root)

	var path_points := _linked_path(trace, hazards_by_id, tile_size)
	var path_shadow := Line2D.new()
	path_shadow.name = "MigrationPathShadow"
	path_shadow.points = path_points
	path_shadow.default_color = Color(0.04, 0.2, 0.24, 0.62)
	path_shadow.width = 6.0
	path_shadow.antialiased = true
	root.add_child(path_shadow)
	var path_line := Line2D.new()
	path_line.name = "MigrationPath"
	path_line.points = path_points
	path_line.default_color = Color(0.58, 0.98, 0.78, 0.92)
	path_line.width = 2.5
	path_line.antialiased = true
	root.add_child(path_line)

	for point in _path_motes(path_points):
		var mote := Polygon2D.new()
		mote.polygon = _ellipse_points(2.3, 2.3, 12)
		mote.position = point
		mote.color = Color(0.76, 1.0, 0.86, 0.92)
		root.add_child(mote)
	root.visible = false
	return root


func _index_hazards(source_hazards: Array) -> Dictionary:
	var indexed := {}
	for value in source_hazards:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var hazard := value as Dictionary
		var hazard_id := str(hazard.get("id", ""))
		if not hazard_id.is_empty():
			indexed[hazard_id] = hazard
	return indexed


func _linked_path(trace: Dictionary, hazards_by_id: Dictionary, tile_size: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var hazard_id := str(trace.get("moving_hazard_id", ""))
	var hazard: Dictionary = (hazards_by_id.get(hazard_id, {}) as Dictionary)
	var trace_center := _center(trace, tile_size)
	for value in hazard.get("path", []):
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var point := value as Dictionary
		points.append(Vector2(float(point.get("x", 0)) + 0.5, float(point.get("y", 0)) + 0.5) * tile_size - trace_center)
	return points


func _path_motes(path: PackedVector2Array) -> Array[Vector2]:
	var values: Array[Vector2] = []
	if path.size() < 2:
		return values
	for index in range(1, 5):
		var point := path[0].lerp(path[path.size() - 1], float(index) / 5.0)
		var offset := Vector2(0.0, -5.0 if index % 2 == 0 else 5.0)
		values.append(point + offset)
	return values


func _apply_node_state(trace_id: String, state: String) -> void:
	if not _nodes_by_id.has(trace_id):
		return
	var node := _nodes_by_id[trace_id] as Node2D
	node.visible = state in [REVEALED, IDENTIFIED]
	node.modulate = Color(0.78, 0.94, 1.0, 1.0) if state == IDENTIFIED else Color.WHITE


func _add_debug_label(parent: Node2D, trace: Dictionary) -> void:
	var label := Label.new()
	label.name = "%sDebugLabel" % str(trace.get("id", "EcologicalTrace"))
	label.text = "HIDDEN ECOLOGICAL TRACE"
	label.position = trace.get("center", Vector2.ZERO) + Vector2(22, -28)
	label.add_theme_color_override("font_color", Color(0.62, 1.0, 0.82, 0.9))
	label.z_index = 24
	parent.add_child(label)


func _center(trace: Dictionary, tile_size: int) -> Vector2:
	return Vector2(float(trace.get("x", 0)) + 0.5, float(trace.get("y", 0)) + 0.5) * tile_size


func _ellipse_points(radius_x: float, radius_y: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
