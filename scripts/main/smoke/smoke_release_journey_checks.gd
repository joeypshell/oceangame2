extends "res://scripts/main/smoke/smoke_check_base.gd"

const AnomalySurveyRuntime := preload("res://scripts/main/anomaly_survey_runtime.gd")

const GATE_ID := "upper_right_current_pocket_gate"
const PAYOFF_TARGET_ID := "salvage_current_pocket_cache"
const NEXT_DIVE_LABEL := "Next dive: Investigate east current"
const OBJECTIVE_COMPLETE_LABEL := "Objective: Relay trail complete"


func _smoke_release_journey_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("loaded unexpected release origin map: %s" % _world.map_id)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var objective_id: String = _world.get_primary_route_objective_id()
	var objective := _objective_by_id(objective_id)
	var required_targets := _required_targets(objective)
	if objective_id.is_empty() or objective.is_empty() or required_targets.size() < 2:
		_fail("missing primary objective source data: objective=%s targets=%s" % [objective_id, required_targets])
		return

	var required_score := _collect_required_primary_targets(required_targets)
	if required_score < 1:
		return
	if _run_complete or _run_failed:
		_fail("completed before returning required cargo: complete=%s failed=%s" % [str(_run_complete), str(_run_failed)])
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var origin_result := _result_text()
	if not _run_complete or _run_failed:
		_fail("did not complete after banking required cargo: complete=%s failed=%s" % [str(_run_complete), str(_run_failed)])
		return
	if _banked_score != required_score:
		_fail("primary objective score mismatch: got=%d expected=%d" % [_banked_score, required_score])
		return
	if origin_result.find(OBJECTIVE_COMPLETE_LABEL) == -1 or origin_result.find(NEXT_DIVE_LABEL) == -1:
		_fail("origin result missing objective/next-dive text: %s" % origin_result)
		return
	var origin_score := _current_expedition_score()
	var origin_oxygen := _oxygen_seconds

	_reset_run()
	if not _prepare_propulsion_fins():
		return
	var gate := _gate_by_id(GATE_ID)
	if gate.is_empty():
		_fail("missing fins gate %s" % GATE_ID)
		return
	_player.global_position = gate["center"]
	if _main._try_world_connector_transition():
		_fail("standard fins current unexpectedly required E")
		return
	if _world.map_id != "production_slice_01":
		_fail("fins current changed maps: %s" % _world.map_id)
		return

	var wallet_before_payoff := _session_wallet()
	var payoff_target := _salvage_by_id(PAYOFF_TARGET_ID)
	if payoff_target.is_empty():
		_fail("missing same-map payoff target %s" % PAYOFF_TARGET_ID)
		return
	_player.global_position = payoff_target["center"]
	if not _collect_salvage_for_smoke(payoff_target):
		_fail("could not collect destination payoff target %s" % PAYOFF_TARGET_ID)
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if not bool(_main._anomaly_survey.report().get("lead_available", false)):
		_fail("same-map payoff did not activate scanner lead")
		return
	if _session_wallet() != wallet_before_payoff + AnomalySurveyRuntime.SCANNER_COST:
		_fail("same-map payoff funding delta drifted: before=%d after=%d" % [wallet_before_payoff, _session_wallet()])
		return
	var scanner_unlock: Dictionary = _main._anomaly_survey.try_unlock_scanner(_world, _player)
	if not bool(scanner_unlock.get("changed", false)) or _session_wallet() != wallet_before_payoff:
		_fail("scanner purchase failed after same-map payoff: %s" % str(scanner_unlock))
		return

	print("Release journey smoke passed: objective=%s required=%s origin_score=%d origin_oxygen=%.1f gate=%s traversal=passive same_map=%s payoff=%s scanner_funded=true scanner_unlocked=true e_required=false." % [
		objective_id,
		",".join(PackedStringArray(required_targets)),
		origin_score,
		origin_oxygen,
		GATE_ID,
		_world.map_id,
		PAYOFF_TARGET_ID,
	])
	get_tree().quit()


func _collect_required_primary_targets(required_targets: Array[String]) -> int:
	var required_score := 0
	for target_id in required_targets:
		var target := _salvage_by_id(target_id)
		if target.is_empty():
			_fail("missing required target %s" % target_id)
			return 0
		_player.global_position = target["center"]
		if not _collect_salvage_for_smoke(target):
			_fail("could not collect required target %s" % target_id)
			return 0
		required_score += int(target.get("score", 0))
		_update_status_label()
	return required_score


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


func _gate_by_id(gate_id: String) -> Dictionary:
	for gate in _world.get_current_gates():
		if str(gate.get("id", "")) == gate_id:
			return gate
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _result_text() -> String:
	return _result_label.text if _result_label != null else ""


func _fail(message: String) -> void:
	push_error("Release journey smoke %s." % message)
	get_tree().quit(1)
