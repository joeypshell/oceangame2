extends RefCounted

const TARGET_ID := "slice_04_destination_cache"
const EXPECTED_PAYOFF_ID := "slice_04_destination_payoff"
const EXPECTED_FEEDBACK := "Destination cache +300"
const CAPTURE_ZOOM := Vector2(1.15, 1.15)
const CAMERA_OFFSET := Vector2(16, -20)

var _main


func _init(main_node) -> void:
	_main = main_node


func capture_and_quit(capture_dir: String) -> void:
	if _main._world == null or _main._player == null:
		push_error("Pass 22 destination payoff capture requires a loaded playable map.")
		_main.get_tree().quit(1)
		return
	if _main._world.map_id != "production_slice_04":
		push_error("Pass 22 destination payoff capture loaded unexpected map: %s." % _main._world.map_id)
		_main.get_tree().quit(1)
		return

	var target := _salvage_by_id(TARGET_ID)
	if target.is_empty():
		push_error("Pass 22 destination payoff capture requires target %s." % TARGET_ID)
		_main.get_tree().quit(1)
		return
	if str(target.get("destination_payoff_id", "")) != EXPECTED_PAYOFF_ID:
		push_error("Pass 22 destination payoff capture target metadata mismatch: %s." % target)
		_main.get_tree().quit(1)
		return

	var target_center: Vector2 = target["center"]
	_main._hazard_interactions_enabled = false
	_main._player.global_position = target_center
	if _main._player.has_method("reset_motion"):
		_main._player.reset_motion()
	_main._process(0.0)
	_main._update_status_label()
	if _main._last_status_note != EXPECTED_FEEDBACK or _status_text().find(EXPECTED_FEEDBACK) == -1:
		push_error("Pass 22 destination payoff capture expected feedback '%s', got note='%s' status='%s'." % [
			EXPECTED_FEEDBACK,
			_main._last_status_note,
			_status_text(),
		])
		_main.get_tree().quit(1)
		return
	_main.set_process(false)

	var camera := Camera2D.new()
	camera.name = "Pass22DestinationPayoffCaptureCamera"
	camera.zoom = CAPTURE_ZOOM
	camera.position_smoothing_enabled = false
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(_main._world.map_pixel_size.x)
	camera.limit_bottom = int(_main._world.map_pixel_size.y)
	_main.add_child(camera)
	camera.make_current()
	camera.position = target_center + CAMERA_OFFSET

	await _main.get_tree().process_frame
	await _main.get_tree().process_frame
	await _main.get_tree().process_frame

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var output_path := "%s/%s_pass_22_destination_payoff.png" % [capture_dir, _safe_filename(_main._world.map_id)]
	var image: Image = _main.get_viewport().get_texture().get_image()
	image.save_png(output_path)
	print("Saved Pass 22 destination payoff capture: %s" % ProjectSettings.globalize_path(output_path))
	_main.get_tree().quit()


func _salvage_by_id(salvage_id: String) -> Dictionary:
	for salvage in _main._world.get_salvage_centers():
		if str(salvage.get("id", "")) == salvage_id:
			return salvage
	return {}


func _status_text() -> String:
	return _main._status_label.text if _main._status_label != null else ""


func _safe_filename(value: String) -> String:
	var output := value.to_lower()
	for character in [" ", "\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		output = output.replace(character, "_")
	return output
