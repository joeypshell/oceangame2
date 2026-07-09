extends "res://scripts/main/smoke/smoke_check_base.gd"

const PRY_INTERACTION := "pry_salvage"


func _smoke_pry_salvage_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Pry salvage smoke loaded unexpected map: %s" % _world.map_id)
		get_tree().quit(1)
		return

	var target := _pry_salvage_target()
	var target_id := str(target.get("id", ""))
	var instant_targets := _instant_salvage_targets(target_id)
	var hazards: Array = _world.get_hazard_centers()
	if target.is_empty() or instant_targets.size() < HELD_SALVAGE_CAPACITY or hazards.is_empty():
		push_error("Pry salvage smoke requires one pry target, enough instant cargo fillers, and a hazard.")
		get_tree().quit(1)
		return

	var target_center: Vector2 = target["center"]
	var interaction_seconds := float(target.get("interaction_seconds", 0.0))
	var pry_stages := int(target.get("pry_stages", 0))
	var target_score := int(target.get("score", 0))
	var partial_seconds := interaction_seconds * 0.4
	var partial_percent := int(round(100.0 * partial_seconds / interaction_seconds))
	var oxygen_start := _oxygen_seconds

	if interaction_seconds <= 0.0 or pry_stages <= 0:
		push_error("Pry salvage smoke target %s has invalid settings seconds=%.2f stages=%d." % [target_id, interaction_seconds, pry_stages])
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = target_center
	_process(0.0)
	if _world.is_salvage_collected(target_id) or _held_salvage_ids.has(target_id):
		push_error("Pry salvage smoke collected %s instantly." % target_id)
		get_tree().quit(1)
		return

	_process(partial_seconds)
	if _world.is_salvage_collected(target_id) or not _status_has_pry_progress(1, pry_stages, partial_percent):
		push_error("Pry salvage smoke did not show stage 1 partial progress; status=%s." % _status_text())
		get_tree().quit(1)
		return
	var oxygen_after_progress := _oxygen_seconds

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _world.is_salvage_collected(target_id) or _status_text().find("Pry interrupted") == -1:
		push_error("Pry salvage smoke did not cancel partial stage when leaving range; status=%s." % _status_text())
		get_tree().quit(1)
		return
	var first_cancel_feedback := _last_status_note

	_player.global_position = target_center
	_process(interaction_seconds + 0.05)
	if _world.is_salvage_collected(target_id) or not _status_has_pry_progress(2, pry_stages):
		push_error("Pry salvage smoke did not persist completed stage 1; status=%s." % _status_text())
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _status_text().find("1/%d saved" % pry_stages) == -1:
		push_error("Pry salvage smoke did not report saved completed stage after leaving; status=%s." % _status_text())
		get_tree().quit(1)
		return
	var saved_stage_feedback := _last_status_note

	_player.global_position = target_center
	_process(interaction_seconds * float(pry_stages - 1) + SMOKE_TIMED_SALVAGE_MARGIN_SECONDS)
	if _held_salvage != 1 or not _held_salvage_ids.has(target_id) or _held_salvage_score != target_score:
		push_error("Pry salvage smoke did not move completed target into held cargo; held=%d ids=%s score=%d." % [_held_salvage, _held_salvage_ids, _held_salvage_score])
		get_tree().quit(1)
		return
	if _status_text().find("opened +%d" % target_score) == -1:
		push_error("Pry salvage smoke did not show completion feedback; status=%s." % _status_text())
		get_tree().quit(1)
		return
	var complete_feedback := _last_status_note
	var held_after_completion := _held_salvage

	_hazard_interactions_enabled = true
	_player.global_position = hazards[0]["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	if _held_salvage != 0 or _world.is_salvage_collected(target_id):
		push_error("Pry salvage smoke hazard hit did not restore completed unbanked target.")
		get_tree().quit(1)
		return

	_reset_run()
	_hazard_interactions_enabled = false
	var expected_fill_score := 0
	for index in range(HELD_SALVAGE_CAPACITY):
		var filler: Dictionary = instant_targets[index]
		expected_fill_score += int(filler.get("score", 0))
		_player.global_position = filler["center"]
		_collect_salvage_for_smoke(filler)
	if _held_salvage != HELD_SALVAGE_CAPACITY:
		push_error("Pry salvage smoke could not fill cargo before capacity test; held=%d." % _held_salvage)
		get_tree().quit(1)
		return

	_player.global_position = target_center
	_process(interaction_seconds * float(pry_stages) + SMOKE_TIMED_SALVAGE_MARGIN_SECONDS)
	if _world.is_salvage_collected(target_id) or _held_salvage_ids.has(target_id):
		push_error("Pry salvage smoke collected target while cargo was full.")
		get_tree().quit(1)
		return
	if _status_text().find("Cargo full - return to extraction") == -1:
		push_error("Pry salvage smoke did not show cargo-full feedback; status=%s." % _status_text())
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _banked_salvage != HELD_SALVAGE_CAPACITY or _banked_score != expected_fill_score:
		push_error("Pry salvage smoke did not bank filled cargo; banked=%d score=%d expected=%d." % [_banked_salvage, _banked_score, expected_fill_score])
		get_tree().quit(1)
		return

	_player.global_position = target_center
	if not _collect_salvage_for_smoke(target):
		push_error("Pry salvage smoke could not collect target after capacity freed.")
		get_tree().quit(1)
		return
	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	var banked_score_after_pry := _banked_score
	var objective_complete_after_pry := _run_complete
	if _held_salvage != 0 or _banked_score != expected_fill_score + target_score:
		push_error("Pry salvage smoke did not bank completed pry target; held=%d banked_score=%d." % [_held_salvage, _banked_score])
		get_tree().quit(1)
		return

	_reset_run()
	_hazard_interactions_enabled = false
	_player.global_position = target_center
	_process(interaction_seconds + 0.05)
	_hazard_interactions_enabled = true
	_player.global_position = hazards[0]["center"]
	_hazard_cooldown_seconds = 0.0
	_process(0.0)
	_hazard_interactions_enabled = false
	_player.global_position = target_center
	_process(0.05)
	if not _status_has_pry_progress(1, pry_stages):
		push_error("Pry salvage smoke hazard reset did not clear staged progress; status=%s." % _status_text())
		get_tree().quit(1)
		return

	_reset_run()
	_player.global_position = target_center
	_process(interaction_seconds + 0.05)
	_oxygen_seconds = 0.1
	_process(0.2)
	if not _run_failed or _held_salvage != 0 or _world.is_salvage_collected(target_id):
		push_error("Pry salvage smoke oxygen failure did not clear active pry state.")
		get_tree().quit(1)
		return
	_reset_run()
	_player.global_position = target_center
	_process(0.05)
	if not _status_has_pry_progress(1, pry_stages):
		push_error("Pry salvage smoke oxygen reset did not restart from stage 1; status=%s." % _status_text())
		get_tree().quit(1)
		return

	_reset_run()
	print("Pry salvage smoke passed: target=%s seconds=%.1f stages=%d partial=%d%% cancel=\"%s\" saved=\"%s\" complete=\"%s\" held_after_complete=%d banked_score=%d objective_complete=%s oxygen=%.1f->%.1f cargo_blocked=true hazard_reset=true oxygen_reset=true." % [
		target_id,
		interaction_seconds,
		pry_stages,
		partial_percent,
		first_cancel_feedback,
		saved_stage_feedback,
		complete_feedback,
		held_after_completion,
		banked_score_after_pry,
		str(objective_complete_after_pry),
		oxygen_start,
		oxygen_after_progress,
	])
	get_tree().quit()


func _pry_salvage_target() -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == PRY_INTERACTION:
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


func _status_has_pry_progress(stage: int, stages: int, percent := -1) -> bool:
	var status := _status_text()
	if status.find("Prying") == -1 or status.find("Stage %d/%d" % [stage, stages]) == -1:
		return false
	return percent < 0 or status.find("%d%%" % percent) != -1


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
