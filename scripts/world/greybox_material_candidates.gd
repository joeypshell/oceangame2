extends RefCounted

const MATERIAL_COLORS := {
	"titanium_scrap": Color(0.68, 0.90, 0.94, 1.0),
	"rubber_sheet": Color(0.96, 0.76, 0.36, 1.0),
	"conductive_coil": Color(0.38, 0.96, 0.78, 1.0),
}

var _candidates: Array[Dictionary] = []
var _nodes_by_id := {}
var _active_ids := {}
var _depleted_ids := {}


func build(parent: Node2D, entities: Array, tile_size: int, show_debug: bool, prop_renderer, asset_lookup) -> void:
	_candidates = []
	_nodes_by_id = {}
	_active_ids = {}
	_depleted_ids = {}
	for value in entities:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var source := value as Dictionary
		if str(source.get("type", "")) != "material_candidate":
			continue
		var candidate: Dictionary = source.duplicate(true)
		candidate["center"] = _center(candidate, tile_size)
		_candidates.append(candidate)
		var candidate_id := str(candidate.get("id", "MaterialCandidate"))
		var node: Node2D = prop_renderer.add_salvage_prop(
			parent,
			candidate_id,
			candidate["center"],
			str(candidate.get("kind", "wreck_fragment")),
			"common",
			"material_collect",
			asset_lookup
		)
		node.modulate = MATERIAL_COLORS.get(str(candidate.get("material_id", "")), Color.WHITE)
		node.visible = false
		_nodes_by_id[candidate_id] = node
		if show_debug:
			_add_debug_label(parent, candidate, tile_size)


func candidates() -> Array:
	var values := []
	for candidate in _candidates:
		values.append(candidate.duplicate(true))
	return values


func configure(selected_ids: Array, depleted_ids: Array) -> void:
	_active_ids = {}
	_depleted_ids = {}
	for candidate_id in selected_ids:
		_active_ids[str(candidate_id)] = true
	for candidate_id in depleted_ids:
		_depleted_ids[str(candidate_id)] = true
	_refresh_visibility()


func candidate_near(position: Vector2, radius_px: float) -> Dictionary:
	for candidate in _candidates:
		var candidate_id := str(candidate.get("id", ""))
		if not _is_available(candidate_id):
			continue
		if position.distance_to(candidate.get("center", Vector2.ZERO)) <= radius_px:
			return candidate.duplicate(true)
	return {}


func collect(candidate_id: String) -> bool:
	if not _is_available(candidate_id):
		return false
	_depleted_ids[candidate_id] = true
	_set_visible(candidate_id, false)
	return true


func restore(candidate_id: String) -> void:
	_depleted_ids.erase(candidate_id)
	_set_visible(candidate_id, bool(_active_ids.get(candidate_id, false)))


func report() -> Dictionary:
	var active := _active_ids.keys()
	var depleted := _depleted_ids.keys()
	active.sort()
	depleted.sort()
	return {
		"candidate_count": _candidates.size(),
		"active_ids": active,
		"depleted_ids": depleted,
	}


func _is_available(candidate_id: String) -> bool:
	return bool(_active_ids.get(candidate_id, false)) and not bool(_depleted_ids.get(candidate_id, false))


func _refresh_visibility() -> void:
	for candidate_id in _nodes_by_id:
		_set_visible(str(candidate_id), _is_available(str(candidate_id)))


func _set_visible(candidate_id: String, visible: bool) -> void:
	if _nodes_by_id.has(candidate_id):
		(_nodes_by_id[candidate_id] as Node2D).visible = visible


func _center(candidate: Dictionary, tile_size: int) -> Vector2:
	return Vector2(float(candidate.get("x", 0)) + 0.5, float(candidate.get("y", 0)) + 0.5) * tile_size


func _add_debug_label(parent: Node2D, candidate: Dictionary, tile_size: int) -> void:
	var label := Label.new()
	label.name = "%sDebugLabel" % str(candidate.get("id", "MaterialCandidate"))
	label.text = "MATERIAL"
	label.position = _center(candidate, tile_size) + Vector2(18, -22)
	label.add_theme_color_override("font_color", Color(0.52, 1.0, 0.88, 0.94))
	label.z_index = 24
	parent.add_child(label)
