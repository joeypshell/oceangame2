extends RefCounted

const STEP_CUE_MARKER_ID := "deep_cache_first_step_cue"
const TARGET_ID := "salvage_lower_loop"
const EXPECTED_CUE := "Objective route: Lower loop"
const CAPTURE_ZOOM := Vector2(0.86, 0.86)
const CAMERA_OFFSET := Vector2(32, -16)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 15 objective follow-through capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var marker: Dictionary = _main._world.get_marker_zone(STEP_CUE_MARKER_ID)
	var target := _salvage_by_id(TARGET_ID)
	if marker.is_empty() or target.is_empty():
		push_error("Pass 15 objective follow-through capture requires marker %s and target %s." % [STEP_CUE_MARKER_ID, TARGET_ID])
		_main.get_tree().quit(1)
		return

	var marker_center := _zone_center(marker)
	_main._hazard_interactions_enabled = false
	_main._player.global_position = marker_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	_main.set_process(false)

	var status_text: String = _main._status_label.text if _main._status_label != null else ""
	if status_text.find(EXPECTED_CUE) == -1:
		push_error("Pass 15 objective follow-through capture expected cue before saving: %s" % status_text)
		_main.get_tree().quit(1)
		return
	if _main._world.is_salvage_collected(TARGET_ID):
		push_error("Pass 15 objective follow-through capture collected %s before review frame." % TARGET_ID)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "Pass15ObjectiveFollowThroughCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = (marker_center + target["center"]) / 2.0 + CAMERA_OFFSET

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_objective_follow_through.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 15 objective follow-through capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


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
