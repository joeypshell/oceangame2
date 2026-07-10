extends RefCounted

const PASS_10_SEGMENT_ID := "return_pressure_to_boat"
const PASS_10_TARGET_ID := "salvage_return_branch"
const LOWER_LOOP_SALVAGE_ID := "salvage_lower_loop"
const DEEP_CACHE_SALVAGE_ID := "salvage_deep_right_cache"
const EXPECTED_FEEDBACK := "Cargo full - bank at boat"
const CAPTURE_ZOOM := Vector2(0.82, 0.82)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 10 return-pressure capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var segment: Dictionary = _main._world.get_marker_zone(PASS_10_SEGMENT_ID)
	var lower_loop: Dictionary = _salvage_by_id(LOWER_LOOP_SALVAGE_ID)
	var deep_cache: Dictionary = _salvage_by_id(DEEP_CACHE_SALVAGE_ID)
	var target: Dictionary = _salvage_by_id(PASS_10_TARGET_ID)
	if segment.is_empty() or lower_loop.is_empty() or deep_cache.is_empty() or target.is_empty():
		push_error("Pass 10 return-pressure capture requires segment, lower-loop, deep-cache, and target source data.")
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	_collect_for_capture(lower_loop)
	_collect_for_capture(deep_cache)
	if _main._sortie_state.held_salvage < _main.HELD_SALVAGE_CAPACITY:
		push_error("Pass 10 return-pressure capture did not fill cargo before target review.")
		_main.get_tree().quit(1)
		return

	var target_center: Vector2 = target["center"]
	_main._player.global_position = target_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	_main.set_process(false)

	if _main._world.is_salvage_collected(PASS_10_TARGET_ID):
		push_error("Pass 10 return-pressure capture collected the blocked target.")
		_main.get_tree().quit(1)
		return
	if _main._status_label == null or _main._status_label.text.find(EXPECTED_FEEDBACK) == -1:
		push_error("Pass 10 return-pressure capture expected feedback before saving: %s" % EXPECTED_FEEDBACK)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "Pass10ReturnPressureCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = (_zone_center(segment) + target_center + lower_loop["center"]) / 3.0 + Vector2(16, -12)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_return_pressure.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 10 return-pressure capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _collect_for_capture(salvage: Dictionary) -> void:
	_main._player.global_position = salvage["center"]
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	if str(salvage.get("interaction", "instant")) == "timed_salvage":
		var interaction_seconds := maxf(0.01, float(salvage.get("interaction_seconds", 0.0)))
		_main._process(interaction_seconds + 0.1)


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _zone_center(zone: Dictionary) -> Vector2:
	return Vector2(
		(float(zone.get("x", 0.0)) + float(zone.get("w", 1.0)) * 0.5) * float(_main._world.tile_size),
		(float(zone.get("y", 0.0)) + float(zone.get("h", 1.0)) * 0.5) * float(_main._world.tile_size)
	)


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
