extends RefCounted

const MaterialCandidateSelector := preload("res://scripts/main/material_candidate_selector.gd")
const DEFAULT_DAYLIGHT_SECONDS := 300.0
const PHASE_ACTIVE := "active"
const PHASE_NIGHTFALL_PENDING := "nightfall_pending"
const PHASE_END_REQUESTED := "end_requested"
const PHASE_DEBRIEF := "debrief"

var day_number := 1
var daylight_capacity_seconds := DEFAULT_DAYLIGHT_SECONDS
var daylight_remaining_seconds := DEFAULT_DAYLIGHT_SECONDS
var phase := PHASE_ACTIVE
var sortie_count := 0
var banked_salvage := 0
var banked_score := 0
var committed_discovery_ids: Array[String] = []
var end_reason := ""
var notable_failure_reason := ""
var current_map_id := ""
var connector_transition_count := 0
var nightfall_event_count := 0
var material_day_seed := 1
var _material_selected_by_map := {}
var _material_depleted_by_map := {}
var _material_researched_pools_by_map := {}


func _init(daylight_seconds := DEFAULT_DAYLIGHT_SECONDS) -> void:
	daylight_capacity_seconds = maxf(0.01, daylight_seconds)
	begin_day(1)


func begin_day(next_day_number: int) -> void:
	day_number = maxi(1, next_day_number)
	daylight_remaining_seconds = daylight_capacity_seconds
	phase = PHASE_ACTIVE
	sortie_count = 0
	banked_salvage = 0
	banked_score = 0
	committed_discovery_ids = []
	end_reason = ""
	notable_failure_reason = ""
	connector_transition_count = 0
	nightfall_event_count = 0
	material_day_seed = day_number
	_material_selected_by_map = {}
	_material_depleted_by_map = {}
	_material_researched_pools_by_map = {}


func begin_next_day() -> void:
	begin_day(day_number + 1)


func advance_daylight(delta: float) -> Dictionary:
	if phase != PHASE_ACTIVE or delta <= 0.0:
		return _daylight_result(false)
	daylight_remaining_seconds = maxf(0.0, daylight_remaining_seconds - delta)
	if daylight_remaining_seconds > 0.0:
		return _daylight_result(false)
	phase = PHASE_NIGHTFALL_PENDING
	end_reason = "nightfall"
	nightfall_event_count += 1
	return _daylight_result(true)


func record_sortie_started() -> int:
	sortie_count += 1
	return sortie_count


func record_bank(salvage_count: int, score: int) -> void:
	banked_salvage += maxi(0, salvage_count)
	banked_score += maxi(0, score)


func record_discovery(discovery_id: String) -> void:
	if not discovery_id.is_empty() and not committed_discovery_ids.has(discovery_id):
		committed_discovery_ids.append(discovery_id)


func record_failure(reason: String) -> void:
	if not reason.is_empty():
		notable_failure_reason = reason


func on_map_loaded(map_id: String) -> void:
	current_map_id = map_id


func on_map_transition(destination_map_id: String) -> void:
	connector_transition_count += 1
	current_map_id = destination_map_id


func material_selection_for(map_id: String, pools: Array, completed_discovery_ids := []) -> Array[String]:
	if _material_selected_by_map.has(map_id):
		var stored: Array = _material_selected_by_map[map_id]
		var copy: Array[String] = []
		for candidate_id in stored:
			copy.append(str(candidate_id))
		return copy
	var selected := MaterialCandidateSelector.select_for_day(map_id, pools, material_day_seed, completed_discovery_ids)
	_material_selected_by_map[map_id] = selected.duplicate()
	_material_researched_pools_by_map[map_id] = MaterialCandidateSelector.researched_pool_ids(pools, completed_discovery_ids)
	return selected


func material_researched_pool_ids(map_id: String) -> Array[String]:
	var values: Array[String] = []
	for pool_id in _material_researched_pools_by_map.get(map_id, []):
		values.append(str(pool_id))
	return values


func material_depleted_ids(map_id: String) -> Array[String]:
	var values: Array[String] = []
	var depleted: Dictionary = _material_depleted_by_map.get(map_id, {})
	for candidate_id in depleted:
		if bool(depleted[candidate_id]):
			values.append(str(candidate_id))
	values.sort()
	return values


func mark_material_depleted(map_id: String, candidate_id: String) -> void:
	if map_id.is_empty() or candidate_id.is_empty():
		return
	var depleted: Dictionary = _material_depleted_by_map.get(map_id, {})
	depleted[candidate_id] = true
	_material_depleted_by_map[map_id] = depleted


func restore_material_candidate(map_id: String, candidate_id: String) -> void:
	if not _material_depleted_by_map.has(map_id):
		return
	var depleted: Dictionary = _material_depleted_by_map[map_id]
	depleted.erase(candidate_id)
	_material_depleted_by_map[map_id] = depleted


func request_end_day(reason: String) -> bool:
	if phase != PHASE_ACTIVE:
		return false
	phase = PHASE_END_REQUESTED
	end_reason = reason
	return true


func end_day(reason: String) -> void:
	phase = PHASE_DEBRIEF
	end_reason = reason


func report() -> Dictionary:
	return {
		"day_number": day_number,
		"daylight_capacity_seconds": daylight_capacity_seconds,
		"daylight_remaining_seconds": daylight_remaining_seconds,
		"phase": phase,
		"sortie_count": sortie_count,
		"banked_salvage": banked_salvage,
		"banked_score": banked_score,
		"committed_discovery_ids": committed_discovery_ids.duplicate(),
		"end_reason": end_reason,
		"notable_failure_reason": notable_failure_reason,
		"current_map_id": current_map_id,
		"connector_transition_count": connector_transition_count,
		"nightfall_event_count": nightfall_event_count,
		"material_day_seed": material_day_seed,
		"material_selected_by_map": _duplicate_nested(_material_selected_by_map),
		"material_depleted_by_map": _duplicate_nested(_material_depleted_by_map),
		"material_researched_pools_by_map": _duplicate_nested(_material_researched_pools_by_map),
	}


func _daylight_result(nightfall_triggered: bool) -> Dictionary:
	return {
		"daylight_remaining_seconds": daylight_remaining_seconds,
		"phase": phase,
		"nightfall_triggered": nightfall_triggered,
		"nightfall_event_count": nightfall_event_count,
	}


func _duplicate_nested(source: Dictionary) -> Dictionary:
	return source.duplicate(true)
