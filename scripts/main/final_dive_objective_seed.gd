extends RefCounted

const TRIGGER_RELAY_FOLLOW_THROUGH_COMPLETE := "relay_follow_through_complete"

var _seeds: Array = []
var _completed_seed_ids: Array[String] = []


func reset(world) -> void:
	_seeds = []
	_completed_seed_ids = []
	if world == null or not world.has_method("get_final_dive_objective_seeds"):
		return
	for seed in world.get_final_dive_objective_seeds():
		if typeof(seed) == TYPE_DICTIONARY:
			_seeds.append(seed.duplicate(true))


func banked_feedback(banked_ids: Array[String]) -> String:
	for seed in _seeds:
		if str(seed.get("trigger", "")).strip_edges() != TRIGGER_RELAY_FOLLOW_THROUGH_COMPLETE:
			continue
		var seed_id := str(seed.get("id", "")).strip_edges()
		var target_id := str(seed.get("target_id", "")).strip_edges()
		if seed_id.is_empty() or target_id.is_empty() or not banked_ids.has(target_id):
			continue
		if not _completed_seed_ids.has(seed_id):
			_completed_seed_ids.append(seed_id)
		return _label_text(seed, "label")
	return ""


func result_text(banked_ids: Array[String]) -> String:
	for seed in _seeds:
		var seed_id := str(seed.get("id", "")).strip_edges()
		var target_id := str(seed.get("target_id", "")).strip_edges()
		if seed_id.is_empty() or target_id.is_empty():
			continue
		if _completed_seed_ids.has(seed_id) or banked_ids.has(target_id):
			return _label_text(seed, "result_label")
	return ""


func is_feedback_note(status_note: String) -> bool:
	var note := status_note.strip_edges()
	if note.is_empty():
		return false
	for seed in _seeds:
		if note == _label_text(seed, "label"):
			return true
	return false


func _label_text(seed: Dictionary, field: String) -> String:
	var label := str(seed.get(field, "")).strip_edges()
	if label.is_empty() and field == "result_label":
		label = str(seed.get("label", "")).strip_edges()
	return label
