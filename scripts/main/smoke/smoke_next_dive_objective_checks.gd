extends "res://scripts/main/smoke/smoke_check_base.gd"

const EXPECTED_PROMPT_ID := "deep_cache_next_dive_prompt"
const EXPECTED_LABEL := "Next dive: Investigate lower-left relay"
const EXPECTED_TARGET_ID := "lower_left_loop_connector"
const EXPECTED_TRIGGER := "primary_objective_complete"


func _smoke_pass_23_next_dive_objective_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("Pass 23 next-dive smoke loaded unexpected map: %s." % _world.map_id)
		return

	var prompt := _source_prompt()
	var objective_id: String = _world.get_primary_route_objective_id()
	var objective := _objective_by_id(objective_id)
	var required_targets := _required_targets(objective)
	if prompt.is_empty() or objective_id.is_empty() or objective.is_empty() or required_targets.size() < 2:
		_fail("Pass 23 next-dive smoke missing source data: prompt=%s objective=%s targets=%s." % [
			str(not prompt.is_empty()),
			objective_id,
			required_targets,
		])
		return
	if str(prompt.get("label", "")) != EXPECTED_LABEL or str(prompt.get("target_id", "")) != EXPECTED_TARGET_ID:
		_fail("Pass 23 next-dive prompt metadata mismatch: %s." % str(prompt))
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_update_status_label()
	if not _assert_prompt_hidden("start"):
		return

	var first_required := _salvage_by_id(required_targets[0])
	var second_required := _salvage_by_id(required_targets[1])
	_collect_and_bank_target(first_required)
	if not _assert_prompt_hidden("one-required-banked"):
		return
	if _run_complete or _result_panel.visible:
		_fail("Pass 23 next-dive smoke completed too early after one required target: banked=%s." % str(_banked_salvage_ids))
		return

	_collect_target(second_required)
	if not _assert_prompt_hidden("second-required-held"):
		return
	if _run_complete:
		_fail("Pass 23 next-dive smoke completed before returning held primary cargo.")
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _run_complete or _run_failed:
		_fail("Pass 23 next-dive smoke did not complete after banking primary objective: complete=%s failed=%s." % [str(_run_complete), str(_run_failed)])
		return
	if _prompt_result_text() != EXPECTED_LABEL or _result_text().find(EXPECTED_LABEL) == -1:
		_fail("Pass 23 next-dive prompt missing after completion: helper=%s result=%s." % [_prompt_result_text(), _result_text()])
		return
	var completed_score := _banked_score
	var completed_oxygen := _oxygen_seconds

	_reset_run()
	if not _assert_prompt_hidden("reset"):
		return

	_hazard_interactions_enabled = false
	_collect_target(first_required)
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed:
		_fail("Pass 23 next-dive smoke expected oxygen failure state.")
		return
	if not _assert_prompt_hidden("oxygen-failure"):
		return

	print("Pass 23 next-dive objective smoke passed: map=%s prompt=%s trigger=%s objective=%s state=complete target=%s banked_score=%d oxygen=%.1f hidden_before=true hidden_failure=true label=\"%s\"." % [
		_world.map_id,
		EXPECTED_PROMPT_ID,
		EXPECTED_TRIGGER,
		objective_id,
		EXPECTED_TARGET_ID,
		completed_score,
		completed_oxygen,
		EXPECTED_LABEL,
	])
	get_tree().quit()


func _source_prompt() -> Dictionary:
	for prompt in _world.get_next_dive_objective_prompts():
		if str(prompt.get("id", "")) == EXPECTED_PROMPT_ID:
			return prompt
	return {}


func _assert_prompt_hidden(state_label: String) -> bool:
	if not _prompt_result_text().is_empty() or _result_text().find(EXPECTED_LABEL) != -1:
		_fail("Pass 23 next-dive prompt visible during %s: helper=%s result=%s." % [
			state_label,
			_prompt_result_text(),
			_result_text(),
		])
		return false
	return true


func _collect_target(target: Dictionary) -> void:
	if target.is_empty():
		_fail("Pass 23 next-dive smoke missing target.")
		return
	_player.global_position = target["center"]
	_collect_salvage_for_smoke(target)
	_update_status_label()


func _collect_and_bank_target(target: Dictionary) -> void:
	_collect_target(target)
	_player.global_position = _world.get_extraction_center()
	_process(0.0)


func _objective_by_id(objective_id: String) -> Dictionary:
	for objective in _world.get_route_objectives():
		if str(objective.get("id", "")) == objective_id:
			return objective
	return {}


func _required_targets(objective: Dictionary) -> Array[String]:
	var targets: Array[String] = []
	for target_id in objective.get("required_banked_targets", []):
		targets.append(str(target_id))
	return targets


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _prompt_result_text() -> String:
	return _main._next_dive_objective_result_text()


func _result_text() -> String:
	return _result_label.text if _result_label != null else ""


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
