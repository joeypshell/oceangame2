extends "res://scripts/main/smoke/smoke_check_base.gd"

func _smoke_salvage_route_and_quit(expected_map_id: String, extraction_label: String) -> void:
	if _world.map_id != expected_map_id:
		push_error("%s route smoke loaded unexpected map: %s" % [expected_map_id, _world.map_id])
		get_tree().quit(1)
		return
	if not _player.has_method("swim_in_direction"):
		push_error("%s route smoke requires player swim_in_direction()." % expected_map_id)
		get_tree().quit(1)
		return
	if _total_salvage <= 0:
		push_error("%s route smoke requires authored salvage." % expected_map_id)
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var salvage_targets: Array = _world.get_salvage_centers()
	var extraction_center: Vector2 = _world.get_extraction_center()
	for salvage in salvage_targets:
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			if _world.find_open_path(_player.global_position, extraction_center).is_empty():
				push_error("%s route smoke found no open return route to %s." % [expected_map_id, extraction_label])
				get_tree().quit(1)
				return
			_player.global_position = extraction_center
			_process(0.0)
		var salvage_id := str(salvage.get("id", "salvage"))
		var target_center: Vector2 = salvage["center"]
		if _world.find_open_path(_player.global_position, target_center).is_empty():
			push_error("%s route smoke found no open route to %s." % [expected_map_id, salvage_id])
			get_tree().quit(1)
			return

		_player.global_position = target_center
		_collect_salvage_for_smoke(salvage)
		if not _world.is_salvage_collected(salvage_id):
			push_error("%s route smoke did not collect reachable salvage %s; held=%d." % [expected_map_id, salvage_id, _held_salvage])
			get_tree().quit(1)
			return

	if _held_salvage > 0:
		if _world.find_open_path(_player.global_position, extraction_center).is_empty():
			push_error("%s route smoke found no final open return route to %s." % [expected_map_id, extraction_label])
			get_tree().quit(1)
			return
		_player.global_position = extraction_center
		_process(0.0)

	if not _run_complete:
		push_error("%s route smoke did not complete after swimming through salvage route." % expected_map_id)
		get_tree().quit(1)
		return

	var completed_total := _total_salvage
	_reset_run()
	print("%s route smoke passed: checked routes to %d salvage and banked at %s." % [
		expected_map_id,
		completed_total,
		extraction_label,
	])
	get_tree().quit()



func _smoke_route_choice_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Route choice probe loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if not _player.has_method("swim_in_direction"):
		push_error("Route choice probe requires player swim_in_direction().")
		get_tree().quit(1)
		return

	var salvage: Array = _world.get_salvage_centers()
	if salvage.is_empty():
		push_error("Route choice probe requires authored salvage.")
		get_tree().quit(1)
		return

	var target: Dictionary = _route_choice_target(salvage)
	if target.is_empty():
		push_error("Route choice probe requires one authored valuable salvage target.")
		get_tree().quit(1)
		return
	var target_id := str(target.get("id", "salvage"))
	var target_center: Vector2 = target["center"]
	var extraction_center: Vector2 = _world.get_extraction_center()

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	var reached_target := await _swim_to_target(target_center)
	if not reached_target:
		get_tree().quit(1)
		return
	_collect_salvage_for_smoke(target)
	if _held_salvage != 1 or _held_salvage_ids.is_empty() or _held_salvage_ids[0] != target_id:
		push_error("Route choice probe did not collect target %s; held=%d ids=%s." % [target_id, _held_salvage, _held_salvage_ids])
		get_tree().quit(1)
		return

	var reached_extraction := await _swim_to_target(extraction_center)
	if not reached_extraction:
		get_tree().quit(1)
		return
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage < 1 or not _world.is_inside_extraction(_player.global_position):
		push_error("Route choice probe did not return/bank target %s; held=%d banked=%d position=%s." % [target_id, _held_salvage, _banked_salvage, _player.global_position])
		get_tree().quit(1)
		return

	var oxygen_after_return := _oxygen_seconds
	var completed_after_return := _run_complete
	var banked_after_return := _banked_salvage
	var score_after_return := _banked_score
	var target_score := int(target.get("score", 0))
	if score_after_return < target_score:
		push_error("Route choice probe banked score %d below target score %d." % [score_after_return, target_score])
		get_tree().quit(1)
		return
	_reset_run()
	print("Route choice probe passed: target=%s collected=1 banked=%d score=%d returned_to=boat extraction run_complete=%s oxygen=%.1f." % [target_id, banked_after_return, score_after_return, str(completed_after_return), oxygen_after_return])
	get_tree().quit()



func _smoke_expanded_route_choice_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Expanded route choice probe loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if not _player.has_method("swim_in_direction"):
		push_error("Expanded route choice probe requires player swim_in_direction().")
		get_tree().quit(1)
		return

	var route_targets: Array = _route_choice_targets_for_route(_world.get_salvage_centers(), EXPANDED_ROUTE_CHOICE_ID)
	if route_targets.size() < 2:
		push_error("Expanded route choice probe requires at least two targets for validation_route=%s, got %d." % [EXPANDED_ROUTE_CHOICE_ID, route_targets.size()])
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	var target_ids := PackedStringArray()
	for target in route_targets:
		var target_id := str(target.get("id", "salvage"))
		target_ids.append(target_id)
		var reached_target := await _swim_to_target(target["center"])
		if not reached_target:
			get_tree().quit(1)
			return
		_collect_salvage_for_smoke(target)
		if not _held_salvage_ids.has(target_id):
			push_error("Expanded route choice probe did not collect target %s; held=%d ids=%s." % [target_id, _held_salvage, _held_salvage_ids])
			get_tree().quit(1)
			return

	var expected_score := 0
	for target in route_targets:
		expected_score += int(target.get("score", 0))
	if _held_salvage != route_targets.size() or _held_salvage_score != expected_score:
		push_error("Expanded route choice probe expected %d held pickups worth %d, got held=%d score=%d ids=%s." % [route_targets.size(), expected_score, _held_salvage, _held_salvage_score, _held_salvage_ids])
		get_tree().quit(1)
		return

	var reached_return_waypoint := await _swim_to_target(route_targets[0]["center"])
	if not reached_return_waypoint:
		get_tree().quit(1)
		return

	var extraction_center: Vector2 = _world.get_extraction_center()
	var reached_extraction := await _swim_to_target(extraction_center)
	if not reached_extraction:
		get_tree().quit(1)
		return
	_process(0.0)

	if _held_salvage != 0 or _banked_salvage < route_targets.size() or _banked_score < expected_score or not _world.is_inside_extraction(_player.global_position):
		push_error("Expanded route choice probe did not bank both targets; held=%d banked=%d score=%d position=%s." % [_held_salvage, _banked_salvage, _banked_score, _player.global_position])
		get_tree().quit(1)
		return

	var oxygen_after_return := _oxygen_seconds
	var banked_after_return := _banked_salvage
	var score_after_return := _banked_score
	_reset_run()
	print("Expanded route choice probe passed: route=%s targets=%s held_capacity=%d banked=%d score=%d returned_to=boat extraction oxygen=%.1f." % [
		EXPANDED_ROUTE_CHOICE_ID,
		",".join(target_ids),
		HELD_SALVAGE_CAPACITY,
		banked_after_return,
		score_after_return,
		oxygen_after_return,
	])
	get_tree().quit()



func _smoke_safe_deep_route_choice_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Safe/deep route comparison smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if not _player.has_method("swim_in_direction"):
		push_error("Safe/deep route comparison smoke requires player swim_in_direction().")
		get_tree().quit(1)
		return

	var salvage: Array = _world.get_salvage_centers()
	var safe_targets: Array = _route_choice_targets_for_route(salvage, SAFE_ROUTE_CHOICE_ID)
	if safe_targets.is_empty():
		push_error("Safe/deep route comparison smoke requires at least one target for validation_route=%s." % SAFE_ROUTE_CHOICE_ID)
		get_tree().quit(1)
		return
	var deep_targets: Array = _route_choice_targets_for_route(salvage, EXPANDED_ROUTE_CHOICE_ID)
	if deep_targets.size() < 2:
		push_error("Safe/deep route comparison smoke requires at least two targets for validation_route=%s, got %d." % [EXPANDED_ROUTE_CHOICE_ID, deep_targets.size()])
		get_tree().quit(1)
		return

	var safe_result: Dictionary = await _run_route_comparison_path("safe", safe_targets, false)
	if safe_result.is_empty():
		get_tree().quit(1)
		return
	_reset_run()
	var deep_result: Dictionary = await _run_route_comparison_path("deep", deep_targets, true)
	if deep_result.is_empty():
		get_tree().quit(1)
		return

	var safe_score := int(safe_result.get("score", 0))
	var deep_score := int(deep_result.get("score", 0))
	var safe_oxygen := float(safe_result.get("oxygen", 0.0))
	var deep_oxygen := float(deep_result.get("oxygen", 0.0))
	if deep_score <= safe_score:
		push_error("Safe/deep route comparison smoke expected deep score > safe score, got deep=%d safe=%d." % [deep_score, safe_score])
		get_tree().quit(1)
		return
	if deep_oxygen >= safe_oxygen:
		push_error("Safe/deep route comparison smoke expected deep oxygen margin below safe margin, got deep=%.1f safe=%.1f." % [deep_oxygen, safe_oxygen])
		get_tree().quit(1)
		return
	if bool(safe_result.get("saw_low", false)) or bool(safe_result.get("saw_critical", false)):
		push_error("Safe/deep route comparison smoke expected safe route to stay comfortable, got feedback=%s status=%s." % [str(safe_result.get("oxygen_feedback", "")), str(safe_result.get("status", ""))])
		get_tree().quit(1)
		return
	if not bool(deep_result.get("saw_low", false)) or not bool(deep_result.get("saw_critical", false)):
		push_error("Safe/deep route comparison smoke expected deep route to show LOW and CRITICAL feedback, got feedback=%s status=%s." % [str(deep_result.get("oxygen_feedback", "")), str(deep_result.get("status", ""))])
		get_tree().quit(1)
		return

	_reset_run()
	print("Safe/deep route comparison smoke passed: safe_targets=%s safe_cargo=%d/%d safe_banked=%d safe_score=%d safe_oxygen=%.1f safe_feedback=%s deep_targets=%s deep_cargo=%d/%d deep_banked=%d deep_score=%d deep_oxygen=%.1f deep_feedback=%s." % [
		str(safe_result.get("target_ids", "")),
		int(safe_result.get("cargo", 0)),
		HELD_SALVAGE_CAPACITY,
		int(safe_result.get("banked", 0)),
		safe_score,
		safe_oxygen,
		str(safe_result.get("oxygen_feedback", "")),
		str(deep_result.get("target_ids", "")),
		int(deep_result.get("cargo", 0)),
		HELD_SALVAGE_CAPACITY,
		int(deep_result.get("banked", 0)),
		deep_score,
		deep_oxygen,
		str(deep_result.get("oxygen_feedback", "")),
	])
	get_tree().quit()



func _run_route_comparison_path(route_label: String, route_targets: Array, return_via_first_target: bool) -> Dictionary:
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = _world.spawn_position
	if _player.has_method("reset_motion"):
		_player.reset_motion()

	var target_ids := PackedStringArray()
	var oxygen_feedback := {
		"low": false,
		"critical": false,
	}
	var expected_score := 0
	for target in route_targets:
		var target_id := str(target.get("id", "salvage"))
		target_ids.append(target_id)
		expected_score += int(target.get("score", 0))
		var reached_target := await _swim_to_target(target["center"])
		if not reached_target:
			return {}
		_collect_salvage_for_smoke(target)
		_record_route_oxygen_feedback(oxygen_feedback)
		if not _held_salvage_ids.has(target_id):
			push_error("Safe/deep route comparison smoke did not collect %s target %s; held=%d ids=%s." % [route_label, target_id, _held_salvage, _held_salvage_ids])
			return {}

	if _held_salvage != route_targets.size() or _held_salvage_score != expected_score:
		push_error("Safe/deep route comparison smoke expected %s route to hold %d pickups worth %d, got held=%d score=%d ids=%s." % [route_label, route_targets.size(), expected_score, _held_salvage, _held_salvage_score, _held_salvage_ids])
		return {}

	if return_via_first_target:
		var reached_return_waypoint := await _swim_to_target(route_targets[0]["center"], oxygen_feedback)
		if not reached_return_waypoint:
			return {}
		_update_status_label()
		_record_route_oxygen_feedback(oxygen_feedback)

	var reached_extraction := await _swim_to_target(_world.get_extraction_center(), oxygen_feedback)
	if not reached_extraction:
		return {}
	_process(0.0)
	_record_route_oxygen_feedback(oxygen_feedback)
	if _held_salvage != 0 or _banked_salvage < route_targets.size() or _banked_score < expected_score or not _world.is_inside_extraction(_player.global_position):
		push_error("Safe/deep route comparison smoke did not bank %s route; held=%d banked=%d score=%d position=%s." % [route_label, _held_salvage, _banked_salvage, _banked_score, _player.global_position])
		return {}

	return {
		"target_ids": ",".join(target_ids),
		"cargo": route_targets.size(),
		"banked": _banked_salvage,
		"score": _banked_score,
		"oxygen": _oxygen_seconds,
		"saw_low": bool(oxygen_feedback.get("low", false)),
		"saw_critical": bool(oxygen_feedback.get("critical", false)),
		"oxygen_feedback": _route_oxygen_feedback_summary(oxygen_feedback),
		"status": _status_label.text if _status_label != null else "",
	}



func _record_route_oxygen_feedback(oxygen_feedback: Dictionary) -> void:
	var feedback_label := _oxygen_feedback_label()
	if feedback_label == "CRITICAL":
		oxygen_feedback["critical"] = true
	elif feedback_label == "LOW":
		oxygen_feedback["low"] = true



func _route_oxygen_feedback_summary(oxygen_feedback: Dictionary) -> String:
	var labels := PackedStringArray()
	if bool(oxygen_feedback.get("low", false)):
		labels.append("LOW")
	if bool(oxygen_feedback.get("critical", false)):
		labels.append("CRITICAL")
	if labels.is_empty():
		return "comfortable"
	return ",".join(labels)



func _smoke_route_choice_metadata_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Route choice metadata smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return

	var salvage: Array = _world.get_salvage_centers()
	var route_targets: Array = _route_choice_targets_for_route(salvage, EXPANDED_ROUTE_CHOICE_ID)
	if route_targets.size() < 2:
		push_error("Route choice metadata smoke requires at least two targets for validation_route=%s, got %d." % [EXPANDED_ROUTE_CHOICE_ID, route_targets.size()])
		get_tree().quit(1)
		return

	var default_target := _route_choice_target(salvage)
	if default_target.is_empty():
		push_error("Route choice metadata smoke requires a default valuable target.")
		get_tree().quit(1)
		return
	if str(default_target.get("id", "")) != str(route_targets[0].get("id", "")):
		push_error("Route choice metadata smoke expected first ordered route target %s to match default route target %s." % [str(route_targets[0].get("id", "")), str(default_target.get("id", ""))])
		get_tree().quit(1)
		return

	var extraction_center: Vector2 = _world.get_extraction_center()
	var previous_order := -1
	var target_ids := PackedStringArray()
	var target_orders := PackedStringArray()
	var target_scores := PackedStringArray()
	for target in route_targets:
		var target_id := str(target.get("id", "salvage"))
		var route_choice_id := str(target.get("route_choice_id", ""))
		var route_order := int(target.get("route_order", -1))
		target_ids.append(target_id)
		target_orders.append(str(route_order))
		target_scores.append(str(int(target.get("score", 0))))

		if route_choice_id.is_empty():
			push_error("Route choice metadata smoke found target %s without route_choice_id." % target_id)
			get_tree().quit(1)
			return
		if not bool(target.get("has_route_order", false)):
			push_error("Route choice metadata smoke found target %s without route_order." % target_id)
			get_tree().quit(1)
			return
		if route_order <= previous_order:
			push_error("Route choice metadata smoke found non-increasing route_order at %s: %d after %d." % [target_id, route_order, previous_order])
			get_tree().quit(1)
			return
		if str(target.get("tier", "common")) != "valuable":
			push_error("Route choice metadata smoke expected target %s to be valuable." % target_id)
			get_tree().quit(1)
			return
		if int(target.get("score", 0)) <= 0:
			push_error("Route choice metadata smoke expected target %s to have positive score." % target_id)
			get_tree().quit(1)
			return

		var target_center: Vector2 = target["center"]
		if _world.find_open_path(_world.spawn_position, target_center).is_empty():
			push_error("Route choice metadata smoke found no open route from spawn to %s." % target_id)
			get_tree().quit(1)
			return
		if _world.find_open_path(target_center, extraction_center).is_empty():
			push_error("Route choice metadata smoke found no open return route from %s to extraction." % target_id)
			get_tree().quit(1)
			return

		previous_order = route_order

	print("Route choice metadata smoke passed: route=%s targets=%s orders=%s scores=%s first_target=%s." % [
		EXPANDED_ROUTE_CHOICE_ID,
		",".join(target_ids),
		",".join(target_orders),
		",".join(target_scores),
		str(default_target.get("id", "")),
	])
	get_tree().quit()



func _route_choice_target(salvage: Array) -> Dictionary:
	for item in salvage:
		if str(item.get("tier", "common")) == "valuable":
			return item
	return {}



func _route_choice_targets_for_route(salvage: Array, route_id: String) -> Array:
	var targets: Array = []
	for item in salvage:
		if str(item.get("validation_route", "")) == route_id:
			targets.append(item)
	targets.sort_custom(Callable(self, "_sort_route_choice_targets"))
	return targets



func _sort_route_choice_targets(a: Dictionary, b: Dictionary) -> bool:
	var a_order := int(a.get("route_order", 0))
	var b_order := int(b.get("route_order", 0))
	if a_order != b_order:
		return a_order < b_order
	return str(a.get("id", "")) < str(b.get("id", ""))



func _swim_to_target(target: Vector2, oxygen_feedback: Dictionary = {}) -> bool:
	var path: Array = _world.find_open_path(_player.global_position, target)
	if path.is_empty():
		push_error("No open-water path from %s to %s." % [_player.global_position, target])
		return false

	for waypoint_value in path:
		var waypoint: Vector2 = waypoint_value
		var frames_at_waypoint := 0
		while _player.global_position.distance_to(waypoint) > 4.0:
			var direction: Vector2 = (waypoint - _player.global_position).normalized()
			_player.swim_in_direction(direction, 1.0 / 60.0)
			frames_at_waypoint += 1
			if frames_at_waypoint > 120:
				push_error("Timed out swimming toward waypoint %s from %s." % [waypoint, _player.global_position])
				return false
			await get_tree().physics_frame
			if not oxygen_feedback.is_empty():
				_record_route_oxygen_feedback(oxygen_feedback)

	_player.swim_in_direction(Vector2.ZERO, 1.0 / 60.0)
	await get_tree().physics_frame
	if not oxygen_feedback.is_empty():
		_record_route_oxygen_feedback(oxygen_feedback)
	return true
