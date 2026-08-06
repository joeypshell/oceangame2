extends RefCounted

const HIDDEN := "hidden"
const REVEALED := "revealed"
const IDENTIFIED := "identified"
const VALID_STATES := {HIDDEN: true, REVEALED: true, IDENTIFIED: true}

var _traces: Array[Dictionary] = []
var _nodes_by_id := {}


func build(parent: Node2D, source_traces: Array, tile_size: int, show_debug: bool) -> void:
	_traces = []
	_nodes_by_id = {}
	for value in source_traces:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var trace: Dictionary = (value as Dictionary).duplicate(true)
		trace["center"] = _center(trace, tile_size)
		trace["state"] = HIDDEN
		_traces.append(trace)
		var trace_id := str(trace.get("id", "EcologicalTrace"))
		_nodes_by_id[trace_id] = _add_trace_marker(parent, trace)
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


func _add_trace_marker(parent: Node2D, trace: Dictionary) -> Node2D:
	var trace_id := str(trace.get("id", "EcologicalTrace"))
	var root := Node2D.new()
	root.name = trace_id
	root.position = trace.get("center", Vector2.ZERO)
	root.z_index = 16
	parent.add_child(root)

	var halo := Polygon2D.new()
	halo.name = "TraceHalo"
	halo.polygon = _ellipse_points(29.0, 18.0, 28)
	halo.color = Color(0.37, 0.92, 0.73, 0.12)
	root.add_child(halo)

	for index in range(3):
		var filament := Line2D.new()
		filament.name = "TraceFilament%d" % (index + 1)
		filament.points = _filament_points(index)
		filament.default_color = Color(0.58, 0.98, 0.78, 0.82 - float(index) * 0.12)
		filament.width = 2.0 - float(index) * 0.25
		filament.antialiased = true
		root.add_child(filament)

	for point in [Vector2(-13, -5), Vector2(4, -9), Vector2(16, 4), Vector2(-2, 10)]:
		var mote := Polygon2D.new()
		mote.polygon = _ellipse_points(2.3, 2.3, 12)
		mote.position = point
		mote.color = Color(0.76, 1.0, 0.86, 0.92)
		root.add_child(mote)
	root.visible = false
	return root


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


func _filament_points(index: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var phase := float(index) * 1.3
	for point_index in range(8):
		var x := -24.0 + float(point_index) * 7.0
		var y := sin(float(point_index) * 0.9 + phase) * (5.0 + float(index)) + float(index - 1) * 4.0
		points.append(Vector2(x, y))
	return points


func _ellipse_points(radius_x: float, radius_y: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(Vector2(cos(angle) * radius_x, sin(angle) * radius_y))
	return points
