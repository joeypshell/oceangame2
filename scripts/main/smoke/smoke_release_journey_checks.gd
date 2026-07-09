extends "res://scripts/main/smoke/smoke_check_base.gd"

const CONNECTOR_ID := "lower_left_loop_connector"
const DESTINATION_MAP_ID := "production_slice_04"
const PAYOFF_TARGET_ID := "slice_04_destination_cache"
const NEXT_DIVE_LABEL := "Next dive: Investigate lower-left relay"
const OBJECTIVE_COMPLETE_LABEL := "Objective: Deep cache complete"
const RELAY_LABEL := "Relay lead confirmed"
const FINAL_SEED_LABEL := "Final dive signal discovered"
const FINAL_RESULT_LABEL := "Final dive signal found"
const FINAL_CUE_LABEL := "Final dive signal locked"


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
	_main._session_progression.record_banked_salvage(1200)
	_main._session_progression.purchase_propulsion_upgrade()
	var connector := _connector_by_id(CONNECTOR_ID)
	if connector.is_empty():
		_fail("missing connector %s" % CONNECTOR_ID)
		return
	_player.global_position = connector["center"]
	if not _main._try_world_connector_transition():
		_fail("could not transition through connector %s" % CONNECTOR_ID)
		return
	if _world.map_id != DESTINATION_MAP_ID:
		_fail("loaded wrong destination map: %s" % _world.map_id)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var payoff_target := _salvage_by_id(PAYOFF_TARGET_ID)
	if payoff_target.is_empty():
		_fail("missing destination payoff target %s" % PAYOFF_TARGET_ID)
		return
	_player.global_position = payoff_target["center"]
	if not _collect_salvage_for_smoke(payoff_target):
		_fail("could not collect destination payoff target %s" % PAYOFF_TARGET_ID)
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _last_status_note.find(RELAY_LABEL) == -1 or _last_status_note.find(FINAL_SEED_LABEL) == -1:
		_fail("destination banking missing relay/final feedback: %s" % _last_status_note)
		return
	var destination_score := _banked_score
	var destination_oxygen := _oxygen_seconds

	_main._run_complete = true
	_main._run_failed = false
	_main._update_result_panel()
	var final_result := _result_text()
	if final_result.find(FINAL_RESULT_LABEL) == -1 or final_result.find(FINAL_CUE_LABEL) == -1:
		_fail("final result missing release payoff text: %s" % final_result)
		return

	print("Release journey smoke passed: objective=%s required=%s origin_score=%d origin_oxygen=%.1f connector=%s destination=%s payoff=%s destination_score=%d destination_oxygen=%.1f final=\"%s\"." % [
		objective_id,
		",".join(PackedStringArray(required_targets)),
		origin_score,
		origin_oxygen,
		CONNECTOR_ID,
		_world.map_id,
		PAYOFF_TARGET_ID,
		destination_score,
		destination_oxygen,
		FINAL_RESULT_LABEL,
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


func _connector_by_id(connector_id: String) -> Dictionary:
	for connector in _world.get_world_connectors():
		if str(connector.get("id", "")) == connector_id:
			return connector
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
