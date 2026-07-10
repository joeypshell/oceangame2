extends RefCounted

const EXPECTED_RESULT_COMPLETE := "Objective: Relay trail complete"
const CAPTURE_ZOOM := Vector2(0.7, 0.7)
const CAMERA_OFFSET := Vector2(180, 180)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Primary dive completion capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return

	var objective := _primary_objective()
	var required_targets := _required_targets(objective)
	if objective.is_empty() or required_targets.is_empty():
		push_error("Primary dive completion capture requires primary objective metadata.")
		_main.get_tree().quit(1)
		return

	_main._hazard_interactions_enabled = false
	for target_id in required_targets:
		var target := _salvage_by_id(target_id)
		if target.is_empty():
			push_error("Primary dive completion capture missing required target %s." % target_id)
			_main.get_tree().quit(1)
			return
		_main._player.global_position = target["center"]
		if _main._player.has_method("reset_motion"):
			_main._player.reset_motion()
		_main._collect_salvage_for_review_state(target)

	_main._player.global_position = _main._world.get_extraction_center()
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	_main.set_process(false)

	var result_text: String = _main._result_label.text if _main._result_label != null else ""
	if not _main._run_complete or result_text.find(EXPECTED_RESULT_COMPLETE) == -1:
		push_error("Primary dive completion capture expected completed objective result before saving: %s" % result_text)
		_main.get_tree().quit(1)
		return

	var camera := Camera2D.new()
	camera.name = "PrimaryDiveCompletionCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = _main._world.spawn_position + CAMERA_OFFSET

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_primary_dive_completion.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved primary dive completion capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _primary_objective() -> Dictionary:
	var primary_objective_id: String = _main._world.get_primary_route_objective_id()
	for objective in _main._world.get_route_objectives():
		if str(objective.get("id", "")) == primary_objective_id:
			return objective
	return {}


func _required_targets(objective: Dictionary) -> Array[String]:
	var targets: Array[String] = []
	for target_id in objective.get("required_banked_targets", []):
		targets.append(str(target_id))
	return targets


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
