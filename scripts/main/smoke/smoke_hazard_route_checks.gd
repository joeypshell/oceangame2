extends "res://scripts/main/smoke/smoke_check_base.gd"

const LOWER_LOOP_SALVAGE_ID := "salvage_lower_loop"
const DEEP_CACHE_SALVAGE_ID := "salvage_deep_right_cache"
const WARNING_PATH_OFFSET_TILES := Vector2.DOWN


func _smoke_pass_07_hazard_route_pressure_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pass 07 hazard route smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	var segment: Dictionary = _world.get_marker_zone(PASS_07_PRESSURE_SEGMENT_ID)
	var lower_loop: Dictionary = _salvage_by_id(LOWER_LOOP_SALVAGE_ID)
	var deep_cache: Dictionary = _salvage_by_id(DEEP_CACHE_SALVAGE_ID)
	var hazard: Dictionary = _hazard_by_id(PASS_07_PRESSURE_HAZARD_ID)
	if segment.is_empty() or lower_loop.is_empty() or deep_cache.is_empty() or hazard.is_empty():
		push_error("Pass 07 hazard route smoke missing segment/salvage/hazard data: segment=%s lower=%s deep=%s hazard=%s." % [
			str(not segment.is_empty()),
			str(not lower_loop.is_empty()),
			str(not deep_cache.is_empty()),
			str(not hazard.is_empty()),
		])
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = true

	var hazard_center: Vector2 = hazard["center"]
	var warning_position := hazard_center + WARNING_PATH_OFFSET_TILES * float(_world.tile_size)
	var warning_hazard: Dictionary = _world.get_nearest_hazard_within(warning_position, HAZARD_WARNING_RADIUS)
	var warning_distance := warning_position.distance_to(hazard_center)
	if str(warning_hazard.get("id", "")) != PASS_07_PRESSURE_HAZARD_ID or not _world.get_hazard_near(warning_position, HAZARD_CONTACT_RADIUS).is_empty():
		push_error("Pass 07 hazard route smoke could not place warning-only probe for %s at distance %.1f." % [
			PASS_07_PRESSURE_HAZARD_ID,
			warning_distance,
		])
		get_tree().quit(1)
		return

	_player.global_position = lower_loop["center"]
	_process(0.0)
	if _held_salvage != 1 or not _held_salvage_ids.has(LOWER_LOOP_SALVAGE_ID):
		push_error("Pass 07 hazard route smoke could not collect setup salvage %s; held=%d ids=%s." % [
			LOWER_LOOP_SALVAGE_ID,
			_held_salvage,
			_held_salvage_ids,
		])
		get_tree().quit(1)
		return

	_player.global_position = warning_position
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _hazard_warning_id != PASS_07_PRESSURE_HAZARD_ID or _status_text().find(PRESSURE_HAZARD_WARNING_PROMPT) == -1:
		push_error("Pass 07 hazard route smoke expected selected warning prompt; warning=%s status=%s." % [
			_hazard_warning_id,
			_status_text(),
		])
		get_tree().quit(1)
		return
	if _held_salvage != 1 or not _held_salvage_ids.has(LOWER_LOOP_SALVAGE_ID):
		push_error("Pass 07 hazard route smoke warning range changed held cargo; held=%d ids=%s." % [
			_held_salvage,
			_held_salvage_ids,
		])
		get_tree().quit(1)
		return

	var oxygen_before_hit := _oxygen_seconds
	_player.global_position = hazard_center
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	var oxygen_after_hit := _oxygen_seconds
	var reset_to_spawn: bool = _player.global_position.distance_to(_world.spawn_position) <= 2.0
	var restored_lower_loop: bool = not _world.is_salvage_collected(LOWER_LOOP_SALVAGE_ID)
	var held_after_contact := _held_salvage
	if _run_failed or not reset_to_spawn or _held_salvage != 0 or not _held_salvage_ids.is_empty() or not restored_lower_loop:
		push_error("Pass 07 hazard route smoke failed contact reset/restoration: failed=%s reset=%s held=%d ids=%s restored=%s." % [
			str(_run_failed),
			str(reset_to_spawn),
			_held_salvage,
			_held_salvage_ids,
			str(restored_lower_loop),
		])
		get_tree().quit(1)
		return
	var expected_oxygen_after_hit := oxygen_before_hit - HAZARD_OXYGEN_PENALTY_SECONDS
	if not is_equal_approx(oxygen_after_hit, expected_oxygen_after_hit):
		push_error("Pass 07 hazard route smoke expected oxygen %.1f after contact, got %.1f." % [
			expected_oxygen_after_hit,
			oxygen_after_hit,
		])
		get_tree().quit(1)
		return

	_reset_run()
	var interaction_seconds := float(deep_cache.get("interaction_seconds", 0.0))
	var partial_seconds := interaction_seconds * 0.4
	var resumed_seconds := interaction_seconds * 0.25
	_player.global_position = deep_cache["center"]
	_process(partial_seconds)
	if _world.is_salvage_collected(DEEP_CACHE_SALVAGE_ID) or not _status_has_salvage_progress(40):
		push_error("Pass 07 hazard route smoke did not establish partial timed salvage progress; status=%s." % _status_text())
		get_tree().quit(1)
		return

	_player.global_position = hazard_center
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _world.is_salvage_collected(DEEP_CACHE_SALVAGE_ID) or _held_salvage != 0:
		push_error("Pass 07 hazard route smoke hazard hit did not clear active timed salvage cleanly.")
		get_tree().quit(1)
		return

	_player.global_position = deep_cache["center"]
	_process(resumed_seconds)
	if not _status_has_salvage_progress(25):
		push_error("Pass 07 hazard route smoke timed salvage did not restart after hazard reset; status=%s." % _status_text())
		get_tree().quit(1)
		return

	_reset_run()
	var return_path: Array = _world.find_open_path(deep_cache["center"], _world.get_extraction_center())
	if return_path.is_empty():
		push_error("Pass 07 hazard route smoke found no return path from %s to extraction." % DEEP_CACHE_SALVAGE_ID)
		get_tree().quit(1)
		return
	_player.global_position = deep_cache["center"]
	_collect_salvage_for_smoke(deep_cache)
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _banked_score < int(deep_cache.get("score", 0)):
		push_error("Pass 07 hazard route smoke could not bank deep cache after route check; held=%d banked_score=%d." % [
			_held_salvage,
			_banked_score,
		])
		get_tree().quit(1)
		return
	var banked_score_after_return := _banked_score

	_reset_run()
	print("Pass 07 hazard route pressure smoke passed: segment=%s hazard=%s warning_distance=%.1f oxygen=%.1f->%.1f held_after_contact=%d banked_score=%d reset_to_spawn=%s restored=%s timed_reset=true returnable=true." % [
		str(segment.get("id", PASS_07_PRESSURE_SEGMENT_ID)),
		PASS_07_PRESSURE_HAZARD_ID,
		warning_distance,
		oxygen_before_hit,
		oxygen_after_hit,
		held_after_contact,
		banked_score_after_return,
		str(reset_to_spawn),
		str(restored_lower_loop),
	])
	get_tree().quit()


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _hazard_by_id(hazard_id: String) -> Dictionary:
	for hazard in _world.get_hazard_centers():
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


func _status_has_salvage_progress(percent: int) -> bool:
	return _status_text().find("Salvaging") != -1 and _status_text().find("%d%%" % percent) != -1


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
