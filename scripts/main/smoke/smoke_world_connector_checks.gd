extends "res://scripts/main/smoke/smoke_check_base.gd"

const PASS_21_CONNECTOR_ID := "lower_left_loop_connector"
const PASS_21_DESTINATION_MAP_ID := "production_slice_04"
const PASS_21_DESTINATION_ENTRY_ID := "relay_sub_entry"
const PASS_22_PAYOFF_TARGET_ID := "slice_04_destination_cache"
const PASS_22_PAYOFF_ID := "slice_04_destination_payoff"
const PASS_22_PAYOFF_LABEL := "Destination cache"
const PASS_24_OBJECTIVE_ID := "lower_left_relay_follow_through"
const PASS_24_TRIGGER := "destination_payoff_banked"
const PASS_24_LABEL := "Relay lead confirmed"
const PASS_24_RESULT_LABEL := "Lower-left relay investigated"


func _smoke_pass_21_world_connector_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pass 21 connector smoke loaded unexpected origin map: %s." % _world.map_id)
		get_tree().quit(1)
		return
	if not _world.has_method("get_world_connectors") or not _world.has_method("get_entry_position"):
		push_error("Pass 21 connector smoke requires world connector runtime queries.")
		get_tree().quit(1)
		return

	var connector := _connector_by_id(PASS_21_CONNECTOR_ID)
	if connector.is_empty():
		push_error("Pass 21 connector smoke did not find connector %s." % PASS_21_CONNECTOR_ID)
		get_tree().quit(1)
		return

	if str(connector.get("destination_map_id", "")) != PASS_21_DESTINATION_MAP_ID:
		push_error("Pass 21 connector smoke destination mismatch: %s." % connector)
		get_tree().quit(1)
		return
	if str(connector.get("destination_entry_id", "")) != PASS_21_DESTINATION_ENTRY_ID:
		push_error("Pass 21 connector smoke destination entry mismatch: %s." % connector)
		get_tree().quit(1)
		return

	_main._session_progression.record_banked_salvage(3600)
	_main._session_progression.purchase_oxygen_tank_upgrade()
	_main._session_progression.purchase_cargo_capacity_upgrade()
	_main._session_progression.purchase_light_upgrade()
	if not _prepare_propulsion_fins() or not _prepare_profile_capability("current_stabilizer"):
		return
	var wallet_before := _session_wallet()

	_held_salvage = 1
	_held_salvage_score = 100
	_banked_salvage = 2
	_banked_score = 200
	_held_salvage_ids = ["origin_probe_salvage"]
	_main._banked_validation_route_counts = {"origin_probe_route": 1}
	_last_status_note = "Collected common salvage +100"
	_player.global_position = connector["center"]
	_update_status_label()
	var status_before := _status_text()
	if status_before.find("E: Enter Lower-left relay") == -1:
		push_error("Pass 21 connector smoke prompt missing before transition: %s." % status_before)
		get_tree().quit(1)
		return

	if not _main._try_world_connector_transition():
		push_error("Pass 21 connector smoke did not trigger transition.")
		get_tree().quit(1)
		return
	var destination_entry: Vector2 = _world.get_entry_position(PASS_21_DESTINATION_ENTRY_ID)
	if _world.map_id != PASS_21_DESTINATION_MAP_ID:
		push_error("Pass 21 connector smoke loaded wrong destination map: %s." % _world.map_id)
		get_tree().quit(1)
		return
	if _player.global_position.distance_to(destination_entry) > 1.0:
		push_error("Pass 21 connector smoke arrival position mismatch: %s expected %s." % [_player.global_position, destination_entry])
		get_tree().quit(1)
		return
	if _held_salvage != 0 or _held_salvage_score != 0 or _banked_salvage != 0 or _banked_score != 0 or not _held_salvage_ids.is_empty():
		push_error("Pass 21 connector smoke local state did not reset: held=%d held_score=%d banked=%d banked_score=%d ids=%s." % [
			_held_salvage,
			_held_salvage_score,
			_banked_salvage,
			_banked_score,
			_held_salvage_ids,
		])
		get_tree().quit(1)
		return
	if not _main._banked_validation_route_counts.is_empty() or _run_complete or _run_failed or (_result_panel != null and _result_panel.visible):
		push_error("Pass 21 connector smoke leaked origin result/route state: counts=%s complete=%s failed=%s result_visible=%s." % [
			_main._banked_validation_route_counts,
			str(_run_complete),
			str(_run_failed),
			str(_result_panel != null and _result_panel.visible),
		])
		get_tree().quit(1)
		return
	if not _has_oxygen_tank_upgrade() or not _has_cargo_capacity_upgrade() or not _has_light_upgrade() or not _main._has_propulsion_upgrade() or _session_wallet() != wallet_before:
		push_error("Pass 21 connector smoke session progression changed: wallet=%d before=%d oxygen=%s cargo=%s light=%s propulsion=%s." % [
			_session_wallet(),
			wallet_before,
			str(_has_oxygen_tank_upgrade()),
			str(_has_cargo_capacity_upgrade()),
			str(_has_light_upgrade()),
			str(_main._has_propulsion_upgrade()),
		])
		get_tree().quit(1)
		return
	if not is_equal_approx(_oxygen_seconds, _oxygen_capacity_seconds()):
		push_error("Pass 21 connector smoke destination oxygen mismatch: oxygen=%.1f capacity=%.1f." % [_oxygen_seconds, _oxygen_capacity_seconds()])
		get_tree().quit(1)
		return
	if _total_salvage != _world.get_total_salvage_count() or _world.get_salvage_centers().is_empty():
		push_error("Pass 21 connector smoke destination salvage state mismatch: total=%d runtime=%d." % [_total_salvage, _world.get_total_salvage_count()])
		get_tree().quit(1)
		return
	if _world.find_open_path(_player.global_position, _world.get_salvage_centers()[0]["center"]).is_empty():
		push_error("Pass 21 connector smoke destination route was corrupted after transition.")
		get_tree().quit(1)
		return

	_update_status_label()
	var final_status := _status_text().replace("\n", " | ")
	if final_status.find("Arrived: Lower-left relay") == -1 or final_status.find("E: Enter Boat hub") == -1:
		push_error("Pass 21 connector smoke final status missing arrival/return prompt: %s." % final_status)
		get_tree().quit(1)
		return

	print("Pass 21 connector smoke passed: connector=%s origin=production_slice_01 destination=%s entry=%s wallet=%d upgrades=o2:%s,cargo:%s,light:%s,propulsion:%s held=%d oxygen=%.1f status=\"%s\"." % [
		PASS_21_CONNECTOR_ID,
		_world.map_id,
		PASS_21_DESTINATION_ENTRY_ID,
		_session_wallet(),
		str(_has_oxygen_tank_upgrade()),
		str(_has_cargo_capacity_upgrade()),
		str(_has_light_upgrade()),
		str(_main._has_propulsion_upgrade()),
		_held_salvage,
		_oxygen_seconds,
		final_status,
	])
	get_tree().quit()


func _smoke_pass_22_destination_payoff_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pass 22 destination payoff smoke loaded unexpected origin map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	var connector := _connector_by_id(PASS_21_CONNECTOR_ID)
	if connector.is_empty():
		push_error("Pass 22 destination payoff smoke did not find connector %s." % PASS_21_CONNECTOR_ID)
		get_tree().quit(1)
		return
	if str(connector.get("destination_map_id", "")) != PASS_21_DESTINATION_MAP_ID:
		push_error("Pass 22 destination payoff smoke connector destination mismatch: %s." % connector)
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	if not _prepare_propulsion_fins() or not _prepare_profile_capability("current_stabilizer"):
		return
	_player.global_position = connector["center"]
	_update_status_label()
	if _status_text().find("E: Enter Lower-left relay") == -1:
		push_error("Pass 22 destination payoff smoke prompt missing before transition: %s." % _status_text())
		get_tree().quit(1)
		return
	if not _main._try_world_connector_transition():
		push_error("Pass 22 destination payoff smoke did not trigger connector transition.")
		get_tree().quit(1)
		return
	if _world.map_id != PASS_21_DESTINATION_MAP_ID:
		push_error("Pass 22 destination payoff smoke loaded wrong destination map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var target := _salvage_by_id(PASS_22_PAYOFF_TARGET_ID)
	if target.is_empty():
		push_error("Pass 22 destination payoff smoke did not find payoff target %s." % PASS_22_PAYOFF_TARGET_ID)
		get_tree().quit(1)
		return
	if str(target.get("destination_payoff_id", "")) != PASS_22_PAYOFF_ID:
		push_error("Pass 22 destination payoff smoke payoff id mismatch: %s." % target)
		get_tree().quit(1)
		return
	if str(target.get("destination_payoff_connector_id", "")) != PASS_21_CONNECTOR_ID:
		push_error("Pass 22 destination payoff smoke connector id mismatch: %s." % target)
		get_tree().quit(1)
		return
	if _world.find_open_path(_player.global_position, target["center"]).is_empty():
		push_error("Pass 22 destination payoff smoke target is not reachable from destination entry.")
		get_tree().quit(1)
		return

	_player.global_position = target["center"]
	if not _collect_salvage_for_smoke(target):
		push_error("Pass 22 destination payoff smoke did not collect target %s." % PASS_22_PAYOFF_TARGET_ID)
		get_tree().quit(1)
		return

	var target_score := int(target.get("score", 0))
	var expected_feedback := "%s +%d" % [PASS_22_PAYOFF_LABEL, target_score]
	if _last_status_note != expected_feedback or _status_text().find(expected_feedback) == -1:
		push_error("Pass 22 destination payoff smoke expected feedback '%s', got note='%s' status='%s'." % [
			expected_feedback,
			_last_status_note,
			_status_text(),
		])
		get_tree().quit(1)
		return
	if _held_salvage != 1 or _held_salvage_score != target_score or not _held_salvage_ids.has(PASS_22_PAYOFF_TARGET_ID):
		push_error("Pass 22 destination payoff smoke cargo mismatch: held=%d score=%d ids=%s." % [
			_held_salvage,
			_held_salvage_score,
			_held_salvage_ids,
		])
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage != 1 or _banked_score != target_score:
		push_error("Pass 22 destination payoff smoke banking mismatch: held=%d banked=%d score=%d expected=%d." % [
			_held_salvage,
			_banked_salvage,
			_banked_score,
			target_score,
		])
		get_tree().quit(1)
		return

	print("Pass 22 destination payoff smoke passed: origin=production_slice_01 destination=%s connector=%s target=%s payoff=%s label=\"%s\" state=banked held=%d banked=%d score=%d oxygen=%.1f feedback=\"%s\"." % [
		_world.map_id,
		PASS_21_CONNECTOR_ID,
		PASS_22_PAYOFF_TARGET_ID,
		PASS_22_PAYOFF_ID,
		PASS_22_PAYOFF_LABEL,
		_held_salvage,
		_banked_salvage,
		_banked_score,
		_oxygen_seconds,
		expected_feedback,
	])
	get_tree().quit()


func _smoke_pass_24_relay_follow_through_and_quit() -> void:
	_load_playable_map(PRODUCTION_SLICE_MAP_PATH, false)
	if _world.map_id != "production_slice_01":
		push_error("Pass 24 relay smoke loaded unexpected origin map: %s." % _world.map_id)
		get_tree().quit(1)
		return
	if not _relay_objectives().is_empty() or not _relay_result_text().is_empty():
		push_error("Pass 24 relay smoke expected no origin relay metadata/result: objectives=%s result=%s." % [
			_relay_objectives(),
			_relay_result_text(),
		])
		get_tree().quit(1)
		return

	var connector := _connector_by_id(PASS_21_CONNECTOR_ID)
	if connector.is_empty():
		push_error("Pass 24 relay smoke did not find connector %s." % PASS_21_CONNECTOR_ID)
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	if not _prepare_propulsion_fins() or not _prepare_profile_capability("current_stabilizer"):
		return
	_player.global_position = connector["center"]
	_update_status_label()
	if not _main._try_world_connector_transition():
		push_error("Pass 24 relay smoke did not trigger connector transition.")
		get_tree().quit(1)
		return
	if _world.map_id != PASS_21_DESTINATION_MAP_ID:
		push_error("Pass 24 relay smoke loaded wrong destination map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var objective := _relay_objective_by_id(PASS_24_OBJECTIVE_ID)
	if objective.is_empty():
		push_error("Pass 24 relay smoke did not find objective %s in %s." % [PASS_24_OBJECTIVE_ID, _world.map_id])
		get_tree().quit(1)
		return
	if (
		str(objective.get("trigger", "")) != PASS_24_TRIGGER
		or str(objective.get("target_id", "")) != PASS_22_PAYOFF_TARGET_ID
		or str(objective.get("connector_id", "")) != PASS_21_CONNECTOR_ID
		or str(objective.get("entry_id", "")) != PASS_21_DESTINATION_ENTRY_ID
		or str(objective.get("label", "")) != PASS_24_LABEL
		or str(objective.get("result_label", "")) != PASS_24_RESULT_LABEL
	):
		push_error("Pass 24 relay smoke metadata mismatch: %s." % objective)
		get_tree().quit(1)
		return
	if not _relay_result_text().is_empty() or _status_text().find(PASS_24_LABEL) != -1:
		push_error("Pass 24 relay smoke showed relay feedback before target banking: helper=%s status=%s." % [
			_relay_result_text(),
			_status_text(),
		])
		get_tree().quit(1)
		return

	var target := _salvage_by_id(PASS_22_PAYOFF_TARGET_ID)
	if target.is_empty():
		push_error("Pass 24 relay smoke did not find target %s." % PASS_22_PAYOFF_TARGET_ID)
		get_tree().quit(1)
		return
	var target_score := int(target.get("score", 0))
	_player.global_position = target["center"]
	if not _collect_salvage_for_smoke(target):
		push_error("Pass 24 relay smoke did not collect target %s." % PASS_22_PAYOFF_TARGET_ID)
		get_tree().quit(1)
		return
	var collection_feedback := "%s +%d" % [PASS_22_PAYOFF_LABEL, target_score]
	if _last_status_note != collection_feedback or _status_text().find(PASS_24_LABEL) != -1:
		push_error("Pass 24 relay smoke expected ordinary collection before banking: note=%s status=%s." % [
			_last_status_note,
			_status_text(),
		])
		get_tree().quit(1)
		return
	if not _relay_result_text().is_empty():
		push_error("Pass 24 relay smoke result appeared before banking: %s." % _relay_result_text())
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _last_status_note.find(PASS_24_LABEL) == -1 or _status_text().find(PASS_24_LABEL) == -1:
		push_error("Pass 24 relay smoke missing banked feedback '%s': note=%s status=%s." % [
			PASS_24_LABEL,
			_last_status_note,
			_status_text(),
		])
		get_tree().quit(1)
		return
	if _held_salvage != 0 or _banked_salvage != 1 or _banked_score != target_score or not _main._banked_salvage_ids.has(PASS_22_PAYOFF_TARGET_ID):
		push_error("Pass 24 relay smoke banking state mismatch: held=%d banked=%d score=%d ids=%s." % [
			_held_salvage,
			_banked_salvage,
			_banked_score,
			_main._banked_salvage_ids,
		])
		get_tree().quit(1)
		return
	if not _relay_result_text().is_empty():
		push_error("Pass 24 relay smoke result appeared before run completion: %s." % _relay_result_text())
		get_tree().quit(1)
		return

	_main._run_complete = true
	_main._sortie_state.failed = false
	_main._update_result_panel()
	var completed_result_text := _result_text()
	if _relay_result_text() != PASS_24_RESULT_LABEL or completed_result_text.find(PASS_24_RESULT_LABEL) == -1:
		push_error("Pass 24 relay smoke missing complete result: helper=%s result=%s." % [
			_relay_result_text(),
			completed_result_text,
		])
		get_tree().quit(1)
		return

	_main._run_complete = false
	_main._sortie_state.failed = true
	_main._update_result_panel()
	if not _relay_result_text().is_empty() or _result_text().find(PASS_24_RESULT_LABEL) != -1:
		push_error("Pass 24 relay smoke failed state leaked result: helper=%s result=%s." % [
			_relay_result_text(),
			_result_text(),
		])
		get_tree().quit(1)
		return

	print("Pass 24 relay follow-through smoke passed: objective=%s target=%s trigger=%s map=%s label=\"%s\" result=\"%s\" held=%d banked=%d score=%d oxygen=%.1f state=banked_complete." % [
		PASS_24_OBJECTIVE_ID,
		PASS_22_PAYOFF_TARGET_ID,
		PASS_24_TRIGGER,
		_world.map_id,
		PASS_24_LABEL,
		PASS_24_RESULT_LABEL,
		_held_salvage,
		_banked_salvage,
		_banked_score,
		_oxygen_seconds,
	])
	get_tree().quit()


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


func _relay_objective_by_id(objective_id: String) -> Dictionary:
	for objective in _relay_objectives():
		if typeof(objective) == TYPE_DICTIONARY and str(objective.get("id", "")) == objective_id:
			return objective
	return {}


func _relay_objectives() -> Array:
	if not _world.has_method("get_relay_follow_through_objectives"):
		return []
	return _world.get_relay_follow_through_objectives()


func _relay_result_text() -> String:
	return _main._relay_follow_through_result_text()


func _result_text() -> String:
	return _result_label.text if _result_label != null else ""


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
