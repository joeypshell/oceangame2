extends RefCounted

const OBSERVATION_EVENT := "ecological_observation_committed"

var _profile
var _traces_by_id := {}
var _opportunities_by_id := {}
var _revealed_trace_ids: Array[String] = []
var _identified_trace_ids: Array[String] = []
var _active_condition_ids: Array[String] = []
var _pending_observation := {}
var _last_result := {}


func bind_map(world, profile, preserve_sortie := false, active_condition_ids := []) -> void:
	_profile = profile
	_active_condition_ids.clear()
	for condition_id in active_condition_ids:
		_active_condition_ids.append(str(condition_id))
	_traces_by_id = _index_records(
		world.get_ecological_traces()
		if world != null and world.has_method("get_ecological_traces")
		else []
	)
	_opportunities_by_id = _index_records(
		world.get_creature_memory_opportunities()
		if world != null and world.has_method("get_creature_memory_opportunities")
		else []
	)
	if not preserve_sortie:
		discard_uncommitted("map_reload")
	else:
		_last_result = {}


func clear_map() -> void:
	discard_uncommitted("map_clear")
	_profile = null
	_traces_by_id = {}
	_opportunities_by_id = {}
	_active_condition_ids.clear()
	_last_result = {}


func record_reveal(trace_id: String) -> Dictionary:
	var trace := _trace(trace_id)
	if trace.is_empty():
		return _remember(_result(false, "source_trace_missing"))
	if not _matches_active_companion(trace):
		return _remember(_result(false, "wrong_active_companion", trace))
	var opportunity := _opportunity_for(trace)
	if opportunity.is_empty():
		return _remember(_result(false, "memory_opportunity_missing", trace))
	var memory_id := str(opportunity.get("memory_id", ""))
	if _memory_committed(memory_id):
		return _remember(_result(false, "already_committed", trace, opportunity))
	if _revealed_trace_ids.has(trace_id):
		return _remember(_result(false, "already_revealed", trace, opportunity))
	_revealed_trace_ids.append(trace_id)
	_revealed_trace_ids.sort()
	var value := _result(true, "relationship_revealed", trace, opportunity)
	value["note"] = "Migration filament revealed | Identify it with the Scanner"
	return _remember(value)


func record_identification(
	trace_id: String,
	observation_id: String,
	active_condition_ids: Array
) -> Dictionary:
	var trace := _trace(trace_id)
	if trace.is_empty():
		return _remember(_result(false, "source_trace_missing"))
	var opportunity := _opportunity_for(trace)
	if opportunity.is_empty():
		return _remember(_result(false, "memory_opportunity_missing", trace))
	if not _matches_active_companion(trace) or not _matches_active_companion(opportunity):
		return _remember(_result(false, "wrong_active_companion", trace, opportunity))
	if not _revealed_trace_ids.has(trace_id):
		return _remember(_result(false, "relationship_not_revealed", trace, opportunity))
	if observation_id != str(trace.get("observation_id", "")):
		return _remember(_result(false, "observation_mismatch", trace, opportunity))
	var condition_id := str(trace.get("daily_condition_id", ""))
	if condition_id.is_empty() or not active_condition_ids.has(condition_id):
		return _remember(_result(false, "linked_condition_inactive", trace, opportunity))
	var memory_id := str(opportunity.get("memory_id", ""))
	if _memory_committed(memory_id):
		return _remember(_result(false, "already_committed", trace, opportunity))
	if not _pending_observation.is_empty():
		return _remember(_result(false, "already_pending", trace, opportunity))
	if not _identified_trace_ids.has(trace_id):
		_identified_trace_ids.append(trace_id)
		_identified_trace_ids.sort()
	_pending_observation = {
		"trace_id": trace_id,
		"observation_id": observation_id,
		"memory_id": memory_id,
		"individual_id": str(opportunity.get("individual_id", "")),
		"species_id": str(opportunity.get("species_id", "")),
	}
	var value := _result(true, "observation_pending", trace, opportunity)
	value["note"] = "Migration identified with Mica | Return to surface boat"
	return _remember(value)


func record_scanner_identification(trace_id: String) -> Dictionary:
	var trace := _trace(trace_id)
	return record_identification(
		trace_id,
		str(trace.get("observation_id", "")),
		_active_condition_ids
	)


func commit_at_boat(at_canonical_boat: bool) -> Dictionary:
	if _pending_observation.is_empty():
		return _remember(_result(false, "nothing_pending"))
	if not at_canonical_boat:
		return _remember(_result(false, "canonical_boat_required"))
	if not _matches_active_companion(_pending_observation):
		return _remember(_result(false, "wrong_active_companion"))
	if _profile == null or not _profile.has_method("earn_companion_memory"):
		return _remember(_result(false, "profile_unavailable"))
	var pending := _pending_observation.duplicate(true)
	var memory_id := str(pending.get("memory_id", ""))
	var saved: Dictionary = _profile.earn_companion_memory(memory_id, true)
	var reason := str(saved.get("reason", ""))
	if not bool(saved.get("changed", false)) and reason != "already_earned":
		var failed := _result(false, reason if not reason.is_empty() else "storage_error")
		failed["memory_id"] = memory_id
		failed["note"] = "Mica's shared observation could not be secured"
		return _remember(failed)
	_pending_observation = {}
	var value := _result(bool(saved.get("changed", false)), "committed" if reason != "already_earned" else "already_committed")
	value["observation_id"] = str(pending.get("observation_id", ""))
	value["memory_id"] = memory_id
	value["note"] = "Mica remembers following the bloom" if bool(saved.get("changed", false)) else ""
	return _remember(value)


func discard_uncommitted(reason := "failure") -> Dictionary:
	var discarded_observation_id := str(_pending_observation.get("observation_id", ""))
	var changed := (
		not _revealed_trace_ids.is_empty()
		or not _identified_trace_ids.is_empty()
		or not _pending_observation.is_empty()
	)
	_revealed_trace_ids.clear()
	_identified_trace_ids.clear()
	_pending_observation = {}
	var value := _result(changed, "discarded" if changed else "nothing_pending")
	value["discard_reason"] = reason
	value["discarded_observation_id"] = discarded_observation_id
	return _remember(value)


func report() -> Dictionary:
	return {
		"revealed_trace_ids": _revealed_trace_ids.duplicate(),
		"identified_trace_ids": _identified_trace_ids.duplicate(),
		"active_condition_ids": _active_condition_ids.duplicate(),
		"pending_observation_id": str(_pending_observation.get("observation_id", "")),
		"pending_memory_id": str(_pending_observation.get("memory_id", "")),
		"last_result": _last_result.duplicate(true),
	}


func _index_records(records: Array) -> Dictionary:
	var indexed := {}
	for value in records:
		if typeof(value) != TYPE_DICTIONARY:
			continue
		var record := (value as Dictionary).duplicate(true)
		var record_id := str(record.get("id", ""))
		if not record_id.is_empty():
			indexed[record_id] = record
	return indexed


func _trace(trace_id: String) -> Dictionary:
	return (_traces_by_id.get(trace_id, {}) as Dictionary).duplicate(true)


func _opportunity_for(trace: Dictionary) -> Dictionary:
	var opportunity_id := str(trace.get("memory_opportunity_id", ""))
	var opportunity := (_opportunities_by_id.get(opportunity_id, {}) as Dictionary).duplicate(true)
	if (
		opportunity.is_empty()
		or str(opportunity.get("event_kind", "")) != OBSERVATION_EVENT
		or str(opportunity.get("target_id", "")) != str(trace.get("id", ""))
	):
		return {}
	return opportunity


func _matches_active_companion(record: Dictionary) -> bool:
	if _profile == null or not _profile.has_method("companion_report"):
		return false
	var companion: Dictionary = _profile.companion_report()
	var individual: Dictionary = companion.get("individual", {})
	return (
		not individual.is_empty()
		and bool(individual.get("rescue_committed", false))
		and str(companion.get("active_individual_id", "")) == str(individual.get("individual_id", ""))
		and str(record.get("individual_id", "")) == str(individual.get("individual_id", ""))
		and str(record.get("species_id", "")) == str(individual.get("species_id", ""))
	)


func _memory_committed(memory_id: String) -> bool:
	if memory_id.is_empty() or _profile == null or not _profile.has_method("companion_report"):
		return false
	var individual: Dictionary = _profile.companion_report().get("individual", {})
	return (individual.get("earned_memory_ids", []) as Array).has(memory_id)


func _result(changed: bool, reason: String, trace := {}, opportunity := {}) -> Dictionary:
	return {
		"changed": changed,
		"reason": reason,
		"trace_id": str(trace.get("id", "")),
		"observation_id": str(trace.get("observation_id", "")),
		"memory_id": str(opportunity.get("memory_id", "")),
		"cargo_delta": 0,
		"score_delta": 0,
		"material_deltas": {},
		"blueprint_ids": [],
		"access_ids": [],
		"adaptation_id": "",
	}


func _remember(value: Dictionary) -> Dictionary:
	_last_result = value.duplicate(true)
	return value
