extends RefCounted

const HAZARD_ID := "deep_route_jellyfish_patrol"
const EXPECTED_PROMPT := "Jellyfish patrol - wait"
const CAPTURE_ZOOM := Vector2(0.92, 0.92)
const CAMERA_OFFSET := Vector2(80, -24)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Moving-hazard capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return
	if _main._world.map_id != "production_slice_01":
		push_error("Moving-hazard capture loaded unexpected map: %s." % _main._world.map_id)
		_main.get_tree().quit(1)
		return

	var hazard := _hazard_by_id(HAZARD_ID)
	if hazard.is_empty():
		push_error("Moving-hazard capture requires hazard %s." % HAZARD_ID)
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	_main._process(1.0)
	hazard = _hazard_by_id(HAZARD_ID)
	_main._player.global_position = hazard["center"] + Vector2(0, _main.HAZARD_CONTACT_RADIUS + 12.0)
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._hazard_interactions_enabled = true
	_main._process(0.0)
	_main._update_status_label()
	var status: String = _main._status_label.text if _main._status_label != null else ""
	if status.find(EXPECTED_PROMPT) == -1:
		push_error("Moving-hazard capture expected warning prompt before saving: %s" % status)
		_main.get_tree().quit(1)
		return
	_main._hazard_interactions_enabled = false
	_main.set_process(false)

	var camera := Camera2D.new()
	camera.name = "MovingHazardCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = _main._player.global_position + CAMERA_OFFSET

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_moving_hazard.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved moving-hazard capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _hazard_by_id(hazard_id: String) -> Dictionary:
	for hazard in _main._world.get_moving_hazards():
		if str(hazard.get("id", "")) == hazard_id:
			return hazard
	return {}


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
