extends RefCounted

var oxygen_seconds := 0.0
var held_salvage := 0
var held_salvage_ids: Array[String] = []
var held_salvage_score := 0
var failed := false
var failure_reason := ""
var current_map_id := ""
var current_entry_id := ""


func _init(oxygen_capacity_seconds := 0.0) -> void:
	oxygen_seconds = maxf(0.0, oxygen_capacity_seconds)


func begin_map_leg(map_id: String, entry_id: String, oxygen_capacity_seconds: float) -> void:
	current_map_id = map_id
	current_entry_id = entry_id
	oxygen_seconds = maxf(0.0, oxygen_capacity_seconds)
	clear_held()
	failed = false
	failure_reason = ""


func collect_salvage(salvage_id: String, score: int) -> void:
	held_salvage += 1
	held_salvage_ids.append(salvage_id)
	held_salvage_score += score


func clear_held() -> Array[String]:
	var cleared_ids := held_salvage_ids.duplicate()
	held_salvage = 0
	held_salvage_ids = []
	held_salvage_score = 0
	return cleared_ids


func mark_failed(reason: String) -> void:
	failed = true
	failure_reason = reason


func apply_oxygen_penalty(seconds: float) -> bool:
	oxygen_seconds = maxf(0.0, oxygen_seconds - maxf(0.0, seconds))
	return oxygen_seconds <= 0.0


func report() -> Dictionary:
	return {
		"current_map_id": current_map_id,
		"current_entry_id": current_entry_id,
		"oxygen_seconds": oxygen_seconds,
		"held_salvage": held_salvage,
		"held_salvage_ids": held_salvage_ids.duplicate(),
		"held_salvage_score": held_salvage_score,
		"failed": failed,
		"failure_reason": failure_reason,
	}
