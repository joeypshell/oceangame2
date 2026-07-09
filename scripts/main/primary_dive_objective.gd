extends RefCounted

var _primary_objective_id := ""
var _primary_objective := {}
var _required_target_ids: Array[String] = []


func reset(world) -> void:
	_primary_objective_id = ""
	_primary_objective = {}
	_required_target_ids = []
	if world == null or not world.has_method("get_primary_route_objective_id"):
		return

	_primary_objective_id = str(world.get_primary_route_objective_id()).strip_edges()
	if _primary_objective_id.is_empty() or not world.has_method("get_route_objectives"):
		return

	for objective in world.get_route_objectives():
		if typeof(objective) != TYPE_DICTIONARY:
			continue
		if str(objective.get("id", "")).strip_edges() != _primary_objective_id:
			continue
		_primary_objective = objective.duplicate(true)
		_required_target_ids = _required_targets(_primary_objective)
		if _required_target_ids.is_empty():
			_primary_objective = {}
			_primary_objective_id = ""
		return

	_primary_objective_id = ""


func has_primary_objective() -> bool:
	return not _primary_objective_id.is_empty() and not _required_target_ids.is_empty()


func objective_id() -> String:
	return _primary_objective_id


func is_complete(banked_salvage_ids: Array[String]) -> bool:
	if not has_primary_objective():
		return false
	for target_id in _required_target_ids:
		if not banked_salvage_ids.has(target_id):
			return false
	return true


func is_required_target(salvage_id: String) -> bool:
	return _required_target_ids.has(salvage_id)


func ordered_salvage_for_full_collection(salvage_centers: Array) -> Array:
	if not has_primary_objective():
		return salvage_centers

	var optional_salvage := []
	var required_salvage := []
	for salvage in salvage_centers:
		if typeof(salvage) != TYPE_DICTIONARY:
			optional_salvage.append(salvage)
			continue

		var salvage_id := str(salvage.get("id", "")).strip_edges()
		if is_required_target(salvage_id):
			required_salvage.append(salvage)
		else:
			optional_salvage.append(salvage)

	optional_salvage.append_array(required_salvage)
	return optional_salvage


func _required_targets(objective: Dictionary) -> Array[String]:
	var targets: Array[String] = []
	for target_id in objective.get("required_banked_targets", []):
		var id := str(target_id).strip_edges()
		if id.is_empty() or targets.has(id):
			continue
		targets.append(id)
	return targets
