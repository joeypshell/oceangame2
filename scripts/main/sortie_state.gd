extends RefCounted

var oxygen_seconds := 0.0
var held_salvage := 0
var held_salvage_ids: Array[String] = []
var held_salvage_score := 0
var failed := false
var failure_reason := ""
var active := false
var current_map_id := ""
var current_entry_id := ""


func _init(oxygen_capacity_seconds := 0.0) -> void:
	oxygen_seconds = maxf(0.0, oxygen_capacity_seconds)


func begin_map_leg(map_id: String, entry_id: String, oxygen_capacity_seconds: float, preserve_active := false) -> void:
	var kept_active := active and preserve_active
	current_map_id = map_id
	current_entry_id = entry_id
	oxygen_seconds = maxf(0.0, oxygen_capacity_seconds)
	clear_held()
	failed = false
	failure_reason = ""
	active = kept_active


func begin_continuous_map_leg(map_id: String, entry_id: String) -> void:
	current_map_id = map_id
	current_entry_id = entry_id


func update_offload_presence(at_offload: bool, oxygen_capacity_seconds: float) -> bool:
	if failed:
		return false
	if at_offload:
		active = false
		return false
	if active:
		return false
	active = true
	oxygen_seconds = maxf(0.0, oxygen_capacity_seconds)
	failure_reason = ""
	return true


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
	active = false


func apply_oxygen_penalty(seconds: float) -> bool:
	oxygen_seconds = maxf(0.0, oxygen_seconds - maxf(0.0, seconds))
	return oxygen_seconds <= 0.0


func drain_oxygen(seconds: float, multiplier := 1.0) -> bool:
	return apply_oxygen_penalty(maxf(0.0, seconds) * maxf(0.0, multiplier))


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
		"active": active,
	}
