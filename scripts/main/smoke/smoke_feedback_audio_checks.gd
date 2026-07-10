extends "res://scripts/main/smoke/smoke_check_base.gd"


func _smoke_feedback_cues_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		_fail("Feedback cue smoke loaded unexpected map: %s." % _world.map_id)
		return
	if _main._audio_cues == null or not _main._audio_cues.has_method("event_log"):
		_fail("Feedback cue smoke requires audio cue event logging.")
		return

	_main._audio_cues.clear_event_log()
	_player.set_physics_process(false)

	var salvage := _first_instant_salvage()
	var hazard := _first_static_hazard()
	if salvage.is_empty() or hazard.is_empty():
		_fail("Feedback cue smoke requires one instant salvage target and one static hazard.")
		return

	var salvage_id := str(salvage.get("id", "salvage"))
	_player.global_position = salvage["center"]
	_process(0.0)
	if _held_salvage != 1 or not _held_salvage_ids.has(salvage_id):
		_fail("Feedback cue smoke could not collect setup salvage %s." % salvage_id)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage != 1:
		_fail("Feedback cue smoke could not bank setup salvage; held=%d banked=%d." % [_held_salvage, _banked_salvage])
		return

	_player.global_position = salvage["center"]
	_process(0.0)
	_oxygen_seconds = _main.OXYGEN_LOW_WARNING_SECONDS + 1.0
	_process(2.0)
	_oxygen_seconds = _main.OXYGEN_CRITICAL_WARNING_SECONDS + 1.0
	_process(2.0)
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed:
		_fail("Feedback cue smoke did not trigger oxygen failure.")
		return

	_reset_run()
	var warning_position := _hazard_warning_probe_position(hazard["center"])
	var warning_hazard: Dictionary = _world.get_nearest_hazard_within(warning_position, HAZARD_WARNING_RADIUS)
	if warning_hazard.is_empty() or not _world.get_hazard_near(warning_position, HAZARD_CONTACT_RADIUS).is_empty():
		_fail("Feedback cue smoke could not find a warning-only hazard probe.")
		return

	_player.global_position = warning_position
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _hazard_warning_id.is_empty():
		_fail("Feedback cue smoke did not enter hazard warning state.")
		return

	_player.global_position = warning_hazard["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _player.global_position.distance_to(_world.spawn_position) > 2.0:
		_fail("Feedback cue smoke hazard contact did not reset player to spawn.")
		return

	var counts := _cue_counts()
	var required := [
		"salvage_pickup",
		"salvage_bank",
		"oxygen_low",
		"oxygen_critical",
		"oxygen_failure",
		"hazard_warning",
		"hazard_contact",
	]
	for cue_id in required:
		if int(counts.get(cue_id, 0)) < 1:
			_fail("Feedback cue smoke missing cue %s; counts=%s." % [cue_id, counts])
			return

	print("Feedback cue smoke passed: target=%s hazard=%s cue_counts=%s." % [
		salvage_id,
		str(warning_hazard.get("id", "hazard")),
		counts,
	])
	get_tree().quit()


func _cue_counts() -> Dictionary:
	var counts := {}
	for event in _main._audio_cues.event_log():
		var cue_id := str(event.get("cue_id", ""))
		if cue_id.is_empty():
			continue
		counts[cue_id] = int(counts.get(cue_id, 0)) + 1
	return counts


func _first_instant_salvage() -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			return salvage
	return {}


func _first_static_hazard() -> Dictionary:
	for hazard in _world.get_hazard_centers():
		var hazard_id := str(hazard.get("id", ""))
		if hazard_id == "deep_route_jellyfish_patrol":
			continue
		return hazard
	return {}


func _hazard_warning_probe_position(hazard_center: Vector2) -> Vector2:
	var warning_distance := HAZARD_CONTACT_RADIUS + 8.0
	var directions: Array[Vector2] = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]
	for direction in directions:
		var candidate: Vector2 = hazard_center + direction * warning_distance
		if _world.get_hazard_near(candidate, HAZARD_CONTACT_RADIUS).is_empty() and not _world.get_nearest_hazard_within(candidate, HAZARD_WARNING_RADIUS).is_empty():
			return candidate
	return hazard_center + Vector2.RIGHT * warning_distance


func _fail(message: String) -> void:
	push_error(message)
	get_tree().quit(1)
