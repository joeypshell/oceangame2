extends "res://scripts/main/smoke/smoke_check_base.gd"

const PASS_12_REST_MARKER_ID := "lower_loop_oxygen_rest_pocket"
const PASS_12_ROUTE_CONTEXT := "oxygen_rest_pressure"
const PASS_12_LABEL := "Rest pocket"


func _smoke_pass_12_oxygen_rest_pressure_and_quit() -> void:
	_load_playable_map(PRODUCTION_SLICE_MAP_PATH, false)
	if _world.map_id != "production_slice_01":
		push_error("Pass 12 oxygen/rest smoke loaded unexpected map: %s." % _world.map_id)
		get_tree().quit(1)
		return

	var marker: Dictionary = _world.get_marker_zone(PASS_12_REST_MARKER_ID)
	if marker.is_empty() or not bool(marker.get("oxygen_rest", false)):
		push_error("Pass 12 oxygen/rest smoke missing rest marker %s." % PASS_12_REST_MARKER_ID)
		get_tree().quit(1)
		return

	var route_context := str(marker.get("route_context", ""))
	var label := str(marker.get("oxygen_rest_label", ""))
	var cap_seconds := float(marker.get("oxygen_rest_cap_seconds", 0.0))
	var refill_per_second := float(marker.get("oxygen_rest_refill_per_second", 0.0))
	if route_context != PASS_12_ROUTE_CONTEXT or label != PASS_12_LABEL or cap_seconds <= 0.0 or refill_per_second <= 0.0:
		push_error("Pass 12 oxygen/rest metadata mismatch: marker=%s." % str(marker))
		get_tree().quit(1)
		return

	var rest_center := _marker_center(marker)
	var path_to_rest: Array = _world.find_open_path(_world.spawn_position, rest_center)
	var return_path: Array = _world.find_open_path(rest_center, _world.get_extraction_center())
	if path_to_rest.is_empty() or return_path.is_empty():
		push_error("Pass 12 oxygen/rest path failure: to_rest=%d return=%d." % [path_to_rest.size(), return_path.size()])
		get_tree().quit(1)
		return

	_player.set_physics_process(false)
	_hazard_interactions_enabled = false
	_player.global_position = rest_center
	_process(0.0)

	var oxygen_before_rest := 20.0
	_oxygen_seconds = oxygen_before_rest
	_process(1.0)
	var oxygen_after_rest := _oxygen_seconds
	var rest_feedback := _status_text()
	if oxygen_after_rest <= oxygen_before_rest or oxygen_after_rest > cap_seconds:
		push_error("Pass 12 oxygen/rest expected recovery up to cap %.1f, got %.1f from %.1f." % [cap_seconds, oxygen_after_rest, oxygen_before_rest])
		get_tree().quit(1)
		return
	if rest_feedback.find("Rest pocket +oxygen") == -1:
		push_error("Pass 12 oxygen/rest did not show recovery feedback: %s." % rest_feedback)
		get_tree().quit(1)
		return

	var oxygen_before_cap_probe := cap_seconds + 15.0
	_oxygen_seconds = oxygen_before_cap_probe
	_process(1.0)
	var oxygen_after_cap_probe := _oxygen_seconds
	var cap_feedback := _status_text()
	if oxygen_after_cap_probe >= oxygen_before_cap_probe or oxygen_after_cap_probe < cap_seconds:
		push_error("Pass 12 oxygen/rest cap probe expected normal drain above cap %.1f, got %.1f from %.1f." % [cap_seconds, oxygen_after_cap_probe, oxygen_before_cap_probe])
		get_tree().quit(1)
		return
	if cap_feedback.find("Rest pocket cap") == -1:
		push_error("Pass 12 oxygen/rest did not show capped feedback: %s." % cap_feedback)
		get_tree().quit(1)
		return
	if _held_salvage != 0 or _banked_salvage != 0 or _banked_score != 0 or _run_complete or _run_failed:
		push_error("Pass 12 oxygen/rest changed cargo/run state: held=%d banked=%d score=%d complete=%s failed=%s." % [
			_held_salvage,
			_banked_salvage,
			_banked_score,
			str(_run_complete),
			str(_run_failed),
		])
		get_tree().quit(1)
		return

	_player.global_position = _world.get_extraction_center()
	_process(0.0)
	if _status_text().find("Rest pocket") != -1:
		push_error("Pass 12 oxygen/rest feedback did not clear after leaving pocket: %s." % _status_text())
		get_tree().quit(1)
		return

	_reset_run()
	if _main._oxygen_rest_prompt() != "" or _held_salvage != 0 or _banked_salvage != 0 or _run_complete or _run_failed:
		push_error("Pass 12 oxygen/rest reset did not clear state: prompt=%s held=%d banked=%d complete=%s failed=%s." % [
			_main._oxygen_rest_prompt(),
			_held_salvage,
			_banked_salvage,
			str(_run_complete),
			str(_run_failed),
		])
		get_tree().quit(1)
		return

	print("Pass 12 oxygen/rest smoke passed: marker=%s route=%s cap=%.1f refill=%.1f paths=%d,%d oxygen=%.1f->%.1f cap_probe=%.1f->%.1f held=%d banked=%d feedback=\"%s\" reset_clean=true." % [
		PASS_12_REST_MARKER_ID,
		route_context,
		cap_seconds,
		refill_per_second,
		path_to_rest.size(),
		return_path.size(),
		oxygen_before_rest,
		oxygen_after_rest,
		oxygen_before_cap_probe,
		oxygen_after_cap_probe,
		_held_salvage,
		_banked_salvage,
		rest_feedback.split("\n")[-1],
	])
	get_tree().quit()


func _marker_center(marker: Dictionary) -> Vector2:
	var tile_size := float(_world.tile_size)
	return Vector2(
		(float(marker.get("x", 0)) + float(marker.get("w", 0)) * 0.5) * tile_size,
		(float(marker.get("y", 0)) + float(marker.get("h", 0)) * 0.5) * tile_size
	)


func _status_text() -> String:
	return _status_label.text if _status_label != null else ""
