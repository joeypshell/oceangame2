extends RefCounted

const TRIGGER_PRIMARY_OBJECTIVE_COMPLETE := "primary_objective_complete"

var _prompts: Array = []


func reset(world) -> void:
	_prompts = []
	if world == null or not world.has_method("get_next_dive_objective_prompts"):
		return
	for prompt in world.get_next_dive_objective_prompts():
		if typeof(prompt) == TYPE_DICTIONARY:
			_prompts.append(prompt.duplicate(true))


func result_text(run_complete: bool, run_failed: bool, primary_objective, banked_ids: Array[String]) -> String:
	if not run_complete or run_failed:
		return ""
	for prompt in _prompts:
		var text := _prompt_result_text(prompt, primary_objective, banked_ids)
		if not text.is_empty():
			return text
	return ""


func _prompt_result_text(prompt: Dictionary, primary_objective, banked_ids: Array[String]) -> String:
	if str(prompt.get("trigger", "")).strip_edges() != TRIGGER_PRIMARY_OBJECTIVE_COMPLETE:
		return ""
	if primary_objective == null or not primary_objective.has_method("is_complete"):
		return ""
	if not primary_objective.is_complete(banked_ids):
		return ""

	var prompt_objective_id := str(prompt.get("objective_id", "")).strip_edges()
	if primary_objective.has_method("objective_id") and primary_objective.objective_id() != prompt_objective_id:
		return ""

	return str(prompt.get("label", "")).strip_edges()
