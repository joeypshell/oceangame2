extends "res://scripts/main/smoke/smoke_check_base.gd"

const PASS_08_SEGMENT_ID := "southwest_return_pocket_extension"
const PASS_08_TARGET_ID := "salvage_southwest_return_cache"
const DEEP_CACHE_SALVAGE_ID := "salvage_deep_right_cache"


func _smoke_pass_08_route_extension_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pass 08 route extension smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	var segment: Dictionary = _world.get_marker_zone(PASS_08_SEGMENT_ID)
	var target: Dictionary = _salvage_by_id(PASS_08_TARGET_ID)
	var deep_cache: Dictionary = _salvage_by_id(DEEP_CACHE_SALVAGE_ID)
	var pressure_segment: Dictionary = _world.get_marker_zone(PASS_07_PRESSURE_SEGMENT_ID)
	var pressure_hazard: Dictionary = _hazard_by_id(PASS_07_PRESSURE_HAZARD_ID)
	if segment.is_empty() or target.is_empty() or deep_cache.is_empty() or pressure_segment.is_empty() or pressure_hazard.is_empty():
		push_error("Pass 08 route extension smoke missing required source data: segment=%s target=%s deep=%s pass07_segment=%s hazard=%s." % [
			str(not segment.is_empty()),
			str(not target.is_empty()),
			str(not deep_cache.is_empty()),
			str(not pressure_segment.is_empty()),
			str(not pressure_hazard.is_empty()),
		])
		get_tree().quit(1)
		return

	var path_to_target: Array = _world.find_open_path(_world.spawn_position, target["center"])
	var return_path: Array = _world.find_open_path(target["center"], _world.get_extraction_center())
	var path_to_deep_cache: Array = _world.find_open_path(target["center"], deep_cache["center"])
	if path_to_target.is_empty() or return_path.is_empty() or path_to_deep_cache.is_empty():
		push_error("Pass 08 route extension smoke path failure: to_target=%d return=%d to_deep=%d." % [
			path_to_target.size(),
			return_path.size(),
			path_to_deep_cache.size(),
		])
		get_tree().quit(1)
		return

	if str(target.get("interaction", "instant")) != "instant":
		push_error("Pass 08 route extension target should remain an instant salvage cue: %s." % str(target))
		get_tree().quit(1)
		return
	if str(deep_cache.get("interaction", "instant")) != "timed_salvage" or float(deep_cache.get("interaction_seconds", 0.0)) <= 0.0:
		push_error("Pass 08 route extension smoke found deep cache timed-salvage behavior missing: %s." % str(deep_cache))
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = target["center"]
	_process(0.0)
	var held_after_pickup := _held_salvage
	var held_score_after_pickup := _held_salvage_score
	var oxygen_after_pickup := _oxygen_seconds
	if _held_salvage != 1 or not _held_salvage_ids.has(PASS_08_TARGET_ID) or held_score_after_pickup != int(target.get("score", 0)):
		push_error("Pass 08 route extension smoke did not collect target cleanly: held=%d ids=%s score=%d." % [
			_held_salvage,
			_held_salvage_ids,
			_held_salvage_score,
		])
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage != 1 or _banked_score != int(target.get("score", 0)):
		push_error("Pass 08 route extension smoke did not bank target at extraction: held=%d banked=%d score=%d." % [
			_held_salvage,
			_banked_salvage,
			_banked_score,
		])
		get_tree().quit(1)
		return

	var banked_score_after_return := _banked_score
	_reset_run()
	print("Pass 08 route extension smoke passed: segment=%s target=%s target_tier=%s route=%s target_score=%d path_to_target=%d path_to_deep_cache=%d return_path=%d held_after_pickup=%d banked_score=%d oxygen=%.1f timed_target=%s pass07_segment=%s hazard=%s." % [
		str(segment.get("id", PASS_08_SEGMENT_ID)),
		PASS_08_TARGET_ID,
		str(target.get("tier", "common")),
		str(target.get("validation_route", "")),
		int(target.get("score", 0)),
		path_to_target.size(),
		path_to_deep_cache.size(),
		return_path.size(),
		held_after_pickup,
		banked_score_after_return,
		oxygen_after_pickup,
		DEEP_CACHE_SALVAGE_ID,
		str(pressure_segment.get("id", PASS_07_PRESSURE_SEGMENT_ID)),
		PASS_07_PRESSURE_HAZARD_ID,
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
