extends "res://scripts/main/smoke/smoke_check_base.gd"

const CONNECTOR_ID := "lower_left_loop_connector"
const DESTINATION_MAP_ID := "production_slice_04"
const PAYOFF_TARGET_ID := "slice_04_destination_cache"
const RELAY_OBJECTIVE_ID := "lower_left_relay_follow_through"
const RELAY_LABEL := "Relay lead confirmed"
const SEED_ID := "lower_left_final_dive_signal"
const SEED_TRIGGER := "relay_follow_through_complete"
const SEED_LABEL := "Final dive signal discovered"
const SEED_RESULT_LABEL := "Final dive signal found"


func _smoke_pass_25_final_dive_objective_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("loaded unexpected origin map: %s" % _world.map_id)
		return
	if not _final_dive_seeds().is_empty() or not _final_dive_result_text().is_empty():
		_fail("expected no origin seed/result: seeds=%s result=%s" % [_final_dive_seeds(), _final_dive_result_text()])
		return

	var connector := _connector_by_id(CONNECTOR_ID)
	if connector.is_empty():
		_fail("did not find connector %s" % CONNECTOR_ID)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_main._session_progression.record_banked_salvage(1200)
	_main._session_progression.purchase_propulsion_upgrade()
	_player.global_position = connector["center"]
	if not _main._try_world_connector_transition():
		_fail("did not trigger connector transition")
		return
	if _world.map_id != DESTINATION_MAP_ID:
		_fail("loaded wrong destination map: %s" % _world.map_id)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var seed := _final_dive_seed_by_id(SEED_ID)
	if seed.is_empty():
		_fail("did not find seed %s in %s" % [SEED_ID, _world.map_id])
		return
	if not _seed_metadata_matches(seed):
		_fail("metadata mismatch: %s" % seed)
		return
	if _status_text().find(SEED_LABEL) != -1 or not _final_dive_result_text().is_empty():
		_fail("showed seed feedback before trigger: status=%s result=%s" % [_status_text(), _final_dive_result_text()])
		return

	var target := _salvage_by_id(PAYOFF_TARGET_ID)
	if target.is_empty():
		_fail("did not find target %s" % PAYOFF_TARGET_ID)
		return
	var target_score := int(target.get("score", 0))
	_player.global_position = target["center"]
	if not _collect_salvage_for_smoke(target):
		_fail("did not collect target %s" % PAYOFF_TARGET_ID)
		return
	if _last_status_note.find(SEED_LABEL) != -1 or not _final_dive_result_text().is_empty():
		_fail("appeared before banking: note=%s result=%s" % [_last_status_note, _final_dive_result_text()])
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _last_status_note.find(RELAY_LABEL) == -1 or _last_status_note.find(SEED_LABEL) == -1:
		_fail("missing combined banked feedback: note=%s" % _last_status_note)
		return
	if _status_text().find(SEED_LABEL) == -1 or _held_salvage != 0 or _banked_salvage != 1 or _banked_score != target_score:
		_fail("banking/status mismatch: status=%s held=%d banked=%d score=%d" % [
			_status_text(),
			_held_salvage,
			_banked_salvage,
			_banked_score,
		])
		return
	if not _final_dive_result_text().is_empty():
		_fail("result appeared before run completion: %s" % _final_dive_result_text())
		return

	_main._run_complete = true
	_main._run_failed = false
	_main._update_result_panel()
	if _final_dive_result_text() != SEED_RESULT_LABEL or _result_text().find(SEED_RESULT_LABEL) == -1:
		_fail("missing complete result: helper=%s result=%s" % [_final_dive_result_text(), _result_text()])
		return

	var completed_banked := _banked_salvage
	var completed_score := _banked_score
	var completed_oxygen := _oxygen_seconds

	_main._run_complete = false
	_main._run_failed = true
	_main._update_result_panel()
	if not _final_dive_result_text().is_empty() or _result_text().find(SEED_RESULT_LABEL) != -1:
		_fail("failed state leaked result: helper=%s result=%s" % [_final_dive_result_text(), _result_text()])
		return

	_main._reset_run()
	if not _final_dive_result_text().is_empty() or _status_text().find(SEED_LABEL) != -1:
		_fail("reset leaked state: helper=%s status=%s" % [_final_dive_result_text(), _status_text()])
		return

	print("Pass 25 final-dive objective smoke passed: seed=%s source=%s target=%s trigger=%s label=\"%s\" result=\"%s\" completed_banked=%d completed_score=%d completed_oxygen=%.1f reset_banked=%d reset_score=%d reset_oxygen=%.1f." % [
		SEED_ID,
		RELAY_OBJECTIVE_ID,
		PAYOFF_TARGET_ID,
		SEED_TRIGGER,
		SEED_LABEL,
		SEED_RESULT_LABEL,
		completed_banked,
		completed_score,
		completed_oxygen,
		_banked_salvage,
		_banked_score,
		_oxygen_seconds,
	])
	get_tree().quit()


func _seed_metadata_matches(seed: Dictionary) -> bool:
	return (
		str(seed.get("trigger", "")) == SEED_TRIGGER
		and str(seed.get("source_objective_id", "")) == RELAY_OBJECTIVE_ID
		and str(seed.get("target_id", "")) == PAYOFF_TARGET_ID
		and str(seed.get("label", "")) == SEED_LABEL
		and str(seed.get("result_label", "")) == SEED_RESULT_LABEL
	)


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


func _final_dive_seed_by_id(seed_id: String) -> Dictionary:
	for seed in _final_dive_seeds():
		if typeof(seed) == TYPE_DICTIONARY and str(seed.get("id", "")) == seed_id:
			return seed
	return {}


func _final_dive_seeds() -> Array:
	if not _world.has_method("get_final_dive_objective_seeds"):
		return []
	return _world.get_final_dive_objective_seeds()


func _final_dive_result_text() -> String:
	return _main._final_dive_objective_result_text()


func _result_text() -> String:
	return _result_label.text if _result_label != null else ""


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""


func _fail(message: String) -> void:
	push_error("Pass 25 final-dive smoke %s." % message)
	get_tree().quit(1)
