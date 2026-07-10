extends RefCounted

var _targets: Array[Dictionary] = []
var _nodes_by_id := {}
var _collected_ids := {}


func build(parent: Node2D, entities: Array, tile_size: int, show_debug: bool, prop_renderer, asset_lookup) -> void:
	_targets = []
	_nodes_by_id = {}
	_collected_ids = {}
	for value in entities:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var source := value as Dictionary
		if str(source.get("type", "")) != "tool_target":
			continue
		var target: Dictionary = source.duplicate(true)
		target["center"] = _center(target, tile_size)
		_targets.append(target)
		var target_id := str(target.get("id", "ToolTarget"))
		var node: Node2D = prop_renderer.add_salvage_prop(
			parent,
			target_id,
			target["center"],
			str(target.get("kind", "crate")),
			str(target.get("tier", "valuable")),
			str(target.get("interaction", "cutter_salvage")),
			asset_lookup
		)
		_nodes_by_id[target_id] = node
		if show_debug:
			_add_debug_label(parent, target)


func targets() -> Array:
	var values := []
	for target in _targets:
		values.append(target.duplicate(true))
	return values


func target_near(position: Vector2, radius_px: float) -> Dictionary:
	for target in _targets:
		var target_id := str(target.get("id", ""))
		if is_collected(target_id):
			continue
		if position.distance_to(target.get("center", Vector2.ZERO)) <= radius_px:
			return target.duplicate(true)
	return {}


func target_by_id(target_id: String) -> Dictionary:
	for target in _targets:
		if str(target.get("id", "")) == target_id:
			return target.duplicate(true)
	return {}


func collect(target_id: String) -> bool:
	if target_by_id(target_id).is_empty() or is_collected(target_id):
		return false
	_collected_ids[target_id] = true
	_set_visible(target_id, false)
	return true


func restore(target_id: String) -> void:
	if target_by_id(target_id).is_empty():
		return
	_collected_ids.erase(target_id)
	_set_visible(target_id, true)


func reset() -> void:
	_collected_ids = {}
	for target_id in _nodes_by_id:
		_set_visible(str(target_id), true)


func is_collected(target_id: String) -> bool:
	return bool(_collected_ids.get(target_id, false))


func report() -> Dictionary:
	var collected := _collected_ids.keys()
	collected.sort()
	return {"target_count": _targets.size(), "collected_ids": collected}


func _set_visible(target_id: String, visible: bool) -> void:
	if _nodes_by_id.has(target_id):
		(_nodes_by_id[target_id] as Node2D).visible = visible


func _center(target: Dictionary, tile_size: int) -> Vector2:
	return Vector2(float(target.get("x", 0)) + 0.5, float(target.get("y", 0)) + 0.5) * tile_size


func _add_debug_label(parent: Node2D, target: Dictionary) -> void:
	var label := Label.new()
	label.name = "%sDebugLabel" % str(target.get("id", "ToolTarget"))
	label.text = "CUTTER TARGET"
	label.position = target.get("center", Vector2.ZERO) + Vector2(18, -22)
	label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.38, 0.94))
	label.z_index = 24
	parent.add_child(label)
