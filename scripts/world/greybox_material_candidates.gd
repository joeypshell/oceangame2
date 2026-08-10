extends RefCounted

const BuriedDepositPresentation := preload("res://scripts/world/greybox_buried_deposit_presentation.gd")
const MATERIAL_COLORS := {
	"titanium_scrap": Color(0.68, 0.90, 0.94, 1.0),
	"rubber_sheet": Color(0.34, 0.52, 0.58, 1.0),
	"conductive_coil": Color(0.96, 0.58, 0.22, 1.0),
}

var _candidates: Array[Dictionary] = []
var _candidates_by_id := {}
var _nodes_by_id := {}
var _mound_nodes_by_id := {}
var _active_ids := {}
var _depleted_ids := {}
var _revealed_ids := {}


func build(parent: Node2D, entities: Array, tile_size: int, show_debug: bool, prop_renderer, asset_lookup) -> void:
	_candidates = []
	_candidates_by_id = {}
	_nodes_by_id = {}
	_mound_nodes_by_id = {}
	_active_ids = {}
	_depleted_ids = {}
	_revealed_ids = {}
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
		_candidates_by_id[candidate_id] = candidate
		var material_id := str(candidate.get("material_id", ""))
		var material_texture = asset_lookup.material_texture(material_id) if asset_lookup != null else null
		var node: Node2D = prop_renderer.add_salvage_prop(
			parent,
			candidate_id,
			candidate["center"],
			str(candidate.get("kind", "wreck_fragment")),
			"common",
			"material_collect",
			asset_lookup,
			material_texture,
			"MaterialSprite"
		)
		node.modulate = Color.WHITE if material_texture != null else MATERIAL_COLORS.get(material_id, Color.WHITE)
		node.visible = false
		_nodes_by_id[candidate_id] = node
		if _is_buried(candidate):
			var mound = BuriedDepositPresentation.new()
			mound.name = "%sMound" % candidate_id
			mound.position = candidate["center"]
			mound.z_index = 7
			mound.visible = false
			parent.add_child(mound)
			_mound_nodes_by_id[candidate_id] = mound
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
	_revealed_ids = {}
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
	_revealed_ids.erase(candidate_id)
	_set_visible(candidate_id, false)
	_set_mound_state(candidate_id, BuriedDepositPresentation.STATE_EMPTY)
	return true


func restore(candidate_id: String) -> void:
	_depleted_ids.erase(candidate_id)
	if _is_buried(_candidate(candidate_id)):
		_revealed_ids.erase(candidate_id)
		_set_visible(candidate_id, false)
		_set_mound_state(candidate_id, BuriedDepositPresentation.STATE_CLOSED)
	else:
		_set_visible(candidate_id, bool(_active_ids.get(candidate_id, false)))


func candidate_state(candidate_id: String) -> Dictionary:
	var candidate := _candidate(candidate_id)
	if candidate.is_empty():
		return {"candidate_id": candidate_id, "exists": false}
	var active := bool(_active_ids.get(candidate_id, false))
	var depleted := bool(_depleted_ids.get(candidate_id, false))
	var revealed := bool(_revealed_ids.get(candidate_id, false))
	return {
		"candidate_id": candidate_id,
		"exists": true,
		"active": active,
		"depleted": depleted,
		"buried": _is_buried(candidate),
		"revealed": revealed,
		"available": _is_available(candidate_id),
		"candidate": candidate.duplicate(true),
		"mound": _mound_report(candidate_id),
	}


func reveal_buried(candidate_id: String) -> bool:
	var candidate := _candidate(candidate_id)
	if not _is_buried(candidate) or not _is_selected_undepleted(candidate_id) or bool(_revealed_ids.get(candidate_id, false)):
		return false
	_revealed_ids[candidate_id] = true
	_set_visible(candidate_id, true)
	_set_mound_state(candidate_id, BuriedDepositPresentation.STATE_OPENED)
	return true


func conceal_buried(candidate_id: String) -> bool:
	var candidate := _candidate(candidate_id)
	if not _is_buried(candidate):
		return false
	var changed := bool(_revealed_ids.get(candidate_id, false))
	_revealed_ids.erase(candidate_id)
	_set_visible(candidate_id, false)
	_set_mound_state(
		candidate_id,
		BuriedDepositPresentation.STATE_EMPTY if bool(_depleted_ids.get(candidate_id, false)) else BuriedDepositPresentation.STATE_CLOSED
	)
	return changed


func set_buried_state(candidate_id: String, state: String, progress := 0.0) -> bool:
	if not _is_buried(_candidate(candidate_id)) or not _is_selected_undepleted(candidate_id):
		return false
	return _set_mound_state(candidate_id, state, progress)


func report() -> Dictionary:
	var active := _active_ids.keys()
	var depleted := _depleted_ids.keys()
	var revealed := _revealed_ids.keys()
	var concealed := []
	for candidate_id in active:
		if _is_buried(_candidate(str(candidate_id))) and not revealed.has(candidate_id) and not depleted.has(candidate_id):
			concealed.append(candidate_id)
	active.sort()
	depleted.sort()
	revealed.sort()
	concealed.sort()
	return {
		"candidate_count": _candidates.size(),
		"active_ids": active,
		"depleted_ids": depleted,
		"revealed_ids": revealed,
		"concealed_ids": concealed,
	}


func _is_available(candidate_id: String) -> bool:
	if not _is_selected_undepleted(candidate_id):
		return false
	return not _is_buried(_candidate(candidate_id)) or bool(_revealed_ids.get(candidate_id, false))


func _is_selected_undepleted(candidate_id: String) -> bool:
	return bool(_active_ids.get(candidate_id, false)) and not bool(_depleted_ids.get(candidate_id, false))


func _refresh_visibility() -> void:
	for candidate_id in _nodes_by_id:
		var normalized_id := str(candidate_id)
		_set_visible(normalized_id, _is_available(normalized_id))
		if _mound_nodes_by_id.has(normalized_id):
			var mound := _mound_nodes_by_id[normalized_id] as Node2D
			mound.visible = bool(_active_ids.get(normalized_id, false))
			_set_mound_state(
				normalized_id,
				BuriedDepositPresentation.STATE_EMPTY if bool(_depleted_ids.get(normalized_id, false)) else BuriedDepositPresentation.STATE_CLOSED
			)


func _set_visible(candidate_id: String, visible: bool) -> void:
	if _nodes_by_id.has(candidate_id):
		(_nodes_by_id[candidate_id] as Node2D).visible = visible


func _set_mound_state(candidate_id: String, state: String, progress := 0.0) -> bool:
	if not _mound_nodes_by_id.has(candidate_id):
		return false
	return bool(_mound_nodes_by_id[candidate_id].set_state(state, progress))


func _mound_report(candidate_id: String) -> Dictionary:
	if not _mound_nodes_by_id.has(candidate_id):
		return {}
	return _mound_nodes_by_id[candidate_id].report()


func _candidate(candidate_id: String) -> Dictionary:
	return _candidates_by_id.get(candidate_id, {}) as Dictionary


func _is_buried(candidate: Dictionary) -> bool:
	return (
		not candidate.is_empty()
		and bool(candidate.get("buried_deposit", false))
		and str(candidate.get("required_companion_action_id", "")) == "excavate"
	)


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
