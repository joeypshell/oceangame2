extends "res://scripts/main/smoke/smoke_check_base.gd"

func _smoke_salvage_loop_and_quit() -> void:
	if _total_salvage <= 0:
		push_error("Salvage loop smoke requires a map with authored salvage.")
		get_tree().quit(1)
		return

	var expected_score := 0
	for salvage in _salvage_centers_for_full_collection():
		expected_score += int(salvage.get("score", 0))
		_player.global_position = salvage["center"]
		_collect_salvage_for_smoke(salvage)
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			_player.global_position = _world.get_extraction_center()
			_process(0.0)

	_player.global_position = _world.get_extraction_center()
	_process(0.0)

	if not _run_complete:
		push_error("Salvage loop smoke did not complete after collecting and returning.")
		get_tree().quit(1)
		return
	if _result_panel == null or not _result_panel.visible or _result_label == null:
		push_error("Salvage loop smoke did not show the expedition result panel on completion.")
		get_tree().quit(1)
		return
	var expected_bonus := _completion_oxygen_bonus
	var expected_total_score := expected_score + expected_bonus
	if _result_label.text.find("Score %d" % expected_total_score) == -1 or _result_label.text.find("Salvage score %d" % expected_score) == -1 or _result_label.text.find("Oxygen bonus +%d" % _completion_oxygen_bonus) == -1 or _result_label.text.find("Salvage %d/%d" % [_banked_salvage, _total_salvage]) == -1:
		push_error("Salvage loop smoke result panel did not report score/salvage: %s" % _result_label.text)
		get_tree().quit(1)
		return
	if _banked_score != expected_score:
		push_error("Salvage loop smoke banked score %d, expected %d." % [_banked_score, expected_score])
		get_tree().quit(1)
		return
	if _session_wallet() != expected_score or _session_payout_total() != expected_score:
		push_error("Salvage loop smoke session wallet %d payout %d, expected banked salvage score %d." % [_session_wallet(), _session_payout_total(), expected_score])
		get_tree().quit(1)
		return

	var completed_total := _total_salvage
	var completed_score := _banked_score
	_reset_run()
	if _held_salvage != 0 or _banked_salvage != 0 or _held_salvage_score != 0 or _banked_score != 0 or _completion_oxygen_bonus != 0 or _run_complete or _run_failed:
		push_error("Salvage loop smoke reset left stale run state.")
		get_tree().quit(1)
		return
	if _session_wallet() != completed_score or _session_payout_total() != completed_score:
		push_error("Salvage loop smoke reset cleared session wallet; wallet=%d payout=%d expected=%d." % [_session_wallet(), _session_payout_total(), completed_score])
		get_tree().quit(1)
		return

	print("Salvage loop smoke passed: collected, banked %d score, completed, and reset %d salvage." % [completed_score, completed_total])
	get_tree().quit()



func _smoke_session_best_score_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Session best score smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if _total_salvage <= 0:
		push_error("Session best score smoke requires authored salvage.")
		get_tree().quit(1)
		return
	if _session_best_score() != 0:
		push_error("Session best score smoke expected a fresh map best of 0, got %d." % _session_best_score())
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var salvage_targets: Array = _salvage_centers_for_full_collection()
	var expected_score := 0
	for salvage in salvage_targets:
		expected_score += int(salvage.get("score", 0))
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			_player.global_position = _world.get_extraction_center()
			_process(0.0)
		_player.global_position = salvage["center"]
		_collect_salvage_for_smoke(salvage)

	if _held_salvage > 0:
		_player.global_position = _world.get_extraction_center()
		_process(0.0)

	if not _run_complete or _banked_score != expected_score:
		push_error("Session best score smoke expected complete score %d, got complete=%s score=%d." % [expected_score, str(_run_complete), _banked_score])
		get_tree().quit(1)
		return
	var expected_bonus := _completion_oxygen_bonus
	var expected_total_score := expected_score + expected_bonus
	if _session_best_score() != expected_total_score:
		push_error("Session best score smoke expected best score %d after completion, got %d." % [expected_total_score, _session_best_score()])
		get_tree().quit(1)
		return
	if _result_panel == null or not _result_panel.visible or _result_label == null:
		push_error("Session best score smoke did not show result panel after completion.")
		get_tree().quit(1)
		return
	if _result_label.text.find("Score %d" % expected_total_score) == -1 or _result_label.text.find("Best %d" % expected_total_score) == -1:
		push_error("Session best score smoke result panel did not show score and best: %s" % _result_label.text)
		get_tree().quit(1)
		return

	_reset_run()
	if _session_best_score() != expected_total_score:
		push_error("Session best score smoke reset cleared best score; expected %d got %d." % [expected_total_score, _session_best_score()])
		get_tree().quit(1)
		return
	if _result_panel != null and _result_panel.visible:
		push_error("Session best score smoke reset left result panel visible.")
		get_tree().quit(1)
		return

	var failure_score := expected_total_score + 100
	_banked_score = failure_score
	_banked_salvage = 1
	_handle_oxygen_depleted()
	_update_status_label()
	if not _run_failed or _session_best_score() != expected_total_score:
		push_error("Session best score smoke failure changed best score; failed=%s best=%d expected=%d." % [str(_run_failed), _session_best_score(), expected_total_score])
		get_tree().quit(1)
		return
	if _result_label == null or _result_label.text.find("Score %d" % failure_score) == -1 or _result_label.text.find("Best %d" % expected_total_score) == -1:
		push_error("Session best score smoke failure panel did not preserve best score: %s" % _result_label.text)
		get_tree().quit(1)
		return

	_reset_run()
	_load_playable_map(PRODUCTION_SLICE_02_MAP_PATH, false)
	if _world.map_id != "production_slice_02" or _session_best_score() != 0:
		push_error("Session best score smoke expected production_slice_02 best to start at 0, got map=%s best=%d." % [_world.map_id, _session_best_score()])
		get_tree().quit(1)
		return
	_load_playable_map(PRODUCTION_SLICE_MAP_PATH, false)
	if _world.map_id != "production_slice_01" or _session_best_score() != expected_total_score:
		push_error("Session best score smoke expected production_slice_01 best %d after map reload, got map=%s best=%d." % [expected_total_score, _world.map_id, _session_best_score()])
		get_tree().quit(1)
		return

	print("Session best score smoke passed: salvage=%d oxygen_bonus=%d best=%d failure_score=%d map_scope=production_slice_01." % [
		expected_score,
		expected_bonus,
		_session_best_score(),
		failure_score,
	])
	get_tree().quit()



func _smoke_oxygen_bonus_score_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Oxygen bonus score smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if _total_salvage <= 0:
		push_error("Oxygen bonus score smoke requires authored salvage.")
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	var expected_salvage_score := 0
	for salvage in _salvage_centers_for_full_collection():
		expected_salvage_score += int(salvage.get("score", 0))
		if _held_salvage >= HELD_SALVAGE_CAPACITY:
			_player.global_position = _world.get_extraction_center()
			_process(0.0)
		_player.global_position = salvage["center"]
		_collect_salvage_for_smoke(salvage)

	if _held_salvage > 0:
		_player.global_position = _world.get_extraction_center()
		_process(0.0)

	var expected_bonus := int(ceil(_oxygen_seconds)) * OXYGEN_BONUS_POINTS_PER_SECOND
	var expected_total_score := expected_salvage_score + expected_bonus
	if not _run_complete:
		push_error("Oxygen bonus score smoke did not complete run.")
		get_tree().quit(1)
		return
	if _banked_score != expected_salvage_score:
		push_error("Oxygen bonus score smoke changed salvage banked score; got %d expected %d." % [_banked_score, expected_salvage_score])
		get_tree().quit(1)
		return
	if _completion_oxygen_bonus != expected_bonus or _current_expedition_score() != expected_total_score:
		push_error("Oxygen bonus score smoke expected salvage %d + bonus %d = %d, got bonus=%d total=%d." % [expected_salvage_score, expected_bonus, expected_total_score, _completion_oxygen_bonus, _current_expedition_score()])
		get_tree().quit(1)
		return
	if expected_bonus <= 0 or expected_bonus > OXYGEN_MAX_SECONDS * OXYGEN_BONUS_POINTS_PER_SECOND:
		push_error("Oxygen bonus score smoke computed out-of-range bonus %d." % expected_bonus)
		get_tree().quit(1)
		return
	if _result_label == null or _result_label.text.find("Score %d" % expected_total_score) == -1 or _result_label.text.find("Salvage score %d" % expected_salvage_score) == -1 or _result_label.text.find("Oxygen bonus +%d" % expected_bonus) == -1:
		push_error("Oxygen bonus score smoke result panel did not report score breakdown: %s" % _result_label.text)
		get_tree().quit(1)
		return

	_reset_run()
	_banked_score = expected_salvage_score
	_banked_salvage = 1
	_oxygen_seconds = 0.0
	_handle_oxygen_depleted()
	_update_status_label()
	if not _run_failed or _completion_oxygen_bonus != 0:
		push_error("Oxygen bonus score smoke failure received completion bonus; failed=%s bonus=%d." % [str(_run_failed), _completion_oxygen_bonus])
		get_tree().quit(1)
		return
	if _result_label == null or _result_label.text.find("Score %d" % expected_salvage_score) == -1 or _result_label.text.find("Oxygen bonus +0") == -1:
		push_error("Oxygen bonus score smoke failure panel did not show zero oxygen bonus: %s" % _result_label.text)
		get_tree().quit(1)
		return

	_reset_run()
	print("Oxygen bonus score smoke passed: salvage=%d oxygen_bonus=%d total=%d failure_bonus=0." % [
		expected_salvage_score,
		expected_bonus,
		expected_total_score,
	])
	get_tree().quit()



func _smoke_route_outcome_result_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Route outcome result smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return
	if _total_salvage <= 0:
		push_error("Route outcome result smoke requires authored salvage.")
		get_tree().quit(1)
		return

	if not _complete_route_outcome_review_state():
		get_tree().quit(1)
		return

	var expected_route_text := "Route: Deep route"
	if _result_label == null or _result_label.text.find(expected_route_text) == -1:
		push_error("Route outcome result smoke did not show %s in result panel: %s" % [expected_route_text, _result_label.text if _result_label != null else ""])
		get_tree().quit(1)
		return

	_reset_run()
	_handle_oxygen_depleted()
	_update_status_label()
	if _result_label == null or _result_label.text.find("Route:") != -1:
		push_error("Route outcome result smoke expected generic failure result without route text: %s" % [_result_label.text if _result_label != null else ""])
		get_tree().quit(1)
		return

	print("Route outcome result smoke passed: tagged completion reported %s and generic failure stayed untagged." % expected_route_text)
	get_tree().quit()



func _smoke_cargo_capacity_and_quit() -> void:
	var salvage: Array = _world.get_salvage_centers()
	if salvage.size() <= HELD_SALVAGE_CAPACITY:
		push_error("Cargo capacity smoke requires more salvage than capacity.")
		get_tree().quit(1)
		return

	for index in range(HELD_SALVAGE_CAPACITY):
		_player.global_position = salvage[index]["center"]
		_collect_salvage_for_smoke(salvage[index])

	var expected_held_score := 0
	for index in range(HELD_SALVAGE_CAPACITY):
		expected_held_score += int(salvage[index].get("score", 0))

	if _held_salvage != HELD_SALVAGE_CAPACITY:
		push_error("Cargo capacity smoke expected held cargo to reach capacity, got %d." % _held_salvage)
		get_tree().quit(1)
		return
	if _held_salvage_score != expected_held_score or _banked_score != 0:
		push_error("Cargo capacity smoke expected held score %d and banked score 0 before extraction, got held score %d banked score %d." % [expected_held_score, _held_salvage_score, _banked_score])
		get_tree().quit(1)
		return

	var blocked_id := str(salvage[HELD_SALVAGE_CAPACITY].get("id", "salvage"))
	var blocked_score := int(salvage[HELD_SALVAGE_CAPACITY].get("score", 0))
	_player.global_position = salvage[HELD_SALVAGE_CAPACITY]["center"]
	_process(0.0)
	if _held_salvage != HELD_SALVAGE_CAPACITY or _held_salvage_ids.has(blocked_id):
		push_error("Cargo capacity smoke collected beyond capacity; held=%d ids=%s." % [_held_salvage, _held_salvage_ids])
		get_tree().quit(1)
		return
	if not _world.has_available_salvage_near(_player.global_position, SALVAGE_COLLECTION_RADIUS):
		push_error("Cargo capacity smoke lost blocked salvage %s." % blocked_id)
		get_tree().quit(1)
		return
	if _world.is_salvage_collected(blocked_id):
		push_error("Cargo capacity smoke marked blocked salvage %s collected while cargo was full." % blocked_id)
		get_tree().quit(1)
		return
	if _status_label == null or _status_label.text.find("Cargo full - return to extraction") == -1:
		push_error("Cargo capacity smoke did not show cargo-full return feedback: %s" % _status_label.text)
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _held_salvage != 0 or _banked_salvage != HELD_SALVAGE_CAPACITY:
		push_error("Cargo capacity smoke did not bank and free capacity; held=%d banked=%d." % [_held_salvage, _banked_salvage])
		get_tree().quit(1)
		return
	if _held_salvage_score != 0 or _banked_score != expected_held_score:
		push_error("Cargo capacity smoke did not move held score into banked score; held score=%d banked score=%d expected=%d." % [_held_salvage_score, _banked_score, expected_held_score])
		get_tree().quit(1)
		return

	_player.global_position = salvage[HELD_SALVAGE_CAPACITY]["center"]
	_collect_salvage_for_smoke(salvage[HELD_SALVAGE_CAPACITY])
	if _held_salvage != 1 or _held_salvage_ids[0] != blocked_id:
		push_error("Cargo capacity smoke could not collect blocked salvage after banking.")
		get_tree().quit(1)
		return
	if _held_salvage_score != blocked_score:
		push_error("Cargo capacity smoke collected blocked salvage with held score %d, expected %d." % [_held_salvage_score, blocked_score])
		get_tree().quit(1)
		return

	_reset_run()
	print("Cargo capacity smoke passed: held=%d capacity=%d held_score=%d banked=%d banked_score=%d blocked=%s blocked_score=%d." % [
		1,
		HELD_SALVAGE_CAPACITY,
		blocked_score,
		HELD_SALVAGE_CAPACITY,
		expected_held_score,
		blocked_id,
		blocked_score,
	])
	get_tree().quit()



func _smoke_salvage_feedback_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Salvage feedback smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return

	var common_target := {}
	var valuable_target := {}
	for salvage in _world.get_salvage_centers():
		var tier := str(salvage.get("tier", "common"))
		if tier == "common" and common_target.is_empty():
			common_target = salvage
		elif tier == "valuable" and valuable_target.is_empty():
			valuable_target = salvage

	if common_target.is_empty() or valuable_target.is_empty():
		push_error("Salvage feedback smoke requires common and valuable salvage targets.")
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = common_target["center"]
	_process(0.0)
	var common_score := int(common_target.get("score", 0))
	var common_feedback := _salvage_collection_feedback("common", common_score)
	if _last_status_note != common_feedback or _status_label == null or _status_label.text.find(common_feedback) == -1:
		push_error("Salvage feedback smoke expected common feedback '%s', got note='%s' status='%s'." % [common_feedback, _last_status_note, _status_label.text])
		get_tree().quit(1)
		return

	_reset_run()
	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = valuable_target["center"]
	_process(0.0)
	var valuable_score := int(valuable_target.get("score", 0))
	var valuable_feedback := _salvage_collection_feedback("valuable", valuable_score)
	if _last_status_note != valuable_feedback or _status_label == null or _status_label.text.find(valuable_feedback) == -1:
		push_error("Salvage feedback smoke expected valuable feedback '%s', got note='%s' status='%s'." % [valuable_feedback, _last_status_note, _status_label.text])
		get_tree().quit(1)
		return

	_reset_run()
	print("Salvage feedback smoke passed: common='%s' valuable='%s'." % [common_feedback, valuable_feedback])
	get_tree().quit()
