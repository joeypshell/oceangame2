extends "res://scripts/main/smoke/smoke_check_base.gd"

const HAZARD_ID := "deep_route_jellyfish_patrol"
const EXPECTED_PROMPT := "Jellyfish patrol - wait"


func _smoke_moving_hazard_and_quit() -> void:
	if _world.map_id != "production_slice_01":
		push_error("Moving-hazard smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return
	if not _world.has_method("get_moving_hazards"):
		push_error("Moving-hazard smoke requires moving hazard runtime queries.")
		get_tree().quit(1)
		return

	var hazard := _moving_hazard_by_id(HAZARD_ID)
	if hazard.is_empty():
		push_error("Moving-hazard smoke did not find %s." % HAZARD_ID)
		get_tree().quit(1)
		return

	var start_center: Vector2 = hazard["center"]
	_process(0.5)
	var moved_hazard := _moving_hazard_by_id(HAZARD_ID)
	var moved_center: Vector2 = moved_hazard["center"]
	var moved_delta := moved_center.x - start_center.x
	if moved_delta <= 8.0:
		push_error("Moving-hazard smoke expected deterministic rightward movement, delta=%.2f." % moved_delta)
		get_tree().quit(1)
		return

	_player.global_position = moved_center + Vector2(0, HAZARD_CONTACT_RADIUS + 12.0)
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	_process(0.0)
	if _status_text().find(EXPECTED_PROMPT) == -1:
		push_error("Moving-hazard smoke missing warning prompt: %s." % _status_text())
		get_tree().quit(1)
		return

	var salvage := _first_instant_salvage()
	if salvage.is_empty():
		push_error("Moving-hazard smoke requires one instant salvage target for reset semantics.")
		get_tree().quit(1)
		return
	_player.global_position = salvage["center"]
	if not _collect_salvage_for_smoke(salvage):
		push_error("Moving-hazard smoke could not collect held salvage before contact.")
		get_tree().quit(1)
		return
	if _held_salvage != 1:
		push_error("Moving-hazard smoke expected one held salvage before contact, held=%d." % _held_salvage)
		get_tree().quit(1)
		return

	var oxygen_before := _oxygen_seconds
	moved_hazard = _moving_hazard_by_id(HAZARD_ID)
	_player.global_position = moved_hazard["center"]
	if _player.has_method("reset_motion"):
		_player.reset_motion()
	_process(0.0)
	if _held_salvage != 0 or _oxygen_seconds >= oxygen_before:
		push_error("Moving-hazard smoke contact did not apply reset/oxygen semantics: held=%d oxygen_before=%.1f oxygen_after=%.1f." % [
			_held_salvage,
			oxygen_before,
			_oxygen_seconds,
		])
		get_tree().quit(1)
		return
	if _world.is_salvage_collected(str(salvage.get("id", ""))):
		push_error("Moving-hazard smoke did not restore held salvage after contact.")
		get_tree().quit(1)
		return

	print("Moving-hazard smoke passed: hazard=%s moved_delta=%.2f prompt='%s' oxygen_before=%.1f oxygen_after=%.1f held_restored=true." % [
		HAZARD_ID,
		moved_delta,
		EXPECTED_PROMPT,
		oxygen_before,
		_oxygen_seconds,
	])
	get_tree().quit()


func _moving_hazard_by_id(hazard_id: String) -> Dictionary:
	for hazard in _world.get_moving_hazards():
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


func _first_instant_salvage() -> Dictionary:
	for salvage in _world.get_salvage_centers():
		if str(salvage.get("interaction", "instant")) == "instant":
			return salvage
	return {}


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
