extends "res://scripts/main/smoke/smoke_check_base.gd"

func _smoke_map_selector_and_quit() -> void:
	_load_playable_map(PRODUCTION_SLICE_03_MAP_PATH, false)
	if _world.map_id != "production_slice_03":
		push_error("Map selector smoke expected production_slice_03, loaded %s." % _world.map_id)
		get_tree().quit(1)
		return

	_load_playable_map(PRODUCTION_SLICE_MAP_PATH, false)
	if _world.map_id != "production_slice_01":
		push_error("Map selector smoke expected production_slice_01, loaded %s." % _world.map_id)
		get_tree().quit(1)
		return

	print("Map selector smoke passed: switched to production_slice_03 and back to production_slice_01.")
	get_tree().quit()



func _smoke_hazard_interaction_and_quit() -> void:
	var salvage: Array = _world.get_salvage_centers()
	var hazards: Array = _world.get_hazard_centers()
	if salvage.is_empty() or hazards.is_empty():
		push_error("Hazard smoke requires authored salvage and hazard entities.")
		get_tree().quit(1)
		return

	_player.global_position = salvage[0]["center"]
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids.is_empty():
		push_error("Hazard smoke could not collect setup salvage.")
		get_tree().quit(1)
		return

	var collected_id := _held_salvage_ids[0]
	var warning_position := _hazard_warning_probe_position(hazards[0]["center"])
	var warning_hazard: Dictionary = _world.get_nearest_hazard_within(warning_position, HAZARD_WARNING_RADIUS)
	if warning_hazard.is_empty() or not _world.get_hazard_near(warning_position, HAZARD_CONTACT_RADIUS).is_empty():
		push_error("Hazard smoke could not find a warning-only probe position near %s." % str(hazards[0].get("id", "hazard")))
		get_tree().quit(1)
		return

	_player.global_position = warning_position
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	var warning_id := str(warning_hazard.get("id", "hazard"))
	if _held_salvage != 1 or _held_salvage_ids[0] != collected_id:
		push_error("Hazard smoke warning range dropped held salvage; held=%d ids=%s." % [_held_salvage, _held_salvage_ids])
		get_tree().quit(1)
		return
	if _player.global_position.distance_to(warning_position) > 2.0:
		push_error("Hazard smoke warning range moved player unexpectedly to %s." % _player.global_position)
		get_tree().quit(1)
		return
	if _hazard_warning_id != warning_id or _status_label == null or _status_label.text.find("Hazard nearby - keep clear") == -1:
		push_error("Hazard smoke did not show warning for %s; warning=%s status=%s." % [warning_id, _hazard_warning_id, _status_label.text])
		get_tree().quit(1)
		return

	var oxygen_before_hit := _oxygen_seconds
	var warning_distance := warning_position.distance_to(warning_hazard["center"])
	_player.global_position = warning_hazard["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _held_salvage != 0 or not _held_salvage_ids.is_empty():
		push_error("Hazard smoke did not drop held salvage.")
		get_tree().quit(1)
		return
	if _player.global_position.distance_to(_world.spawn_position) > 2.0:
		push_error("Hazard smoke did not return player to spawn.")
		get_tree().quit(1)
		return
	var expected_oxygen_after_hit := oxygen_before_hit - HAZARD_OXYGEN_PENALTY_SECONDS
	if _run_failed or not is_equal_approx(_oxygen_seconds, expected_oxygen_after_hit):
		push_error("Hazard smoke expected oxygen %.1f after penalty, got %.1f failed=%s." % [expected_oxygen_after_hit, _oxygen_seconds, str(_run_failed)])
		get_tree().quit(1)
		return
	if _status_label == null or _status_label.text.find("oxygen -%ds" % int(HAZARD_OXYGEN_PENALTY_SECONDS)) == -1:
		push_error("Hazard smoke did not show oxygen penalty feedback: %s" % _status_label.text)
		get_tree().quit(1)
		return
	var oxygen_after_hit := _oxygen_seconds

	_player.global_position = salvage[0]["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids[0] != collected_id:
		push_error("Hazard smoke did not restore dropped salvage for recollection.")
		get_tree().quit(1)
		return

	_reset_run()
	_player.global_position = salvage[0]["center"]
	_process(0.0)
	_oxygen_seconds = HAZARD_OXYGEN_PENALTY_SECONDS * 0.5
	_player.global_position = warning_hazard["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if not _run_failed or _held_salvage != 0 or not _held_salvage_ids.is_empty():
		push_error("Hazard smoke expected oxygen failure after low-oxygen hazard hit; failed=%s held=%d ids=%s." % [str(_run_failed), _held_salvage, _held_salvage_ids])
		get_tree().quit(1)
		return
	if _world.is_salvage_collected(collected_id):
		push_error("Hazard smoke low-oxygen failure did not restore held salvage %s." % collected_id)
		get_tree().quit(1)
		return
	if not _result_panel.visible or _result_label == null or _result_label.text.find("Expedition failed") == -1:
		push_error("Hazard smoke low-oxygen penalty did not show failed result panel: %s" % _result_label.text)
		get_tree().quit(1)
		return

	_reset_run()
	print("Hazard pressure smoke passed: hazard=%s warning_distance=%.1f warning_radius=%.1f contact_radius=%.1f oxygen=%.1f->%.1f restored=%s low_oxygen_failure=true." % [
		warning_id,
		warning_distance,
		HAZARD_WARNING_RADIUS,
		HAZARD_CONTACT_RADIUS,
		oxygen_before_hit,
		oxygen_after_hit,
		collected_id,
	])
	get_tree().quit()



func _hazard_warning_probe_position(hazard_center: Vector2) -> Vector2:
	var warning_distance := HAZARD_CONTACT_RADIUS + 8.0
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]
	for direction in directions:
		var candidate: Vector2 = hazard_center + direction * warning_distance
		if _world.get_hazard_near(candidate, HAZARD_CONTACT_RADIUS).is_empty() and not _world.get_nearest_hazard_within(candidate, HAZARD_WARNING_RADIUS).is_empty():
			return candidate
	return hazard_center + Vector2.RIGHT * warning_distance



func _smoke_oxygen_pressure_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Oxygen pressure smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return

	var salvage: Array = _world.get_salvage_centers()
	if salvage.is_empty():
		push_error("Oxygen pressure smoke requires authored salvage.")
		get_tree().quit(1)
		return

	_player.global_position = salvage[0]["center"]
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids.is_empty():
		push_error("Oxygen pressure smoke could not collect setup salvage.")
		get_tree().quit(1)
		return

	var collected_id := _held_salvage_ids[0]
	_oxygen_seconds = 0.1
	_process(0.2)
	if _held_salvage != 0 or not _held_salvage_ids.is_empty():
		push_error("Oxygen pressure smoke did not drop held salvage on depletion.")
		get_tree().quit(1)
		return
	if not _run_failed:
		push_error("Oxygen pressure smoke did not enter a failed retry state.")
		get_tree().quit(1)
		return
	if _result_panel == null or not _result_panel.visible or _result_label.text.find("Expedition failed") == -1:
		push_error("Oxygen pressure smoke did not show failed expedition result panel: %s" % _result_label.text)
		get_tree().quit(1)
		return
	if _player.global_position.distance_to(_world.spawn_position) > 2.0:
		push_error("Oxygen pressure smoke did not return player to spawn.")
		get_tree().quit(1)
		return
	if not is_equal_approx(_oxygen_seconds, OXYGEN_MAX_SECONDS):
		push_error("Oxygen pressure smoke did not refill oxygen after depletion.")
		get_tree().quit(1)
		return

	_reset_run()
	if _run_failed or _held_salvage != 0 or _banked_salvage != 0 or _banked_score != 0:
		push_error("Oxygen pressure smoke reset did not clear failed run state.")
		get_tree().quit(1)
		return

	_player.global_position = salvage[0]["center"]
	_process(0.0)
	if _held_salvage != 1 or _held_salvage_ids[0] != collected_id:
		push_error("Oxygen pressure smoke did not restore dropped salvage for recollection.")
		get_tree().quit(1)
		return

	_oxygen_seconds = OXYGEN_MAX_SECONDS * 0.5
	_player.global_position = _world.get_extraction_center()
	_process(1.0)
	if _banked_salvage != 1 or _held_salvage != 0:
		push_error("Oxygen pressure smoke did not preserve collect-return banking.")
		get_tree().quit(1)
		return
	if _oxygen_seconds <= OXYGEN_MAX_SECONDS * 0.5:
		push_error("Oxygen pressure smoke did not refill at extraction.")
		get_tree().quit(1)
		return

	_reset_run()
	print("Oxygen pressure smoke passed: depleted, surfaced, restored salvage, refilled, and banked salvage.")
	get_tree().quit()


func _smoke_timed_salvage_and_quit() -> void:
	var target := _timed_salvage_target()
	var instant_targets := _instant_salvage_targets(str(target.get("id", "")))
	var hazards: Array = _world.get_hazard_centers()
	if target.is_empty() or instant_targets.size() < HELD_SALVAGE_CAPACITY or hazards.is_empty():
		push_error("Timed salvage smoke requires one timed target, enough instant cargo fillers, and a hazard.")
		get_tree().quit(1)
		return

	var target_id := str(target.get("id", "salvage"))
	var target_center: Vector2 = target["center"]
	var interaction_seconds := float(target.get("interaction_seconds", 0.0))
	var target_score := int(target.get("score", 0))
	var partial_seconds := interaction_seconds * 0.4
	var resumed_seconds := interaction_seconds * 0.25
	var partial_percent := int(round(100.0 * partial_seconds / interaction_seconds))
	var resumed_percent := int(round(100.0 * resumed_seconds / interaction_seconds))
	var oxygen_start := _oxygen_seconds

	if str(target.get("interaction", "instant")) != "timed_salvage" or interaction_seconds <= 0.0:
		push_error("Timed salvage smoke target %s is not an available timed_salvage interaction." % target_id)
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = target_center
	_process(0.0)
	if _world.is_salvage_collected(target_id) or _held_salvage_ids.has(target_id):
		push_error("Timed salvage smoke collected %s instantly." % target_id)
		get_tree().quit(1)
		return

	_process(partial_seconds)
	if _world.is_salvage_collected(target_id) or not _status_has_salvage_progress(partial_percent):
		push_error("Timed salvage smoke did not show %d%% progress without collecting; status=%s." % [partial_percent, _status_text()])
		get_tree().quit(1)
		return
	var oxygen_after_progress := _oxygen_seconds

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _world.is_salvage_collected(target_id) or _status_text().find("Salvage interrupted") == -1:
		push_error("Timed salvage smoke did not cancel progress when leaving range; status=%s." % _status_text())
		get_tree().quit(1)
		return
	var cancel_feedback := _last_status_note

	_player.global_position = target_center
	_process(resumed_seconds)
	if _world.is_salvage_collected(target_id) or not _status_has_salvage_progress(resumed_percent):
		push_error("Timed salvage smoke did not restart from %d%% after cancel; status=%s." % [resumed_percent, _status_text()])
		get_tree().quit(1)
		return

	_process(interaction_seconds + SMOKE_TIMED_SALVAGE_MARGIN_SECONDS)
	if _held_salvage != 1 or not _held_salvage_ids.has(target_id) or _held_salvage_score != target_score:
		push_error("Timed salvage smoke did not move completed target into held cargo; held=%d ids=%s score=%d." % [_held_salvage, _held_salvage_ids, _held_salvage_score])
		get_tree().quit(1)
		return
	if _status_text().find("Deep cache secured +%d" % target_score) == -1:
		push_error("Timed salvage smoke did not show completion feedback; status=%s." % _status_text())
		get_tree().quit(1)
		return
	var complete_feedback := _last_status_note
	var held_after_completion := _held_salvage

	_hazard_interactions_enabled = true
	_player.global_position = hazards[0]["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _held_salvage != 0 or _world.is_salvage_collected(target_id):
		push_error("Timed salvage smoke hazard hit did not restore completed unbanked target.")
		get_tree().quit(1)
		return

	_reset_run()
	var expected_fill_score := 0
	for index in range(HELD_SALVAGE_CAPACITY):
		var filler: Dictionary = instant_targets[index]
		expected_fill_score += int(filler.get("score", 0))
		_player.global_position = filler["center"]
		_collect_salvage_for_smoke(filler)
	if _held_salvage != HELD_SALVAGE_CAPACITY:
		push_error("Timed salvage smoke could not fill cargo before capacity test; held=%d." % _held_salvage)
		get_tree().quit(1)
		return

	_player.global_position = target_center
	_process(interaction_seconds + SMOKE_TIMED_SALVAGE_MARGIN_SECONDS)
	if _world.is_salvage_collected(target_id) or _held_salvage_ids.has(target_id):
		push_error("Timed salvage smoke collected timed target while cargo was full.")
		get_tree().quit(1)
		return
	if _status_text().find("Cargo full - return to extraction") == -1:
		push_error("Timed salvage smoke did not show cargo-full feedback; status=%s." % _status_text())
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _banked_salvage != HELD_SALVAGE_CAPACITY or _banked_score != expected_fill_score:
		push_error("Timed salvage smoke did not bank filled cargo; banked=%d score=%d expected=%d." % [_banked_salvage, _banked_score, expected_fill_score])
		get_tree().quit(1)
		return

	_player.global_position = target_center
	_collect_salvage_for_smoke(target)
	if not _held_salvage_ids.has(target_id):
		push_error("Timed salvage smoke could not collect target after capacity freed.")
		get_tree().quit(1)
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var banked_score_after_timed := _banked_score
	if _held_salvage != 0 or _banked_score != expected_fill_score + target_score:
		push_error("Timed salvage smoke did not bank completed timed target; held=%d banked_score=%d." % [_held_salvage, _banked_score])
		get_tree().quit(1)
		return

	_reset_run()
	_player.global_position = target_center
	_process(partial_seconds)
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed or _held_salvage != 0 or _world.is_salvage_collected(target_id):
		push_error("Timed salvage smoke oxygen failure did not clear active timed state.")
		get_tree().quit(1)
		return
	_reset_run()
	_player.global_position = target_center
	_process(resumed_seconds)
	if not _status_has_salvage_progress(resumed_percent):
		push_error("Timed salvage smoke did not restart cleanly after oxygen reset; status=%s." % _status_text())
		get_tree().quit(1)
		return

	_reset_run()
	print("Timed salvage smoke passed: target=%s seconds=%.1f available=true progress=%d%% cancel=\"%s\" complete=\"%s\" held_after_complete=%d banked_score=%d oxygen=%.1f->%.1f cargo_blocked=true hazard_restored=true oxygen_reset=true." % [
		target_id,
		interaction_seconds,
		partial_percent,
		cancel_feedback,
		complete_feedback,
		held_after_completion,
		banked_score_after_timed,
		oxygen_start,
		oxygen_after_progress,
	])
	get_tree().quit()


func _timed_salvage_target() -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "timed_salvage":
			return salvage
	return {}


func _instant_salvage_targets(excluded_id: String) -> Array:
	var targets: Array = []
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == excluded_id:
			continue
		if str(salvage.get("interaction", "instant")) == "instant":
			targets.append(salvage)
	return targets


func _status_has_salvage_progress(percent: int) -> bool:
	return _status_text().find("Salvaging") != -1 and _status_text().find("%d%%" % percent) != -1


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""



func _smoke_player_facing_and_quit() -> void:
	if not _player.has_method("swim_in_direction") or not _player.has_method("get_facing_report"):
		push_error("Player facing smoke requires swim_in_direction() and get_facing_report().")
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_player.swim_in_direction(Vector2.RIGHT, 1.0 / 60.0)
	var right_report: Dictionary = _player.get_facing_report()
	_player.swim_in_direction(Vector2.LEFT, 1.0 / 60.0)
	var left_report: Dictionary = _player.get_facing_report()
	_player.swim_in_direction(Vector2.RIGHT, 1.0 / 60.0)
	var restored_report: Dictionary = _player.get_facing_report()

	if not _facing_report_matches(right_report, false, 88.0, 1.0):
		push_error("Player facing smoke expected right-facing visual children, got %s." % right_report)
		get_tree().quit(1)
		return
	if not _facing_report_matches(left_report, true, -88.0, -1.0):
		push_error("Player facing smoke expected left-facing visual children, got %s." % left_report)
		get_tree().quit(1)
		return
	if not _facing_report_matches(restored_report, false, 88.0, 1.0):
		push_error("Player facing smoke expected restored right-facing visual children, got %s." % restored_report)
		get_tree().quit(1)
		return

	print("Player facing smoke passed: root scale stayed stable while visual children flipped left/right.")
	get_tree().quit()



func _smoke_movement_feel_and_quit() -> void:
	if not _player.has_method("swim_in_direction"):
		push_error("Movement feel probe requires player swim_in_direction().")
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = MOVEMENT_FEEL_PROBE_CENTER_TILES * float(_world.tile_size)
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	await _swim_for_frames(Vector2.RIGHT, 15)
	var start_velocity: Vector2 = _player.velocity
	await _swim_for_frames(Vector2.ZERO, 15)
	var stop_velocity: Vector2 = _player.velocity
	await _swim_for_frames(Vector2.LEFT, 20)
	var reverse_velocity: Vector2 = _player.velocity
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	await _swim_for_frames(Vector2(1.0, -1.0), 15)
	var diagonal_velocity: Vector2 = _player.velocity

	if start_velocity.x <= 0.0:
		push_error("Movement feel probe expected positive x velocity after right input, got %s." % start_velocity)
		get_tree().quit(1)
		return
	if stop_velocity.length() >= start_velocity.length():
		push_error("Movement feel probe expected stop phase to slow the player, got start %s stop %s." % [start_velocity, stop_velocity])
		get_tree().quit(1)
		return
	if reverse_velocity.x >= 0.0:
		push_error("Movement feel probe expected negative x velocity after left reversal, got %s." % reverse_velocity)
		get_tree().quit(1)
		return
	if diagonal_velocity.length() > _player.swim_speed + 1.0:
		push_error("Movement feel probe expected diagonal speed to stay normalized, got %s." % diagonal_velocity)
		get_tree().quit(1)
		return

	print("Movement feel probe passed: start=%s stop=%s reverse=%s diagonal=%s." % [
		_format_vector(start_velocity),
		_format_vector(stop_velocity),
		_format_vector(reverse_velocity),
		_format_vector(diagonal_velocity),
	])
	get_tree().quit()



func _swim_for_frames(direction: Vector2, frame_count: int) -> void:
	for _frame in range(frame_count):
		_player.swim_in_direction(direction, 1.0 / 60.0)
		await get_tree().physics_frame



func _format_vector(value: Vector2) -> String:
	return "(%.1f, %.1f)" % [value.x, value.y]



func _facing_report_matches(report: Dictionary, body_flip_h: bool, light_x: float, light_scale_x: float) -> bool:
	return (
		is_equal_approx(float(report.get("root_scale_x", 0.0)), 1.0)
		and bool(report.get("body_flip_h", not body_flip_h)) == body_flip_h
		and is_equal_approx(float(report.get("light_cone_position_x", 0.0)), light_x)
		and is_equal_approx(float(report.get("light_cone_scale_x", 0.0)), light_scale_x)
	)
