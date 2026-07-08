extends "res://scripts/main/smoke/smoke_check_base.gd"

const OBJECTIVE_ID := "deep_cache_route_objective"
const ROUTE_CONTEXT := "deep_cache_commitment"
const LOWER_LOOP_ID := "salvage_lower_loop"
const DEEP_CACHE_ID := "salvage_deep_right_cache"
const SAFE_TARGET_ID := "salvage_entry_shaft"
const CARGO_BLOCK_TARGET_ID := "salvage_return_branch"
const REST_MARKER_ID := "lower_loop_oxygen_rest_pocket"
const EXPECTED_ONE_HELD := "Objective: Deep cache 1/2"
const EXPECTED_TWO_HELD := "Objective: Deep cache 2/2 - bank"
const EXPECTED_ONE_BANKED := "Objective: Deep cache 1/2 banked"
const EXPECTED_COMPLETE := "Objective complete: Deep cache"
const EXPECTED_START_CUE := "Objective: Deep cache 0/2"
const EXPECTED_RESULT_COMPLETE := "Objective: Deep cache complete"
const EXPECTED_RESULT_INCOMPLETE := "Objective: Deep cache incomplete"


func _smoke_pass_13_route_commitment_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("Pass 13 route commitment smoke loaded unexpected map: %s." % _world.map_id)
		return

	var objective := _objective_by_id(OBJECTIVE_ID)
	var lower_loop := _salvage_by_id(LOWER_LOOP_ID)
	var deep_cache := _salvage_by_id(DEEP_CACHE_ID)
	var safe_target := _salvage_by_id(SAFE_TARGET_ID)
	var cargo_block_target := _salvage_by_id(CARGO_BLOCK_TARGET_ID)
	var rest_marker: Dictionary = _world.get_marker_zone(REST_MARKER_ID)
	if objective.is_empty() or lower_loop.is_empty() or deep_cache.is_empty() or safe_target.is_empty() or cargo_block_target.is_empty() or rest_marker.is_empty():
		_fail("Pass 13 route commitment smoke missing source data: objective=%s lower=%s deep=%s safe=%s cargo=%s rest=%s." % [
			str(not objective.is_empty()),
			str(not lower_loop.is_empty()),
			str(not deep_cache.is_empty()),
			str(not safe_target.is_empty()),
			str(not cargo_block_target.is_empty()),
			str(not rest_marker.is_empty()),
		])
		return

	var required_targets: Array = objective.get("required_banked_targets", [])
	var interaction_seconds := float(deep_cache.get("interaction_seconds", 0.0))
	if str(objective.get("route_context", "")) != ROUTE_CONTEXT or not required_targets.has(LOWER_LOOP_ID) or not required_targets.has(DEEP_CACHE_ID):
		_fail("Pass 13 route objective metadata mismatch: %s." % str(objective))
		return
	if str(deep_cache.get("interaction", "instant")) != "timed_salvage" or interaction_seconds <= 0.0:
		_fail("Pass 13 deep cache target must remain timed salvage: %s." % str(deep_cache))
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_update_status_label()
	if _status_text().find(EXPECTED_START_CUE) == -1:
		_fail("Pass 13 start cue missing '%s': %s." % [EXPECTED_START_CUE, _status_text()])
		return

	_collect_and_bank_target(safe_target)
	if _status_text().find("Objective complete") != -1 or _banked_salvage_ids.has(LOWER_LOOP_ID) or _banked_salvage_ids.has(DEEP_CACHE_ID):
		_fail("Pass 13 safe-route target completed objective unexpectedly: status=%s banked_ids=%s." % [_status_text(), _banked_salvage_ids])
		return
	_player.global_position = safe_target["center"]
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed or _result_label == null or _result_label.text.find(EXPECTED_RESULT_INCOMPLETE) == -1:
		_fail("Pass 13 safe/failure result did not report incomplete objective: %s." % _result_text())
		return

	_reset_run()
	_hazard_interactions_enabled = false
	_collect_target(lower_loop)
	if not _held_salvage_ids.has(LOWER_LOOP_ID) or _status_text().find(EXPECTED_ONE_HELD) == -1:
		_fail("Pass 13 lower-loop held state missing '%s': held=%s status=%s." % [EXPECTED_ONE_HELD, _held_salvage_ids, _status_text()])
		return

	_player.global_position = deep_cache["center"]
	_process(interaction_seconds * 0.4)
	if _held_salvage_ids.has(DEEP_CACHE_ID) or _status_text().find("Salvaging") == -1 or _status_text().find(EXPECTED_ONE_HELD) == -1:
		_fail("Pass 13 timed target collected too early or lost objective progress: held=%s status=%s." % [_held_salvage_ids, _status_text()])
		return
	_process(interaction_seconds + SMOKE_TIMED_SALVAGE_MARGIN_SECONDS)
	if not _held_salvage_ids.has(DEEP_CACHE_ID) or _status_text().find(EXPECTED_TWO_HELD) == -1:
		_fail("Pass 13 two-held state missing '%s': held=%s status=%s." % [EXPECTED_TWO_HELD, _held_salvage_ids, _status_text()])
		return

	_player.global_position = cargo_block_target["center"]
	_process(0.0)
	if _held_salvage != HELD_SALVAGE_CAPACITY or _held_salvage_ids.has(CARGO_BLOCK_TARGET_ID) or _world.is_salvage_collected(CARGO_BLOCK_TARGET_ID):
		_fail("Pass 13 cargo capacity did not block extra target: held=%d ids=%s collected=%s." % [_held_salvage, _held_salvage_ids, str(_world.is_salvage_collected(CARGO_BLOCK_TARGET_ID))])
		return
	if _status_text().find("Cargo full") == -1:
		_fail("Pass 13 cargo-full prompt missing while objective cargo was full: %s." % _status_text())
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or not _banked_salvage_ids.has(LOWER_LOOP_ID) or not _banked_salvage_ids.has(DEEP_CACHE_ID):
		_fail("Pass 13 required targets did not bank cleanly: held=%d banked_ids=%s." % [_held_salvage, _banked_salvage_ids])
		return
	if _status_text().find(EXPECTED_COMPLETE) == -1:
		_fail("Pass 13 complete overlay missing '%s': %s." % [EXPECTED_COMPLETE, _status_text()])
		return

	_collect_and_bank_remaining()
	if not _run_complete or _result_label == null or _result_label.text.find(EXPECTED_RESULT_COMPLETE) == -1:
		_fail("Pass 13 completed run did not report complete objective: %s." % _result_text())
		return
	var completed_banked_score := _banked_score
	var completed_oxygen := _oxygen_seconds

	_reset_run()
	_hazard_interactions_enabled = false
	_collect_and_bank_target(lower_loop)
	if _status_text().find(EXPECTED_ONE_BANKED) == -1:
		_fail("Pass 13 one-banked state missing '%s': %s." % [EXPECTED_ONE_BANKED, _status_text()])
		return
	_collect_target(deep_cache)
	_hazard_interactions_enabled = true
	var hazard: Dictionary = _world.get_hazard_centers()[0]
	_player.global_position = hazard["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _held_salvage != 0 or _world.is_salvage_collected(DEEP_CACHE_ID) or _status_text().find(EXPECTED_ONE_BANKED) == -1:
		_fail("Pass 13 hazard reset did not restore held target while preserving banked progress: held=%d deep_collected=%s status=%s." % [_held_salvage, str(_world.is_salvage_collected(DEEP_CACHE_ID)), _status_text()])
		return

	_reset_run()
	_hazard_interactions_enabled = false
	_collect_target(lower_loop)
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed or _world.is_salvage_collected(LOWER_LOOP_ID) or _result_label == null or _result_label.text.find(EXPECTED_RESULT_INCOMPLETE) == -1:
		_fail("Pass 13 oxygen failure did not restore held target and report incomplete objective: collected=%s result=%s." % [str(_world.is_salvage_collected(LOWER_LOOP_ID)), _result_text()])
		return

	_reset_run()
	var rest_center := _marker_center(rest_marker)
	_player.global_position = rest_center
	_oxygen_seconds = 20.0
	_process(1.0)
	if _status_text().find("Rest pocket +oxygen") == -1 or _status_text().find("Objective") != -1 or _banked_salvage != 0 or _held_salvage != 0:
		_fail("Pass 13 rest pocket interfered with objective/cargo state: held=%d banked=%d status=%s." % [_held_salvage, _banked_salvage, _status_text()])
		return

	_reset_run()
	print("Pass 13 route commitment smoke passed: objective=%s route=%s targets=%s timed_target=%s seconds=%.1f completion_state=complete held=%d banked_score=%d oxygen=%.1f result=\"%s\" hazard_reset=true oxygen_failure=incomplete rest_pocket_stable=true." % [
		OBJECTIVE_ID,
		ROUTE_CONTEXT,
		",".join(PackedStringArray([LOWER_LOOP_ID, DEEP_CACHE_ID])),
		DEEP_CACHE_ID,
		interaction_seconds,
		_held_salvage,
		completed_banked_score,
		completed_oxygen,
		EXPECTED_RESULT_COMPLETE,
	])
	get_tree().quit()


func _smoke_pass_14_objective_cue_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("Pass 14 objective cue smoke loaded unexpected map: %s." % _world.map_id)
		return

	var objective := _objective_by_id(OBJECTIVE_ID)
	var lower_loop := _salvage_by_id(LOWER_LOOP_ID)
	var deep_cache := _salvage_by_id(DEEP_CACHE_ID)
	var safe_target := _salvage_by_id(SAFE_TARGET_ID)
	if objective.is_empty() or lower_loop.is_empty() or deep_cache.is_empty() or safe_target.is_empty():
		_fail("Pass 14 objective cue smoke missing source data: objective=%s lower=%s deep=%s safe=%s." % [
			str(not objective.is_empty()),
			str(not lower_loop.is_empty()),
			str(not deep_cache.is_empty()),
			str(not safe_target.is_empty()),
		])
		return

	var required_targets: Array = objective.get("required_banked_targets", [])
	if str(objective.get("route_context", "")) != ROUTE_CONTEXT or not required_targets.has(LOWER_LOOP_ID) or not required_targets.has(DEEP_CACHE_ID):
		_fail("Pass 14 route objective metadata mismatch: %s." % str(objective))
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = _world.get_extraction_center()
	_update_status_label()
	if _status_text().find(EXPECTED_START_CUE) == -1:
		_fail("Pass 14 start cue missing at extraction: %s." % _status_text())
		return

	_player.global_position = safe_target["center"]
	_update_status_label()
	if _status_has_objective_text():
		_fail("Pass 14 start cue stayed visible away from extraction before route progress: %s." % _status_text())
		return

	_collect_and_bank_target(safe_target)
	if _status_text().find(EXPECTED_COMPLETE) != -1 or _banked_salvage_ids.has(LOWER_LOOP_ID) or _banked_salvage_ids.has(DEEP_CACHE_ID):
		_fail("Pass 14 safe-route banking completed deep objective unexpectedly: status=%s banked_ids=%s." % [_status_text(), _banked_salvage_ids])
		return
	if _status_text().find(EXPECTED_START_CUE) == -1:
		_fail("Pass 14 start cue missing after unrelated safe-route banking at extraction: %s." % _status_text())
		return

	_reset_run()
	_hazard_interactions_enabled = false
	_collect_target(lower_loop)
	if _status_text().find(EXPECTED_ONE_HELD) == -1:
		_fail("Pass 14 one-held progress missing '%s': %s." % [EXPECTED_ONE_HELD, _status_text()])
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _status_text().find(EXPECTED_ONE_BANKED) == -1:
		_fail("Pass 14 one-banked progress missing '%s': %s." % [EXPECTED_ONE_BANKED, _status_text()])
		return

	_collect_target(deep_cache)
	if _status_text().find(EXPECTED_TWO_HELD) == -1:
		_fail("Pass 14 two-required-target progress missing '%s': %s." % [EXPECTED_TWO_HELD, _status_text()])
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _status_text().find(EXPECTED_COMPLETE) == -1:
		_fail("Pass 14 completed objective overlay missing '%s': %s." % [EXPECTED_COMPLETE, _status_text()])
		return

	print("Pass 14 objective cue smoke passed: objective=%s start_cue=\"%s\" away_hidden=true safe_route_incomplete=true one_held=true one_banked=true two_held=true complete=true banked_ids=%s." % [
		OBJECTIVE_ID,
		EXPECTED_START_CUE,
		_banked_salvage_ids,
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


func _collect_and_bank_remaining() -> void:
	for salvage in _world.get_salvage_centers():
		var salvage_id := str(salvage.get("id", ""))
		if _world.is_salvage_collected(salvage_id):
			continue
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			_player.global_position = _world.get_extraction_center()
			_process(0.0)
		_collect_target(salvage)
	if _held_salvage > 0:
		_player.global_position = _world.get_extraction_center()
		_process(0.0)


func _objective_by_id(objective_id: String) -> Dictionary:
	for objective in _world.get_route_objectives():
		if str(objective.get("id", "")) == objective_id:
			return objective
	return {}


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _marker_center(marker: Dictionary) -> Vector2:
	var tile_size := float(_world.tile_size)
	return Vector2(
		(float(marker.get("x", 0)) + float(marker.get("w", 0)) * 0.5) * tile_size,
		(float(marker.get("y", 0)) + float(marker.get("h", 0)) * 0.5) * tile_size
	)


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""


func _status_has_objective_text() -> bool:
	return _status_text().find("Objective:") != -1 or _status_text().find("Objective complete") != -1


func _result_text() -> String:
	return _result_label.text if _result_label != null else ""


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
