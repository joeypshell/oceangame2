extends RefCounted

const CONNECTOR_KIND := "exceptional_interior"
const DIRECTION_FORWARD := "forward"
const DIRECTION_RETURN := "return"
const PHASE_INACTIVE := "inactive"
const PHASE_ENTERING := "entering"
const PHASE_INSIDE := "inside"
const PHASE_RETURNING := "returning"
const PHASE_FAILED := "failed"

var _phase := PHASE_INACTIVE
var _round_trip := {}
var _consumed_ids_by_map := {}


func is_exceptional(connector: Dictionary) -> bool:
	return str(connector.get("connector_kind", "")) == CONNECTOR_KIND


func prepare_transition(
	connector: Dictionary,
	current_map_id: String,
	current_map_path: String,
	has_discovery: Callable
) -> Dictionary:
	if not is_exceptional(connector):
		if _phase in [PHASE_ENTERING, PHASE_INSIDE, PHASE_RETURNING, PHASE_FAILED]:
			return _blocked("unrelated_connector", "Return through the Transfer Hub doorway")
		reset()
		return {"allowed": true, "continuous": false, "reason": "legacy_connector"}

	var direction := str(connector.get("connector_direction", ""))
	if direction == DIRECTION_FORWARD:
		return _prepare_forward(connector, current_map_id, current_map_path, has_discovery)
	if direction == DIRECTION_RETURN:
		return _prepare_return(connector, current_map_id)
	return _blocked("invalid_direction", "Transfer Hub connection unavailable")


func complete_arrival(destination_map_id: String) -> Dictionary:
	if _phase == PHASE_ENTERING and destination_map_id == str(_round_trip.get("interior_map_id", "")):
		_phase = PHASE_INSIDE
		return {"changed": true, "phase": _phase, "reason": "entered"}
	if _phase == PHASE_RETURNING and destination_map_id == str(_round_trip.get("origin_map_id", "")):
		_phase = PHASE_INACTIVE
		return {"changed": true, "phase": _phase, "reason": "returned"}
	_phase = PHASE_FAILED
	return {"changed": true, "phase": _phase, "reason": "arrival_mismatch"}


func capture_consumed(world, held_salvage_ids: Array) -> void:
	if _round_trip.is_empty() or world == null:
		return
	var map_id := str(world.map_id)
	var consumed: Dictionary = _consumed_ids_by_map.get(map_id, {}).duplicate(true)
	for value in held_salvage_ids:
		var item_id := str(value)
		if not item_id.is_empty() and world.has_method("is_salvage_collected") and world.is_salvage_collected(item_id):
			consumed[item_id] = true
	if world.has_method("get_tool_target_report"):
		for value in world.get_tool_target_report().get("collected_ids", []):
			var target_id := str(value)
			if not target_id.is_empty():
				consumed[target_id] = true
	_consumed_ids_by_map[map_id] = consumed


func apply_consumed(world) -> Array[String]:
	var applied: Array[String] = []
	if _round_trip.is_empty() or world == null:
		return applied
	var map_id := str(world.map_id)
	var consumed: Dictionary = _consumed_ids_by_map.get(map_id, {})
	var ids: Array = consumed.keys()
	ids.sort()
	for value in ids:
		var item_id := str(value)
		var changed := false
		if world.has_method("collect_salvage_by_id"):
			changed = bool(world.collect_salvage_by_id(item_id))
		if not changed and world.has_method("collect_tool_target"):
			changed = bool(world.collect_tool_target(item_id))
		if changed or (world.has_method("is_salvage_collected") and world.is_salvage_collected(item_id)):
			applied.append(item_id)
	return applied


func mark_failed() -> void:
	if not _round_trip.is_empty():
		_phase = PHASE_FAILED


func requires_canonical_reload(current_map_id: String) -> bool:
	return not _round_trip.is_empty() and current_map_id != str(_round_trip.get("origin_map_id", ""))


func origin_map_path() -> String:
	return str(_round_trip.get("origin_map_path", ""))


func reset() -> void:
	_phase = PHASE_INACTIVE
	_round_trip = {}
	_consumed_ids_by_map = {}


func report() -> Dictionary:
	return {
		"phase": _phase,
		"round_trip": _round_trip.duplicate(true),
		"consumed_ids_by_map": _consumed_ids_by_map.duplicate(true),
	}


func _prepare_forward(
	connector: Dictionary,
	current_map_id: String,
	current_map_path: String,
	has_discovery: Callable
) -> Dictionary:
	if _phase != PHASE_INACTIVE:
		return _blocked("round_trip_active", "Transfer Hub transition already active")
	var required_discovery_id := str(connector.get("required_discovery_id", ""))
	if (
		not required_discovery_id.is_empty()
		and (not has_discovery.is_valid() or not bool(has_discovery.call(required_discovery_id)))
	):
		return _blocked("prerequisite_missing", "Transfer Hub | Coordinates not triangulated")
	var connector_id := str(connector.get("id", ""))
	var interior_map_id := str(connector.get("destination_map_id", ""))
	var interior_entry_id := str(connector.get("destination_entry_id", ""))
	var return_connector_id := str(connector.get("paired_connector_id", ""))
	if (
		connector_id.is_empty()
		or current_map_id.is_empty()
		or current_map_path.is_empty()
		or interior_map_id.is_empty()
		or interior_entry_id.is_empty()
		or return_connector_id.is_empty()
	):
		return _blocked("invalid_source", "Transfer Hub connection unavailable")
	_round_trip = {
		"id": "%s/%s>%s/%s" % [current_map_id, connector_id, interior_map_id, return_connector_id],
		"origin_map_id": current_map_id,
		"origin_map_path": current_map_path,
		"origin_connector_id": connector_id,
		"interior_map_id": interior_map_id,
		"interior_entry_id": interior_entry_id,
		"return_connector_id": return_connector_id,
	}
	_phase = PHASE_ENTERING
	return {"allowed": true, "continuous": true, "reason": "entering", "phase": _phase}


func _prepare_return(connector: Dictionary, current_map_id: String) -> Dictionary:
	if _phase != PHASE_INSIDE:
		return _blocked("not_inside", "Transfer Hub return unavailable")
	if (
		current_map_id != str(_round_trip.get("interior_map_id", ""))
		or str(connector.get("id", "")) != str(_round_trip.get("return_connector_id", ""))
		or str(connector.get("destination_map_id", "")) != str(_round_trip.get("origin_map_id", ""))
		or str(connector.get("paired_connector_id", "")) != str(_round_trip.get("origin_connector_id", ""))
	):
		return _blocked("pair_mismatch", "Transfer Hub return connection unavailable")
	_phase = PHASE_RETURNING
	return {"allowed": true, "continuous": true, "reason": "returning", "phase": _phase}


func _blocked(reason: String, note: String) -> Dictionary:
	return {"allowed": false, "continuous": true, "reason": reason, "note": note}
