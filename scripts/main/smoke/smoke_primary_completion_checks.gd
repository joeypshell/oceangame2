extends "res://scripts/main/smoke/smoke_check_base.gd"

const EXPECTED_RESULT_COMPLETE := "Objective: Deep cache complete"
const EXPECTED_RESULT_INCOMPLETE := "Objective: Deep cache incomplete"


func _smoke_primary_dive_completion_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("Primary dive completion smoke loaded unexpected map: %s." % _world.map_id)
		return

	var primary_objective_id: String = _world.get_primary_route_objective_id()
	var objective := _objective_by_id(primary_objective_id)
	var required_targets := _required_targets(objective)
	var optional_target := _optional_salvage(required_targets)
	if primary_objective_id.is_empty() or objective.is_empty() or required_targets.size() < 2 or optional_target.is_empty():
		_fail("Primary dive completion smoke missing source data: primary=%s objective=%s required=%s optional=%s." % [
			primary_objective_id,
			str(not objective.is_empty()),
			required_targets,
			str(not optional_target.is_empty()),
		])
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_collect_and_bank_target(optional_target)
	if _run_complete or _result_panel.visible:
		_fail("Primary dive completion smoke completed after optional cargo: banked=%d ids=%s result_visible=%s." % [
			_banked_salvage,
			_banked_salvage_ids,
			str(_result_panel.visible),
		])
		return
	var optional_score := _banked_score
	var optional_banked := _banked_salvage

	var required_score := 0
	for target_id in required_targets:
		var target := _salvage_by_id(target_id)
		if target.is_empty():
			_fail("Primary dive completion smoke missing required target %s." % target_id)
			return
		required_score += int(target.get("score", 0))
		_collect_target(target)

	if _run_complete or _held_salvage != required_targets.size():
		_fail("Primary dive completion smoke completed before banking primary cargo: complete=%s held=%d ids=%s." % [
			str(_run_complete),
			_held_salvage,
			_held_salvage_ids,
		])
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not _run_complete or _result_label == null or _result_label.text.find(EXPECTED_RESULT_COMPLETE) == -1:
		_fail("Primary dive completion smoke did not complete after banking primary objective: result=%s." % _result_text())
		return
	if _banked_score != optional_score + required_score:
		_fail("Primary dive completion smoke banked score mismatch: got=%d expected=%d." % [_banked_score, optional_score + required_score])
		return
	var completed_score := _banked_score
	var completed_oxygen := _oxygen_seconds

	_reset_run()
	if _run_complete or _run_failed or _held_salvage != 0 or _banked_salvage != 0 or _banked_score != 0:
		_fail("Primary dive completion smoke reset left stale state: complete=%s failed=%s held=%d banked=%d score=%d." % [
			str(_run_complete),
			str(_run_failed),
			_held_salvage,
			_banked_salvage,
			_banked_score,
		])
		return

	var first_required := _salvage_by_id(required_targets[0])
	var second_required := _salvage_by_id(required_targets[1])
	_hazard_interactions_enabled = false
	_collect_and_bank_target(first_required)
	_collect_target(second_required)
	_hazard_interactions_enabled = true
	var hazard: Dictionary = _world.get_hazard_centers()[0]
	_player.global_position = hazard["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _run_complete or _run_failed or _held_salvage != 0 or _world.is_salvage_collected(str(second_required.get("id", ""))):
		_fail("Primary dive completion smoke hazard reset left stale completion/cargo: complete=%s failed=%s held=%d restored=%s." % [
			str(_run_complete),
			str(_run_failed),
			_held_salvage,
			str(not _world.is_salvage_collected(str(second_required.get("id", "")))),
		])
		return

	_reset_run()
	_hazard_interactions_enabled = false
	_collect_target(first_required)
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed or _run_complete or _world.is_salvage_collected(str(first_required.get("id", ""))) or _result_text().find(EXPECTED_RESULT_INCOMPLETE) == -1:
		_fail("Primary dive completion smoke oxygen failure left stale completion state: complete=%s failed=%s collected=%s result=%s." % [
			str(_run_complete),
			str(_run_failed),
			str(_world.is_salvage_collected(str(first_required.get("id", "")))),
			_result_text(),
		])
		return

	_reset_run()
	print("Primary dive completion smoke passed: objective=%s optional_banked=%d required=%s completed_score=%d oxygen=%.1f hazard_reset=true oxygen_failure=incomplete." % [
		primary_objective_id,
		optional_banked,
		",".join(PackedStringArray(required_targets)),
		completed_score,
		completed_oxygen,
	])
	get_tree().quit()


func _collect_target(target: Dictionary) -> void:
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


func _optional_salvage(required_targets: Array[String]) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if not required_targets.has(str(salvage.get("id", ""))):
			return salvage
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _result_text() -> String:
	return _result_label.text if _result_label != null else ""


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
