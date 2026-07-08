extends "res://scripts/main/smoke/smoke_check_base.gd"

const PASS_08_SEGMENT_ID := "southwest_return_pocket_extension"
const PASS_08_TARGET_ID := "salvage_southwest_return_cache"
const PASS_09_ROUTE_ID := "southwest_pocket_decision"
const PASS_09_ROUTE_CHOICE_ID := "southwest_pocket_detour"
const PASS_10_SEGMENT_ID := "return_pressure_to_boat"
const PASS_10_TARGET_ID := "salvage_return_branch"
const PASS_10_ROUTE_ID := "return_pressure_decision"
const PASS_10_ROUTE_CHOICE_ID := "return_branch_bank_prompt"
const PASS_10_FEEDBACK := "Cargo full - bank at boat"
const LOWER_LOOP_SALVAGE_ID := "salvage_lower_loop"
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


func _smoke_pass_09_southwest_pocket_decision_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pass 09 southwest pocket smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	var segment: Dictionary = _world.get_marker_zone(PASS_08_SEGMENT_ID)
	var target: Dictionary = _salvage_by_id(PASS_08_TARGET_ID)
	var deep_cache: Dictionary = _salvage_by_id(DEEP_CACHE_SALVAGE_ID)
	if segment.is_empty() or target.is_empty() or deep_cache.is_empty():
		push_error("Pass 09 southwest pocket smoke missing source data: segment=%s target=%s deep=%s." % [
			str(not segment.is_empty()),
			str(not target.is_empty()),
			str(not deep_cache.is_empty()),
		])
		get_tree().quit(1)
		return

	var route_id := str(target.get("validation_route", ""))
	var route_choice_id := str(target.get("route_choice_id", ""))
	var target_score := int(target.get("score", 0))
	if route_id != PASS_09_ROUTE_ID or route_choice_id != PASS_09_ROUTE_CHOICE_ID:
		push_error("Pass 09 southwest target has wrong route metadata: route=%s choice=%s." % [route_id, route_choice_id])
		get_tree().quit(1)
		return
	if str(target.get("tier", "common")) != "valuable" or target_score <= 0:
		push_error("Pass 09 southwest target should be a valuable payoff: %s." % str(target))
		get_tree().quit(1)
		return
	if str(target.get("interaction", "instant")) != "instant":
		push_error("Pass 09 southwest target should remain instant salvage: %s." % str(target))
		get_tree().quit(1)
		return

	var path_to_target: Array = _world.find_open_path(_world.spawn_position, target["center"])
	var return_path: Array = _world.find_open_path(target["center"], _world.get_extraction_center())
	var path_to_deep_cache: Array = _world.find_open_path(target["center"], deep_cache["center"])
	if path_to_target.is_empty() or return_path.is_empty() or path_to_deep_cache.is_empty():
		push_error("Pass 09 southwest pocket path failure: to_target=%d return=%d to_deep=%d." % [
			path_to_target.size(),
			return_path.size(),
			path_to_deep_cache.size(),
		])
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var oxygen_start := _oxygen_seconds
	_player.global_position = target["center"]
	_process(0.0)
	var expected_feedback := "Southwest pocket payoff +%d" % target_score
	if _held_salvage != 1 or not _held_salvage_ids.has(PASS_08_TARGET_ID) or _held_salvage_score != target_score:
		push_error("Pass 09 southwest pocket did not collect into held cargo: held=%d ids=%s score=%d." % [
			_held_salvage,
			_held_salvage_ids,
			_held_salvage_score,
		])
		get_tree().quit(1)
		return
	if _last_status_note != expected_feedback or _status_label == null or _status_label.text.find(expected_feedback) == -1:
		push_error("Pass 09 southwest pocket feedback mismatch: note=%s status=%s." % [_last_status_note, _status_label.text])
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage != 1 or _banked_score != target_score:
		push_error("Pass 09 southwest pocket did not bank target: held=%d banked=%d score=%d." % [
			_held_salvage,
			_banked_salvage,
			_banked_score,
		])
		get_tree().quit(1)
		return
	if int(_main._banked_validation_route_counts.get(PASS_09_ROUTE_ID, 0)) != 1:
		push_error("Pass 09 southwest pocket did not record banked route count: %s." % str(_main._banked_validation_route_counts))
		get_tree().quit(1)
		return
	var route_label: String = _main._route_outcome_label(PASS_09_ROUTE_ID)
	if route_label != "Southwest pocket":
		push_error("Pass 09 southwest route label mismatch: %s." % route_label)
		get_tree().quit(1)
		return

	var oxygen_after_return := _oxygen_seconds
	_reset_run()
	if int(_main._banked_validation_route_counts.get(PASS_09_ROUTE_ID, 0)) != 0 or _status_label.text.find("Southwest pocket") != -1:
		push_error("Pass 09 southwest reset left stale route state: counts=%s status=%s." % [
			str(_main._banked_validation_route_counts),
			_status_label.text,
		])
		get_tree().quit(1)
		return

	print("Pass 09 southwest pocket decision smoke passed: segment=%s target=%s route=%s route_choice=%s route_label=%s target_score=%d path_to_target=%d path_to_deep_cache=%d return_path=%d held_after_pickup=1 banked_score=%d oxygen=%.1f->%.1f feedback=\"%s\" reset_clean=true." % [
		str(segment.get("id", PASS_08_SEGMENT_ID)),
		PASS_08_TARGET_ID,
		route_id,
		route_choice_id,
		route_label,
		target_score,
		path_to_target.size(),
		path_to_deep_cache.size(),
		return_path.size(),
		target_score,
		oxygen_start,
		oxygen_after_return,
		expected_feedback,
	])
	get_tree().quit()


func _smoke_pass_10_return_pressure_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pass 10 return-pressure smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	var segment: Dictionary = _world.get_marker_zone(PASS_10_SEGMENT_ID)
	var lower_loop: Dictionary = _salvage_by_id(LOWER_LOOP_SALVAGE_ID)
	var deep_cache: Dictionary = _salvage_by_id(DEEP_CACHE_SALVAGE_ID)
	var target: Dictionary = _salvage_by_id(PASS_10_TARGET_ID)
	if segment.is_empty() or lower_loop.is_empty() or deep_cache.is_empty() or target.is_empty():
		push_error("Pass 10 return-pressure smoke missing source data: segment=%s lower=%s deep=%s target=%s." % [
			str(not segment.is_empty()),
			str(not lower_loop.is_empty()),
			str(not deep_cache.is_empty()),
			str(not target.is_empty()),
		])
		get_tree().quit(1)
		return

	var route_id := str(target.get("validation_route", ""))
	var route_choice_id := str(target.get("route_choice_id", ""))
	if route_id != PASS_10_ROUTE_ID or route_choice_id != PASS_10_ROUTE_CHOICE_ID:
		push_error("Pass 10 target has wrong route metadata: route=%s choice=%s." % [route_id, route_choice_id])
		get_tree().quit(1)
		return
	if str(target.get("interaction", "instant")) != "instant":
		push_error("Pass 10 target should remain instant salvage: %s." % str(target))
		get_tree().quit(1)
		return

	var path_to_lower: Array = _world.find_open_path(_world.spawn_position, lower_loop["center"])
	var path_to_deep: Array = _world.find_open_path(lower_loop["center"], deep_cache["center"])
	var path_to_target: Array = _world.find_open_path(deep_cache["center"], target["center"])
	var return_path: Array = _world.find_open_path(target["center"], _world.get_extraction_center())
	if path_to_lower.is_empty() or path_to_deep.is_empty() or path_to_target.is_empty() or return_path.is_empty():
		push_error("Pass 10 return-pressure path failure: lower=%d deep=%d target=%d return=%d." % [
			path_to_lower.size(),
			path_to_deep.size(),
			path_to_target.size(),
			return_path.size(),
		])
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var oxygen_start := _oxygen_seconds
	_player.global_position = lower_loop["center"]
	_collect_salvage_for_smoke(lower_loop)
	_player.global_position = deep_cache["center"]
	_collect_salvage_for_smoke(deep_cache)
	var expected_banked_score := int(lower_loop.get("score", 0)) + int(deep_cache.get("score", 0))
	if _held_salvage != HELD_SALVAGE_CAPACITY or _held_salvage_score != expected_banked_score:
		push_error("Pass 10 return-pressure smoke did not fill cargo with planned pickups: held=%d score=%d expected=%d ids=%s." % [
			_held_salvage,
			_held_salvage_score,
			expected_banked_score,
			_held_salvage_ids,
		])
		get_tree().quit(1)
		return

	_player.global_position = target["center"]
	_process(0.0)
	if _held_salvage != HELD_SALVAGE_CAPACITY or _held_salvage_ids.has(PASS_10_TARGET_ID):
		push_error("Pass 10 return-pressure smoke collected while cargo was full: held=%d ids=%s." % [
			_held_salvage,
			_held_salvage_ids,
		])
		get_tree().quit(1)
		return
	if _world.is_salvage_collected(PASS_10_TARGET_ID) or not _world.has_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS):
		push_error("Pass 10 return-pressure target availability changed while cargo was full.")
		get_tree().quit(1)
		return
	if _last_status_note != PASS_10_FEEDBACK or _status_label == null or _status_label.text.find(PASS_10_FEEDBACK) == -1:
		push_error("Pass 10 return-pressure feedback mismatch: note=%s status=%s." % [_last_status_note, _status_label.text])
		get_tree().quit(1)
		return

	var oxygen_at_pressure := _oxygen_seconds
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage != HELD_SALVAGE_CAPACITY or _banked_score != expected_banked_score:
		push_error("Pass 10 return-pressure smoke did not bank full cargo: held=%d banked=%d score=%d expected=%d." % [
			_held_salvage,
			_banked_salvage,
			_banked_score,
			expected_banked_score,
		])
		get_tree().quit(1)
		return
	if _world.is_salvage_collected(PASS_10_TARGET_ID):
		push_error("Pass 10 return-pressure target was deleted during banking.")
		get_tree().quit(1)
		return

	var target_score := int(target.get("score", 0))
	_player.global_position = target["center"]
	_collect_salvage_for_smoke(target)
	if _held_salvage != 1 or not _held_salvage_ids.has(PASS_10_TARGET_ID) or _held_salvage_score != target_score:
		push_error("Pass 10 return-pressure target did not collect after banking: held=%d ids=%s score=%d expected=%d." % [
			_held_salvage,
			_held_salvage_ids,
			_held_salvage_score,
			target_score,
		])
		get_tree().quit(1)
		return

	_reset_run()
	print("Pass 10 return-pressure smoke passed: segment=%s target=%s route=%s route_choice=%s held_full=%d banked_score=%d target_score=%d oxygen=%.1f->%.1f feedback=\"%s\" paths=%d,%d,%d,%d target_collects_after_banking=true." % [
		str(segment.get("id", PASS_10_SEGMENT_ID)),
		PASS_10_TARGET_ID,
		route_id,
		route_choice_id,
		HELD_SALVAGE_CAPACITY,
		expected_banked_score,
		target_score,
		oxygen_start,
		oxygen_at_pressure,
		PASS_10_FEEDBACK,
		path_to_lower.size(),
		path_to_deep.size(),
		path_to_target.size(),
		return_path.size(),
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
