extends RefCounted

const DEFAULT_DAYLIGHT_SECONDS := 300.0
const PHASE_ACTIVE := "active"
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
var current_map_id := ""
var connector_transition_count := 0


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
	connector_transition_count = 0


func begin_next_day() -> void:
	begin_day(day_number + 1)


func record_sortie_started() -> void:
	sortie_count += 1


func record_bank(salvage_count: int, score: int) -> void:
	banked_salvage += maxi(0, salvage_count)
	banked_score += maxi(0, score)


func record_discovery(discovery_id: String) -> void:
	if not discovery_id.is_empty() and not committed_discovery_ids.has(discovery_id):
		committed_discovery_ids.append(discovery_id)


func on_map_loaded(map_id: String) -> void:
	current_map_id = map_id


func on_map_transition(destination_map_id: String) -> void:
	connector_transition_count += 1
	current_map_id = destination_map_id


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
		"current_map_id": current_map_id,
		"connector_transition_count": connector_transition_count,
	}
