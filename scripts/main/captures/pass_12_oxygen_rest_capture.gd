extends RefCounted

const REST_MARKER_ID := "lower_loop_oxygen_rest_pocket"
const EXPECTED_FEEDBACK := "Rest pocket +oxygen"
const CAPTURE_ZOOM := Vector2(0.78, 0.78)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 12 oxygen/rest capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var marker: Dictionary = _main._world.get_marker_zone(REST_MARKER_ID)
	if marker.is_empty() or not bool(marker.get("oxygen_rest", false)):
		push_error("Pass 12 oxygen/rest capture requires marker %s." % REST_MARKER_ID)
		_main.get_tree().quit(1)
		return

	var rest_center := _zone_center(marker)
	_main._hazard_interactions_enabled = false
	_main._sortie_state.oxygen_seconds = 20.0
	_main._player.global_position = rest_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(1.0)
	_main._update_status_label()
	_main.set_process(false)

	if _main._status_label == null or _main._status_label.text.find(EXPECTED_FEEDBACK) == -1:
		push_error("Pass 12 oxygen/rest capture expected feedback before saving: %s." % EXPECTED_FEEDBACK)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "Pass12OxygenRestCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = rest_center + Vector2(24, 32)

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_oxygen_rest_pressure.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 12 oxygen/rest capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


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
