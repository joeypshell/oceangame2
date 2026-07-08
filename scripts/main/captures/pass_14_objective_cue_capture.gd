extends RefCounted

const EXPECTED_START_CUE := "Objective: Deep cache 0/2"
const CAPTURE_ZOOM := Vector2(1.05, 1.05)
const CAMERA_OFFSET := Vector2(72, 48)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 14 objective cue capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var review_position: Vector2 = _main._world.spawn_position
	_main._hazard_interactions_enabled = false
	_main._player.global_position = review_position
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	_main.set_process(false)

	if not _main._world.is_inside_extraction(_main._player.global_position):
		push_error("Pass 14 objective cue capture expected spawn to be inside extraction.")
		_main.get_tree().quit(1)
		return

	var status_text: String = _main._status_label.text if _main._status_label != null else ""
	if status_text.find(EXPECTED_START_CUE) == -1:
		push_error("Pass 14 objective cue capture expected start cue before saving: %s" % status_text)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "Pass14ObjectiveCueCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = review_position + CAMERA_OFFSET

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_objective_cue.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 14 objective cue capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
