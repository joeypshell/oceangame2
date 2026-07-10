extends RefCounted

const PASSIVE_ROLE := "passive_sample"
const HOSTILE_ROLE := "hostile_harvest"
const PHASE_DEFEATED := "defeated"

var _profile
var _sources_by_id := {}
var _collected_ids := {}
var _active_source_id := ""
var _progress_seconds := 0.0
var _last_result := {}


func _init(profile_state) -> void:
	_profile = profile_state


func on_map_loaded(world, preserve_day_state := false) -> void:
	if not preserve_day_state:
		_collected_ids = {}
	_sources_by_id = {}
	if world != null and world.has_method("get_biological_resource_sources"):
		for source in world.get_biological_resource_sources():
			if typeof(source) == TYPE_DICTIONARY:
				var source_id := str(source.get("id", ""))
				if not source_id.is_empty():
					_sources_by_id[source_id] = source.duplicate(true)
	cancel_interaction("map_loaded")
	_sync_visuals(world, null)


func update(
	world,
	hostiles,
	material_runtime,
	position: Vector2,
	radius_px: float,
	delta: float,
	occupied_salvage: int,
	capacity: int
) -> Dictionary:
	_sync_visuals(world, hostiles)
	var nearby := _nearest_source(position, radius_px, hostiles)
	if nearby.is_empty():
		return cancel_interaction("left_range")
	var eligibility := _eligibility(nearby, hostiles)
	if not bool(eligibility.get("eligible", false)):
		cancel_interaction(str(eligibility.get("reason", "ineligible")))
		var note := str(eligibility.get("note", ""))
		return {"handled": not note.is_empty(), "reason": eligibility.get("reason", "ineligible"), "note": note}

	var source_id := str(nearby.get("id", ""))
	if _active_source_id != source_id:
		_active_source_id = source_id
		_progress_seconds = 0.0
	var required := float(nearby.get("interaction_seconds", 0.0))
	_progress_seconds = minf(required, _progress_seconds + maxf(0.0, delta))
	if _progress_seconds < required:
		_last_result = _progress_result(nearby, "progress")
		return _last_result.duplicate(true)

	var cargo: Dictionary = material_runtime.collect_biological_source(
		nearby,
		str(world.map_id),
		occupied_salvage,
		capacity
	)
	if not bool(cargo.get("changed", false)):
		_progress_seconds = 0.0
		_last_result = cargo.duplicate(true)
		_last_result["handled"] = true
		_last_result["id"] = source_id
		_last_result["source"] = nearby.duplicate(true)
		return _last_result.duplicate(true)

	_collected_ids[source_id] = true
	_active_source_id = ""
	_progress_seconds = 0.0
	_sync_visuals(world, hostiles)
	_last_result = cargo.duplicate(true)
	_last_result["handled"] = true
	_last_result["id"] = source_id
	_last_result["collected"] = true
	_last_result["note"] = "%s - return to boat" % str(nearby.get("collected_label", cargo.get("note", "Biological material held")))
	return _last_result.duplicate(true)


func restore_material_cargo(material_runtime, world, day_state, hostiles, reason: String) -> Dictionary:
	var result: Dictionary = material_runtime.restore_unbanked(world, day_state, reason)
	restore_unbanked(result.get("entries", []), world, hostiles)
	return result


func restore_unbanked(entries: Array, world, hostiles = null) -> int:
	var restored := 0
	for entry in entries:
		if typeof(entry) != TYPE_DICTIONARY or str(entry.get("cargo_source_type", "")) != "biological_resource":
			continue
		var source_id := str(entry.get("candidate_id", ""))
		if _collected_ids.erase(source_id):
			restored += 1
	cancel_interaction("restored")
	_sync_visuals(world, hostiles)
	return restored


func cancel_interaction(reason := "canceled") -> Dictionary:
	var changed := not _active_source_id.is_empty() or _progress_seconds > 0.0
	var canceled_id := _active_source_id
	_active_source_id = ""
	_progress_seconds = 0.0
	_last_result = {"handled": false, "changed": changed, "reason": reason, "id": canceled_id}
	return _last_result.duplicate(true)


func is_collected(source_id: String) -> bool:
	return bool(_collected_ids.get(source_id, false))


func report() -> Dictionary:
	var ids: Array[String] = []
	for source_id in _collected_ids:
		if bool(_collected_ids[source_id]):
			ids.append(str(source_id))
	ids.sort()
	return {
		"source_ids": _sorted_source_ids(),
		"collected_ids": ids,
		"active_source_id": _active_source_id,
		"progress_seconds": _progress_seconds,
		"last_result": _last_result.duplicate(true),
	}


func _nearest_source(position: Vector2, radius_px: float, hostiles) -> Dictionary:
	var nearest := {}
	var nearest_distance := maxf(0.0, radius_px)
	for source_id in _sorted_source_ids():
		if is_collected(source_id):
			continue
		var source: Dictionary = _sources_by_id[source_id]
		var center := _source_center(source, hostiles)
		if center == Vector2.INF:
			continue
		var distance := position.distance_to(center)
		if distance <= nearest_distance:
			nearest = source.duplicate(true)
			nearest["center"] = center
			nearest_distance = distance
	return nearest


func _eligibility(source: Dictionary, hostiles) -> Dictionary:
	var role := str(source.get("source_role", ""))
	if role == PASSIVE_ROLE:
		var capability_id := str(source.get("required_capability_id", ""))
		if _profile == null or not _profile.has_capability(capability_id):
			return {"eligible": false, "reason": "capability_required", "note": "Glow anemone | Scanner required"}
		return {"eligible": true}
	if role == HOSTILE_ROLE:
		var hostile_state := _hostile_state(source, hostiles)
		return {"eligible": str(hostile_state.get("phase", "")) == PHASE_DEFEATED, "reason": "hostile_not_defeated"}
	return {"eligible": false, "reason": "unsupported_role"}


func _source_center(source: Dictionary, hostiles) -> Vector2:
	if str(source.get("source_role", "")) == PASSIVE_ROLE:
		return source.get("center", Vector2.INF)
	var hostile_state := _hostile_state(source, hostiles)
	return hostile_state.get("position", Vector2.INF)


func _hostile_state(source: Dictionary, hostiles) -> Dictionary:
	if hostiles == null or not hostiles.has_method("state_for"):
		return {}
	return hostiles.state_for(str(source.get("hostile_id", "")))


func _sync_visuals(world, hostiles) -> void:
	if world == null or not world.has_method("set_biological_resource_visual_state"):
		return
	for source_id in _sorted_source_ids():
		var source: Dictionary = _sources_by_id[source_id]
		var center := _source_center(source, hostiles)
		var state := "available"
		if str(source.get("source_role", "")) == PASSIVE_ROLE:
			if is_collected(source_id):
				state = "depleted"
			elif not bool(_eligibility(source, hostiles).get("eligible", false)):
				state = "locked"
		else:
			state = "available" if not is_collected(source_id) and bool(_eligibility(source, hostiles).get("eligible", false)) else "hidden"
		world.set_biological_resource_visual_state(source_id, center, state)


func _progress_result(source: Dictionary, state: String) -> Dictionary:
	var required := float(source.get("interaction_seconds", 0.0))
	return {
		"handled": true,
		"changed": true,
		"state": state,
		"id": str(source.get("id", "")),
		"source": source.duplicate(true),
		"progress_seconds": _progress_seconds,
		"required_seconds": required,
		"note": "%s %.1f/%.1fs" % [str(source.get("interaction_label", "Sampling")), _progress_seconds, required],
	}


func _sorted_source_ids() -> Array[String]:
	var ids: Array[String] = []
	for source_id in _sources_by_id:
		ids.append(str(source_id))
	ids.sort()
	return ids
